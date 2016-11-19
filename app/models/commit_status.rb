class CommitStatus < ActiveRecord::Base
  include Importable
  include AfterCommitQueue

  self.table_name = 'ci_builds'

  belongs_to :project, foreign_key: :gl_project_id
  belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :commit_id
  belongs_to :user

  delegate :commit, to: :pipeline

  validates :pipeline, presence: true, unless: :importing?

  validates_presence_of :name

  alias_attribute :author, :user

  scope :latest, -> do
    max_id = unscope(:select).select("max(#{quoted_table_name}.id)")

    where(id: max_id.group(:name, :commit_id))
  end

  scope :retried, -> { where.not(id: latest) }
  scope :ordered, -> { order(:name) }

  scope :failed_but_allowed, -> do
    where(allow_failure: true, status: [:failed, :canceled])
  end

  scope :exclude_ignored, -> do
    quoted_when = connection.quote_column_name('when')
    # We want to ignore failed_but_allowed jobs
    where("allow_failure = ? OR status IN (?)",
      false, all_state_names - [:failed, :canceled]).
      # We want to ignore skipped manual jobs
      where("#{quoted_when} <> ? OR status <> ?", 'manual', 'skipped').
      # We want to ignore skipped on_failure
      where("#{quoted_when} <> ? OR status <> ?", 'on_failure', 'skipped')
  end

  scope :latest_ci_stages, -> { latest.ordered.includes(project: :namespace) }
  scope :retried_ci_stages, -> { retried.ordered.includes(project: :namespace) }

  def self.all_state_names
    state_machines.values.flat_map(&:states).flat_map { |s| s.map(&:name) }
  end

  def self.status
    all.pluck(status_sql).first
  end

  def self.status_sql
    total = exclude_ignored.select('count(*)').to_sql
    created = exclude_ignored.created.select('count(*)').to_sql
    success = exclude_ignored.success.select('count(*)').to_sql
    pending = exclude_ignored.pending.select('count(*)').to_sql
    running = exclude_ignored.running.select('count(*)').to_sql
    skipped = exclude_ignored.skipped.select('count(*)').to_sql
    canceled = exclude_ignored.canceled.select('count(*)').to_sql
    warnings = failed_but_allowed.select('count(*)').to_sql

    "(CASE
      WHEN (#{total})=(#{success}) AND (#{warnings})>0 THEN 'success_with_warnings'
      WHEN (#{total})=(#{success}) THEN 'success'
      WHEN (#{total})=(#{created}) THEN 'created'
      WHEN (#{total})=(#{success})+(#{skipped}) THEN 'skipped'
      WHEN (#{total})=(#{success})+(#{skipped})+(#{canceled}) THEN 'canceled'
      WHEN (#{total})=(#{created})+(#{skipped})+(#{pending}) THEN 'pending'
      WHEN (#{running})+(#{pending})+(#{created})>0 THEN 'running'
      ELSE 'failed'
    END)"
  end

  def self.available_statuses
    %w[created pending running success failed canceled skipped]
  end

  def self.ordered_statuses
    %w[failed pending running canceled success skipped]
  end

  validates :status, inclusion: { in: available_statuses }

  state_machine :status, initial: :created do
    CommitStatus.available_statuses.each do |status|
      state status.to_sym, value: status
    end

    event :enqueue do
      transition [:created, :skipped] => :pending
    end

    event :process do
      transition skipped: :created
    end

    event :run do
      transition pending: :running
    end

    event :skip do
      transition [:created, :pending] => :skipped
    end

    event :drop do
      transition [:created, :pending, :running] => :failed
    end

    event :success do
      transition [:created, :pending, :running] => :success
    end

    event :cancel do
      transition [:created, :pending, :running] => :canceled
    end

    before_transition created: [:pending, :running] do |commit_status|
      commit_status.queued_at = Time.now
    end

    before_transition [:created, :pending] => :running do |commit_status|
      commit_status.started_at = Time.now
    end

    before_transition any => [:success, :failed, :canceled] do |commit_status|
      commit_status.finished_at = Time.now
    end

    after_transition do |commit_status, transition|
      next if transition.loopback?

      commit_status.run_after_commit do
        pipeline.try do |pipeline|
          if complete?
            PipelineProcessWorker.perform_async(pipeline.id)
          else
            PipelineUpdateWorker.perform_async(pipeline.id)
          end
        end
      end
    end

    after_transition any => :failed do |commit_status|
      commit_status.run_after_commit do
        MergeRequests::AddTodoWhenBuildFailsService
          .new(pipeline.project, nil).execute(self)
      end
    end
  end

  scope :created, -> { where(status: 'created') }
  scope :relevant, -> { where.not(status: 'created') }
  scope :running, -> { where(status: 'running') }
  scope :pending, -> { where(status: 'pending') }
  scope :success, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failed')  }
  scope :canceled, -> { where(status: 'canceled') }
  scope :skipped, -> { where(status: 'skipped') }
  scope :running_or_pending, -> { where(status: [:running, :pending]) }
  scope :finished, -> { where(status: [:success, :failed, :canceled]) }

  def active?
    %w[pending running].include?(status)
  end

  def complete?
    %w[success failed canceled].include?(status)
  end

  delegate :sha, :short_sha, to: :pipeline

  def before_sha
    pipeline.before_sha || Gitlab::Git::BLANK_SHA
  end

  def group_name
    name.gsub(/\d+[\s:\/\\]+\d+\s*/, '').strip
  end

  def self.stages
    # We group by stage name, but order stages by theirs' index
    unscoped.from(all, :sg).group('stage').order('max(stage_idx)', 'stage').pluck('sg.stage')
  end

  def self.stages_status
    # We execute subquery for each stage to calculate a stage status
    statuses = unscoped.from(all, :sg).group('stage').pluck('sg.stage', all.where('stage=sg.stage').status_sql)
    statuses.inject({}) do |h, k|
      h[k.first] = k.last
      h
    end
  end

  def failed_but_allowed?
    allow_failure? && (failed? || canceled?)
  end

  def playable?
    false
  end

  def duration
    if started_at && finished_at
      finished_at - started_at
    elsif started_at
      Time.now - started_at
    end
  end

  def stuck?
    false
  end
end
