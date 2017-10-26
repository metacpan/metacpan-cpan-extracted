# Map endpoints to subroutine names in Git::V1.
use strict;
{
    'git/1.0/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/rebase GET' => 'can_rebase',
    'git/1.0/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/rebase POST' => 'rebase',
    'git/1.0/projects/{projectKey}/repos/{repositorySlug}/tags POST' => 'create_tag',
    'git/1.0/projects/{projectKey}/repos/{repositorySlug}/tags/{name:.*} DELETE' => 'delete_tag',
};
