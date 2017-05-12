package dtRdr::Annotation::SyncRules;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

=head1 NAME

dtRdr::Annotation::SyncRules - rules engine

=head1 SYNOPSIS

  my $sr = dtRdr::Annotation::SyncRules->new(
    current  => \@current,
    deleted  => \@deleted,
    manifest => \%s_man,
    error    => sub {die @_, "..."},
  );

  while(my @ans = $sr->next) {
    my ($action, $object) = @ans;
    # then do something with them
  }
  # and maybe something to finish

=cut

=head1 Constructor

=head2 new

  my $sr = dtRdr::Annotation::SyncRules->new(
    current  => [@current],
    deleted  => [@deleted],
    manifest => {%s_man},
    error    => sub {die @_},
  )->init;

The references will be modified in-place, so deref accordingly.

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {@_};
  $self->{error} ||= sub {
    die @_, ' at ', join(' line ', (caller(1))[1,2]), "\n";
  };
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head1 Rulings

FRESHEN is really just GET, but is an update.  By definition, if we're
talking to check_srev, we have it and so does the server.

  deleted:
    (implies mine)
    verify srev and DELETE; finish_delete

  current: (mine)
    shas:
      Y: check_srev ? PUT : FRESHEN :: NOOP # quaternary?
      N: has_prev ? (really_delete) : POST
  notmine:
    shas:
      Y: check_srev ? die : FRESHEN :: NOOP
      N: really_delete

Where:

  check_srev := {(rev > prev) ? ((srev > prev) ? CONFLICT : 1) :
    (srev > prev ? 0 : (srev < prev ? ERROR : SKIP)))}

Ok, so that's a ternary boolean.  It returns true if we should push,
false if we should pull, SKIP if nothing changed.  (Aside: (srev < prev)
is an error in-general and can be checked beforehand.)

What's left in the server manifest after that should be only new
incoming annotations.

=head2 check_srev

Returns one of FRESHEN|PUT|SKIP|CONFLICT

  my $ans = $self->check_srev($rev, $public_rev, $server_rev);

=cut

sub check_srev {
  my $self = shift;
  my ($rev, $prev, $srev) = @_;

  defined($_) or ($_ = -1) for($prev);
  defined($_) or die("cannot compare undef") for($rev, $srev);

  ($rev > $prev) ?
    # local change
    (($srev > $prev) ? 'CONFLICT' : 'PUT') :
    # server or no change
    (($srev > $prev) ? 'FRESHEN' : 'SKIP')
} # end subroutine check_srev definition
########################################################################

=head2 next

  my @ans = $sr->next;

=cut

sub next {
  my $self = shift;

  my $todo = $self->{todo};
  my $current;
  while(1) {
    @$todo or return;
    $current = $todo->[0];
    @{$current->[1]} and last;
    shift(@$todo);
  }
  my $sub = $current->[0];
  my $val = shift(@{$current->[1]});
  my @ans = $sub->($self, $val);
  @ans or die "bad answer/error handler";
  if($ans[0] and ($ans[0] eq 'CONTINUE')) {
    return($self->next);
  }
  return(@ans);
} # end subroutine next definition
########################################################################

=head1 Internals

=head2 init

  $self = $self->init;

=cut

sub init {
  my $self = shift;

  my $current = $self->{current} or croak("requires current");
  my $notmine = $self->{notmine} = [];
  my $deleted = $self->{deleted};
  my $s_man = $self->{manifest} or croak("requires manifest");
  for(my $i = 0; $i < @$current; $i++) {
    my $anno = $current->[$i];
    my $id = $anno->id;
    if(defined($anno->public->owner)) {
      push(@$notmine, splice(@$current, $i, 1));
      $i--;
    }
  }

  my $todo = $self->{todo} = [];

  # TODO something with these (or similar) to check assertions
  #my @c_overlap = grep({exists($s_man->{$_->id})} @$current);
  #my @n_overlap = grep({exists($s_man->{$_->id})} @$notmine);
  #my @d_overlap = grep({exists($s_man->{$_->id})} @$deleted);

  # setup iterators
  if(0) { # should we even be handling assertions here?
    my $subref = sub {
      my $s = shift;
      my ($anno) = @_;
      defined($anno->public->owner) and
        return $self->error($anno, 'BAD_DELETE',
          "'" . $anno->id . "' was deleted, but does not belong to me");
      return('OK', $anno);
    };
    push(@$todo, [$subref, [@$deleted]]);
  }

  0 and warn join("\n  ",
    'sman: ', map({"$_ => $s_man->{$_}"} keys(%$s_man)));
  { # deletions
    my $subref = sub {
      my $s = shift;
      my ($anno) = @_;
      my $id = $anno->id;
      my $srev = delete($s_man->{$id});
      my $action;
      if($anno->public and defined(my $prev = $anno->public->rev)) {
        $action = 'CONFLICT_DELETE'
          unless($prev == (defined($srev) ? $srev : -1));
      }
      else {
        $action = 'CONFLICT' if(defined($srev));
      }
      $action ||= (defined($srev)
        ? (($srev > $anno->revision) ? 'CONFLICT' : 'REMOTE_DELETE')
        : 'FINISH_DELETE'
      );
      return($action, $anno);
    };
    push(@$todo, [$subref, [@$deleted]]);
  }
  { # mine
    my $subref = sub {
      my $s = shift;
      my ($anno) = @_;
      my $id = $anno->id;
      my $action;
      if(exists($s_man->{$id})) {
        my $srev = delete($s_man->{$id});
        $action =
          $s->check_srev($anno->revision, $anno->public->rev, $srev);
      }
      else {
        $action = defined($anno->public->rev) ?
          'LOCAL_DELETE' : 'POST';
      }
      return($action, $anno);
    };
    push(@$todo, [$subref, [@$current]]);
  }
  { # theirs
    my $subref = sub {
      my $s = shift;
      my ($anno) = @_;
      my $id = $anno->id;
      my $action;
      if(exists($s_man->{$id})) {
        my $srev = delete($s_man->{$id});
        $action =
          $s->check_srev($anno->revision, $anno->public->rev, $srev);
        my %no = map({$_ => 1} qw(PUT POST));
        if($no{$action}) {
          return $self->error($anno, 'PERMISSION_DENIED',
            "cannot update what is not yours")
        }
      }
      else {
        $action = 'LOCAL_DELETE';
      }
      return($action, $anno);
    };
    push(@$todo, [$subref, [@$notmine]]);
  }
  { # the rest
    my $idlist = [1];
    my $started;
    my $subref = sub {
      my $s = shift;
      my ($id) = @_;
      unless($started) {
        $started = 1;
        @$idlist = (keys(%$s_man));
        @$idlist or return('CONTINUE'); # done
        $id = shift(@$idlist);
      }
      return('GET', $id);
    };
    # this is a delayed-setup to pick up the rest
    push(@$todo, [$subref, $idlist]);
  }


  return($self);
} # end subroutine init definition
########################################################################

=head2 error

  $self->error(@list);

=cut

sub error {
  my $self = shift;
  $self->{error}->(@_);
} # end subroutine error definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
