#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Test::Fatal;
use Test::More;

use lib File::Spec->catdir( qw(t lib) );

use Toggl::MockRequest;
use WebService::Toggl;


{
    my $mock_request = Toggl::MockRequest->new;
    my $toggl = WebService::Toggl->new({
        _request => $mock_request,
    });

    like exception { $toggl->summary() },
        qr{missing.+required.+argument.+workspace_id}i,
            'workspace_id is required!';
    like exception { $toggl->summary({workspace_id => "moo"}) },
        qr{did not pass type constraint.+workspace_id}i, 'workspace_id is wrong type!';

    like exception { $toggl->summary({workspace_id => 1, since => "moo"}) },
        qr{did not pass type constraint.+since}i, 'since is wrong type!';

    like exception { $toggl->summary({workspace_id => 1, until => "moo"}) },
        qr{did not pass type constraint.+until}i, 'until is wrong type!';

    ok my $report = $toggl->summary({workspace_id => 1});
    ok $report->$_() for (qw(total_grand total_billable total_currencies));

    is ref($report->data), 'ARRAY', 'got array of report data';
}


done_testing();
