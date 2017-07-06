package Yars::Command::yars_disk_scan;

# PODNAME: yars_disk_scan
# ABSTRACT: scan a disk for corruption and report corrupt files to stdout
our $VERSION = '1.28'; # VERSION


use strict;
use warnings;
use 5.010;
use Clustericious::Config;
use Clustericious::Log::CommandLine qw/:all/;
use Clustericious::Log;
use File::Find::Rule;
use Digest::file qw/digest_file_hex/;
use Getopt::Long qw( GetOptions );
use Pod::Usage qw( pod2usage );
use Fcntl ':flock';

sub main {
    my $class = shift;
    my $status = 0;
    my $conf = Clustericious::Config->new("Yars");
    my $opt_all = 0;
    my $opt_lock;
    local @ARGV = @_;
    GetOptions(
        'all|a'   => \$opt_all,
        'help|h'  => sub { pod2usage({ -verbose => 2}) },
        'lock=s'  => \$opt_lock,
        'version' => sub {
            say 'Yars version ', ($Yars::Command::yars_disk_scan::VERSION // 'dev');
            exit 1;
        },
    ) || pod2usage(1);
    my @disks = $opt_all ? (map $_->{root}, map @{ $_->{disks} }, $conf->servers) : (@ARGV);
    LOGDIE "Usage : $0 [-a] [disk1] [disk2] ...\n" unless @disks;
    
    if($opt_lock) {
        use autodie;
        state $fh;
        open $fh, '>', $opt_lock;
        unless(flock $fh, LOCK_EX | LOCK_NB) {
            INFO "There is already a scan in process...";
            return 0;
        }
    }
    
    for my $root (@disks) {
        -d $root or next;
        -r $root or next;
        my $found_bad = 0;
        INFO "Checking disk $root";
        File::Find::Rule->new->file->exec(sub {
             my $md5 = $File::Find::dir;
             my $root_re = quotemeta $root;
             $md5 =~ s/^$root_re//;
             $md5 =~ s[/][]g;
             if ($md5 =~ /^tmp/) {
                DEBUG "Skipping tmp file in $File::Find::dir";
                return;
             }
             TRACE "Checking $_ $md5";
             my $computed = digest_file_hex($_,'MD5');
             if ($computed eq $md5) {
                DEBUG "ok $md5 $_";
             } else {
                DEBUG "not ok $md5 $_ (got $computed)";
                print "Found bad files on $root :\n" unless $found_bad++;
                print "$md5 $_\n";
                $status = 2;
             }
             })->in($root);
    }
    $status;
}

1;

__END__

=pod

=head1 NAME

Yars::Command::yars_disk_scan - code for yars_disk_scan

=head1 DESCRIPTION

This module contains the machinery for the command line program L<yars_disk_scan>

=head1 SEE ALSO

L<yars_disk_scan>

=cut