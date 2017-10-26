# Map endpoints to subroutine names in DefaultReviewers::V1.
use strict;
{
    'default-reviewers/1.0/projects/{projectKey}/condition POST' => 'create_pull_request_condition',
    'default-reviewers/1.0/projects/{projectKey}/condition/{id} DELETE' => 'delete_pull_request_condition',
    'default-reviewers/1.0/projects/{projectKey}/condition/{id} PUT' => 'update_pull_request_condition',
    'default-reviewers/1.0/projects/{projectKey}/conditions GET' => 'get_pull_request_conditions',
    'default-reviewers/1.0/projects/{projectKey}/repos/{repositorySlug}/condition POST' => 'create_pull_request_condition_for_repository',
    'default-reviewers/1.0/projects/{projectKey}/repos/{repositorySlug}/condition/{id} DELETE' => 'delete_pull_request_condition_for_repository',
    'default-reviewers/1.0/projects/{projectKey}/repos/{repositorySlug}/condition/{id} PUT' => 'update_pull_request_condition_for_repository',
    'default-reviewers/1.0/projects/{projectKey}/repos/{repositorySlug}/conditions GET' => 'get_pull_request_conditions_for_repository',
    'default-reviewers/1.0/projects/{projectKey}/repos/{repositorySlug}/reviewers GET' => 'get_reviewers_for_repository',
};
