class SongsController < ApplicationController
  before_action :require_login
  before_action :set_group

  def index
    authorize Song.new(group: @group), :index?
    @query = params[:q]
    @songs = @group.songs.search(@query).includes(:added_by).order(:artist, :title)
    @song = Song.new(group: @group)
  end

  def create
    @song = @group.songs.build(song_params.merge(added_by: current_user))
    authorize @song
    if save_song_with_activity
      redirect_to group_songs_path(@group), notice: "«#{@song.title}» wurde hinzugefügt."
    else
      @query = nil
      @songs = @group.songs.includes(:added_by).order(:artist, :title)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    song = @group.songs.find(params[:id])
    authorize song
    if destroy_song_with_activity(song)
      redirect_to group_songs_path(@group), notice: "«#{song.title}» wurde entfernt."
    else
      redirect_to group_songs_path(@group), alert: "«#{song.title}» wurde schon in einer Runde gespielt und kann nicht entfernt werden."
    end
  end

  private

  def save_song_with_activity
    Song.transaction do
      @song.save && Activity.record!(group: @group, action: "song_added", title: @song.title)
    end
  end

  def destroy_song_with_activity(song)
    Song.transaction do
      song.destroy && Activity.record!(group: @group, action: "song_removed", title: song.title)
    end
  end

  def set_group
    @group = policy_scope(Group).find(params[:group_id])
  end

  def song_params
    params.expect(song: [ :title, :artist, :audio_url ])
  end
end
