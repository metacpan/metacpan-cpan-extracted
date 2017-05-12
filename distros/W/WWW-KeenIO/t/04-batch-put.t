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
    my @data1 = map {
        {
            hostname => hostname(),
              time     => q{} . localtime(),
                sequence => $_,
                data     => rand()
            } 
    } 1..3;
    my @data2 = map {
        {
            hostname => hostname(),
              time     => q{} . localtime(),
                sequence => $_,
                data     => rand()
            } 
    } 1..2;
    ok(
        $r = $obj->batch_put(
            {
                data1 => \@data1,
                data2 => \@data2
               }
        ),
        'Insert object'
    );
    note( 'Error ' . $obj->error_message() ) unless $r;
 }

done_testing;
