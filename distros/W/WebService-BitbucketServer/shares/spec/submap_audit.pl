# Map endpoints to subroutine names in Audit::V1.
use strict;
{
    'audit/1.0/projects/{projectKey}/events GET' => 'get_events_for_project',
    'audit/1.0/projects/{projectKey}/repos/{repositorySlug}/events GET' => 'get_events_for_repository',
};
