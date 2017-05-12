#!perl -T

use warnings;
use strict;
use Test::More 'tests' => 5;

use_ok('WWW::Freelancer');
use WWW::Freelancer;

my $freelancer = WWW::Freelancer->new();
isa_ok( $freelancer, 'WWW::Freelancer' );

subtest 'project' => sub {
    plan 'tests' => 15;

    my $project = $freelancer->get_project(1000);
    isa_ok( $project, 'WWW::Freelancer::Project' );

    is( $project->get_id(),   '1000',           'id' );
    is( $project->get_name(), 'Website design', 'name' );
    is( $project->get_url(), 'http://www.freelancer.com/projects/1000.html',
        'url' );
    is( $project->get_start_unixtime(), '1081886916', 'start_unixtime' );
    is( $project->get_start_date, 'Tue, 13 Apr 2004 16:08:36 -0400',
        'start_date' );
    is( $project->get_end_unixtime, '1082491716', 'end_unixtime' );
    is( $project->get_end_date, 'Tue, 20 Apr 2004 16:08:36 -0400', 'end_date' );

    subtest 'buyer' => sub {
        plan tests => 4;

        my $buyer = $project->get_buyer();
        isa_ok( $buyer, 'WWW::Freelancer::Project::Buyer' );

        is( $buyer->get_url(), 'http://www.freelancer.com/users/15116.html',
            'url' );
        is( $buyer->get_id(),       '15116',     'id' );
        is( $buyer->get_username(), 'Pokereyez', 'username' );
    };

    is( $project->get_state, 'C', 'state' );
    like(
        $project->get_short_description,
        qr{\*\*Build a &amp;quot;Product Photography Website using web4usa.com \(FREE WEBSITE BUILDER\)},
        'short_descr'
    );

    subtest 'options' => sub {
        plan 'tests' => 7;

        my $options = $project->get_options();
        isa_ok( $options, 'WWW::Freelancer::Project::Options' );

        is( $options->is_featured(),         0, 'featured' );
        is( $options->is_nonpublic(),        0, 'non_public' );
        is( $options->is_trial(),            0, 'trial' );
        is( $options->is_fulltime(),         0, 'fulltime' );
        is( $options->is_for_gold_members(), 0, 'for_gold_members' );
        is( $options->is_hidden_bids(),      0, 'hidden_bids' );
    };

    subtest 'budget' => sub {
        plan 'tests' => 3;

        my $budget = $project->get_budget();
        isa_ok( $budget, 'WWW::Freelancer::Project::Budget' );

        is( $budget->get_minimum(), '100', 'min' );
        is( $budget->get_maximum(), '500', 'max' );
    };

    my @jobs = $project->get_jobs();
    ok( eq_array(
            \@jobs,
            [   'Banner Design',
                'Flash',
                'Graphic Design',
                'Photography',
                'Website Design'
            ]
        ),
        'jobs'
    );

    subtest 'bid_stats' => sub {
        plan 'tests' => 3;

        my $bid_stats = $project->get_bid_stats();
        isa_ok( $bid_stats, 'WWW::Freelancer::Project::BidStats' );

        is( $bid_stats->get_count(),   39,  'count' );
        is( $bid_stats->get_average(), 387, 'average' );
    };
};

my @projects = $freelancer->search_project( 'jobs' => ['Perl'] );
isa_ok( $projects[0], 'WWW::Freelancer::Project' );

subtest 'user' => sub {
    plan 'tests' => 6;

    my $user = $freelancer->get_user('alanhaggai');
    isa_ok( $user, 'WWW::Freelancer::User' );
    is( $user->get_url(), 'http://www.freelancer.com/users/156215.html',
        'get_url' );
    is( $user->get_id(),       '156215',     'get_id' );
    is( $user->get_username(), 'alanhaggai', 'get_username' );
    is( $user->get_registration_unixtime(),
        '1140974793', 'get_registration_unixtime' );
    is( $user->get_registration_date(),
        'Sun, 26 Feb 2006 12:26:33 -0500',
        'get_registration_date'
    );
};
