package Test::Dirs;

use warnings;
use strict;

our $VERSION = '0.07';

use base 'Exporter';
our @EXPORT = qw(
    temp_copy_ok
    is_dir
    dir_cleanup_ok
);

use File::Temp;
use Test::Builder;
use File::Copy::Recursive 'dircopy';
use Carp 'confess';
use File::DirCompare;
use List::MoreUtils 'any';
use Text::Diff 'diff';
use Path::Class;
use File::Path 2.07 'remove_tree';

our $test = Test::Builder->new;

sub temp_copy_ok {
	my $src_dir = shift or confess 'pass source folder as argument';
	my $message = shift || 'copy of '.$src_dir;
	
	if (not -d $src_dir) {
		$test->ok(0, $message);
		confess($src_dir.' is not a folder');
	}
	
	my $dst_dir = File::Temp->newdir();
	dircopy($src_dir, $dst_dir->dirname)
		or die 'failed to copy '.$src_dir.' to temp folder '.$dst_dir.' '.$!;
	$test->ok(1, $message);
	
	return $dst_dir;
}

sub is_dir {
	my $dir1 = shift or confess 'pass folders as argument';
	my $dir2 = shift or confess 'pass two folders as argument';
	my $message = shift || 'cmp '.$dir1.' with '.$dir2;
	my $ignore_ref = shift || [];
	my $verbose = shift;

	$verbose = $ENV{TEST_VERBOSE}
		unless defined($verbose);

	if ( $ENV{FIXIT} ) {
		dircopy( $dir1, $dir2 )
			or die 'failed to copy '
			. $dir1
			. ' to temp folder '
			. $dir2 . ' '
			. $!;
		$test->ok( 1, 'FIXIT: ' . $message );
		return;
	}

	my $have_two_folders = -d $dir1 && -d $dir2;
	unless ($have_two_folders) {
		$test->ok( -d $dir2, 'expected-param "' . $dir2 . '" is directory' );
		$test->ok( -d $dir1, 'is-param "' . $dir1 . '" is directory' );
		return;
	}

	my @ignore_files = @{$ignore_ref};
	my @differences;
	File::DirCompare->compare($dir1, $dir2, sub {
		my ($a, $b) = @_;
		my ($a_short, $b_short);
		
		if ($a) {
			$a_short = substr($a, length($dir1)+1);
			return if any { $_ eq $a_short } @ignore_files;
		}
		if ($b) {
			$b_short = substr($b, length($dir2)+1);
			return if any { $_ eq $b_short } @ignore_files;
		}
		
		if (not $b) {
			push @differences, 'Only in '.$dir1.': '.$a_short;
		} elsif (not $a) {
			push @differences, 'Only in '.$dir2.': '.$b_short;
		} else {
			push @differences, 'File "'.$a_short.'" differ';
			if ($verbose) {
				if (-f $a and -d $b) {
					push @differences, 'in '.$dir1.' is a regular file while in '.$dir2.' is a directory';
				}
				elsif (-d $a and -f $b) {
					push @differences, 'in '.$dir1.' is a directory while in '.$dir2.' is a regular file';
				}
				else {
					push @differences, diff($b, $a);
				}
			}
		}
	});
	
	if (not @differences) {
		$test->ok(1, $message);
		return;
	}
	
	$test->ok(0, $message);
	foreach my $difference (@differences) {
		$test->diag($difference);
	}
}

sub dir_cleanup_ok {
	my $filename = shift or confess 'pass filename as argument';
	my $message  = shift;

	$filename    = File::Spec->catfile(@{$filename})
		if (ref $filename eq 'ARRAY');
	if (-f $filename) {
		$filename = file($filename)->dir->stringify;
	}
	
	$message ||= 'cleaning up '.$filename.' folder and all empty folders up';
	
	my $removed_filenames;
	my $rm_err;
	remove_tree($filename, {result => \$removed_filenames, keep_root => 1, error => \$rm_err});
	if (@{$rm_err}) {
		$test->ok(0, $message);
		$test->diag("Error:\n", @{$rm_err});
		return;
	}
	@{$removed_filenames} = map { File::Spec->catfile($filename, $_)."\n" } @{$removed_filenames};
	
	# remove the file folder and all empty folders upwards
	while (rmdir $filename) {
		push @{$removed_filenames}, $filename."\n";
		$filename = file($filename)->parent->stringify;
	}

	$test->ok(1, $message);
	$test->diag("Removed:\n", @{$removed_filenames});
}


'A car is not merely a faster horse.';


__END__

=head1 NAME

Test::Dirs - easily copy and compare folders inside tests

=head1 SYNOPSIS

	use Test::More tests => 5;
	use Test::Dirs;
	
	# make a temporary copy of a folder
	my $tmp_dir = temp_copy_ok($src_dir, 'copy template to tmp folder');
	
	# compare one folder with another
	is_dir($src_dir, $tmp_dir, 'temp copy should be the same as source');
	
	# set files to ignore
	my @ignore_files = qw(.ignore_me);
	open(my $fh, '>', File::Spec->catfile($tmp_dir, '.ignore_me')) or die $!;
	is_dir($src_dir, $tmp_dir, 'temp copy should be the same as source', \@ignore_files);
	
	TODO: {
		local $TODO = 'do something with the extra file in the future';
		is_dir($src_dir, $tmp_dir, 'fails without @ignore_files');
	};
	
	# force verbose, print out the diff if doesn't match
	is_dir($src_dir, $tmp_dir, 'test with verbose on', \@ignore_files, 'verbose');
	
=head1 DESCRIPTION

Exports test function L</is_dir> to compare two folders if their file
structure match and a function to make a temporary copy of a folder
L</temp_copy_ok> so it can be safely manipulated and compared to another
folder.

Can be used to test modules or programs that are manipulating a whole folder
structure via making a temporary copy of a initial folder state. Calling
module or a program to manipulate files inside this temporary folder and
then comparing it to a desired folder state.

In addition there is a L</dir_cleanup_ok> function that can be used to
completely remove folder structures that are not important for comparing.

=head1 EXPORTS

    temp_copy_ok()
    is_dir()
    dir_cleanup_ok()

=head1 FUNCTIONS

=head2 temp_copy_ok($src_dir, $message)

Will recursively copy C<$src_dir> to a L<File::Temp/newdir> folder and
returning L<File::Temp::Dir> object. This object will stringify to a
path and when destroyed (will leave the scope) folder is automatically
deleted.

C<$message> is optional.

=head2 is_dir($is_dir, $expected_dir, $message, \@ignore_files, $verbose)

Compares C<$is_dir> with C<$expected_dir>. Files that has to be ignored (are not important)
can be specified as C<@ignore_files>. The filenames are relative to the C<$dir1(2)>
folders.

C<$verbose> will output unified diff between C<$expected_dir> and C<$is_dir>.

Setting C<FIXIT> env to true will make this function copy C<$is_dir> folder
content into C<$expected_dir>. Usefull for bootstraping test results or for
acnkowledging results after code update.

C<$message>, C<\@ignore_files>, C<$verbose> are optional.
Default verbose value is C<$ENV{TEST_VERBOSE}>.

=head2 dir_cleanup_ok($filename, $message)

If the C<$filename> is a folder. Removes this folder and all empty
folders upwards.

If the C<$filename> is a file. Removes parent folder of this file and all empty
folders upwards.

C<$message> is optional.

PS: Just be careful :-)

=head1 SEE ALSO

L<File::DirCompare>, L<File::Copy::Recursive>, L<File::Temp>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Jozef Kutej

=cut
