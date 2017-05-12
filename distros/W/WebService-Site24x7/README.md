# NAME

WebService::Site24x7 - An api client for https://site24x7.com

# SYNOPSIS

    use WebService::Site24x7;

    my $site24x7 = WebService::Site24x7->new(
        auth_token        => '...'
        user_agent_header => 'mybot v1.0',
    );

    # All methods return a $response hashref which contains the jason response

    $site24x7->current_status;
    $site24x7->current_status(monitor_id => $monitor_id);
    $site24x7->current_status(group_id => $group_id);
    $site24x7->current_status(type => $type);

    $site24x7->monitors->list;

    $site24x7->location_profiles->list;
    $site24x7->location_template;  # get a list all locations

    $site24x7->reports->log_reports($monitor_id, date => $date);
    $site24x7->reports->performance($monitor_id,
        location_id => $location_id,
        granularity => $granularity,
        period      => $period,
    );

# DESCRIPTION

WebService::Site24x7 is an api client for [https://site24x7.com](https://site24x7.com).  It
currently implements a really limited subset of all the endpoints though.

# SEE ALSO

[https://www.site24x7.com/help/api/index.html](https://www.site24x7.com/help/api/index.html)

# LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>
