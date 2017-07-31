package Yars::Tools;

use strict;
use warnings;
use Clustericious::Config;
use List::Util qw/ shuffle uniq /;
use Hash::MoreUtils qw/safe_reverse/;
use Clustericious::Log;
use File::Find::Rule;
use File::Basename qw/dirname/;
use File::Path qw/mkpath/;
use File::Temp;
use File::Compare;
use JSON::MaybeXS ();
# TODO: rm dep on stat
use File::stat qw/stat/;
use Mojo::ByteStream qw/b/;
use File::Spec;
use Mojo::UserAgent;
use File::Spec;
use Yars::Util qw( format_tx_error );
use File::Glob qw( bsd_glob );

# ABSTRACT: various utility functions dealing with servers, hosts, etc
our $VERSION = '1.30'; # VERSION


sub new
{
  my($class, $config) = @_;
  WARN "No url found in config file" unless eval { $config->url };
  my $self = bless {
    bucket_to_url                => { }, # map buckets to server urls
    bucket_to_root               => { }, # map buckets to disk roots
    disk_is_local                => { }, # our disk roots (values are just 1)
    servers                      => { }, # all servers
    our_url                      => '',  # our server url
    state_file                   => '',  # name of file with disk states
    ua                           => '',  # UserAgent
    server_status_cache          => {},
    server_status_cache_lifetime => 3,
    default_dir                  => '',
  }, $class;
  $self->refresh_config($config);
  $self;
}

sub _set_ua
{
  my($self, $ua) = @_;
  $self->{ua} = $ua;
  return;
}

sub _ua
{
  my($self) = @_;
  my $ua = $self->{ua} ? $self->{ua}->() : Mojo::UserAgent->new;
  $ua->max_redirects(30);
  $ua;
}


sub refresh_config {
  my $self = shift;
  my $config = shift;
  return 1 if defined($self->{our_url}) && keys %{ $self->{bucket_to_root} } > 0 && keys %{ $self->{bucket_to_url} } > 0;
  $config ||= Clustericious::Config->new("Yars");
  $self->{our_url} ||= $config->url or WARN "No url found in config file";
  TRACE "Our url is " . $self->{our_url};
  for my $server ($config->servers) {
    $self->{servers}->{$server->{url}} = 1;
    for my $disk (@{ $server->{disks} }) {
        for my $bucket (@{ $disk->{buckets} }) {
            $self->{bucket_to_url}->{$bucket} = $server->{url};
            next unless $server->{url} eq $self->{our_url};
            $self->{bucket_to_root}->{$bucket} = $disk->{root};
            LOGDIE "Disk root not given" unless defined($disk->{root});
            $self->{disk_is_local}->{$disk->{root}} = 1;
        }
    }
  }
  my $default_dir = $self->{default_dir} = bsd_glob("~/var/run/yars");
  
  my $state_file = $self->{state_file} = $config->state_file(default => "$default_dir/state.txt");
  -e $state_file or do {
    INFO "Writing new state file ($state_file)";
    my %disks = map { ($_ => "up") } keys %{ $self->{disk_is_local} };
    $self->_write_state({disks => \%disks});
  };
  -e $state_file or LOGDIE "Could not write state file $state_file";
  #TRACE "bucket2url : ".Dumper($self->{bucket_to_url});
}

sub _dir_is_empty {
    # stolen from File::Find::Rule::DirectoryEmpty
    my $dir = shift;
    opendir( DIR, $dir ) or return;
    while ( $_ = readdir DIR ) {
        if ( !/^\.\.?$/ ) {
            closedir DIR;
            return 0;
        }
    }
    closedir DIR;
    return 1;
}


sub disk_for {
    my $self = shift;
    my $digest = shift;
    unless (keys %{ $self->{bucket_to_root} }) {
        $self->refresh_config;
        LOGDIE "No config data" unless keys %{ $self->{bucket_to_root} } > 0;
    }
    my ($bucket) = grep { $digest =~ /^$_/i } keys %{ $self->{bucket_to_root} };
    TRACE "no local disk for $digest in ".(join ' ', keys %{ $self->{bucket_to_root} }) unless defined($bucket);
    return unless defined($bucket);
    return $self->{bucket_to_root}->{$bucket};
}


sub local_buckets {
    my($self) = @_;
    $self->refresh_config unless keys %{ $self->{bucket_to_root} };
    my %r = safe_reverse $self->{bucket_to_root};
    do {$_ = [ $_ ] unless ref $_} for values %r;
    return %r;
}

sub _state {
    my $self = shift;
    $self->refresh_config() unless $self->{state_file} && -e $self->{state_file};
    # TODO: rm dep on File::stat
    return $self->{_state}->{cached} if $self->{_state}->{mod_time} && $self->{_state}->{mod_time} == stat($self->{state_file})->mtime;
    our $j ||= JSON::MaybeXS->new;
    -e $self->{state_file} or LOGDIE "Missing state file " . $self->{state_file};
    $self->{_state}->{cached} = $j->decode(Mojo::Asset::File->new(path => $self->{state_file})->slurp);
    # TODO: rm dep on File::stat
    $self->{_state}->{mod_time} = stat($self->{state_file})->mtime;
    return $self->{_state}->{cached};
}

sub _write_state {
    my $self = shift;
    my $state = shift;
    my $dir = dirname($self->{state_file});
    our $j ||= JSON::MaybeXS->new;
    mkpath $dir;
    my $temp = File::Temp->new(DIR => $dir, UNLINK => 0);
    print $temp $j->encode($state);
    $temp->close;
    rename "$temp", $self->{state_file} or return 0;
    return 1;
}


sub disk_is_up {
    my $class = shift;
    my $root = shift;
    return 0 if -d $root && ! -w $root;
    return 1 if ($class->_state->{disks}{$root} || 'up') eq 'up';
    return 0;
}


sub disk_is_up_verified
{
    my($self, $root) = @_;
    return unless $self->disk_is_up($root);
    my $tmpdir = File::Spec->catdir($root, 'tmp');
    my $temp;
    eval {
        use autodie;
        unless(-d $tmpdir)
        {
            mkpath $tmpdir;
            chmod 0777, $tmpdir;
        };
        $temp = File::Temp->new("disk_is_up_verifiedXXXXX", DIR => $tmpdir, SUFFIX => '.txt');
        print $temp "test";
        close $temp;
        die "file has zero size" if -z $temp->filename;
        unlink $temp->filename;
    };
    if(my $error = $@)
    {
        INFO "Create temp file in $tmpdir FAILED: $error";
        return;
    }
    else
    {
        INFO "created temp file to test status: " . $temp->filename;
        return 1;
    }
}


sub disk_is_down {
    return not shift->disk_is_up(@_);
}


sub disk_is_local {
    my $self = shift;
    my $root = shift;
    return $self->{disk_is_local}->{$root};
}


sub server_is_up {
    # TODO use state file for this
    my $self = shift;
    my $server_url = shift;
    if (exists($self->{server_status_cache}->{$server_url}) && $self->{server_status_cache}->{$server_url}{checked} > time - $self->{server_status_cache_lifetime}) {
        return $self->{server_status_cache}->{$server_url}{result};
    }
    TRACE "Checking $server_url/status";
    my $tx = $self->_ua->get( "$server_url/status" );
    $self->{server_status_cache}->{$server_url}{checked} = time;
    if (my $res = $tx->success) {
        my $got = $res->json;
        if (defined($got->{server_version}) && length($got->{server_version})) {
            return ($self->{server_status_cache}->{$server_url}{result} = 1);
        }
        TRACE "/status did not return version, got : ". JSON::MaybeXS::encode_json($got);
        return ($self->{server_status_cache}->{$server_url}{result} = 0);
    }
    TRACE "Server $server_url is not up : response was ".format_tx_error($tx->error);
    return ($self->{server_status_cache}->{$server_url}{result} = 0);
}
sub server_is_down {
    return not shift->server_is_up(@_);
}

sub _touch {
    my $path = shift;
    my $dir = dirname($path);
    -d $dir or do {
        my $ok;
        eval { mkpath($dir); $ok = 1; };
        if($@) { WARN "mkpath $dir failed : $@;"; $ok = 0; };
        return 0 unless $ok;
    };
    open my $fp, ">>$path" or return 0;
    close $fp;
    return 1;
}


sub mark_disk_down {
    my $class = shift;
    my $root = shift;
    return 1 if $class->disk_is_down($root);
    my $state = $class->_state;
    INFO "Marking disk $root down";
    exists($state->{disks}{$root}) or WARN "$root not present in state file";
    $state->{disks}{$root} = 'down';
    $class->_write_state($state) and return 1;
    ERROR "Could not mark disk $root down";
    return 0;
}

sub mark_disk_up {
    my $class = shift;
    my $root = shift;
    return 1 if $class->disk_is_up($root);
    my $state = $class->_state;
    INFO "Marking disk $root up";
    $state->{disks}{$root} = 'up';
    $class->_write_state($state) and return 1;
    ERROR "Could not mark disk up";
    return 0;
}


sub server_for {
    my $self = shift;
    my $digest = shift;
    my $found;
    $self->refresh_config unless keys %{ $self->{bucket_to_url} } > 0;
    for my $i (0..length($digest)) {
        last if $found = $self->{bucket_to_url}->{ uc substr($digest,0,$i) };
        last if $found = $self->{bucket_to_url}->{ lc substr($digest,0,$i) };
    }
    return $found;
}


sub bucket_map {
    return shift->{bucket_to_url};
}


sub storage_path {
    my $class = shift;
    my $digest = shift;
    my $root = shift || $class->disk_for($digest) || LOGDIE "No local disk for $digest";
    return join "/", $root, ( grep length, split /(..)/, $digest );
}


sub remote_stashed_server {
    my $self = shift;
    my ($filename,$digest) = @_;

    my $assigned_server = $self->server_for($digest);
    # TODO broadcast these requests all at once
    for my $server (shuffle(keys %{ $self->{servers} })) {
        next if $server eq $self->{our_url};
        next if $server eq $assigned_server;
        DEBUG "Checking remote $server for $filename";
        my $tx = $self->_ua->head( "$server/file/$filename/$digest", { "X-Yars-Check-Stash" => 1, "Connection" => "Close" } );
        if (my $res = $tx->success) {
            # Found it!
            return $server;
        }
    }
    return '';
}


sub local_stashed_dir {
    my $self = shift;
    my ($filename,$md5) = @_;
    for my $root ( shuffle(keys %{ $self->{disk_is_local} })) {
        my $dir = $self->storage_path($md5,$root);
        TRACE "Checking for $dir/$filename";
        return $dir if -r "$dir/$filename";
    }
    return '';
}


sub server_exists {
    my $self = shift;
    my $server_url = shift;
    return exists($self->{servers}->{$server_url}) ? 1 : 0;
}


sub server_url {
    return shift->{our_url};
}


sub disk_roots {
    return keys %{ shift->{disk_is_local} };
}


sub server_urls {
    return keys %{ shift->{servers} }
}


sub cleanup_tree {
    my $self = shift;
    my ($dir) = @_;
    while (_dir_is_empty($dir)) {
        last if $self->{disk_is_local}->{$dir};
        rmdir $dir or do { warn "cannot rmdir $dir : $!"; last; };
        $dir =~ s[/[^/]+$][];
     }
}


sub count_files {
    my $class = shift;
    my $dir = shift;
    -d $dir or return 0;
    my @list = File::Find::Rule->file->in($dir);
    return scalar @list;
}


sub human_size {
    my $class = shift;
    my $val   = shift;
    my @units = qw/B K M G T P/;
    my $unit = shift @units;
    do {
        $unit = shift @units;
        $val /= 1024;
    } until $val < 1024 || !@units;
    return sprintf( "%.0f%s", $val + 0.5, $unit );
}


sub content_is_same {
    my $class = shift;
    my ($filename,$asset) = @_;
    my $check;
    if ($asset->isa("Mojo::Asset::File")) {
        $asset->handle->flush;
        $check = ( compare($filename,$asset->path) == 0 );
    } else {
        # Memory asset.  Assume that if one can fit in memory, two can, too.
        my $existing = Mojo::Asset::File->new(path => $filename);
        $check = ( $existing->size == $asset->size && $asset->slurp eq $existing->slurp );
    }
    return $check;
}


sub hex2b64 {
    my $class = shift;
    my $hex = shift;
    my $b64 = b(pack 'H*', $hex)->b64_encode;
    local $/="\n";
    chomp $b64;
    return $b64;
}

sub b642hex {
    my $class = shift;
    my $b64 = shift;
    return unpack 'H*', b($b64)->b64_decode;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Yars::Tools - various utility functions dealing with servers, hosts, etc

=head1 VERSION

version 1.30

=head1 DESCRIPTION

This module is largely used internally by L<Yars>.  Documentation for 
some of its capabilities are provided here for the understanding of how 
the rest of the L<Yars> server works, but they should not be considered 
to be a public interface and they may change in the future, though 
probably not for a good reason.

=head1 FUNCTIONS

=head2 new

Create a new instance of Yars::Tools

=head2 refresh_config

Refresh the configuration data cached in memory.

=head2 disk_for

Given an md5 digest, calculate the root directory of this file. Undef is 
returned if this file does not belong on the current host.

=head2 local_buckets

Get a hash from disk to list of buckets for this server.

=head2 disk_is_up

Given a disk root, return true unless the disk is marked down. A disk is 
down if the state file indicates it, or if it exists but is unwriteable.

=head2 disk_is_up_verified

This is the same as disk_is_up, but doesn't trust the operating system, 
and tries to write a file to the disk's temp directory and verify that 
the file is not of zero size.

=head2 disk_is_down

Disk is not up.

=head2 disk_is_local

Return true if the disk is on this server.

=head2 server_is_up, server_is_down

Check to see if a remote server is up or down.

=head2 mark_disk_down, mark_disk_up

Mark a disk as up or down.

=head2 server_for

Given an md5, return the url for the server for this file.

=head2 bucket_map

Return a map from bucket prefix to server url.

=head2 storage_path

Calculate the directory of an md5 on disk. Optionally pass a second 
parameter to force it onto a particular disk.

=head2 remote_stashed_server

Find a server which is stashing this file, if one exists.
Parameters :
    $c - controller
    $filename - filename
    $digest - digest

=head2 local_stashed_dir

Find a local directory stashing this file, if one exists.
Parameters :
    $filename - filename
    $digest - digest
Returns :
    The directory or false.

=head2 server_exists

Does this server exist?

=head2 server_url

Returns the url of the current server.

=head2 disk_roots

Return all the local directory roots, in a random order.

=head2 server_urls

Return all the other urls, in a random order.

=head2 cleanup_tree

Given a directory, traverse upwards until encountering a local disk root 
or a non-empty directory, and remove all empty directories.

=head2 count_files

Count the number of files in a directory tree.

=head2 human_size

Given a size, format it like df -kh

=head2 content_is_same

Given a filename and an Asset, return true if the content is the same 
for both.

=head2 hex2b64, b642hex

Convert from hex to base 64.

=head1 SEE ALSO

L<Yars>, L<Yars::Client>

=head1 AUTHOR

Original author: Marty Brandon

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brian Duggan

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
