# Map endpoints to subroutine names in CommentLikes::V1.
use strict;
{
    'comment-likes/1.0/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/comments/{commentId}/likes DELETE' => 'unlike_commit',
    'comment-likes/1.0/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/comments/{commentId}/likes GET' => 'get_commit_likers',
    'comment-likes/1.0/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/comments/{commentId}/likes POST' => 'like_commit',
    'comment-likes/1.0/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/comments/{commentId}/likes DELETE' => 'unlike_pull_request',
    'comment-likes/1.0/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/comments/{commentId}/likes GET' => 'get_pull_request_likers',
    'comment-likes/1.0/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/comments/{commentId}/likes POST' => 'like_pull_request',
};
