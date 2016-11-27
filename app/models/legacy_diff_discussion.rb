class LegacyDiffDiscussion < DiffDiscussion
  def legacy_diff_discussion?
    true
  end

  def potentially_resolvable?
    false
  end

  def collapsed?
    !active?
  end
end
