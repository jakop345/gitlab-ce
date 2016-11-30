require 'spec_helper'

describe PipelineConcludeWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when pipeline is completed' do
      let(:pipeline) { create(:ci_pipeline, status: :success) }

      it 'does not drop pipeline' do
        expect_no_pipeline_drop { worker.perform(pipeline.id) }
      end
    end

    context 'when pipeline is not completed' do
      let(:pipeline) do
        create(:ci_pipeline, status: :running)
      end

      context 'when pipeline is locked and can be unlocked' do
        before do
          create(:ci_build, :success, pipeline: pipeline)
        end

        it 'does not drop pipeline' do
          expect_no_pipeline_drop { worker.perform(pipeline.id) }
        end
      end

      context 'when updating pipeline has no effect' do
        before do
          create(:ci_build, :running, pipeline: pipeline)
        end

        it 'drops the pipeline' do
          expect_pipeline_drop { worker.perform(pipeline.id) }
        end
      end
    end
  end

  def expect_pipeline_drop
    expect_any_instance_of(Ci::Pipeline)
      .to receive(:drop).once

    yield
  end

  def expect_no_pipeline_drop
    expect_any_instance_of(Ci::Pipeline)
      .not_to receive(:drop)

    yield
  end
end
