#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Util::H2O;

# trying to figure out the "redefine" CPAN Testers failures
# https://www.cpantesters.org/distro/U/Util-H2O.html?oncpan=1&distmat=1&version=0.18&grade=3
# https://www.cpantesters.org/distro/U/Util-H2O.html?oncpan=1&distmat=1&version=0.20&grade=3
# 'Subroutine Util::H2O::_7f53e778fd48::DESTROY redefined at /home/cpan/pit/bare/conf/perl-5.22.0/.cpanplus/5.22.0/build/5VoT4ISXn_/Util-H2O-0.20/blib/lib/Util/H2O.pm line 440.'
# https://github.com/haukex/Util-H2O/issues/17

# I suspect it was the fact that the `h2o -clean=>0, -meth, { DESTROY=>sub{} }`
# test was running before the "redefine" test.

# The following test code shows the failure on Perls 5.22 and up,
# at least on my machine; on CPAN Testers there were also some failures on 5.20

# I added some delete_package calls to the tests to see if that helps.

#use warnings FATAL=>'redefine';
sub warns (&) { my @w; { local $SIG{__WARN__} = sub { push @w, shift }; shift->() } @w }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn)

my %packs;
my @w = warns {
	for (1..100) {
		my $o = h2o -clean=>0, -meth, { DESTROY=>sub{} };
		$packs{ref $o}++;
	}
	for (1..100) {
		my $o = h2o -clean=>1, {};
		#print "Reused ",ref $o,"\n" if exists $packs{ref $o};
		$packs{ref $o}++;
	}
};
delete @packs{ grep {$packs{$_}<2} keys %packs };
note explain \%packs, \@w;
ok grep { /redefined/i } @w, 'I was able to reproduce the warning'
	or diag explain \%packs, \@w;

done_testing;
