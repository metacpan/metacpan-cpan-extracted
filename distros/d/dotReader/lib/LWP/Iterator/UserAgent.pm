package LWP::Iterator::UserAgent;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

use base 'LWP::Parallel::UserAgent';

use Time::HiRes;
use constant {DBG => 0};

=head1 NAME

LWP::Iterator::UserAgent - a non-blocking LWP iterator

=head1 SYNOPSIS

=cut

#sub on_failure { warn "we failed"; undef}
#sub on_connect { warn "we connected"; undef}
#sub on_return { warn "we returned"; undef}

=head2 new

Construct a new LWP::Iterator::UserAgent object.  Passes additional
%opts through to LWP::UserAgent::new().

  my $pua = LWP::Iterator::UserAgent->new(%opts, deadline => 10.5);

=cut

sub new {
  my $class = shift;
  my (%cnf) = @_;
  # XXX huh?  LWP::P::UA isn't playing the same game as LWP::UA!
  # So... we have to bypass LWP::P::UA::new and then copy/paste the init
  # stuff into here.  Uh, hello?  That's not how this OO thing is
  # supposed to work!
  my $self = $class->LWP::UserAgent::new(%cnf);

  ######################################################################
  { # Oh, how I wish we had a sane superclass...
    # So, since we have to rewrite it anyway, let's do it right. 
    my %defaults = (
      handle_response   => 1,
      nonblock          => 0,
      handle_duplicates => 0,
      handle_in_order   => 0,
      remember_failures => 0,
      max_hosts         => 7,
      max_req           => 5,
    );
    foreach my $att (keys %defaults) {
      $self->{$att} = $defaults{$att} unless(exists($self->{$att}));
    }

    $self->initialize;
  } # end "I wish we had a sane ..."
  ######################################################################


  $self->{deadline} = $cnf{deadline};
  return($self);
} # end subroutine new definition
########################################################################

=head2 deadline

  $pua->deadline;

  $pua->deadline($seconds);

=cut

sub deadline {
  my $self = shift;
  LWP::Debug::trace("($_[0])");
  $self->{deadline} = $_[0] if(@_);
  $self->{deadline};
} # end subroutine deadline definition
########################################################################

=head2 pester

Where the Parallel::UserAgent expects you to wait() on it, this class
needs to be nagged or it will never do anything.

  while(1) {
    $pua->pester and last;
  }

Optionally, you can pass a timeout value.

  $are_we_there_yet = $pua->pester(0.1);

Note that while the LWP::Parallel::UserAgent class uses timeout as an
overall deadline, this class uses the deadline attribute.

=cut

sub pester {
  my $self = shift;
  my ($timeout) = @_;

  defined($self->{deadline}) or die "must have a deadline";
  $timeout = $self->{'timeout'} unless defined $timeout;
  my $start_time = Time::HiRes::time;
  $self->{_fate} = $self->{deadline} unless(exists($self->{_fate}));
  my $tick = sub {
    my $diff = Time::HiRes::time - $start_time;
    DBG and warn "deadline $self->{_fate} - $diff\n";
    $self->{_fate} -= $diff;
  };

  # shortcuts to in- and out-filehandles
  my $fh_out = $self->{'select_out'};
  my $fh_in  = $self->{'select_in'};

  $self->{_is_done} = 1 unless($self->_check_connections);
  if($self->{_is_done}) {
    $self->_remove_all_sockets();
    DBG and warn "all done\n";
    return 1;
  }
  elsif(! $self->{_is_connected}) {
    DBG and warn "connect\n";
    { # allow high-latency on connection create (TODO nonblock https?)
      local $self->{timeout} = 10 * $self->{timeout};
      $self->_make_connections;
    }
    $self->{_is_connected} = 1;
    DBG and warn "connected\n";
    # deadline?
    $tick->();
    return 0; # maybe puts us a little over the deadline, but no biggie
  }
  elsif((scalar $fh_in->handles) or (scalar $fh_out->handles)) {
    LWP::Debug::debug("Selecting Sockets, timeout is $timeout seconds");
    if(my @ready = IO::Select->select($fh_in, $fh_out, undef, $timeout)) {
      DBG and warn "ready!\n";
      # something is ready for reading or writing
      my ($ready_read, $ready_write, $error) = @ready;

      # reset the deadline
      delete($self->{_fate});

      # WRITE QUEUE
      foreach my $socket (@$ready_write) {
        my $so_err;
        if($socket->can('getsockopt')) { # we also might have IO::File!
          # check if there is any error
          $so_err = $socket->getsockopt( Socket::SOL_SOCKET(),
                                         Socket::SO_ERROR() );
          LWP::Debug::debug( "SO_ERROR: $so_err" ) if $so_err;
        }
        $self->_perform_write($socket, $timeout) unless $so_err;
      }

      # READ QUEUE
      $self->_perform_read($_, $timeout) for(@$ready_read);
      return(0);
    }
    else {
      # empty array, means that select timed out
      DBG and warn "timeout\n"; # ELW: not really a timeout here
      LWP::Debug::trace('select timeout');
      return if($tick->() > 0); # XXX hack?
      # set all active requests to "timed out"
      foreach my $socket ($fh_in->handles ,$fh_out->handles) {
        my $entry = $self->{'entries_by_sockets'}->{$socket};
        delete $self->{'entries_by_sockets'}->{$socket};
        unless($entry->response->code) {
          # each entry gets its own response object
          my $response = HTTP::Response->new(&HTTP::Status::RC_REQUEST_TIMEOUT,
                                           'User-agent timeout (select)');
          $entry->response($response);
          $response->request($entry->request);
          $self->on_failure($entry->request, $response, $entry);
        }
        else {
          my $res = $entry->response;
          $res->message($res->message . " (timeout)");
          $entry->response ($res);
          # XXX on_failure for now, unless on_return is better
          $self->on_failure($entry->request, $res, $entry);
        }
        $self->_remove_current_connection($entry);
      } # end foreach socket
      # and delete from read- and write-queues
      $fh_out->remove($_) for($fh_out->handles);
      $fh_in->remove($_)  for($fh_in->handles);
      # TODO continue processing -- pending requests might still work?
      #      except if we got here, we are past the deadline
      return(1);
    } # end if (@ready...) {} else {}
  }
  die "clueless";
} # end subroutine pester definition
########################################################################

=head2 _check_connections

  $bool = $self->_check_connections;

=cut

sub _check_connections {
  my $self = shift;
  my $v;
  $v = 1 if(
    scalar(keys(%{$self->{'current_connections'}}))  or
    scalar(
      $self->{'handle_in_order'} ?
      @{$self->{'ordpend_connections'}} :
      keys(%{$self->{'pending_connections'}})
    )
  );
  return($v);
} # end subroutine _check_connections definition
########################################################################

=head2 handle_response

  $self->handle_response(thbbt);

=cut

sub handle_response {
  my $self = shift;
  DBG and warn "handlinginging\n";
  local $self->{in_handler} = 1;
  $self->SUPER::handle_response(@_);
} # end subroutine handle_response definition
########################################################################

=head2 request

Internal use only.  Our base class drops everything on the floor when
this method is called (during authentication), so we need to hatchet on
it a good bit.

  $self->request(thbbt);

=cut

sub request {
  my $self = shift;

  $self->{in_handler} or
    die "cannot use request() method on an iterator";

  0 and warn "connections before: ",
    ($self->_check_connections ? 'ok' : 'gone'), "\n";

  if(my $res = $self->register(@_)) {
    die $res->error_as_string;
  }
  return;
} # end subroutine request definition
########################################################################
sub _single_request {croak "cannot be used"};

=head1 AUTHOR

Eric Wilhelm (@) <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

Portions derived from LWP::Parallel::UserAgent, copyright 1997-2004 Marc
Langheinrich.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
