package dtRdr::UserAgent;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

use base 'LWP::Iterator::UserAgent';

my @subs = qw(
  progress_sub
  complete_sub
  error_sub
  auth_sub
);
use Class::Accessor::Classy;
rw @subs;
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::UserAgent - Custom LWP::Iterator::UserAgent

=head1 SYNOPSIS

=cut


=head2 new

  my $ua = dtRdr::UserAgent->new;

=cut

sub new {
  my $class = shift;
  (@_ %2) and croak("odd number of elements in argument hash");
  my %args = @_;
  my %internal = map(
    {exists($args{$_}) ? ($_ => delete($args{$_})) : ()}
    @subs
  );
  my $self = $class->SUPER::new(%args);

  $self->{$_} = $internal{$_} for(keys %internal);
  $self->{deadline} ||= 5;
  $self->timeout(0.1);
  $self->redirect(1);

  $self->{_token_map} = {};
  $self->{_request_time} = {};
  $self->{_collecting} = {};
  $self->{_collected} = {};
  $self->{_leftover} = {};

  return($self);
} # end subroutine new definition
########################################################################

=head2 add_request

This registers a request and returns a token for accessing the returned
data from it later.  The $method, $url, (and optional headers, content)
arguments get passed to HTTP::Request.

  my $token = $ua->add_request($method, $url, [%headers], $content);

Or, options in a leading hash reference.

  $ua->add_request({token => $token}, $method, $url);

=cut

my $autotoken = 0;
sub add_request {
  my $self = shift;
  my $args = (ref($_[0]) ? shift(@_) : {});

  my $req = HTTP::Request->new(@_);

  # take the given token or else make something unique (and useful)
  my $token = $args->{token} ||
    '[' . $autotoken++ . '.' . $req->method . '.' . $req->uri . ']';

  my $subref = sub {
    $self->_collect($token, @_);
  };

  $self->{_token_map}{"$subref"} = $token;

  if(my $res = $self->register($req, $subref)) {
    die $res->error_as_string;
  }
  #warn "registered $req\n";
  return($token);
} # end subroutine add_request definition
########################################################################

=head2 register

Override base class to deal with request-time tracking.

  $self->register(@_);

=cut

sub register {
  my $self = shift;
  my ($this, $code, @that) = @_;

  $code or Carp::confess("oops, no code");
  my $token = $self->{_token_map}{$code};
  defined($token) or die "arg! no token here";

  $self->{_request_time}{$token} = [Time::HiRes::time()];
  return $self->SUPER::register($this, $code, @that);
} # end subroutine register definition
########################################################################

=head2 is_started

  $ua->is_started($token);

=cut

sub is_started {
  my $self = shift;

  die "finish me";
} # end subroutine is_started definition
########################################################################

=head2 is_complete

  $ua->is_complete($token);

=cut

sub is_complete {
  my $self = shift;
  die "finish me";
} # end subroutine is_complete definition
########################################################################

=head2 collect

Take possession of the data collected for $token (can only be called
once.)

  my %data = $ua->collect($token);

This is the point where asynchronous processing joins back to the main
flow, so it will die if exceptions were thrown during the connection.

=cut

sub collect {
  my $self = shift;
  my ($token) = @_;
  $token or croak("must have a token");

  my $coll = $self->{_collected};
  exists($coll->{$token}) or return;

  my $data = delete($coll->{$token});
  #require YAML::Syck; warn YAML::Syck::Dump($data);

  { # gah! throw an exception already!
    my $h = $data->{response}{_headers};
    exists($h->{'x-died'}) and die $h->{'x-died'};
  }
  return(%$data);
} # end subroutine collect definition
########################################################################

=head2 leftovers

  my %also = $ua->leftovers;

=cut

sub leftovers {
  my $self = shift;
  my $left = delete($self->{_leftover}) || {};
  return(%$left);
} # end subroutine leftovers definition
########################################################################

=head1 Internals

=head2 _collect

  $ua->_collect;

=cut

sub _collect {
  my $self = shift;
  my ($token, $str, $res, $proto) = @_;
  # XXX why does $proto matter?

  ######################################################################
  # NOTE TO SELF:  Exceptions in here get trapped by the L.P.Protocol  #
  # and stuffed into an HTTP::Response header.  A kitten dies.         #
  # See collect() for 'throw an exception already"!'                   #
  ######################################################################

  # TODO some way to enable progress guessing?
  my $clen = $res->content_length;
  0 and warn "response size: ", defined($clen) ? $clen : '~', "\n",
    "received size: ", length($str);

  #warn "response age: ", $res->current_age; # always zero
  #warn "got this at " , scalar localtime $res->date;
  #warn "client_date " , scalar localtime $res->client_date;

  #warn "on_collect @_";
  #warn "received ", length($str), " bytes for $token (", $res->code, ")\n";

  my $coll = $self->{_collecting};
  if(exists($coll->{$token})) { # TODO make add_request() setup that bit?
    $coll->{$token}{string} .= $str;
  }
  else { # first arrival

    #require YAML::Syck; warn YAML::Syck::Dump($res);

    $coll->{$token} = {
      string     => $str,
      response   => $res,
      time_shift => $self->compute_time_shift($token, $res),
    };
  }

  # TODO eval { $progress_sub->($self, $token, $str)}; # or something

  return(undef);
} # end subroutine _collect definition
########################################################################

=head2 compute_time_shift

Calculates server time shift.

  $self->compute_time_shift($token, $response);

=cut

sub compute_time_shift {
  my $self = shift;
  my ($token, $res) = @_;

  # adjust by half-latency plus 0.5s average rounding error
  my $times = delete($self->{_request_time}{$token});
  $times or die "what?";
  my ($req_time, $res_time) = @$times;
  my $local_mean = ($res_time + $req_time) / 2;

  # TODO (uh, think I fixed it) this is thrown-off when authentication
  # is required thus, the delta gives an accurate latency, but doesn't
  # tell us the current time (somewhere in the re-request, we lose track
  # of request time.)

  #warn "round-trip: ", $res_time - $req_time;
  #warn "response date: ", $res->date;
  my $td = sprintf('%0.0f', $res->date + 0.5 - $local_mean);

  return($td);
} # end subroutine compute_time_shift definition
########################################################################

=head2 on_connect

  $ua->on_connect;

=cut

sub on_connect {
  my $self = shift;
  my ($req, $res, $entry) = @_;

  #warn "on_connect";
  # determine connect latency ASAP
  # $response is a skeleton here, so time shift calc comes later
  my $token = $self->{_token_map}{$entry->arg};
  defined($token) or die "arg! no token here";
  my $list = $self->{_request_time}{$token} or
    die "no req time for $token?";
  my $time = Time::HiRes::time();
  $list->[1] and die "connected twice? @$list ", Time::HiRes::time();
  $list->[1] = $time;

  return(undef);
} # end subroutine on_connect definition
########################################################################

=head2 on_failure

  $ua->on_failure;

=cut

sub on_failure {
  my $self = shift;
  my ($req, $res, $entry) = @_;

  my $subref = $entry->arg; # turn it back into a token
  my $token = delete($self->{_token_map}{"$subref"});
  delete($self->{_collecting}{$token});
  delete($self->{_leftover}{$token});
  undef &$subref;

  if(my $cb = $self->error_sub) {
    $cb->($self, $token, $req, $res);
  }
  else {
    die "failed on $token \n ", $res->message;
  }
  return(undef);
} # end subroutine on_failure definition
########################################################################

=head2 on_return

  $ua->on_return;

=cut

sub on_return {
  my $self = shift;
  my ($req, $res, $entry) = @_;

  #warn "on_return @_";
  #require YAML::Syck; warn YAML::Syck::Dump($res);

  # we have to bake our own cookies?
  if(my $cj = $self->cookie_jar) {$cj->extract_cookies($res);}

  # How silly is this!?  Only persistent token I have is the subref!
  my $subref = $entry->arg; # turn it back into a token
  if(defined(my $token = $self->{_token_map}{"$subref"})) {
    # see if we hit the collector yet
    my $coll_in = $self->{_collecting};
    if(defined(my $coll = delete($coll_in->{$token}))) {
      $self->_complete_request($subref, $coll);
    }
    else { # otherwise, this is a redirect, but maybe an error
      my $c = $res->code;
      if($c == 401) { # TODO and maybe redirect?
        $self->{_leftover}{$token} = {
          string => '',
          response => $res,
        };
      }
      else {
        # TODO something with redirects
        ## ($c =~ m/^30[12]$/) and
        ##   warn "$c to ", $res->headers->header('location');
        $self->_complete_request($subref, {
          string => undef, response => $res,
          time_shift => $self->compute_time_shift($token, $res),
        });
      }
    }
  }
  else {
    die "oops, no token";
  }

  return(undef);
} # end subroutine on_return definition
########################################################################

=head2 _complete_request

Delete the token and destroy the subref, then hit the callback.

  $self->_complete_request($subref);

=cut

sub _complete_request {
  my $self = shift;
  my ($subref, $coll) = @_;

  # we should never see it again
  my $token = delete($self->{_token_map}{"$subref"});

  # drop any of these as well
  delete($self->{_leftover}{$token});

  exists($self->{_collected}{$token}) and die "trouble $token";
  $self->{_collected}{$token} = $coll;
  # free the closure memory
  undef(&$subref); # XXX hope that's safe

  # hit the callback
  if(my $comp = $self->complete_sub) {
    $comp->($self, $token);
  }
} # end subroutine _complete_request definition
########################################################################

=head2 get_basic_credentials

Called by base class upon authentication request.  Triggers the auth_sub
callback.

  $self->get_basic_credentials($realm, $uri);

  $callback->($realm, $uri);

=cut

sub get_basic_credentials {
  my $self = shift;

  if(my $cb = $self->auth_sub) {
    return $cb->(@_);
  }

  return();
} # end subroutine get_basic_credentials definition
########################################################################

# TODO $bool = $self->redirect_ok($request, $response);

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006-2007 Eric L. Wilhelm and Osoft, All Rights Reserved.

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

