package Yars::Command::yars_fast_balance;

# PODNAME: yars_fast_balance
# ABSTRACT: Fix all files
our $VERSION = '1.27'; # VERSION


use strict;
use warnings;
use 5.010;
use Yars::Client;
use Log::Log4perl ();
use Clustericious::Log::CommandLine ':all', ':loginit' => { level => $Log::Log4perl::INFO };
use Clustericious::Log;
use Clustericious::Config;
use Hash::MoreUtils qw/safe_reverse/;
use File::Find::Rule;
use Fcntl qw(:DEFAULT :flock);
use File::Basename qw/dirname/;
use Getopt::Long qw( GetOptions );
use Pod::Usage qw( pod2usage );

our $conf;
our $yc;

sub _is_empty_dir {
  # http://www.perlmonks.org/?node_id=617410
  #my ($shortname, $path, $fullname) = @_;
  my $fullname = $_[2];
  my $dh;
  opendir($dh, $fullname) || return;
  my $count = scalar(grep{!/^\.\.?$/} readdir $dh);
  closedir $dh;
  return($count==0);
}

sub cleanup_subdir {
    my ($dir) = @_;
    while (_is_empty_dir(undef,undef,$dir) ) {
        last unless $dir =~ m{/[0-9a-f]{2}$};
        rmdir $dir or do { WARN "cannot rmdir $dir : $!"; last; };
        $dir =~ s{/[^/]+$}{};
    }
}

sub cleanup_directory {
    my $dir = shift;
    DEBUG "Looking for empty directories in $dir";
    my @found = File::Find::Rule->new->directory->exec(\&_is_empty_dir)->in($dir);
    return unless @found;
    for my $empty (@found) {  ### Cleaning up $dir ... [%]
        TRACE "Cleaning up $empty";
        cleanup_subdir($empty);
    }
}

sub _lock {
    my $filename = shift;
    my $fh;
    open $fh, ">> $filename" or do {
        TRACE "Cannot lock $filename : $!";
        return;
    };
    flock( $fh, LOCK_EX | LOCK_NB ) or do {
        WARN "cannot flock $filename";
        close $fh;
        return;
    };
    return $fh;
}

sub _unlock {
    my $fh = shift;
    flock $fh, LOCK_UN;
}

sub upload_file {
    my $filename = shift;
    TRACE "Moving $filename";
    $yc //= Yars::Client->new;
    $yc->upload('--nostash', 1, $filename) or do {
        WARN "Could not upload $filename : ".$yc->errorstring;
        return;
    };
    unlink $filename or do {
        WARN "Could not unlink $filename : $!";
        return;
    };
    cleanup_subdir(dirname($filename));
}

sub upload_directory {
    my $dir = shift;
    my @found = File::Find::Rule->new->file->in($dir);
    return unless @found;
    for my $file (@found) {  ### Uploading files from $dir ... [%]
        my $fh = _lock($file) or next;
        upload_file($file);
        _unlock($fh);
    }
}

sub check_disk {
    my $root = shift;
    my @this = grep { $_->{root} eq $root } map @{ $_->{disks} }, $conf->servers;
    LOGDIE "Found ".@this." matches for $root" unless @this==1;
    my $disk = $this[0];
    my @buckets = @{ $disk->{buckets} };
    my @wrong;
    for my $dir (glob "$root/*") {
        $dir =~ s/^$root\///;
        next unless $dir =~ /^[0-9a-f]{2}$/;
        next if grep { $dir =~ /^$_/i } @buckets;
        push @wrong, $dir;
    }
    if (@wrong==0) {
        INFO "Disk $root : ok";
        return;
    }
    INFO "Disk $root : ".@wrong." stashed directories";
    for my $dir (@wrong) {
        cleanup_directory("$root/$dir");
        upload_directory("$root/$dir");
    }
}

sub main {
    my $class = shift;
    local @ARGV = @_;
    GetOptions(
        'help|h'  => sub { pod2usage({ -verbose => 2}) },
        'version' => sub {
            say 'Yars version ', ($Yars::Command::yars_fast_balance::VERSION // 'dev');
            exit 1;
        },
    ) || pod2usage(1);
    $conf = Clustericious::Config->new("Yars");
    my @disks = map $_->{root}, map @{ $_->{disks} }, $conf->servers;
    LOGDIE "No disks" unless @disks;
    for my $disk (@disks) {
       next unless -d $disk;
       check_disk($disk);
    }
}

1;

__END__

=pod

=head1 NAME

Yars::Command::yars_fast_balance - code for yars_fast_balance

=head1 DESCRIPTION

This module contains the machinery for the command line program L<yars_fast_balance>

=head1 SEE ALSO

L<yars_disk_scan>

=cut