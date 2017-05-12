#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec ();
use Test::More;

use lib File::Spec->catdir( qw(t lib) );

use Toggl::MockRequest;
use WebService::Toggl;


{
    my $mock_request = Toggl::MockRequest->new;
    my $toggl = WebService::Toggl->new({
        _request => $mock_request,
    });


    ok my $me = $toggl->me;
    is $me->email, 'johnt@swift.com';
    is $me->fullname, 'John Swift';

    ok my $workspace_set = $me->workspaces;
    ok my @workspaces = $workspace_set->all;
    is scalar(@workspaces), 1;
    is $workspaces[0]->name, q{John's WS};

    is $mock_request->get_call_count, 1, 'Only one call (to me) made';

    ok my $project_set = $me->projects;
    ok my @projects = $project_set->all;
    is scalar(@projects), 1;
    is $projects[0]->name, q{Important project};

    ok my $client_set = $me->clients;
    ok my @clients = $client_set->all;
    is scalar(@clients), 1;
    is $clients[0]->name, q{Best client};

    ok my $time_entry_set = $me->time_entries;
    ok my @time_entries = $time_entry_set->all;
    is scalar(@time_entries), 1;
    is $time_entries[0]->description, q{Best work so far};

    ok my $tag_set = $me->tags;
    ok my @tags = $tag_set->all;
    is scalar(@tags), 2;
    is $tags[0]->name, q{billable};
    is $tags[1]->name, q{important};

}


done_testing();
