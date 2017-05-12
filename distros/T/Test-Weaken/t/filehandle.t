#!/usr/bin/perl

# A test case provided by Kevin Ryde,
# with minor changes.

package MyObject;
use strict;
use warnings;
use Scalar::Util;
use Fatal qw(open);

sub new {
    my ($class) = @_;
    ## no critic (InputOutput::RequireBriefOpen)
    open my $out, '<', '/dev/null';
    ## use critic
    return bless { fh => $out }, $class;
} ## end sub new

package main;
use strict;
use warnings;
use Test::Weaken;
use Test::More tests => 3;

{
    my $leak;
    my $test = Test::Weaken::leaks(
        {   constructor => sub {
                my $obj = MyObject->new;
                $leak = $obj->{'fh'}
                    or Carp::croak('MyObject has no fh attribute');
                return $obj;
            },
            tracked_types => ['GLOB'],
        }
    );
    Test::More::ok( $test, 'leaky file handle detection' );
    Test::More::is( $test && $test->unfreed_count, 1, 'one object leaked' );
}

{

## use Marpa::Test::Display tracked_types snippet

    my $test = Test::Weaken::leaks(
        {   constructor => sub {
                my $obj = MyObject->new;
                return $obj;
            },
            tracked_types => ['GLOB'],
        }
    );

## no Marpa::Test::Display

    Test::More::ok( ( not defined $test ), 'file handle detection' );
}

exit 0;
