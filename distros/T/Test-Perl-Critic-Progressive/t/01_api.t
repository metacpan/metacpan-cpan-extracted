#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Test-Perl-Critic-Progressive-0.03/t/01_api.t $
#     $Date: 2008-07-27 16:01:56 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 2620 $
########################################################################

use strict;
use warnings;
use Test::More tests => 6;
use Test::Perl::Critic::Progressive ( ':all' );
use English qw(-no_match_vars);

#---------------------------------------------------------------------------
# Accessor tests

{
    my ($expected, $got);

    $expected = 10;
    set_total_step_size($expected);
    $got = get_total_step_size();
    is($got, $expected, 'Accessor: set_total_step_size');

    $expected = 'foo/bar/baz';
    set_history_file($expected);
    $got = get_history_file();
    is($got, $expected, 'Accessor: set_history_file');

    my %given = (Foo => 1);
    my %expected = ('Perl::Critic::Policy::Foo' => 1);
    set_step_size_per_policy(%given);
    my %got = get_step_size_per_policy();
    is_deeply(\%got, \%expected, 'Accessor: set_step_size_per_policy');
}


#---------------------------------------------------------------------------
# Exception tests

{
    my $bogus_path = 'foo/bar/baz';

    eval{ progressive_critic_ok($bogus_path) };
    ok( defined $EVAL_ERROR, 'Critique bogus code file' );

    eval { Test::Perl::Critic::Progressive::_open_history_file($bogus_path) };
    like( $EVAL_ERROR, qr/Can't open/m, 'Open bogus history file' );

    my $got = eval { Test::Perl::Critic::Progressive::_read_history($bogus_path) };
    is_deeply( $got, [], 'Load bogus history file' );
}

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
