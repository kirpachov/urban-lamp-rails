# frozen_string_literal: true

class Video < ApplicationRecord
  validates :download_jid, uniqueness: { allow_nil: true, case_sensitive: false }

  validates_uniqueness_of :url, scope: :playlist_id, allow_nil: true

  belongs_to :playlist
  belongs_to :user

  before_validation :assign_defaults

  scope :valid_media, -> { where(valid_media: true) }
  scope :invalid_media, -> { where(valid_media: false) }

  scope :with_url, -> { where.not(url: nil) }
  scope :without_url, -> { where(url: nil) }

  scope :with_download_jid, -> { where.not(download_jid: nil) }
  scope :without_download_jid, -> { where(download_jid: nil) }

  scope :ready_for_download, -> { with_url.without_download_jid.where('download_attempts < ?', Config.max_download_attempts) }

  def download_later
    update(download_jid: DownloadVideoJob.perform_async(id))
  end

  # params:
  #  async: DownloadVideoJob instance || nil
  def download(params = {})
    DownloadVideo.run(params.merge(video: self))
  end

  def default_downloader
    puts "TODO: #{self.class}##{__method__} should return a downloader based on the video url." unless Rails.env.test?
    'VideoDownloader'
  end

  private

  def assign_defaults
    self.download_jid ||= nil
  end
end
