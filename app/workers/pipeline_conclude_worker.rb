# This worker is used to repair or drop stuck pipelines that are created
# more than one week ago. It is called by PipelineUnlockWorker.
#
class PipelineConcludeWorker
  include Sidekiq::Worker
  include PipelineQueue

  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      return if pipeline.complete?
      return unless pipeline.created_at < 1.week.ago

      # We try to repair pipeline for the last time.
      #
      PipelineUpdateWorker.new.perform(pipeline_id)

      pipeline.drop unless pipeline.reload.complete?
    end
  end
end
