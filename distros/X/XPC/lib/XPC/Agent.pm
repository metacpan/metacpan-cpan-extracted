#!/usr/bin/perl -w
#
# Agent.pm - XPC Agent
#
# Copyright (C) 2001 Gregor N. Purdy.
# All rights reserved.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
#


use strict;

package XPC::Agent;

use URI;
use LWP::UserAgent;
use HTTP::Request;
use XPC;


#
# new()
#

sub new
{
  my $class = shift;
  my $uri_input = shift;

  my $self = bless { }, $class;

  $self->{URI} = URI->new($uri_input);
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
# uri()
#

sub uri
{
  my $self = shift;
  return $self->{URI};
}


#
# _call_()
#

sub _call_
{
  my ($self, $procedure, @args) = @_;

  #
  # Request Building:
  #

  print "$0: Building XPC request...\n" if $self->debug();

  my $uri_string = $self->uri->as_string;

  my $xpc_req    = XPC->new_call($procedure);
  my $xpc_string = $xpc_req->as_string;

  if ($self->debug()) {
    print "XPC REQUEST:\n";
    print $xpc_string;
    print "\n\n";
  }

  print "$0: Building HTTP request 'POST => $uri_string'...\n" if $self->debug();

  my $http_req = HTTP::Request->new('POST', $uri_string);

  print "$0: Adding XPC content...\n" if $self->debug();

  $http_req->content($xpc_string);

  if ($self->debug()) {
    print "HTTP REQUEST:\n";
    print $http_req->as_string;
    print "\n\n";
  }

  #
  # Sending Request:
  #

  my $ua       = LWP::UserAgent->new;
  my $http_res = $ua->request($http_req);

  #
  # Response Processing:
  #

  if ($self->debug()) {
    print "HTTP RESPONSE:\n";
    print $http_res->as_string;
    print "\n\n";
  }

  if ($http_res->code != 200) {
    die "XPC::Agent::_call_(): Server did not return status 200!\n";
  }

  my $xpc_res = XPC->new($http_res->content);
  $xpc_res = $xpc_res->[0];

  if ($xpc_res->faults) {
    my $fault = $xpc_res->fault(0);
    die "XPC::Agent::_call_(): Detected fault presence but can't find it!\n" unless defined $fault;
    my $code    = $fault->code;
    my $message = $fault->message;
    die "Fault [$code]: $message\n";
  } else {
    my $result = $xpc_res->result(0);
    return $result->value;
  }
}


#
# AUTOLOAD()
#

use vars qw($AUTOLOAD);

sub AUTOLOAD
{
  my ($self, @args) = @_;

  return if $AUTOLOAD eq 'XPC::Agent::DESTROY';

  my $procedure = $AUTOLOAD;
  $procedure =~ s/^XPC::Agent:://;

  print "Calling procedure '$procedure'...\n" if $self->debug();

  return $self->_call_($procedure, @args);
}


1;


=head1 NAME

XPC::Agent - XML Procedure Call client


=head1 SYNOPSIS

  use XPC::Agent;
  my $agent = XPC::Agent->new($server_url);
  printf "localtime() --> %s\n", $agent->localtime();


=head1 DESCRIPTION

Uses Perl's AUTOLOAD mechanism to intercept calls to undefined subroutines
and forward them via XPC over HTTP to a server.


=head1 AUTHOR

Gregor N. Purdy E<lt>gregor@focusresearch.comE<gt>


=head1 COPYRIGHT

Copyright (C) 2001 Gregor N. Purdy.
All rights reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

