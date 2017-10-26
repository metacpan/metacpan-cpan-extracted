# Map endpoints to subroutine names in MirroringUpstream::V1.
use strict;
{
    'mirroring/1.0/account/settings/preferred-mirror DELETE' => 'remove_preferred_mirror',
    'mirroring/1.0/account/settings/preferred-mirror GET' => 'get_preferred_mirror',
    'mirroring/1.0/account/settings/preferred-mirror POST' => 'set_preferred_mirror',
    'mirroring/1.0/analyticsSettings GET' => 'get_analytics_settings',
    'mirroring/1.0/authenticate POST' => 'authenticate',
    'mirroring/1.0/mirrorServers GET' => 'get_mirrors',
    'mirroring/1.0/mirrorServers/{mirrorId} DELETE' => 'remove_mirror',
    'mirroring/1.0/mirrorServers/{mirrorId} GET' => 'get_mirror',
    'mirroring/1.0/mirrorServers/{mirrorId}/webPanels/config GET' => 'render_webpanel',
    'mirroring/1.0/repos GET' => 'get_repositories',
    'mirroring/1.0/repos/{repoId} GET' => 'get_repository',
    'mirroring/1.0/repos/{repoId}/mirrors GET' => 'get_repository_mirrors',
    'mirroring/1.0/requests GET' => 'get_requests',
    'mirroring/1.0/requests POST' => 'create_request',
    'mirroring/1.0/requests/{mirroringRequestId} DELETE' => 'delete_request',
    'mirroring/1.0/requests/{mirroringRequestId} GET' => 'get_request',
    'mirroring/1.0/requests/{mirroringRequestId}/accept POST' => 'accept_request',
    'mirroring/1.0/requests/{mirroringRequestId}/reject POST' => 'reject_request',
};
