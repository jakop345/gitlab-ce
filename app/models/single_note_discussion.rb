class SingleNoteDiscussion < Discussion
  def potentially_resolvable?
    false
  end

  def single_note?
    true
  end
end
