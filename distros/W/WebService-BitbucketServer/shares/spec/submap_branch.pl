# Map endpoints to subroutine names in Branch::V1.
use strict;
{
    'branch-utils/1.0/projects/{projectKey}/repos/{repositorySlug}/branches DELETE' => 'delete_branch',
    'branch-utils/1.0/projects/{projectKey}/repos/{repositorySlug}/branches POST' => 'create_branch',
    'branch-utils/1.0/projects/{projectKey}/repos/{repositorySlug}/branches/info/{commitId} GET' => 'find_branch_info_by_commit',
    'branch-utils/1.0/projects/{projectKey}/repos/{repositorySlug}/branchmodel GET' => 'get_branch_model',
};
