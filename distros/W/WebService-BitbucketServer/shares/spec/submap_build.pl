# Map endpoints to subroutine names in Build::V1.
use strict;
{
    'build-status/1.0/commits/stats POST' => 'get_multiple_build_status_stats',
    'build-status/1.0/commits/stats/{commitId} GET' => 'get_build_status_stats',
    'build-status/1.0/commits/{commitId} GET' => 'get_build_status',
    'build-status/1.0/commits/{commitId} POST' => 'add_build_status',
};
