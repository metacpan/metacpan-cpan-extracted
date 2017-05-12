use warnings;
use strict;
use Archive::Tar;
$Archive::Tar::DO_NOT_USE_PREFIX = 1;

=head1 NAME

fix.pl

=head1 DESCRIPTION

This code found at http://perlmonks.org/index.pl?node_id=731935
via PAUSE's reports of failed uploads.

The author wrote:

	I found it way too hard to try to make Getopt::Std and Getopt::Long
	behave as I'd like It's much easier to just implement command line
	options parsing by h and... Careful: you cannot combine several
	single letter command line optio ns into one, They must stay separate.

I have removed command line options: the script now just takes
the path to a tarball to fix.

=cut

# DISTVNAME
while(@ARGV) {
    my $dist = shift;
    $dist =~ /\.t(ar\.)?gz$/
      or die "Wrong argument: '$dist'; please provide a '.tar.gz' file as argument";
    print "Loading distribution '$dist'\n";

    my $fixes;
    my $tar = Archive::Tar->new;
    if (not $tar->read($dist)){
		warn "Have you run make tardist?\n";
		next;
	}
    my @files = $tar->get_files;
    foreach my $file (@files) {
        my $fixedmode = my $mode = $file->mode;
        my $filetype = '';
        if($file->is_file) {
            $filetype = 'file';
            if(substr(${ $file->get_content_by_ref }, 0, 2) eq '#!') {
                $fixedmode = $ENV{PERM_RW}? '0'.$ENV{PERM_RW} : 0775;
            } else {
                $fixedmode = $ENV{PERM_RWX}? '0'.$ENV{PERM_RWX} : 0664;
            }
        }
        elsif($file->is_dir) {
            $filetype = 'dir';
			$fixedmode = $ENV{PERM_RW}? '0'.$ENV{PERM_RW} : 0775;;
        }
        else {
            next;
        }
        next if $mode eq $fixedmode;
        $file->mode($fixedmode);
        $fixes++;
        printf "Change mode %03o to %03o for %s '%s'\n", $mode, $fixedmode, $filetype, $file->name;
    }

    if ($fixes) {
		rename $dist, "$dist.bak" or die "Cannot rename file '$dist' to '$dist.bak': $!";
		$tar->write($dist, 9);
		print "File '$dist' saved.\n";
	} else {
        print "File '$dist' didn't need fixing, skipped.\n";
    }
}

