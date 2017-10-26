# Map endpoints to subroutine names in SSH::V1.
use strict;
{
    'keys/1.0/projects/{projectKey}/repos/{repositorySlug}/ssh GET' => 'get_keys_for_repository',
    'keys/1.0/projects/{projectKey}/repos/{repositorySlug}/ssh POST' => 'add_key_for_repository',
    'keys/1.0/projects/{projectKey}/repos/{repositorySlug}/ssh/{keyId} DELETE' => 'revoke_key_for_repository',
    'keys/1.0/projects/{projectKey}/repos/{repositorySlug}/ssh/{keyId} GET' => 'get_key_for_repository',
    'keys/1.0/projects/{projectKey}/repos/{repositorySlug}/ssh/{keyId}/permission/{permission} PUT' => 'update_permission_for_repository',
    'keys/1.0/projects/{projectKey}/ssh GET' => 'get_keys_for_project',
    'keys/1.0/projects/{projectKey}/ssh POST' => 'add_key_for_project',
    'keys/1.0/projects/{projectKey}/ssh/{keyId} DELETE' => 'revoke_key_for_project',
    'keys/1.0/projects/{projectKey}/ssh/{keyId} GET' => 'get_key_for_project',
    'keys/1.0/projects/{projectKey}/ssh/{keyId}/permission/{permission} PUT' => 'update_permission_for_project',
    'keys/1.0/ssh/{keyId} DELETE' => 'revoke_key',
    'keys/1.0/ssh/{keyId}/projects GET' => 'get_projects_for_key',
    'keys/1.0/ssh/{keyId}/repos GET' => 'get_repositories_for_key',
    'ssh/1.0/keys DELETE' => 'delete_ssh_keys',
    'ssh/1.0/keys GET' => 'get_ssh_keys',
    'ssh/1.0/keys POST' => 'add_ssh_key',
    'ssh/1.0/keys/{keyId} DELETE' => 'delete_ssh_key',
    'ssh/1.0/settings GET' => 'get_ssh_settings',
};
