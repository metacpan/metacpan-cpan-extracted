# Map endpoints to subroutine names in JIRA::V1.
use strict;
{
    'jira/1.0/comments/{commentId}/issues POST' => 'create_issue',
    'jira/1.0/issues/{issueKey}/commits GET' => 'get_commits',
    'jira/1.0/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/issues GET' => 'get_issue_keys_for_pull_request',
};
