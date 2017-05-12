sub get_root {
	if (-f ".vssroot") {
		open(ROOT, ".vssroot");
		my $new_root = <ROOT>;
		close(ROOT);
		if ($new_root) {return $new_root}
	}

	warn <<EOL;

In order to run tests, we must have a valid VSS database,
if you would like to specify one and run the tests, please 
enter the path to it now.  Your response will be cached in a file 
named .vssroot in the source directory.  You can delete it 
if you wish and this question will be asked the next time 
you run the tests.  You can also just hit enter and we'll skip 
all the tests that require actually using the database.
EOL
	chomp(my $response = <STDIN>);

	if (!$response) {$response = 'SKIP'}
	else {
		if (!-f $response . '/srcsafe.ini') {
			warn "***There's no srcsafe.ini file at $response!***\n";
			return get_root();
		}
	}
	open(ROOT, ">.vssroot");
	print ROOT $response;
	close(ROOT);
	return $response;
}

sub no_db {
	return $ENV{VSSROOT} eq 'SKIP';
}

sub get_dir() {
	my $dir = VCS::Dir->new('vcs://localhost/VCS::Vss/');
	return $dir->content();
}

sub get_file() {
	foreach my $item (get_dir()) {
		if (ref($item) eq 'VCS::Vss::File') {
			return $item;
		}
	}
	return undef;
}

sub get_version() {
	my $file = get_file();
	return undef if !$file;
	my @versions = $file->versions();
	return undef if !@versions;
	return $versions[0];
}

1;