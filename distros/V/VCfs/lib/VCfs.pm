package VCfs;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

use File::Basename qw(
  dirname
);

use IPC::Run ();

use Class::Accessor::Classy;
ro qw(
  dir
  vcs
  vcs_cmd
);
no  Class::Accessor::Classy;

=head1 NAME

VCfs - Version Control agnostic interface on the local system

=head1 Synopsis

  my $vc = VCfs->new(".");
  my %status = $vc->status;
  my @tags = $vc->taglist;

=head1 About

I need somewhere to put all of this repeated code.  There are probably
other modules on the CPAN which do this sort of thing differently.  The
basic idea is to just capture output from shelling-out to the
appropriate frontend command for a given version control tool.  Examples
of usage can be found in the 'bin/' directory of this distribution.

Where necessary, assumes a typical "trunk,branches,tags" layout.

This currently supports svn and svk.  Your help and input is welcome.

=cut

=head1 Constructor

=head2 new

  $vc = VCfs->new($dir|$file, \%options);

=cut

sub new {
  my $caller = shift;
  my ($dir, $opts) = @_;
  my $class = ref($caller) || $caller;
  my $self = {$opts ? %$opts : ()};

  $dir or croak("constructor must have a directory or file");
  unless(-d $dir) {
    $dir = dirname($dir);
  }
  (-d $dir) or croak("eek");
  $self->{dir} = $dir;

  bless($self, $class);
  $self->detect;
  return($self);
} # end subroutine new definition
########################################################################

=head1 Methods

=head2 detect

Tries to guess at what sort of VCS by examining the directory.

  $vc->detect;

=cut

sub detect {
  my $self = shift;
  my $dir = $self->{dir};
  (-d $dir) or croak("eek");
  my %dmatches = (
    svn => "$dir/.svn",
    darcs => "$dir/_darcs",
    cvs => "$dir/CVS",
    );
  foreach my $k (keys(%dmatches)) {
    (-d $dmatches{$k}) and ($self->{vcs} = $k);
  }
  $self->{vcs} ||= 'svk'; # the oddball
  $self->{vcs_cmd} = $self->{vcs}; # XXX for now;
} # end subroutine detect definition
########################################################################

=head2 _do_run

  %res = $vc->_do_run(@command);

=cut

sub _do_run {
  my $self = shift;
  my @command = @_;
  my ($in, $out, $err);
  0 and warn "run $self->{vcs_cmd} @command\n";
  my $ret = IPC::Run::run([$self->vcs_cmd, @command], \$in, \$out, \$err);
  $ret or die "command died $err";
  return(out => $out, err => $err, status => ($? >> 8), ret => $ret);
} # end subroutine _do_run definition
########################################################################

=head2 is_<type>

Returns true if the underlying VCS is <type>.

These are mostly used internally to handle special cases.

=over

=item is_svn

=item is_svk

=item is_cvs

=item is_darcs

=back

=cut

foreach my $type (qw(svn svk cvs darcs)) {
  no strict 'refs';
  *{__PACKAGE__ . "::is_$type"} = sub {
    my $self = shift;
    return($self->{vcs} eq $type);
  }; # end sub
}

=head2 get_log

  $vc->get_log($target);

=cut

sub get_log {
  my $self = shift;
  my ($target, %opts) = @_;

  my @args = $opts{args} ? @{$opts{args}} : ();

  my ($in, $out, $err);
  IPC::Run::run(
    [$self->vcs_cmd, 'log', ($self->is_svk ? '-x' : ()), @args, $target],
    \$in, \$out, \$err
    );
  $err and warn "eek! $err ";
  # warn "see: $out";
  # XXX error checking?
  # XXX wantarray?
  return(split(/\n/, $out));
} # end subroutine get_log definition
########################################################################

=head2 get_log_times

  $vc->get_log_times($target);

=cut

sub get_log_times {
  my $self = shift;
  # XXX maybe want this regex for other things? - get_summary_lines ?
  my @l = grep(/^r\d+:?.*\|\s/,
    $self->get_log(@_)
    );
  my @times;
  foreach my $s (@l) { # XXX also, usable in other areas
    if($self->is_svk) {
      $s =~ s/^(r\d+):\s*/$1 | /;
    }
    my ($r, $u, $d, $else) = split(/\s\|\s/, $s, 4);
    $else ||= '';
    #warn "split into ", join("#", $r, $u, $d, $else), "\n";
    push(@times, $d);
  }
  return(@times);
} # end subroutine get_log_times definition
########################################################################

=head2 get_info

  my %vals = $vc->get_info;

=cut

sub get_info {
  my $self = shift;

  my %ans = $self->_do_run('info', $self->dir);
  my %info;
  foreach my $line (split(/\n/, $ans{out})) {
    my ($key, $val) = split(/ *: */, $line, 2);
    $key = lc($key);
    $key =~ s/ +/_/g;
    $key =~ s/__+/_/g;
    $key =~ s/[^a-z0-9_]+//g;
    exists($info{$key}) and die "oops $key twice in $ans{out}";
    $info{$key} = $val;
  }
  return(%info);
} # end subroutine get_info definition
########################################################################

=head2 taglist

  my @tags = $vc->taglist;

=cut

sub taglist {
  my $self = shift;
  return(map({s#/$##;$_} $self->list($self->tag_dir)));
} # end subroutine taglist definition
########################################################################

=head2 tag_dir

  my $dir = $vc->tag_dir;

=cut

sub tag_dir {
  my $self = shift;

  my %info = $self->get_info;
  my $url = $info{url};
  my $tagdir = $url;
  $tagdir =~ s/trunk$/tags\// or die "eek, $url not trunk?";
  return($tagdir);
} # end subroutine tag_dir definition
########################################################################

=head2 taggit

(Currently) assumes a proj/trunk, proj/tags layout and that we're
looking at trunk.  I guess you could tag a branch, but, uh...

  $vc->taggit($tagname, message => $message);

Big issue:  There is no syntax of copy that prevents writing into an
existing tag directory.  The subversion developers seem to think this
should be handled via pre-commit hooks (see
http://svn.haxx.se/users/archive-2005-11/0056.shtml for details.)

=cut

sub taggit {
  my $self = shift;
  my ($name, %opts) = @_;
  ($name =~ m#/#) and die "improper tagname $name";

  my %info = $self->get_info;
  my $url = $info{url};
  die "I can't taggit() on type ", $self->vcs_command, " yet"
    unless($url);

  # TODO svk support
  # TODO config-file and/or propval layout?

  my $trunk = $url; # could also be a branch I guess
  my $tagdir = $url;
  $tagdir =~ s{(?:trunk|branches/[^/]+)/?$}{tags/} or
    croak("eek, $url not trunk|branches?");
  my $tagdest = $tagdir . $name;

  # Bah! svn doesn't prevent copying into an existing tag directory (at
  # least not in any form that I can see.)
  #warn $self->list($tagdir);
  my @has = grep(/^\Q$name\E\/$/, $self->list($tagdir));
  @has and die "tag '$name' already exists in $tagdir";

  my $message = $opts{message};
  $message = "tagging $name" unless(defined($message));

  $self->_do_run('copy', $trunk, $tagdest, '--message', $message);
} # end subroutine taggit definition
########################################################################

=head1 normal methods

Just abstraction for standard commands.


=head2 add

  $vc->add(@files);

=cut

sub add {
  my $self = shift;
  my @files = @_;
  my %r = $self->_do_run('add', @files);
  $r{err} and warn "eek! $r{err} ($r{status})";
  $r{ret} or warn "eek";
  # XXX or should parse output and return number of added files?
  return($r{ret});
} # end subroutine add definition
########################################################################

=head2 remove

  $vc->remove(@files);

=cut

sub remove {
  my $self = shift;
  my @files = @_;
  my %r = $self->_do_run('remove', @files);
  $r{err} and warn "eek! $r{err} ($r{status})";
  $r{ret} or warn "eek";
  # XXX or should parse output and return number of added files?
  return($r{ret});
} # end subroutine remove definition
########################################################################

=head2 commit

  $vc->commit($message, @files);

=cut

sub commit {
  my $self = shift;
  my ($message, @files) = @_;
  @files or die;
  my %r = $self->_do_run('commit', @files, '-m', $message);
  $r{err} and warn "eek! $r{err} ($r{status})";
  $r{ret} or warn "eek";
  # XXX or should return what?
  return($r{ret});
} # end subroutine commit definition
########################################################################

=head2 update

  $vc->update;

=cut

sub update {
  my $self = shift;

  my %r = $self->_do_run('update');
} # end subroutine update definition
########################################################################

=head2 list

  my @list = $vc->list($path);

=cut

sub list {
  my $self = shift;
  my ($path) = @_;
  $path or die; # XXX ?
  my %r = $self->_do_run('list', $path);
  #$r{err} and warn "eek! $r{err} ($r{status})";
  #$r{ret} or warn "eek";
  #$r{out} or warn "that's a problem";
  return(split(/\n/, $r{out}));
} # end subroutine list definition
########################################################################

=head2 revert

  $vc->revert(@files);

=cut

sub revert {
  my $self = shift;
  my (@files) = @_;
  @files or die "need files";
  my %r = $self->_do_run('revert', @files);
  # TODO read the qr/Reverted '([^']+)'/ lines?
  warn $r{out};
} # end subroutine revert definition
########################################################################

=head2 status

Returns a hash of files and their status codes.

  %status = $vc->status(@files);

=cut

sub status {
  my $self = shift;
  my @files = @_;
  my %r = $self->_do_run('status', @files);
  $r{err} and warn "eek! $r{err} ($r{status})";
  $r{ret} or warn "eek";
  $r{out} or return();
  return(map({reverse(split(/\s+/, $_, 2))}
      split(/\n/, $r{out})
    ));
} # end subroutine status definition
########################################################################

=head2 propget

  $vc->propget($propname, $url||$file);

=cut

sub propget {
  my $self = shift;
  my ($prop, $file) = @_;

  my %r = $self->_do_run('propget', $prop, $file);
  defined(my $string = $r{out}) or croak("nothing there");

  die "this is unfinished";


} # end subroutine propget definition
########################################################################

=head2 propset

Takes an array reference or string for propvals.

  $vc->propset($propname, \@vals, @files);

  $vc->propset($propname, $valstring, @files);

=cut

sub propset {
  my $self = shift;
  my ($prop, $val, @files) = @_;
  if(ref($val)) {
    UNIVERSAL::isa($val, 'ARRAY') or die;
    $val = join("\n", @$val);
  }
  my %r = $self->_do_run('propset', $prop, $val, @files);
  $r{err} and warn "eek! $r{err} ($r{status})";
  $r{ret} or warn "eek";
  return($r{ret});
} # end subroutine propset definition
########################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2004-2009 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:sw=2:ts=2:et:sta
1;
