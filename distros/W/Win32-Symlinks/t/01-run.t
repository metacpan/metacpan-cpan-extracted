use Win32::Symlinks;
use Test::More;
use File::Spec ();
use Cwd ();

if ($^O eq 'MSWin32') {
	my @parts = File::Spec->splitpath(Cwd::cwd());
	my $volume = shift @parts;
	my $error;
	if ($volume and $volume =~ /^\w:$/) {
		my $cmd = $ENV{COMSPEC} || 'cmd.exe';
		my $r = `"$cmd" /c fsutil fsinfo volumeinfo $volume 2>&1`;
		if ($r !~ /:\s+NTFS\n/) {
			$error = 'This code seems to be running on a filesystem different than NTFS.';
		}
	} else {
		$error = 'Could not detect the current system volume.';
	}
	if ($error) {
		plan skip_all => $error;
	}
}

my $l_operator_works = 1;
my $mklink_works = 1;
if ($^O eq 'MSWin32') {
    $l_operator_works = $] >= 5.016;
    $mklink_works = Win32::Symlinks::_mklink_works();
}
unless ($mklink_works) {
    plan skip_all => "mklink is not available on this system, cannot test symlink";
}

plan tests => $l_operator_works ? 25 : 20;



my $folder1 = 'testfolder_'.int time;
my $folder2 = 'testfolder_link_'.int time;
my $file1 = 'testfile1_'.int time;
my $file2 = 'testfile_link_'.int time;
my $invalid_path = 'invalid_path_'.int time;
my $content1 = 'Hello world! '.scalar localtime;
sleep 1;
my $content2 = 'Hello world! '.scalar localtime;


mkdir $folder1;
open my $out, '>', $file1 or die "Cannot create file $file1: $!";
print $out $content1;
close $out;

# 1
is -f $file1, 1, "File $file1 exists";

# 2
my $file1_data = slurp ($file1);
is $file1_data, $content1, "File $file1 has the right content";

# 3, 4, 5
symlink $folder1, $folder2;
# In Perl 5.18, a folder symlink is true for -f and false for -d. So, let's try both.
# The important thing is that it's found by one of them and that -l actually works fine.
is -d $folder2 || -f $folder2, 1, "Folder $folder2 exists";
if ($l_operator_works) {
    is -l $folder2, 1, "Folder $folder2 is a symlink";
}
is readlink($folder2), $folder1, 'Symlink points correctly';

# 6, 7, 8
symlink File::Spec->catfile('..', $file1), File::Spec->catfile($folder2, $file2);
is -f File::Spec->catfile($folder2, $file2), 1, "File $folder2/$file2 exists";
if ($l_operator_works) {
    is -l File::Spec->catfile($folder2, $file2), 1, "File $folder2/$file2 is a symlink";
}
is readlink(File::Spec->catfile($folder2, $file2)), File::Spec->catfile('..', $file1), 'Symlink points correctly';

# 9
my $file2_data = slurp (File::Spec->catfile($folder2, $file2));
is $file2_data, $content1, "File $folder2/$file2 data is correct";

open my $out2, '>', File::Spec->catfile($folder2, $file2) or die "Cannot write to $file2: $!";
print $out2 $content2;
close $out2;

# 10
$file2_data = slurp (File::Spec->catfile($folder2, $file2));
is $file2_data, $content2, "File $folder2/$file2 new data is correct";

# 11
$file1_data = slurp ($file1);
is $file1_data, $content2, "File $file1 new data is correct";

# 12, 13, 14, 15, 16, 17
symlink $invalid_path, 'invalid_symlink';
if ($l_operator_works) {
    is -l 'invalid_symlink', 1, 'Invalid symlink was created and is symlink';
}
isnt -f 'invalid_symlink', 1, 'Invalid symlink returns false with -f';
isnt -d 'invalid_symlink', 1, 'Invalid symlink returns false with -d';
isnt -e 'invalid_symlink', 1, 'Invalid symlink returns false with -e';
is readlink('invalid_symlink'), $invalid_path, 'Readlink works with invalid symlink';
unlink 'invalid_symlink';
if ($l_operator_works) {
    isnt -l 'invalid_symlink', 1, 'Invalid symlink is gone';
}

# 18
unlink $folder2;
isnt -d $folder2, 1, "Folder $folder2 is gone with unlink";

# 19, 20, 21
is -f File::Spec->catfile($folder1, $file2), 1, "File $folder1/$file2 still exists in Folder $folder1";
if ($l_operator_works) {
    is -l File::Spec->catfile($folder1, $file2), 1, "File $folder1/$file2 is a symlink as expected";
}
$file1_data = slurp (File::Spec->catfile($folder1, $file2));
is $file1_data, $content2, 'The content of the symlinked file is correct';

# 22
unlink File::Spec->catfile($folder1, $file2);
isnt -f File::Spec->catfile($folder1, $file2), 1, "File $folder1/$file2 is gone with unlink";

# 23
unlink $file1;
isnt -f $file1, 1, "File $file1 is gone with unlink";

# 24
unlink $folder1;
is -d $folder1, 1, "Folder $folder1 was not removed by unlink";

# 25
rmdir $folder1;
isnt -d $folder1, 1, "Folder $folder1 is gone";

sub slurp {
	my $path = shift;
	open my $in, '<', $path or die $!;
	my $data = do { local $/; <$in> };
	close $in;
	return $data;
}