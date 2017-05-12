package inc::dtRdrBuilder::Distribute;

# Copyright (C) 2006, 2007 by Eric Wilhelm and OSoft, Inc.

# server-related stuff

use warnings;
use strict;
use Carp;

=head1 ACTIONS

=over

=cut

our $RUN_SSH = 1; # enables actual execution
our $VERBOSE = 1;

my $dosystem = sub {
  warn "# ", ($RUN_SSH ? () : ('(skip) ')), "@_\n";
  $RUN_SSH and return(system(@_));
  return 0;
};

=item demo_push

OBSOLETE

Push and symlink binary_build/ to the server/directory specified in
server_details.yml

  server: example.com
  directory: foo
  distribute:
    - user@host:dir/

=cut

sub ACTION_demo_push {
  my $self = shift;

  my @args = @{$self->{args}{ARGV}};
  my $release = shift(@args);
  my %opts = $self->_my_args;
  $release = $opts{release} unless(defined($release));
  $release or die "must have release name";
  $release =~ m/ / and die;

  my $data = $self->server_details;
  my $server = $data->{server} or die;
  my $dir = $data->{directory} or die;
  $dir .= "/$^O" unless($^O eq 'MSWin32');

  $self->jailshell_ssh($server, "test '!' -e $dir/$release") or
    die "'$dir/$release' already exists";

  my $have_current = $self->jailshell_ssh($server,
    "test -e $dir/current &&" .
    "cp -RH $dir/current $dir/$release"
  );

  $self->ssh_rsync($server,
    '-rz', $self->binary_build_dir . '/', $dir . '/' . $release . '/'
  );

  unless($opts{nolink}) {
    $self->jailshell_ssh($server,
      "rm $dir/current && ln -s $release $dir/current"
    );
  }
} # end subroutine ACTION_demo_push definition
########################################################################

=item bindistribute

Distribute binary_build/ to each of the @distribute entries in the
server_details.yml file.

=cut

sub ACTION_bindistribute {
  my $self = shift;

  my $data = $self->server_details;
  if($data->{distribute}) {
    my @dirs = @{$data->{distribute}};
    foreach my $dest (@dirs) {
      $dest =~ s#/*$#/#;
      $dosystem->('rsync', '--delete', '-rv',
        $self->binary_build_dir . '/', $dest
      ) and die;
    }
  }
} # end subroutine ACTION_bindistribute definition
########################################################################

=item package_push

Push the packaged binary release for the current platform.

=cut

sub ACTION_package_push {
  my $self = shift;

  my $src = $self->distfilename;
  (-e $src) or die "no file $src";

  $self->transfer_and_link($src);
} # end subroutine ACTION_package_push definition
########################################################################

=item parts_push

Push the par archives for the current platform.

Unlike the other 'push' items, this *probably* doesn't involve symlinks.

=cut

sub ACTION_parts_push {
  my $self = shift;

  require File::Basename;
  my %files = map({my $f = $self->$_;
      ($_ => [File::Basename::basename($f) => $f])
    }
    qw(par_mini par_core par_deps par_wx)
  );

  my $data = $self->server_details;
  my $server = $data->{server} or die;
  my $dir = $data->{directory} or die;
  $dir .= '/downloads/parts/';

  # get list of existing files
  my $answer = $self->jailshell_ssh2($server,
    join(';',
      map({my $f = "$dir/$files{$_}[0]";
      "test -e $f && test -e $f.md5 && echo $_"
      } keys(%files)),
      "test -e $dir"
    )
  );
  my %got = map({$_ => 1} split(/\n/, $answer));

  $got{par_mini} and
    die "ERROR: $files{par_mini}[0] is already on the server\n";

  foreach my $k (keys(%files)) {
    # don't transfer anything that's already there
    if($got{$k}) {
      warn "already got $k $files{$k}[0]\n";
      next;
    }
    my $md_file = $self->make_md5_file($files{$k}[1]);
    $self->ssh_rsync($server,
      '-z', $files{$k}[1], $md_file, $dir . '/'
    );

    # add uploaded deps to our local cache if we have one
    my $cache_dir = $ENV{HOME} . '/.dotreader_dep_cache/';
    if((-d $cache_dir) and ($k ne 'par_mini')) {
      my $cache_file = $cache_dir . $files{$k}[0];
      if(-e $cache_file) {
        unlink($cache_file) or die "cannot remove $cache_file";
      }
      File::Copy::copy($files{$k}[1], $cache_file) or die;
    }

  }

  # send a .yml for the given release/preview
  my $yml = $files{par_mini}[1] . '.yml';
  (-e $yml) or die "$yml not found";

  # make a -current/-release file for the .yml?
  $self->transfer_and_link($yml);

} # end subroutine ACTION_parts_push definition
########################################################################

=item dist_push

Push the source tarball.

=cut

sub ACTION_dist_push {
  my $self = shift;

  my $src = $self->dist_dir . '.tar.gz';
  (-e $src) or die "no file $src";

  $self->transfer_and_link($src);
} # end subroutine ACTION_dist_push definition
########################################################################

=item release_links

Complete the release by checking and renaming all of the -ready links on
the server.

=cut

sub ACTION_release_links {
  my $self = shift;

  my $data = $self->server_details;
  my $server = $data->{server} or die;
  my $dir = $data->{directory} or die;
  $dir .= '/downloads/';

  my @expect = qw(
    dotReader-current.tar.gz
    dotReader-mini-current-i386.ltm-5.8.4.par.yml
    dotReader-mini-current-MSWin32.x86mt-5.8.7.par.yml
    dotreader-bare-mac-current.dmg
    dotreader-mac-current.dmg
    dotreader-mini-bare-linux-current.tar.gz
    dotreader-mini-bare-win32-current.exe
    dotreader-mini-linux-current.tar.gz
    dotreader-mini-win32-current.exe
  );
    #dotreader-bare-linux-current.tar.gz
    #dotreader-bare-win32-current.exe
    #dotreader-linux-current.tar.gz
    #dotreader-win32-current.exe

  my $answer = $self->jailshell_ssh2($server,
      "for i in \$(ls $dir/*-ready);" .
        'do echo $(basename $i) $(readlink $i);done');
  0 and warn $answer;
  my %got = map({split(/ +/, $_)} split(/\n/, $answer));

  my $version = $self->dist_version;
  foreach my $file (@expect) {
    my $ready = "$file-ready";
    $got{$ready} or die "no -ready link for $file";

    # also check the versions
    my $want = $file;
    $want =~ s/-current/-$version/ or die "huh?";
    ($got{$ready} eq $want) or die "version mismatch on $got{$ready}";
  }

  # now rename them
  my @fromto = map({["$_-ready", $_]} @expect);
  $self->jailshell_ssh($server,
    join(' && ', "cd $dir", map({"mv @$_"} @fromto))
  ) or die "error renaming files";

  { # TODO probably should just handle this in CPDK
    local $RUN_SSH = $ENV{NOCPAN} ? 0 : 1;
    my $src = $got{'dotReader-current.tar.gz-ready'} or die;
    $dosystem->('cpan-upload', "http://dotreader.com/downloads/$src")
      and die "cpan-upload failed";
  }
} # end subroutine ACTION_release_links definition
########################################################################

=item checkserver

Just tests connection, remote execution.

=cut

sub ACTION_checkserver {
  my $self = shift;

  my $data = $self->server_details;
  my $server = $data->{server} or die;
  my $dir = $data->{directory} or die;
  $dir .= '/downloads/';
  $self->jailshell_ssh($server, "test -e $dir") or
    die "'$dir' does not exist";
  $self->jailshell_ssh($server, "test '!' -e $dir/foo") or
    die "'$dir/foo' exists";
  $self->jailshell_ssh($server, "touch $dir/foo") or
    die "cannot make $dir/foo $!";
  $self->jailshell_ssh($server, "test -e $dir/foo") or
    die "'$dir/foo' could not be made";
  $self->jailshell_ssh($server, "rm $dir/foo") or
    die "cannot rm $dir/foo";
  $self->jailshell_ssh($server, "test '!' -e $dir/foo") or
    die "'$dir/foo' exists";
  print "ok\n";
}

=back

=cut

########################################################################
# NO MORE ACTIONS
########################################################################

=head1 Remote Execution

=head2 jailshell_ssh

Wrapper on jailshell_ssh2 which returns true/false rather than output.

  my $bool = $self->jailshell_ssh($server, $command, @opts);

=cut

sub jailshell_ssh {
  my $self = shift;
  eval{$self->jailshell_ssh2(@_), 1};
} # end subroutine jailshell_ssh definition
########################################################################

=head2 jailshell_ssh2

Workaround for buggy, proprietary code.

Required for getting success/failure from cpanel's broken jailshell
implementation (which doesn't return the remote command exit status like
any good ssh shell would.)

  my $answer = $self->jailshell_ssh2($server, $command, @opts);

Trouble is that it assumes stderr output means an error exit code.  So,
pretty much everything is broken and buggy from here down.

Dies on error.

=cut

sub jailshell_ssh2 {
  my $self = shift;
  my ($server, $command, @opts) = @_;

  push(@opts, $self->ssh_opts($server));

  $VERBOSE and warn "# ssh $server @opts $command\n";
  $RUN_SSH or return(1); # pretend it is ok

  my ($in, $out, $err);
  my $token = time;
  require IPC::Run;
  my $ret = IPC::Run::run(['ssh', $server, @opts,
    "$command && echo $token ok"],
    \$in, \$out, \$err);
  # XXX stupid jailshell, now this isn't compatible with any actual ssh
  # implementation!
  unless($ret) {
    $err and die "command failed $err";
  }
  #$err and ($! = $err);
  $out =~ s/$token ok\n$// or die "command not ok";
  return($out);
} # end subroutine jailshell_ssh2 definition
########################################################################

=head2 ssh_rsync

The $to argument must not contain the "$server:" bit.

  $self->ssh_rsync($server, @args, $from, $to);

Multiple from files is okay too.  See the rsync manpage.

  $self->ssh_rsync($server, @args, @from, $to);

=cut

sub ssh_rsync {
  my $self = shift;
  my ($server, @args) = @_;
  my @ssh_opts = $self->ssh_opts($server);

  my $dest = pop(@args);
  $dest = $server . ':' . $dest;

  my @command = (
    'rsync',
    (scalar(@ssh_opts) ? '--rsh=' . join(' ', 'ssh', @ssh_opts) : ()),
    @args, $dest
  );

  $VERBOSE and warn "# ", join(" ", map({"'$_'"} @command)), "\n";
  $RUN_SSH or return(1);

  system(@command) and die $!;
} # end subroutine ssh_rsync definition
########################################################################

=head2 transfer_and_link

  $self->transfer_and_link($file);

=cut

sub transfer_and_link {
  my $self = shift;
  my ($src) = @_;

  my %opts = $self->args;

  my $data = $self->server_details;
  my $server = $data->{server} or die;
  my $dir = $data->{directory} or die;
  $dir .= '/downloads/';

  require File::Basename;
  my $file = File::Basename::basename($src);

  $self->jailshell_ssh($server, "test '!' -e $dir/$file") or
    die "'$dir/$file' already exists";
  my $current = $file;

  # let's have a consistent naming scheme
  # vX.Y.Z      is a release
  # pX.Y.Z.N is a preview
  my $preview;
  unless($current =~ s/-v\d+\.\d+\.\d+/-current/) {
    # allow a preview build, but don't ever link it as current
    ($current =~ s/-p\d+\.\d+.\d+\.[A-Z0-9]+/-current/) or
      die "cannot transform $current name";
    $preview = $current;
    $preview =~ s/-current/-preview/ or die "ack";
  }

  0 and die join("\n  ", 'bye now', $src, $current, $preview, ' ');

  # Should we really require an existing seed?
  # (This copy is just rsync optimization.)
  # TODO --noexist option?
  my $nolink = $opts{nolink};
  $self->jailshell_ssh($server, "cp -H $dir/$current $dir/$file") or
    sub{$nolink ? warn @_ : die @_}->("cannot make copy");

  $self->ssh_rsync($server, '-cvz', $src, "$dir/$file");

  # just link for preview
  # -current uses '-ready' scheme and release_links does finalization
  my $dest = $dir . '/' . ($preview || "$current-ready");
  $self->jailshell_ssh($server,
    "rm $dest 2>/dev/null; ln -s $file $dest"
  ) or die "link juggling failed";
} # end subroutine transfer_and_link definition
########################################################################

=head2 server_details

Loads the yaml data.

  my $data = $self->server_details;

=cut

sub server_details {
  my $self = shift;

  $self->{server_details} and return($self->{server_details});
  require YAML::Syck;
  my ($data) = YAML::Syck::LoadFile('server_details.yml');
  if(my $keyring = $data->{keyring}) {
    foreach my $host (keys(%$keyring)) {
      $keyring->{$host} =~ s#^~#$ENV{HOME}/#;
    }
  }
  return($self->{server_details} = $data);
} # end subroutine server_details definition
########################################################################

=head2 ssh_opts

  my @opts = $self->ssh_opts($server);

=cut

sub ssh_opts {
  my $self = shift;
  my ($server) = @_;

  my $data = $self->server_details;
  my @opts;
  if(my $keyring = $data->{keyring}) {
    my $key = $keyring->{$server};
    push(@opts, ($key ? ('-i', $key) : ()));
  }
  return(@opts);
} # end subroutine ssh_opts definition
########################################################################

=head2 make_md5_file

  my $md5_filename = $self->make_md5_file($filename);

=cut

sub make_md5_file {
  my $self = shift;
  my ($filename) = @_;

  require Digest::MD5;
  open(my $fh, '<', $filename) or die "cannot read $filename";
  binmode($fh);
  my $md5 = Digest::MD5->new->addfile($fh)->hexdigest;

  my $md_file = $filename.'.md5';
  open(my $ofh, '>', $md_file) or die "cannot write $md_file";
  print $ofh $md5, "\n";
  close($ofh) or die "failed to close $md_file";
  return($md_file);
} # end subroutine make_md5_file definition
########################################################################

# vi:ts=2:sw=2:et:sta
1;
