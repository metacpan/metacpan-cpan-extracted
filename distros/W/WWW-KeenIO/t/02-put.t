#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Sys::Hostname;

BEGIN {
    use_ok('WWW::KeenIO') || print "Bail out!\n";
}

# skip tests under automated testing or without user and pass
my $automated = $ENV{AUTOMATED_TESTING};
my $skip_reason;

if ($automated) {
    $skip_reason = 'skip live tests under $ENV{AUTOMATED_TESTING}';
}

if (   !$automated
    && !$ENV{KEEN_PROJ_ID}
    && !$ENV{KEEN_API_KEY} )
{

    $skip_reason =
'set $ENV{KEEN_PROJ_ID}, $ENV{KEEN_API_KEY} and (optionally) $ENV{KEEN_API_WRITE_KEY}';
}

SKIP: {
    skip( $skip_reason, 3 ) if $skip_reason;

    diag "Running tests with live WWW::KeenIO service\n";

    my $class = 'WWW::KeenIO';
    my $obj   = new_ok(
        $class => [
            {
                project   => $ENV{KEEN_PROJ_ID},
                api_key   => $ENV{KEEN_API_KEY},
                write_key => $ENV{KEEN_API_WRITE_KEY}
            }
        ]
    );

    my $r;
    ok(
        $r = $obj->put(
            'tests',
            {
                hostname => hostname(),
                time     => q{} . localtime(),
                data     => rand()
            }
        ),
        'Insert object'
    );
    note( 'Error ' . $obj->error_message() ) unless $r;
    my $saved_project = $obj->project;
    $obj->project('aaa');    # fake
    ok( !( $r = $obj->put( 'tests', {} ) ), 'Handle insertion error' );
}

done_testing;
