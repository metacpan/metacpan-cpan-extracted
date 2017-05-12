#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec ();
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

    like exception { $toggl->summary({workspace_id => 1, grouping => 'moo'}) },
        qr{did not pass type constraint.+grouping}, 'Failed type for grouping!';

    like exception { $toggl->summary({workspace_id => 1, subgrouping => 'moo'}) },
        qr{did not pass type constraint.+subgrouping}, 'Failed type for subgrouping!';


    ok my $report = $toggl->summary({workspace_id => 1});

    is $report->total_grand, 36004000;
    is $report->total_billable, 14400000;
    is_deeply $report->total_currencies, [{"currency"=>"EUR","amount"=>40}];
    is $report->total_grand, 36004000;

    is ref($report->data), 'ARRAY', 'got array of report data';
}


done_testing();
