#! /usr/bin/perl -w
use strict;
$| = 1;

# $Id$
# This file checks to see if the new Test::Smoke::Policy object
# does the same as the old way Merijn originaly wrote

my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;
use Test::Smoke::Util qw( get_config );
use Data::Dumper;
use Test::More tests => 3 + 8 + 24 + 2;

use_ok( 'Test::Smoke::Policy' );

my $l_policy = <<EOPOLICY;
#! /bin/sh

# Testfile: set -DDEBUGGING -DHAVE_COW

ccflags='-DDEBUGGING -DHAVE_COW'
EOPOLICY

my $pobj = Test::Smoke::Policy->new( \$l_policy );
isa_ok( $pobj, 'Test::Smoke::Policy' );

like( $pobj->{_policy}, q!/^ccflags='-DDEBUGGING -DHAVE_COW'/m!,
      "Got the right policy" );

my $Policy = $l_policy;
# Create a simple configuration (with policy-target)
my @config = (
  { policy_target => '-DHAVE_COW', args => [ '', '-DHAVE_COW'] },
  [ '', '-Dusethreads'],
  { policy_target => '-DDEBUGGING', args => [ '', '-DDEBUGGING' ] },
);

my @p_conf = ( "", "" );
run_tests( \@p_conf, $Policy, "-Dusedevel", [ ], @config );

# Need more tests!
$pobj   = Test::Smoke::Policy->new; # default policy
$Policy = $pobj->{_policy};
@config = get_config( undef );
@p_conf = ( "", "" );
run_tests( \@p_conf, $Policy, '-Dusedevel', [ ], @config );

# This is a "short-copy" of the mktest.pl
sub run_tests {
    my( $p_conf, $policy, $old_config_args, $substs, $this_test, @tests ) = @_;

    my $policy_target;
    if ( ref $this_test eq 'HASH' ) {
        $policy_target = $this_test->{policy_target};
        $this_test     = $this_test->{args};
    }

    foreach my $conf ( @$this_test ) {
        my $config_args = $old_config_args;
        # Try not to add spurious spaces as it confuses mkovz.pl
        length $conf and $config_args .= " $conf";
        $pobj->reset_rules;
        $pobj->set_rules( $_ ) for @$substs;
        my @substs = @$substs;
        if (defined $policy_target) {
            # This set of permutations also need to subst inside Policy.sh
            # somewhere.
            push @substs, [$policy_target, $conf];
            $pobj->set_rules( [$policy_target,$conf] );
        }

        if (@tests) {
            # Another level of tests
            run_tests ($p_conf, $policy, $config_args, \@substs, @tests);
            next;
        }
        # Turn the array of instructions on what to substitute into one or
        # more regexps. Initially we have a list of target/value pairs.
        my %substs;
        # First group all the values by target.
        foreach (@substs) {
            push @{$substs{$_->[0]}}, $_->[1];
        }
        # use Data::Dumper; print Dumper (\@substs, \%substs);
        # Then for each target do the substitution.
        # If more than 1 value wishes to substitute, join them with spaces
        my $this_policy = $policy;
        while (my ($target, $values) = each %substs) {
#diag( "TRADITIONAL: '$target'-> '@$values' " , 
#      ($this_policy=~/^(ccflags.*)/m) );
            unless ($this_policy =~ s/$target/join " ", @$values/seg) {
                warn "Policy target '$target' failed to match";
            }
        }

        $pobj->_do_subst;
#diag( Dumper $pobj );

        my @old = grep ! /^#/ => split /\n/, $this_policy;
        my @new = grep ! /^#/ => split /\n/, $pobj->{_new_policy};
#diag( Dumper \@old, \@new );
        is_deeply( \@new, \@old, "Policy.sh up-to-date: $config_args" );
      
    }
}


{ # Test the new default_Policy

    my @ccflags = qw( -DPERL_COPY_ON_WRITE -DDEBUGGING );

    my $p = Test::Smoke::Policy->new( undef, 0, @ccflags );

    isa_ok $p, "Test::Smoke::Policy";
    like $p->{_policy}, "/ccflags='@ccflags'/",
        "Default policy created with '@ccflags'";
}
