require 'spec_helper'

describe PipelineUnlockWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when locked pipelines are present' do
      context 'when multiple pipelines are locked in the last stage' do
        let(:created_pipeline) do
          create(:ci_pipeline, status: :created,
                               updated_at: 10.hours.ago)
        end

        let(:pending_pipeline) do
          create(:ci_pipeline, status: :pending,
                               updated_at: 10.hours.ago)
        end

        let(:running_pipeline) do
          create(:ci_pipeline, status: :running,
                               updated_at: 10.hours.ago)
        end

        before do
          create_build(created_pipeline, :pending, stage: 'test')
          create_build(pending_pipeline, :success, stage: 'test')
          create_build(running_pipeline, :failed, stage: 'test')
        end

        it 'processes each pipeline that needs update' do
          pipelines = [created_pipeline, pending_pipeline, running_pipeline]

          expect_pipeline_processing(*pipelines) { worker.perform }
        end

        it 'does not drop pipelines' do
          expect_no_pipeline_drop { worker.perform }
        end
      end

      context 'when locked pipeline has multiple stages ahead' do
        let(:pipeline) do
          create(:ci_pipeline, status: :running,
                               updated_at: 10.hours.ago)
        end

        before do
          create_build(pipeline, :success, stage: 'build', stage_idx: 1)
          create_build(pipeline, :created, stage: 'test', stage_idx: 2)
          create_build(pipeline, :created, stage: 'deploy', stage_idx: 3)
        end

        it 'retriggers pipeline processing' do
          expect_pipeline_processing(pipeline) { worker.perform }
        end

        it 'does not drop pipelines' do
          expect_no_pipeline_drop { worker.perform }
        end
      end

      context 'when locked pipeline is more than week old' do
        context 'when pipeline is unfinished' do
          let(:pipeline) do
            create(:ci_pipeline, status: :created,
                                 created_at: 2.weeks.ago)
          end

          before do
            create_build(pipeline, :success)
          end

          it 'does not trigger update' do
            expect_no_pipeline_processing { worker.perform }
          end

          it 'drops the pipeline' do
            expect_pipeline_drop(pipeline) { worker.perform }
          end
        end

        context 'when pipeline is complete' do
          let(:pipeline) do
            create(:ci_pipeline, status: :success,
                                 created_at: 2.weeks.ago)
          end

          before do
            create_build(pipeline, :success)
          end

          it 'does not trigger update' do
            expect_no_pipeline_processing { worker.perform }
          end

          it 'does not trigger pipeline drop' do
            expect_no_pipeline_drop { worker.perform }
          end
        end
      end
    end

    context 'when locked pipelines are not present' do
      context 'when there is a running pipeline' do
        let(:pipeline) do
          create(:ci_pipeline, status: :running,
                               updated_at: 4.hours.ago)
        end

        before do
          create_build(pipeline, :success)
        end

        it 'does not trigger update' do
          expect_no_pipeline_processing { worker.perform }
        end

        it 'does not trigger conclude worker' do
          expect_no_pipeline_drop { worker.perform }
        end
      end

      context 'when there are no pipelines at all' do
        it 'does nothing' do
          expect_no_pipeline_processing { worker.perform }
          expect_no_pipeline_drop { worker.perform }
        end
      end
    end
  end

  def create_build(pipeline, status, opts = {})
    create(:ci_build, opts.merge(pipeline: pipeline, status: status))
  end

  def expect_pipeline_processing(*pipelines, &block)
    expect_pipeline_worker(PipelineProcessWorker, *pipelines, &block)
  end

  def expect_no_pipeline_processing(&block)
    expect_no_pipeline_worker(PipelineProcessWorker, &block)
  end

  def expect_pipeline_drop(*pipelines, &block)
    expect_pipeline_worker(PipelineConcludeWorker, *pipelines, &block)
  end

  def expect_no_pipeline_drop(&block)
    expect_no_pipeline_worker(PipelineConcludeWorker, &block)
  end

  def expect_pipeline_worker(worker, *pipelines)
    pipeline_ids = pipelines.map(&:id).in_groups_of(1)

    expect(Sidekiq::Client).to receive(:push_bulk)
      .with(hash_including('class' => worker,
                            'args' => pipeline_ids))
      .once

    yield
  end

  def expect_no_pipeline_worker(worker)
    expect(Sidekiq::Client).not_to receive(:push_bulk)
      .with(hash_including('class' => worker))

    yield
  end
end
