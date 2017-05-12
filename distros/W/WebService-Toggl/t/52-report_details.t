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

    like exception { $toggl->details({workspace_id => 1, page => 'moo'}) },
        qr{did not pass type constraint.+page}, 'Failed type for page!';

    ok my $report = $toggl->details({workspace_id => 1});

    is $report->total_grand, 23045000;
    is $report->total_billable, 23045000;
    is_deeply $report->total_currencies, [{"currency"=>"EUR","amount"=>128.07}];
    is $report->per_page, 50;
    # XXX this doesn't agree with docs
    # is $report->total_count, 2;

    is ref($report->data), 'ARRAY', 'got array of report data';
}


done_testing();
