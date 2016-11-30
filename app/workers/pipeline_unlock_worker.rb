class PipelineUnlockWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    process_stuck_pipelines
    finish_outdated_pipelines
  end

  private

  def process_stuck_pipelines
    Ci::Pipeline.unfinished.with_builds
      .where('ci_commits.updated_at < ?', 6.hours.ago)
      .where('ci_commits.created_at > ?', 1.week.ago)
      .order(:id).pluck(:id).tap do |ids|
        break if ids.empty?

        Sidekiq::Client.push_bulk('class' => PipelineProcessWorker,
                                  'args' => ids.in_groups_of(1))
      end
  end

  def finish_outdated_pipelines
    Ci::Pipeline.unfinished
      .where('ci_commits.created_at < ?', 1.week.ago)
      .order(:id).pluck(:id).tap do |ids|
        break if ids.empty?

        Sidekiq::Client.push_bulk('class' => PipelineConcludeWorker,
                                  'args' => ids.in_groups_of(1))
      end
  end
end
