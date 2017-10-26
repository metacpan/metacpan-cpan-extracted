# Map endpoints to subroutine names in RepositoryRefSync::V1.
use strict;
{
    'sync/1.0/projects/{projectKey}/repos/{repositorySlug} GET' => 'get_status',
    'sync/1.0/projects/{projectKey}/repos/{repositorySlug} POST' => 'set_enabled',
    'sync/1.0/projects/{projectKey}/repos/{repositorySlug}/synchronize POST' => 'synchronize',
};
