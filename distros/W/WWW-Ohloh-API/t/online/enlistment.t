use strict;
use warnings;

use Test::More;

use WWW::Ohloh::API;

plan skip_all => <<'END_MSG', 1 unless $ENV{OHLOH_KEY};
set OHLOH_KEY to your api key to enable these tests
END_MSG

my $p_id = $ENV{TEST_OHLOH_PROJECT}
  or plan skip_all => "set TEST_OHLOH_PROJECT to enable these tests";

plan 'no_plan';

my $ohloh = WWW::Ohloh::API->new( debug => 1, api_key => $ENV{OHLOH_KEY} );

diag "using project $p_id";

my @enlistments = $ohloh->get_enlistments( project_id => $p_id )->all
  or diag "no enlistments found";

validate_enlistment($_) for @enlistments;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub validate_enlistment {
    my $e = shift;

    diag "enlistment";

    like $e->id,            qr/^\d+$/, 'id()';
    like $e->project_id,    qr/^\d+$/, 'project_id()';
    like $e->repository_id, qr/^\d+$/, 'repository_id()';

    validate_repository( $e->repository );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub validate_repository {
    my $r = shift;

    diag "repository";

    like $r->id => qr/^\d+$/, 'id()';
    like $r->type => qr/^(Svn|Git|Cvs)Repository$/, 'type()';
    ok length $r->url, 'url()';
    $r->module_name;
    $r->username;
    $r->password;
    like $r->logged_at        => qr/20\d\d/,             'logged_at';
    like $r->commits          => qr/^\d+$/,              'commits()';
    like $r->ohloh_job_status => qr/^(success|failed)$/, 'ohloh_job_status';
}
