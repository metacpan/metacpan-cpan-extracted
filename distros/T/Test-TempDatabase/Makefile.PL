use ExtUtils::MakeMaker;

my %prereq = ('Test::More' => 0, 'DBD::Pg' => 0, 'DBI' => 0,
		     'File::Slurp' => '');
if ($<) {
	my $psql = `psql -l 2>&1`;
	if ($psql !~ /template1/) {
		warn "To install this module you should be postgres admin";
		$prereq{"You::Should::Be::Postgres::Admin"} = '';
	}
}

WriteMakefile(
    NAME         => 'Test::TempDatabase',
    VERSION_FROM => 'lib/Test/TempDatabase.pm', # finds $VERSION
    AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
    ABSTRACT     => 'Creates and destructs temporary database for testing purposes',
    PREREQ_PM    => \%prereq,
);
