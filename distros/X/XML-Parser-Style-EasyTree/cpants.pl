#!/usr/bin/env perl -w

use Module::CPANTS::Analyse;

my $dist;
$dist = shift if @ARGV;
($dist) = sort {$b cmp $a} sort <*.tar.gz> unless $dist;
($dist) = sort {$b cmp $a} <dist/*.tar.gz> unless $dist;
$dist or die "No dist";
printf "Testing dist $dist\n";
my $analyser=Module::CPANTS::Analyse->new({
	dist => $dist,
});
$analyser->unpack;
$analyser->analyse;
$analyser->calc_kwalitee;

printf "\n== Prereq ==\n";
for (@{$analyser->d->{prereq}}) {
	printf "%-30s v%-10s (%s)\n",$_->{requires},$_->{version},
		$_->{is_optional_prereq} ? 'optional' :
		$_->{is_build_prereq}    ? 'build' :
		$_->{is_prereq}          ? 'runtime' :
		'???';
}

printf "\n== Kwalitee:%s ==\n",$analyser->d->{kwalitee}{kwalitee};
for (keys %{ $analyser->d->{kwalitee} }) {
	print "$_: 0\n" unless $analyser->d->{kwalitee}{$_};
}
if ($analyser->d->{kwalitee}{kwalitee} < 41) {
	die "Kwalitee lower than 41\n";
}

END {
	-e 'Debian_CPANTS.txt' and do { unlink 'Debian_CPANTS.txt' or $! and warn $! };
}
