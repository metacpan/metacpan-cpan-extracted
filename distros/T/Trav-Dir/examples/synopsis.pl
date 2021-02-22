#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use Trav::Dir;
my $o = Trav::Dir->new (
    # Don't traverse directories matching these patterns
    no_trav => qr!/(\.git|xt|blib)$!,
    # Reject files matching this pattern
    rejfile => qr!~$|MYMETA|\.tar\.gz!,
    # Don't add directories to @files
    no_dir => 1,
);
my @files;
chdir "$Bin/..";
$o->find_files (".", \@files);
for (sort @files) {
    print "$_\n";
}
