package OutputDir;
use strict;
use warnings;
use Carp;
use File::Spec;
use DirHandle;
use FileHandle;

sub BEGIN {
	my $dirname = File::Spec->catfile("t", "output");
	mkdir $dirname || croak "error: $!";

	my $dir = DirHandle->new($dirname);
	if (defined $dir) {
		while (defined($_ = $dir->read)) {
			unlink File::Spec->catfile($dirname, $_);
		}
	}
}

1
