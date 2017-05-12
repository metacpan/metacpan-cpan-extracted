package dtRdr::Annotation::Sync::Standard;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

use dtRdr::UserAgent;
use dtRdr::Annotation::IOBlob;
use dtRdr::Annotation::SyncRules;

use HTTP::Status; # XXX RC_THBBT
use YAML::Syck ();
my $LOAD = sub {my $v = YAML::Syck::Load(@_);
  return(defined($v) ? $v : {})};
my $DUMP = sub {YAML::Syck::Dump(@_)};

use dtRdr::Logger;

use constant NOISE => 0;

use base 'MultiTask::Minion';

use Class::Accessor::Classy;
ro 'anno_io';
ro 'ua';
ro 'uri';
ro 'server';
ro 'bookbag';
ri 'cookies';
rw 'auth_sub';
rw 'server_drift';
lw 'books';
# TODO cookie_something?
# TODO progress_sub?
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::Annotation::Sync::Standard - standard server sync

=head1 SYNOPSIS

=cut

=head1 Constructor

=head2 new

  my $sync = dtRdr::Annotation::Sync::Standard->new($uri);

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $uri;
  $uri = shift(@_) if(@_ % 2);
  my %args = @_;
  $uri = $args{server}->uri unless(defined($uri));

  $uri =~ s#/*$#/#;

  my $self = {
    %args,
    uri => $uri,
    _queue => {},
  };
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head1 Methods


=head2 start

  $sync->start;

=cut

sub start {
  my $self = shift;

  my $ua = $self->{ua} ||= dtRdr::UserAgent->new;
  $ua->set_complete_sub(sub {shift; $self->next_request(@_)});
  $ua->set_auth_sub(sub {shift; $self->authenticate(@_)});

  # TODO start with login/etc?

  # setup the work chain, starting with the time sync on config.yml
  my $token = $self->add_request('GET', 'config.yml');
  $self->queue($token => sub {$self->process_config(%{$_[1]})});

} # end subroutine start definition
########################################################################

=head2 work

  $sync->work;

=cut

sub work {
  my $self = shift;

  NOISE and warn "working\n";

  $self->ua->pester and $self->finish;

} # end subroutine work definition
########################################################################

=head2 finish

  $sync->finish;

=cut

sub finish {
  my $self = shift;

  # check for leftovers
  my %left = $self->ua->leftovers;
  foreach my $token (keys(%left)) {
    die "failed to finish $token ", $left{$token}{response}->code;
  }
  $self->quit;
} # end subroutine finish definition
########################################################################

=head1 Callbacks


=head2 authenticate

Looks for username and password in the server object, otherwise hits the
callback.

  ($user, $pass) = $self->authenticate($realm, $uri);

That's an oversimplification.  The user agent hits this on every new
request (possibly multiple times in one request if the server rejects
the header.)

Also, maybe a bug in LWP:  it only tries it twice per request.  So, if
you typo the password twice, we're dead.

=cut

sub authenticate {
  my $self = shift;
  my ($realm, $uri) = @_;

  # The credential cache will look like [$token, [$u,$p], [$u,$p]].
  # The second $u,$p is to make the cache logic quicker and disallow the
  # same server wanting a different password for different pages.
  my $c = $self->{_auth_cache} ||= [];

  # hmm, should we allow one $server object to have different realms?
  # Probably too silly, and the config would have to support that.

  # return the cached credential unless we're stuck on the same page
  if(scalar(@$c) == 3) {
    return(@{$c->[2]});
  }

  my $s = $self->server;

  # make a token (those shouldn't be undef, but ...)
  my $token = join("|", map({defined($_) ? $_ : '~'} $uri, $realm));

  # more cache logic
  if(@$c and ($c->[0] ne $token)) { # must have worked last time, we moved on
    push(@$c, $c->[1]); # mark it as golden
    return(@{$c->[2]});
  }

  # now we're either at the first try or some failed auth

  my $callback = sub {
    my $cb = $self->auth_sub or die "no auth_sub callback";
    my @ans = $cb->($s, $realm, $uri);
    $self->quit unless(@ans);
    return(@ans);
  };

  unless(@$c) { # first try
    # try the user's input if we have it
    my ($u, $p) = ($s->username, $s->password);
    unless(defined($u) and defined($p)) {
      ($u, $p) = $callback->();
    }
    @$c = ($token, [$u, $p]);
    return($u,$p);
  }

  # TODO If we fix LWP, we have to configurably limit the number of
  # times we nag to support non-gui usage.

  # now we were just plain wrong
  my ($u, $p) = $callback->();

  return(@{$c->[1]} = ($u, $p));
} # end subroutine authenticate definition
########################################################################

=head1 Small Parts

=head2 add_request

A convenience method that prepends the server base to a ua.add_request()
call.

  $self->add_request($method, $path);

=cut

sub add_request {
  my $self = shift;
  my ($method, $path, @and) = @_;

  return($self->ua->add_request($method, $self->uri . $path, @and));
} # end subroutine add_request definition
########################################################################

=head2 queue

  $self->queue($token => sub {...});

=cut

sub queue {
  my $self = shift;
  my ($token, $subref) = @_;

  my $Q = $self->{_queue};
  $Q->{$token} ||= [];
  push(@{$Q->{$token}}, $subref);
} # end subroutine queue definition
########################################################################

=head2 dequeue

  my @subs = $self->dequeue($token);

=cut

sub dequeue {
  my $self = shift;
  my ($token) = @_;

  my $Q = $self->{_queue};
  exists($Q->{$token}) or return;
  return(@{$Q->{$token}});
} # end subroutine dequeue definition
########################################################################

=head2 next_request

Callback for collecty user-agent scheme.

Takes a completed request token and runs the registered add_request()
subref.

  $self->next_request($token);

=cut

sub next_request {
  my $self = shift;
  my ($token) = @_;

  my %result = $self->ua->collect($token);
  foreach my $subref ($self->dequeue($token)) {
    $subref->($token, \%result);
  }
} # end subroutine next_request definition
########################################################################

=head2 cookies

  my $cookies = $self->cookies;

=cut

sub cookies {
  my $self = shift;

  if(my $c = $self->SUPER::cookies) {
    return($c);
  }

  require HTTP::Cookies;
  my $cookies = HTTP::Cookies->new(
    # TODO do we have any need to save cookies?
    #file       => "/tmp/cookies.txt", autosave   => 1,
  );
  $self->ua->cookie_jar($cookies);
  $self->set_cookies($cookies);
} # end subroutine cookies definition
########################################################################

=head1 Data Handling

=head2 process_config

  $self->process_config(%data);

=cut

sub process_config {
  my $self = shift;
  my (%result) = @_;

  # regardless of the result, we should have a time_shift value
  $self->set_server_drift($result{time_shift} || 0);

  my $resp = $result{response};
  my $conf = {};
  if(RC_OK == $resp->code) {
    $conf = $LOAD->($result{string});
  }

  # slightly odd callback control-flow:
  # setup the GET_manifest sequence, then either login+this or just this
  my @books = $self->books or die "need books to sync";
  my $after_login = sub {
    my $arg = '?' . join('&', map({'book=' . $_} @books));
    my $token = $self->add_request('GET', 'manifest.yml'.$arg);
    $self->queue($token => sub {$self->process_manifest(%{$_[1]})});
  };

  # TODO properly deal with auth_required: if unset, we don't do this
  # bit if we're only reading.  For now, auth_required=1
  if(my $lconf = $conf->{login}) {
    $self->cookies;
    my $url = $lconf->{url} or die "need url for login directive";
    my $template = $lconf->{template} or die "need template for login";
    my ($u,$p) = $self->authenticate($self->server->id, $url);
    #$template =~ s/\s*$//;
    $template =~ s/#USERNAME#/$u/ or die "no #USERNAME# in template?";
    $template =~ s/#PASSWORD#/$p/ or die "no #PASSWORD# in template?";
    my $token = $self->ua->add_request('POST', $url,
      [Content_Type => "application/x-www-form-urlencoded"], $template);
    $self->queue($token => sub {
      my ($t, $result) = @_;
      my $res = $result->{response};
      my $code = $res->code;
      NOISE and warn "login response:  ", $res->as_string;
      ($code == RC_OK) or die "failed login '$code' ", $res->message;
      NOISE and warn "we logged in";
      $after_login->();
    });
  }
  else {
    $after_login->();
  }

} # end subroutine process_config definition
########################################################################

=head2 process_manifest

Takes the ua response data (string/response) and sets up a course of
action to complete the sync.

Currently assumes a yaml manifest.

  $self->process_manifest(%data);

The rules are in L<dtRdr::Annotation::SyncRules>.

=cut

sub process_manifest {
  my $self = shift;
  my (%result) = @_;

  # TODO maybe allow a modified-since scheme too

  NOISE and warn "process_manifest\n";

  my $yaml = $result{string};
  my $resp = $result{response};
  if(RC_OK != $resp->code) {
    die "(", $resp->code, ") server not happy: $yaml";
  }

  my %s_man = %{$LOAD->($yaml)};
  # be super-strict about the manifest
  foreach my $id (keys(%s_man)) {
    defined($s_man{$id}) or
      die "server sent undefined revision for $id";
  }

  # any SELECT involved on the server needs to be mirrored here
  # for now just based on $self->books and the server id
  my $sid = $self->server->id;
  my $OBlob = sub {
    # TODO put this in the io req?
    my %book_ok = map({$_ => 1} $self->books);
    grep({$book_ok{$_->book}}
      grep({my $p; $p = $_->public and ($p->server eq $sid)}
        map({dtRdr::Annotation::IOBlob->outgoing(%$_)} @_)
      )
    )
  };

  my %current = map({$_->id => $_} $OBlob->($self->anno_io->items));
  my %deleted = map({$_->id => $_} $OBlob->($self->anno_io->deleted));

  ASSERT: { # deletes are sane
    foreach my $id (keys(%deleted)) {
      exists($current{$id}) and die "'$id' got undeleted incorrectly";
      defined($deleted{$id}->public->owner) and
        die "'$id' was deleted, but does not belong to me";
    }
  }
  ASSERT: { # prev's are sane
    foreach my $id (keys(%s_man)) {
      my $anno = $current{$id} || $deleted{$id} or next;
      ($anno->public->rev <= $s_man{$id}) or
        die "'$id' has higher synchronized revision than server!";
    }
  }

  my %actions;
  %actions = (
    REMOTE_DELETE => sub {
      my ($anno) = @_;
      my $id = $anno->id;
      my $rev = $anno->public->rev;
      my $token = $self->add_request(
        'DELETE',
        'annotation/' . $id . ".yml?rev=$rev",
      );
      $self->queue($token => sub {
        ($_[1]->{response}->code == RC_OK) or
          die YAML::Syck::Dump([@_]);
        # TODO it will send us the yaml of what gets deleted.
        # We should check it.
        $self->anno_io->x_finish_delete($anno->id);
      });
    },
    LOCAL_DELETE => sub {
      my ($anno) = @_;
      NOISE and warn "delete locally: ", $anno->id;
      $self->anno_io->s_delete($anno->id, $self->book($anno));
    },
    CONFLICT_DELETE => sub { # TODO warn/prompt?
      $actions{LOCAL_DELETE}->(@_);
    },
    POST => sub {
      my ($anno) = @_;
      my $id = $anno->id;
      my $send = $self->adjust_times('out', $anno);
      my $token = $self->add_request(
        'POST',
        'annotation/',
        [content_type => 'text/x-yaml'],
        $DUMP->($send->deref),
      );
      $self->queue($token => sub {
        my $code = $_[1]->{response}->code;
        ($code == RC_CREATED) or die "bad return code '$code',",
          "expected CREATED", YAML::Syck::Dump([@_]);
        $anno->public->set_rev($anno->revision);
        $self->anno_io->s_update($id, $anno->deref, $self->book($anno));
      });
    },
    PUT  => sub {
      my ($anno) = @_;
      my $id = $anno->id;
      my $rev = $anno->public->rev;
      my $send = $self->adjust_times('out', $anno);
      my $token = $self->add_request(
        'PUT',
        'annotation/' . $id . ".yml?rev=$rev",
        [content_type => 'text/x-yaml'],
        $DUMP->($send->deref),
      );
      $self->queue($token => sub {
        ($_[1]->{response}->code == RC_OK) or
          die YAML::Syck::Dump([@_]);
        $anno->public->set_rev($anno->revision);
        $self->anno_io->s_update($id, $anno->deref, $self->book($anno));
      });
    },
    FRESHEN => sub { # like get, but just an update from the server
      my ($anno) = @_;
      my $id = $anno->id;
      my $token =
        $self->add_request('GET', 'annotation/' . $id . '.yml');
      $self->queue($token => sub {
        $self->incoming($id, %{$_[1]},
          expect => $s_man{$id},
          have   => $anno,
        );
      });
    },
    GET  => sub {
      my ($id) = @_; # no object here
      my $token =
        $self->add_request('GET', 'annotation/' . $id . '.yml');
      $self->queue($token => sub {
        $self->incoming($id, %{$_[1]}, expect => $s_man{$id});
      });
    },
    SKIP => 0,
  );

  my $sr = dtRdr::Annotation::SyncRules->new(
    current  => [values(%current)],
    deleted  => [values(%deleted)],
    manifest => {%s_man},
    #error    => sub {
    #  my ($anno, @message) = @_;
    #  return('DIED.' . $message[0], $anno);
    #},
  )->init;
  while(my @ans = $sr->next) {
    my ($action, $anno) = @ans;
    exists($actions{$action}) or
      die "nothing for '$action' (" . (eval {$anno->id} || $anno) . ')';
    my $run = $actions{$action} or next;
    $run->($anno);
  }

} # end subroutine process_manifest definition
########################################################################

=head2 incoming

  $self->incoming($id, %answer);

=cut

sub incoming {
  my $self = shift;
  my ($id, %result) = @_;
  NOISE and warn "incoming $id";

  my $yaml = $result{string};
  my $resp = $result{response};
  if(RC_OK != $resp->code) {
    die "(", $resp->code, ") for $id server not happy: $yaml ";
  }

  my $got = $LOAD->($yaml);
  $got = dtRdr::Annotation::IOBlob->incoming(%$got);
  ($got->id eq $id) or die "server sent the wrong id for '$id'";

  my $rev = $got->revision;
  defined($rev) or
    die "server sent no (or undefined) revision for '$id'";
  if(defined(my $exp = $result{expect})) {
    ($exp == $rev) or # TODO $self->complain ?
      NOISE and warn "revision was not what I expected";
  }

  $got = $self->adjust_times('in', $got, $result{have} || undef);
  # set the public attribs
  my $server = $self->server or croak("need a server object here");
  my $p = $got->public;

  # these two are spoof-prevention
  $p->set_rev($rev);
  $p->set_server($server->id);

  # set 'me' as undef
  #   XXX note this could be an edge case when username changes on the
  #   server without a local update -- force login?
  $p->set_owner(undef) if($p->owner eq $server->username);

  # TODO do we need to dig for race conditions where the annotation has
  # changed locally since the sync started?

  # explicitly distinguish update from get
  my $io = $self->anno_io;
  my $method = 's_insert';
  if(my $anno = $result{have}) {
    # TODO just do an inner update on the object?
    $method = 's_update';
  }
  $io->$method($id, $got->deref, $self->book($got));
} # end subroutine incoming definition
########################################################################

=head1 Various


=head2 adjust_times

Adjust the object times by the server_drift and direction (+/- 1)

  $self->adjust_times('out', $obj);

  $self->adjust_times('in', $obj, $have);

=cut

sub adjust_times {
  my $self = shift;
  my ($mode, $obj, $have) = @_;

  $obj = $obj->clone;

  my $dir = {out => 1, in => -1}->{$mode} or
    croak("'$mode' is not 'in' or 'out'");

  my $drift = $self->server_drift;
  $drift or return($obj); # XXX what about undef fixups?

  $drift *= $dir;
  my @attribs = qw(create_time mod_time);
  if(($dir < 0) and $have) { # incoming freshen
    # don't change create time if we already have it
    # TODO check drift value?
    shift(@attribs);
  }
  foreach my $att (@attribs) {
    my $v = $obj->$att;
    defined($v) or next;
    my $set_att = 'set_' . $att;
    $obj->$set_att($v + $drift);
  }
  return($obj);
} # end subroutine adjust_times definition
########################################################################

=head2 book

See if we have access to an open book object for a given annotation (or
book id?)  (Used to notify the book about the changes.)

  $book = $self->book($anno);

=cut

sub book {
  my $self = shift;
  my ($anno) = @_;

  my $bag = $self->bookbag or return;

  my $bid = eval {$anno->book};
  $@ and ($bid = $anno);
  return($bag->find($bid));
} # end subroutine book definition
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
