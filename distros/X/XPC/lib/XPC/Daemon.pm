#!/usr/bin/perl -w
#
# Daemon.pm - XPC Daemon
#
# TODO: Make this a subclass of HTTP::Daemon and override
# &product_tokens() to return "XPC::Daemon" + version number
# so that the Server HTTP header won't say libwww*.
#
# Copyright (C) 2001 Gregor N. Purdy.
# All rights reserved.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
#


use strict;

package XPC::Daemon;

use HTTP::Daemon;
use HTTP::Status;
use Data::Dumper;

use XPC;


#
# new()
#

sub new
{
  my $class = shift;

  my $self = bless { PROCEDURES => { } }, $class;

  $self->{DAEMON} = new HTTP::Daemon;
  $self->{DEBUG} = 0;

  return $self;
}


#
# debug()
#

sub debug
{
  my $self = shift;

  $self->{DEBUG} = ($_[0] ? 1 : 0) if @_;

  return $self->{DEBUG};
}


#
# url()
#

sub url
{
  my $self = shift;

  return $self->daemon->url . "XPC";
}


#
# run()
#

sub run
{
  my $self = shift;

  die "$0: No procedures defined!" unless keys %{$self->{PROCEDURES}};

  while (my $c = $self->daemon->accept) {
    while (my $r = $c->get_request) {
      if ($r->method eq 'POST' and $r->url->path eq "/XPC") {
        my @response = $self->process_request($r);
        my $xpc = XPC->new;
        map { $xpc->add_response($_); } @response;
        my $http_res = new HTTP::Response;
        $http_res->content($xpc->as_string);
        $http_res->code(200);
        $c->send_response($http_res);
      } else {
        $c->send_error(RC_FORBIDDEN)
      }
    }
    $c->close;
    undef($c);
  }
}



#
# add_procedure()
#

sub add_procedure
{
  my $self = shift;
  my ($procedure, $callback) = @_;

  $self->{PROCEDURES}{$procedure} = $callback;

  print "&XPC::Daemon::add_procedure(): Added procedure '$procedure'.\n" if $self->debug();
}


#
# callback()
#

sub callback
{
  my ($self, $procedure) = @_;

  return $self->{PROCEDURES}{$procedure};
}


#
# daemon()
#

sub daemon
{
  my $self = shift;
  return $self->{DAEMON};
}


#
# process_request()
#

sub process_request
{
  my $self = shift;
  my $r = shift;

  my @response;
  my $id_required;

  if ($self->debug()) {
    print "&XPC::Daemon::process_request(): Recieved request:\n";
    print $r->content;
    print "\n";

    print "&XPC::Daemon::process_request(): Parsing request...\n";
  }

  my $xml = $r->content;
  my $xpc;

  eval { $xpc = XPC->new($xml); };

  if ($@ or !defined $xpc) {
    print "&XPC::Daemon::process_request(): Unable to parse XPC request:\n";
    print $xml;
    print "\n";
    push @response, make_fault(7, "Unable to parse request!");
    return @response;
  }

  print "&XPC::Daemon::process_request(): Request parses as class ", ref $xpc, ".\n" if $self->debug;

  $xpc = $xpc->[0];

  if ($self->debug()) {
    print "&XPC::Daemon::process_request(): Class is ", ref $xpc, ".\n";
    print Dumper($xpc);
    print "\n";
  }


  my @requests = grep { ref $_ ne 'XPC::Characters' } @{$xpc->{Kids}};

  print "&XPC::Daemon::process_request(): Processing queries and calls...\n" if $self->debug();

  foreach my $req (@requests) {
    if (@requests > 1 and not $req->id) {
      @response = ( make_fault(3, "Every request of a multi-request must set 'id'!") );
      last;

      # TODO: We really should scan them first so we don't cause any side-effects.
    }

    if (ref $req eq 'XPC::call') {
      push @response, $self->process_call($req);
    } elsif (ref $req eq 'XPC::query') {
      push @response, make_fault(1, "&lt;query&gt;s are not supported!");
    } elsif (ref $req eq 'XPC::result') {
      push @response, make_fault(5, "&lt;result&gt;s are not requests!");
    } elsif (ref $req eq 'XPC::fault') {
      push @response, make_fault(6, "&lt;fault&gt;s are not requests!");
    } else {
      push @response, make_fault(4, sprintf("Unknown request type '%s'!", ref $req));
    }
  }

  return @response;
}


#
# process_call()
#

sub process_call
{
  my $self = shift;
  my $call = shift;

  my $procedure = $call->procedure;

  print "&XPC::Daemon::process_call(): Processing call to '$procedure'...\n" if $self->debug();

  my $callback  = $self->callback($procedure);

  if ($callback) {
    return make_result(scalar(&$callback()));
  } else {
    return make_fault(2, sprintf("&lt;call&gt; to unknown procedure '%s'!", $procedure));
  }
}


##############################################################################
##
## UTILITIES:
##
##############################################################################


#
# make_fault()
#

sub make_fault
{
  return new XPC::fault(@_);
}


#
# make_result()
#

sub make_result
{
  return XPC::result->new_scalar(@_);
}


1;


=head1 NAME

XPC::Daemon - XML Procedure Call daemon class


=head1 SYNOPSIS

  use XPC::Daemon;
  my $daemon = new XPC::Daemon;
  $daemon->add_procedure('localtime', sub { localtime });
  my $pid = fork;
  die "$0: Unable to fork!\n" unless  defined $pid;
  
  if ($pid) {
    print STDOUT $daemon->url, "\n";
    print STDERR "$0: Forked child $pid.\n";
    exit 0;
  } else {
    $daemon->run;
    exit 0;
  } 


=head1 DESCRIPTION

This class is a generic XPC-over-HTTP server daemon. Use the C<add_procedure>
method to give it specific functionality.


=head1 AUTHOR

Gregor N. Purdy E<lt>gregor@focusresearch.comE<gt>


=head1 COPYRIGHT

Copyright (C) 2001 Gregor N. Purdy.
All rights reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

