package # Don't index by CPAN
	Test::Manifest::Tempdir;

=head1 Test::Manifest::_Tempdir

Helper module for tests. The exported function C<prepare_tmp_dir>
creates a temp directory and copies some files to it in order to run
tests there instead of the original C<t/> directory, enabling to
change the files even for parallel test processing.

=cut

use warnings;
use strict;

use Exporter qw(import);
our @EXPORT = qw(prepare_tmp_dir);

use File::Copy qw(copy);
use File::Spec;
use File::Temp qw(tempdir);

sub prepare_tmp_dir {
	my $tmp_dir = tempdir( CLEANUP => 1 ) or die "Cannot create tmp dir: $!";
	mkdir my $tmp_t_dir = File::Spec->catfile($tmp_dir, 't')
		or die "Cannot create dir t in $tmp_dir: $!";
	opendir my $t_dir_handle, 't' or die "Cannot read dir t: $!";
	for my $filename (readdir $t_dir_handle) {
		my $fullname = File::Spec->catfile('t', $filename);
		copy($fullname, $tmp_t_dir)
			or die "Cannot copy $fullname to $tmp_t_dir: $!"
			if -f $fullname;
	}
	return $tmp_dir;
}

1;
