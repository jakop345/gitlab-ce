class Discussion
  MEMOIZED_VALUES = []

  attr_reader :notes

  delegate  :created_at,
            :project,
            :author,

            :noteable,
            :for_commit?,
            :for_merge_request?,

            to: :first_note

  delegate  :resolved_at,
            :resolved_by,

            to: :last_resolved_note,
            allow_nil: true

  def self.build(notes)
    notes.first.discussion_class.new(notes)
  end

  def self.build_collection(notes)
    notes.group_by(&:discussion_id).values.map { |notes| build(notes) }
  end

  def initialize(notes)
    @notes = notes
  end

  def last_resolved_note
    return unless resolved?

    @last_resolved_note ||= resolved_notes.sort_by(&:resolved_at).last
  end
  MEMOIZED_VALUES << :last_resolved_note

  def last_updated_at
    last_note.created_at
  end

  def last_updated_by
    last_note.author
  end

  def id
    first_note.discussion_id
  end

  alias_method :to_param, :id

  def diff_discussion?
    false
  end

  def potentially_resolvable?
    true
  end

  def single_note?
    false
  end

  def resolvable?
    return @resolvable if @resolvable.present?

    @resolvable = potentially_resolvable? && notes.any?(&:resolvable?)
  end
  MEMOIZED_VALUES << :resolvable

  def resolved?
    return @resolved if @resolved.present?

    @resolved = resolvable? && notes.none?(&:to_be_resolved?)
  end
  MEMOIZED_VALUES << :resolved

  def first_note
    @first_note ||= @notes.first
  end
  MEMOIZED_VALUES << :first_note

  def last_note
    @last_note ||= @notes.last
  end
  MEMOIZED_VALUES << :last_note

  def resolved_notes
    notes.select(&:resolved?)
  end

  def to_be_resolved?
    resolvable? && !resolved?
  end

  def can_resolve?(current_user)
    return false unless current_user
    return false unless resolvable?

    current_user == self.noteable.author ||
      current_user.can?(:resolve_note, self.project)
  end

  def resolve!(current_user)
    return unless resolvable?

    update { |notes| notes.resolve!(current_user) }
  end

  def unresolve!
    return unless resolvable?

    update { |notes| notes.unresolve! }
  end

  def collapsed?
    if resolvable?
      # New diff discussions only disappear once they are marked resolved
      resolved?
    else
      false
    end
  end

  def expanded?
    !collapsed?
  end

  def reply_attributes
    {
      noteable_type: first_note.noteable_type,
      noteable_id:   first_note.noteable_id,
      commit_id:     first_note.commit_id,
      discussion_id: self.id,
      note_type:     first_note.type
    }
  end

  private

  def update
    # Do not select `Note.resolvable`, so that system notes remain in the collection
    notes_relation = Note.where(id: notes.map(&:id))

    yield(notes_relation)

    # Set the notes array to the updated notes
    @notes = notes_relation.fresh.to_a

    MEMOIZED_VALUES.each do |var|
      instance_variable_set(:"@#{var}", nil)
    end
  end
end
