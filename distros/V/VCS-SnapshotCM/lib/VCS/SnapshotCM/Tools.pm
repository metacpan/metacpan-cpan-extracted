################################################################################
#
# $Project: /VCS-SnapshotCM $
# $Author: mhx $
# $Date: 2005/04/09 13:36:08 +0200 $
# $Revision: 9 $
# $Snapshot: /VCS-SnapshotCM/0.02 $
# $Source: /lib/VCS/SnapshotCM/Tools.pm $
#
################################################################################
#
# Copyright (c) 2004 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

=head1 NAME

VCS::SnapshotCM::Tools - Tools for SnapshotCM Version Control

=head1 SYNOPSIS

  use VCS::SnapshotCM::Tools;

  $vcs = VCS::SnapshotCM::Tools->new;

  $vcs->configure(server => 'scmsrv.mydomain');

  if ($vcs->exists_snapshot(snapshot => '/my-project/Current')) {
    # ...
  }

  # ... and lots more. Use the Source, Luke!

=head1 DESCRIPTION

VCS::SnapshotCM::Tools is a collection of tools to query information
from the SnapshotCM version control system.

SnapshotCM is available from L<http://www.truebluesoftware.com>.

This module is mainly used to implement the functionality required
by the tools L<whistory> and L<wannotate>. It lacks documentation
as well as lots of possible features. The interface may change in
backwards-incompatible ways. Use at your own risk.

=head1 METHODS

=cut

package VCS::SnapshotCM::Tools;
use strict;
use Carp;
use File::Temp qw( mktemp );
use IO::File;
use Time::Local;
use Data::Dumper;
use vars qw( $VERSION );

$VERSION = do { my @r = '$Snapshot: /VCS-SnapshotCM/0.02 $' =~ /(\d+\.\d+(?:_\d+)?)/; @r ? $r[0] : '9.99' };

=head2 C<new> OPTION =E<gt> VALUE, ...

Create a new VCS::SnapshotCM::Tools object. You may pass the
same options as to the L<C<configure>|/"configure"> method.

=cut

sub new
{
  my $class = shift;
  my $self = bless {
    debug    => 0,
    server   => undef,
    project  => undef,
    snapshot => undef,
  }, $class;
  $self->configure(@_);
  $self->_debug(1, "## perl version $] on $^O\n");
  $self->_debug(2, Data::Dumper->Dump([$self], ['self']));
  return $self;
}

=head2 C<configure> OPTION =E<gt> VALUE, ...

Configures certain properties of a VCS::SnapshotCM::Tools object.

=over 2

=item C<debug> =E<gt> 0 | 1

Turn debug output on or off.

=item C<server> =E<gt> I<server-hostname>

Set a default server hostname.

=item C<project> =E<gt> I<project-name>

Set a default project name.

=back

=cut

sub configure
{
  my($self, %prop) = @_;
  for my $p (keys %prop) {
    if (exists $self->{$p}) {
      $self->{$p} = $prop{$p};
    }
    else {
      croak "Unknown property '$p'.";
    }
  }
  return $self;
}

=head2 C<get_current_mapping>

Get workspace mapping information for the current directory.

=cut

sub get_current_mapping
{
  my $self = shift;
  $self->_map_options([], @_);
  my $out = $self->_run("wls -f -M");
  for (@{$out->{stderr}}) {
    /^=/ or last;
    if (/^=+\s*Workspace:\s*(.*?)\s*=\s*/) {
      return $self->get_mapping(name => $1);
    }
  }
  return undef;
}

=head2 C<get_mapping> OPTION =E<gt> VALUE, ...

Get workspace mapping information.

=cut

sub get_mapping
{
  my $self = shift;
  my $arg = $self->_map_options([qw(server dir snapshot name)], @_);
  my $out = $self->_run("wmap list $arg");
  my %tr = (
    'Workspace Name'   => 'name',
    'Server'           => 'server',
    'Snapshot'         => 'snapshot_path',
    'Mapped Directory' => 'mapped_dir',
    'Text Format'      => 'text_format',
    'Workspace Type'   => 'type',
    'Working Set'      => 'working_set',
  );

  my @rv;
  for (@{$out->{stdout}}) {
    /^\s*([^:]+):\s*(.*?)\s*$/ or next;
    exists $tr{$1} or carp "Unknown wmap property '$1'.\n";
    push @rv, {} if @rv == 0 or exists $rv[-1]{$tr{$1}};
    $rv[-1]{$tr{$1}} = $2;
  }

  @rv or return;

  for (@rv) {
    if (exists $_->{snapshot_path}) {
      ($_->{project}, $_->{snapshot}) = $self->split_snapshot_path($_->{snapshot_path});
    }
  }

  return wantarray ? @rv : $rv[0];
}

=head2 C<guess_server_hostname> OPTION =E<gt> VALUE, ...

Try to guess the hostname of the SnapshotCM server.

=cut

sub guess_server_hostname
{
  my $self = shift;
  my(undef, %opt) = $self->_map_options([qw(*snapshot)], @_);
  my $out = $self->_run("wmap list");
  my %server;
  for (@{$out->{stdout}}) {
    /Server:\s*(.*?)\s*$/ and $server{$1}++;
  }
  my @servers = keys %server;

  unless (@servers) {
    my $out = $self->_run("sslist -P -t1");
    my @servers = @{$out->{stdout}};
    chomp @servers;
  }

  if (@servers > 1 and exists $opt{snapshot}) {
    for (@servers) {
      $self->exists_snapshot(server => $_, snapshot => $opt{snapshot})
          and return $_;
    }
  }
  return wantarray ? @servers : @servers == 1 ? $servers[0] : undef;
}

=head2 C<guess_local> OPTION =E<gt> VALUE, ...

Poorly named method that guesses local hostname
and snapshot properties.

=cut

sub guess_local
{
  my $self = shift;
  my(undef, %opt) = $self->_map_options([qw(*server[d] *snapshot[m])], @_);
  my %rv;

  my $map = $self->get_current_mapping;
  $rv{mapping} = $map if defined $map;

  my @servers = exists $opt{server} ? $opt{server}
                                    : $self->guess_server_hostname;

  for my $server (@servers) {
    my @ss = ($opt{snapshot});
    push @ss, "$map->{project}/$opt{snapshot}" if defined $map;

    for my $snapshot (@ss) {
      next unless $snapshot =~ m! ^/ !x;
      if ($self->exists_snapshot(server => $server, snapshot => $snapshot)) {
        $rv{server} = $server;
        $rv{path}   = $snapshot;
        @rv{qw(project snapshot)} = $self->split_snapshot_path($snapshot);
        return \%rv;
      }
    }
  }

  return undef;
}

=head2 C<exists_snapshot> OPTION =E<gt> VALUE, ...

Check if a snapshot exists.

=cut

sub exists_snapshot
{
  my $self = shift;
  my($arg, %opt) = $self->_map_options([qw(server[md] *snapshot[m])], @_);
  my $snapshot = $self->_expand_snapshot_path($opt{snapshot});
  my $out = $self->_run("sslist $arg -d -H $snapshot");
  for (@{$out->{stdout}}) {
    /^\s*\Q$snapshot\E\s*$/ and return 1;
  }
  return 0;
}

=head2 C<get_snapshots> OPTION =E<gt> VALUE, ...

Get list of snapshots for a project.

=cut

sub get_snapshots
{
  my $self = shift;
  my($arg, %opt) = $self->_map_options([qw(server[md] *project[md])], @_);
  my $out = $self->_run("sslist $arg -H -R $opt{project}");
  chomp @{$out->{stdout}};
  return @{$out->{stdout}};
}

=head2 C<get_files> OPTION =E<gt> VALUE, ...

Get list of files for a snapshot.

=cut

sub get_files
{
  my $self = shift;
  my($arg, %opt) = $self->_map_options([qw(server[md] snapshot[md])], @_);
  my $out = $self->_run("wls -Rfpv $arg");
  my %f;
  for (@{$out->{stdout}}) {
    chomp;
    if (m! ^ (.*?) (/?) \[(\d+)\] $ !x) {
      $f{$1} = { type => ($2 ? 'dir' : 'file'), 
                 revision => $3 };
    }
    else {
      warn "Cannot parse wls output: $_\n";
    }
  }
  return \%f;
}

=head2 C<read_file> OPTION =E<gt> VALUE, ...

Read a certain revision of a file from a snapshot.

=cut

sub read_file
{
  my $self = shift;
  my($arg, %opt) = $self->_map_options([qw(server[md] snapshot[md] rev *file)], @_);
  my $out = $self->_run("wco -p -q $arg $opt{file}");
  return @{$out->{stdout}};
}

=head2 C<open_file> OPTION =E<gt> VALUE, ...

Get an IO::File reference to a certain revision of a file from a snapshot.

=cut

sub open_file
{
  my $self = shift;
  my($arg, %opt) = $self->_map_options([qw(server[md] snapshot[md] rev *file)], @_);
  $self->_open("wco -p -q $arg $opt{file}");
}

=head2 C<read_diff> OPTION =E<gt> VALUE, ...

Read the diff between two revisions of a file.

=cut

sub read_diff
{
  my $self = shift;
  my($arg, %opt) = $self->_map_options([qw(server[md] snapshot[md] rev1=-r{} rev2=-r{} *file)], @_);
  my $out = $self->_run("wdiff $arg $opt{file}");
  return @{$out->{stdout}};
}

=head2 C<open_diff> OPTION =E<gt> VALUE, ...

Get an IO::File reference to the diff between two revisions of a file.

=cut

sub open_diff
{
  my $self = shift;
  my($arg, %opt) = $self->_map_options([qw(server[md] snapshot[md] rev1=-r{} rev2=-r{} *file)], @_);
  $self->_open("wdiff $arg $opt{file}");
}

=head2 C<get_history> OPTION =E<gt> VALUE, ...

Get history information for a file.

=cut

sub get_history
{
  my $self = shift;
  my($arg, %opt) = $self->_map_options([qw(server[md] snapshot[md] *rev1 *rev2 *file ancestors[b]=-A)], @_);
  my $rev = '';
  $rev .=   $opt{rev1}  if exists $opt{rev1};
  $rev .= ":$opt{rev2}" if exists $opt{rev2};
  $rev  = "-r$rev"      if $rev;
  my $out = $self->_run("whist -d $rev $arg $opt{file}") or return undef;

  my($info, @rev) = split /\s* ^ -{20,} $ \s*/mx, join('', @{$out->{stdout}});
  defined $info or return undef;

  my %info = $info =~ /^([^:]+):\s*(.*)$/mg;

  return {
    snapshot    => $info{Snapshot},
    permissions => $info{Permissions},
    current_rev => $info{'Current revision'},
    revisions   => _get_rev_info(@rev),
  };
}

=head2 C<split_snapshot_path> PATH

Split a snapshot path into project and snapshot.

=cut

sub split_snapshot_path
{
  my($self, $path) = @_;
  exists $self->{_pcache} or $self->rebuild_project_cache;
  for my $p (@{$self->{_pcache}}) {
    if ($path =~ m! ^ \Q$p->[0]\E / (.+) $ !x) {
      return ($p->[0], $1);
    }
  }
  return ($1, $2) if $path =~ m! ^ (/.*) / ([^/]+) $ !x;
  return ('', $path);
}

=head2 C<rebuild_project_cache>

Explicitly rebuild the project cache. The project cache is
required for splitting snapshot paths correctly.

=cut

sub rebuild_project_cache
{
  my($self) = @_;
  my @servers = defined $self->{server} ? $self->{server}
                                        : $self->guess_server_hostname;
  my @projects;
  for my $s (@servers) {
    my $out = $self->_run("sslist -h$s -H");
    my @p = @{$out->{stdout}};
    chomp @p;
    push @projects, map { [$_ => $s] } @p;
  }
  $self->{_pcache} = [sort { length $b->[0] <=> length $a->[0] } @projects];
}

sub _map_options
{
  Carp::cluck("Invalid arguments") if @_ % 2;

  my($self, $accept, %opts) = @_;

  $self->_debug(1, "## _map_options([".join(", ", map qq{'$_'}, @$accept)."]".
                   (@_>2 ? ", ".join(", ", map qq{'$_'}, @_[2..$#_]) : '').")\n");

  my $caller = (caller(1))[3];
  my %map = (
    server   => '-h{}',
    dir      => '-D{}',
    rev      => '-r{}',
    snapshot => '-S{}',
    name     => '-N{}',
  );
  my %default = (
    server   => $self->{server},
    project  => $self->{project},
    snapshot => $self->{snapshot},
  );
  my %process = (
    snapshot => sub { $self->_expand_snapshot_path(@_) },
  );

  $self->_debug(2, Data::Dumper->Dump([$self, $accept, \%opts, \%default],
                                      [qw(self accept *opts *default)]));

  my %pass;
  my @arg;
  my $more = 0;
  s/^-// for keys %opts;
  for (@$accept) {
    if ($_ eq '*') { $more++; next }
    # (m)andatory (d)efault (b)oolean
    my($passthrough, $o) = /^(\*?)(\w+)(?:\[([mdb]+)\])?(?:=(.*))?$/
                           or die "Invalid option spec '$_'";
    $map{$o} = $4 if defined $4;
    my %mod = map {($_ => 1)} ($3 || '') =~ /./g;
    unless (exists $opts{$o}) {
      $opts{$o} = $default{$o} if $mod{d} and defined $default{$o};
      unless (exists $opts{$o}) {
        $mod{m} and croak "Missing option '$o' for '$caller'";
        next;
      }
    }
    if ($passthrough) {
      $pass{$o} = delete $opts{$o};
      next;
    }
    my $a = $map{$o} or die "Unsupported option '$o'";
    my $in = delete $opts{$o};
    if (!$mod{b} or $in) {
      $in = $process{$o}->($in) if exists $process{$o};
      $a =~ s/\{\}/$in/g;
      push @arg, $a;
    }
  }
  unless ($more || keys(%opts) == 0) {
    my $invalid = join ", ", map { "'$_'" } keys %opts;
    my $s = keys %opts == 1 ? '' : 's';
    croak "Invalid option$s $invalid for '$caller'";
  }
  my $arg = join ' ', @arg;
  return wantarray ? ($arg, %opts, %pass) : $arg;
}

sub _expand_snapshot_path
{
  my($self, $path) = @_;
  my($project, $snapshot) = $self->split_snapshot_path($path);
  $project ||= $self->{project};
  defined $project or Carp::cluck("Project undefined");
  return defined $project ? "$project/$snapshot" : $snapshot;
}

sub _get_rev_info
{
  my @revisions = @_;
  my %rev;
  
  for (@revisions) {
    m/
      \A
      ^ Revision: \s* (\d+) \s* .*? \s* (?: Derivation: \s* (.*?) \s* )? $ \s*  # (revision) (derivation)
      ^ Date: \s* ([^;]+) ; \s* Size: \s* (\d+) \s* bytes \s* $            \s*  # (date) (size)
      ^ Author: \s* (.*?) \s* $                                            \s*  # (author)
      ^ Snapshot: \s* (.*?) \s* $                                          \s*  # (snapshot)
      (?: ^ Used \s+ in: \s* (.*? (?: \s* ^\s{8,} .+?)* ) \s* $ )?         \s*  # (used)
      (?: ^ Change: \s* (.*?) \s* $ )?                                     \s*  # (change)
      ^ ([\s\S]+)                                                          \s*  # (comment)
      \Z
    /mx or die "Couldn't match revision output";

    my %r = (
      revision => $1,
      date     => $3,
      size     => $4,
      author   => $5,
      snapshot => $6,
      comment  => $9,
    );

    defined $2 and $r{derivation} = $2;
    defined $7 and $r{used_in}    = [ split /\s{8,}/, $7 ];
    defined $8 and $r{change}     = $8;

    my($Y,$M,$D,$h,$m,$s,$zh,$zm) =
           $r{date} =~ m!(\d+)/(\d+)/(\d+) \s* (\d+):(\d+):(\d+) (?:\s+ [+-](\d{2})(\d{2}))?!x
           or warn("Cannot parse date '$r{date}'");

    $r{time} = timegm($s, $m, $h, $D, $M-1, $Y) - (($zh * 60) + $zm) * 60;

    $r{comment} =~ s/[\r\n]+$//;

    $rev{$r{revision}} = \%r;
  }

  return \%rev;
}

sub _run
{
  my($self, $cmd) = @_;
  my %rv = (error => 0);

  $self->_debug(1, "## run: $cmd\n");

  my $out = mktemp("soutXXXX");
  my $err = mktemp("serrXXXX");
  my $error;

  if (system "$cmd 1>$out 2>$err") {
    $rv{error} = $?;
  }

  if (-f $out) {
    $rv{stdout} = [_slurp($out)];
    unlink $out or carp "Couldn't remove temporary file '$out'";
    if ($self->{debug} >= 2) {
      $self->_debug(2, "1> $_") for @{$rv{stdout}};
    }
  }

  if (-f $err) {
    $rv{stderr} = [_slurp($err)];
    unlink $err or carp "Couldn't remove temporary file '$err'";
    if ($self->{debug} >= 2) {
      $self->_debug(2, "2> $_") for @{$rv{stderr}};
    }
  }

  return \%rv;
}

sub _open
{
  my($self, $cmd) = @_;
  $self->_debug(1, "## open: $cmd\n");
  IO::File->new("$cmd 2>/dev/null |");
}

sub _debug
{
  my($self, $level, @args) = @_;
  if ($self->{debug} >= $level) {
    my $output = join '', @args;
    $output =~ s/^/[$level] /mg;
    print STDERR $output;
  }
}

sub _slurp
{
  my $file = shift;
  my $fh = new IO::File $file or return undef;
  return wantarray ? <$fh> : do { local $/; <$fh> };
}

1;

=head1 COPYRIGHT

Copyright (c) 2004 Marcus Holland-Moritz. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

SnapshotCM is copyright (c) 2000-2003 True Blue Software Company.

=head1 SEE ALSO

See L<whistory>, L<wannotate>.

=cut

