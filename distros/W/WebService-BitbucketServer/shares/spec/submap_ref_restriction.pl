# Map endpoints to subroutine names in RefRestriction::V2.
use strict;
{
    'branch-permissions/2.0/projects/{projectKey}/repos/{repositorySlug}/restrictions GET' => 'get_restrictions_for_repository',
    'branch-permissions/2.0/projects/{projectKey}/repos/{repositorySlug}/restrictions POST' => 'create_restrictions_for_repository',
    'branch-permissions/2.0/projects/{projectKey}/repos/{repositorySlug}/restrictions/{id} DELETE' => 'delete_restriction_for_repository',
    'branch-permissions/2.0/projects/{projectKey}/repos/{repositorySlug}/restrictions/{id} GET' => 'get_restriction_for_repository',
    'branch-permissions/2.0/projects/{projectKey}/restrictions GET' => 'get_restrictions',
    'branch-permissions/2.0/projects/{projectKey}/restrictions POST' => 'create_restriction',
    'branch-permissions/2.0/projects/{projectKey}/restrictions/{id} DELETE' => 'delete_restriction',
    'branch-permissions/2.0/projects/{projectKey}/restrictions/{id} GET' => 'get_restriction',
};
