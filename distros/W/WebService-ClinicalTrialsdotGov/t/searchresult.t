
use strict;
use warnings;

use Test::More tests => 10;

use_ok('WebService::ClinicalTrialsdotGov::SearchResult');

my $rh_study = {
        'last_changed' => 'June 9, 2010',
        'condition_summary' => 'Breast Cancer; Cognitive/Functional Effects; Colorectal Cancer; Psychosocial Effects of Cancer and Its Treatment',
        'nct_id' => 'NCT00740961',
        'status' => {
                    'open' => 'Y',
                    'content' => 'Recruiting'
                  },
        'order' => '6',
        'url' => 'http://ClinicalTrials.gov/show/NCT00740961',
        'title' => 'Older Patients With Newly Diagnosed Breast Cancer or Colon Cancer',
        'score' => '0.93349'
};

my $SERP =
   WebService::ClinicalTrialsdotGov::SearchResult->new( $rh_study );

isa_ok( $SERP, 'WebService::ClinicalTrialsdotGov::SearchResult' );

is(
   $SERP->last_changed,
   $rh_study->{last_changed},
);

is(
   $SERP->condition_summary,
   $rh_study->{condition_summary},
);

is(
   $SERP->nct_id,
   $rh_study->{nct_id},
);

is(
   $SERP->status,
   $rh_study->{status},
);

is(
   $SERP->order,
   $rh_study->{order},
);

is(
   $SERP->url,
   $rh_study->{url},
);

is(
   $SERP->title,
   $rh_study->{title},
);
is(
   $SERP->score,
   $rh_study->{score},
);



