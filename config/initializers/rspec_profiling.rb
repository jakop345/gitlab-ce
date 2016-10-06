if Rails.env.test?
  RspecProfiling.configure do |config|
    config.collector = RspecProfiling::Collectors::CSV
    config.csv_path = -> do
      if ENV['CI']
        "tmp/rspec_profiling_#{ENV['CI_NODE_INDEX']}_#{ENV['CI_NODE_TOTAL']}.csv"
      else
        "tmp/rspec_profiling_#{Time.now.to_i}.csv"
      end
    end
  end
end
