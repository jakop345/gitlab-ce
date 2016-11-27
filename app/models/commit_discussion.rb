class CommitDiscussion < Discussion
  def potentially_resolvable?
    false
  end
end
