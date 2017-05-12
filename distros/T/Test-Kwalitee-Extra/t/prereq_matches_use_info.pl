use Module::CPANTS::Kwalitee::Prereq;

my ($error, $remedy, $berror, $bremedy);

my $ref = Module::CPANTS::Kwalitee::Prereq->kwalitee_indicators;
foreach my $val (@$ref) {
	($error, $remedy) = @{$val}{qw(error remedy)} if $val->{name} eq 'prereq_matches_use';
	($berror, $bremedy) = @{$val}{qw(error remedy)} if $val->{name} eq 'build_prereq_matches_use';
}
$error   ||= q{This distribution uses a module or a dist that's not listed as a prerequisite.};
$remedy  ||= q{List all used modules in META.yml requires};
$berror  ||= q{This distribution uses a module or a dist in its test suite that's not listed as a build prerequisite.};
$bremedy ||= q{List all modules used in the test suite in META.yml build_requires};

return ($error, $remedy, $berror, $bremedy);
