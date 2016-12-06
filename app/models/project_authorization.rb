class ProjectAuthorization < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  validates :project, presence: true
  validates :access_level, inclusion: { in: Gitlab::Access.all_values }, presence: true
  validates :user, uniqueness: { scope: [:project, :access_level] }, presence: true

  def self.insert_authorizations(rows)
    connection.execute <<-EOF.strip_heredoc
    INSERT INTO project_authorizations (user_id, project_id, access_level)
    VALUES #{rows.map { |tuple| "(#{tuple.join(', ')})" }.join(', ')}
    EOF
  end
end
