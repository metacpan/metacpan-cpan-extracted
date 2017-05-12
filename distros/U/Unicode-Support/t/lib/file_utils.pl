use utf8;
use strict;
use warnings;

sub make_test_dir {
	my $test_dir = 'test_dir';
	mkdir $test_dir, 0700 unless -d $test_dir;
	chdir $test_dir;
	remove_files();
	}
	
sub create_file {
	open my $fh, '>', $_[0];
	say $fh 'test';
	close $fh;	
	}

sub remove_files {
	my $file_count = file_count();
	my $unlinked   = unlink files();
	is( $file_count, $unlinked, "Unlinked $unlinked of $file_count files" );
	}

sub file_count { scalar grep { ! -d and ! -l } files() }

sub files { glob( '*' ) }

sub get_code_numbers {
	 join ' ', map { sprintf 'U+%04X', ord($_) }  $_[0] =~ m/(.)/sg;
	 }

1;
