package WWW::Domain::Registry::Joker;

use 5.006;
use strict;
use warnings;

use LWP;
use URI::Escape;

use WWW::Domain::Registry::Joker::Loggish;

use WWW::Domain::Registry::Joker::Response;

our @ISA = qw(WWW::Domain::Registry::Joker::Loggish);

our $VERSION = '0.11';

=head1 NAME

WWW::Domain::Registry::Joker - an interface to the Joker.com DMAPI

=head1 SYNOPSIS

  use WWW::Domain::Registry::Joker;

  $reg = new WWW::Domain::Registry::Joker('username' => 'testuser',
    'password' => 'secret', 'debug' => 1);

  @res = $reg->result_list();

  eval {
    $procid = $reg->do_request('ns-create', 'Host' => 'a.ns.example.com',
      'IP' => '192.168.13.1');
  };
  if ($@) {
    warn("Joker request failed: $@\n");
  }

=head1 DESCRIPTION

The C<WWW::Domain::Registry::Joker> module provides a Perl interface to
the Domain Management API (DMAPI) used by the Joker.com DNS registrar.
It is designed to help Joker.com resellers in automating the domain
registration and all the other relevant actions.

The recommended usage of the C<WWW::Domain::Registry::Joker> class is
to create an object, initialize it with the Joker.com reseller's username
and password, and then use it to send all the DMAPI requests.  This will
take care of caching both login credentials and network connections
(at least as far as C<LWP> takes care of caching connections to the same
webserver).

In most cases it is not necessary to invoke the C<login()> method
explicitly, since all the "real" action methods check for an authentication
token and invoke C<login()> if there is none yet.

=head1 METHODS

The C<WWW::Domain::Registry::Joker> class defines the following methods:

=over 4

=item * new ( PARAMS )

Create a new Joker.com interface object with the specified parameters:

=over 4

=item * username

The Joker.com reseller authentication username.

=item * password

The Joker.com reseller authentication password.

=item * debug

The diagnostic output level, 0 for no diagnostic messages.

=item * dmapi_url

The URL to use for Joker.com Domain Management API (DMAPI) requests;
if not specified, the standard URL I<https://dmapi.joker.com/request>
is used.

=back

=cut

sub new($ %)
{
	my ($proto, %param) = @_;
	my $class = ref $proto || $proto;
	my $self;

	$self = WWW::Domain::Registry::Joker::Loggish::new($proto,
		'authsid' => undef,
		'lwp' => undef,
		'err' => undef,
		'fake' => 0,
		'password' => undef,
		'dmapi_url' => 'https://dmapi.joker.com/request',
		'username' => undef,
		%param,
	);
	return $self;
}

=item * lwp ( [OBJECT] )

Get or set the C<LWP::UserAgent> object used for sending the actual
requests to the Joker.com web API.

This method should probably never interest any consumers of this class :)

=cut

sub lwp($ $)
{
	my ($self, $obj) = @_;

	if (defined($obj)) {
		if (index(ref($obj), '::') == -1 ||
		    !$obj->isa('LWP::UserAgent')) {
			die("WWW::Domain::Registry::Joker->lwp() requires a ".
			    "LWP::UserAgent object, not '".ref($obj)."'\n");
		}
		$self->{'lwp'} = $obj;
	} elsif (!defined($self->{'lwp'})) {
		$obj = new LWP::UserAgent();
		$self->{'lwp'} = $obj;
	}
	return $self->{'lwp'};
}

=item * build_request ( REQUEST, PARAMS )

Build a C<HTTP::Request> object for submitting an actual request to
the Joker.com API.

This method should probably never interest any consumers of this class :)

=cut

sub build_request($ $ %)
{
	my ($self, $req, %param) = @_;
	my ($s, $k, $v, $l, $i);

	$s = "$self->{'dmapi_url'}/$req";
	if (%param) {
		$s .= '?'.join '&', map
		    uri_escape($_).'='.uri_escape($param{$_}), keys %param;
	}
	return new HTTP::Request('GET' => $s);
}

=item * login ()

Send a DMAPI login authentication request and obtain the auth SID for
use in the follow-up actual requests.  The I<username> and I<password>
member variables must be initialized.

=cut

sub login($)
{
	my ($self) = @_;
	my ($req, $hresp, $resp);

	die("No DMAPI credentials supplied")
	    unless defined($self->{'username'}) && defined($self->{'password'});
	$req = $self->build_request('login', 'username' => $self->{'username'},
	    'password' => $self->{'password'});
	$self->debug("=== DMAPI login request\n".$req->as_string()."\n===\n");
	$hresp = $self->lwp()->request($req);
	$resp = new WWW::Domain::Registry::Joker::Response(
	    'debug' => $self->{'debug'}, 'log' => $self->{'log'});
	$resp->parse($hresp);
	die("DMAPI login: $resp->{Error}\n") if defined($resp->{'Error'});
	die("DMAPI login: $resp->{status}\n") unless $resp->{'success'};
	die("DMAPI login error: $resp->{code} $resp->{msg}\n")
	    unless defined($resp->{'code'}) && $resp->{'code'} == 0;
	die("DMAPI login parse error: no auth session ID\n")
	    unless defined($resp->{'Auth-Sid'});
	$self->{'authsid'} = $resp->{'Auth-Sid'};
	return $self->{'authsid'};
}

=item * query_domain_list ( PATTERN )

Return information about the domains registered by this reseller whose names
match the supplied pattern.  Returns a hash indexed by domain name, each
element of which is a hash:

=over 4

=item * domain

The domain name (yes, again :))

=item * exp

The expiration date of the domain registration.

=back

Invokes the C<login()> method if necessary.

=cut

sub query_domain_list($ $)
{
	my ($self, $pattern) = @_;
	my ($req, $hresp, $resp);
	my (%res);

	if (!defined($self->{'authsid'})) {
		return undef unless $self->login();
	}
	$req = $self->build_request('query-domain-list',
	    'Auth-Sid' => $self->{'authsid'},
	    'pattern' => $pattern);
	$self->debug("=== DMAPI qdlist request\n".$req->as_string()."\n===\n");
	$hresp = $self->lwp()->request($req);
	$resp = new WWW::Domain::Registry::Joker::Response(
	    'debug' => $self->{'debug'}, 'log' => $self->{'log'});
	$resp->parse($hresp);
	die("DMAPI qdlist: $resp->{Error}\n") if defined($resp->{'Error'});
	die("DMAPI qdlist: $resp->{status}\n") unless $resp->{'success'};
	die("DMAPI qdlist error: $resp->{code} $resp->{msg}\n")
	    unless defined($resp->{'code'}) && $resp->{'code'} == 0;
	foreach (@{$resp->{'data'}}) {
		if (!/^(\S+)\s+(\S+)$/) {
			$self->debug("- invalid format $_");
			next;
		}
		$res{$1} = { 'domain' => $1, 'exp' => $2 };
	}
	return %res;
}

=item * do_request ( REQUEST, PARAMS )

Send a DMAPI request with the name specified in C<REQUEST> and
parameters in the C<PARAMS> hash.  The request name string and
the parameters (required and optional) are as specified by
the DMAPI documentation

Note that for object modification requests (those which type is
C<domain-owner-change> or ends in C<-modify>) if a parameter is supplied
with the empty string as a value, the C<do_request()> method will send
the I<"!@!"> string instead, since the DMAPI considers empty values to mean
no change requested.

Invokes the C<login()> method if necessary.

=cut

sub do_request($ $ %)
{
	my ($self, $type, %data) = @_;
	my ($req, $hresp, $resp);
	my (%d);

	if (!defined($self->{'authsid'})) {
		return undef unless $self->login();
	}
	foreach (keys %data) {
		if (defined($data{$_}) && length($data{$_})) {
			$d{$_} = $data{$_};
		} elsif ($type eq 'domain-owner-change' ||
		    $type =~ /-modify$/) {
			$d{$_} = '!@!';
		}
	}
	$req = $self->build_request("$type",
	    'Auth-Sid' => $self->{'authsid'},
	    %d);
	$self->debug("=== DMAPI $type request\n".$req->as_string()."\n===\n");
	$hresp = $self->lwp()->request($req);
	$resp = new WWW::Domain::Registry::Joker::Response(
	    'debug' => $self->{'debug'}, 'log' => $self->{'log'});
	$resp->parse($hresp);
	die("DMAPI $type: $resp->{Error}\n") if defined($resp->{'Error'});
	die("DMAPI $type: $resp->{status}\n") unless $resp->{'success'};
	die("DMAPI $type error: $resp->{code} $resp->{msg}\n")
	    unless defined($resp->{'code'}) && $resp->{'code'} == 0;
	die("DMAPI $type - no processing ID returned!\n")
	    unless defined($resp->{'Proc-ID'});
	return $resp->{'Proc-ID'};
}

=item * result_list ()

Obtain the list of processed requests from the Joker.com DMAPI and
the corresponding result status and object ID (where applicable).
Returns a hash indexed by DMAPI I<Proc-Id> values.

Invokes the C<login()> method if necessary.

=cut

sub result_list($)
{
	my ($self) = @_;
	my ($req, $hresp, $resp);
	my (@r);
	my (%a, %res);

	if (!defined($self->{'authsid'})) {
		return undef unless $self->login();
	}
	$req = $self->build_request('result-list',
	    'Auth-Sid' => $self->{'authsid'});
	$self->debug("=== DMAPI rlist request\n".$req->as_string()."\n===\n");
	$hresp = $self->lwp()->request($req);
	$resp = new WWW::Domain::Registry::Joker::Response(
	    'debug' => $self->{'debug'}, 'log' => $self->{'log'});
	$resp->parse($hresp);
	die("DMAPI rlist: $resp->{Error}\n") if defined($resp->{'Error'});
	die("DMAPI rlist: $resp->{status}\n") unless $resp->{'success'};
	die("DMAPI rlist error: $resp->{code} $resp->{msg}\n")
	    unless defined($resp->{'code'}) && $resp->{'code'} == 0;
	%res = ();
	foreach (@{$resp->{'data'}}) {
		@r = split /\s+/;
		if ($#r != 6) {
			$self->debug("Unrecognized result-list line: $_");
			next;
		}
		@a{qw/tstamp svtrid procid reqtype reqobject status cltrid/} =
		    @r;
		$self->debug("result $a{procid} $a{status} $a{reqobject}");
		$res{$a{'procid'}} = { %a };
	}
	return %res;
}

=back

=head1 EXAMPLES

Initialize a C<WWW::Domain::Registry::Joker> object with your reseller's
username and password:

  $jreq = new WWW::Domain::Registry::Joker('username' => 'me@example.com',
  	'password' => 'somekindofsecret');

Fetch the list of pending and processed requests and their status:

  %h = $jreq->result_list();
  foreach (sort { $a->{'procid'} cmp $b->{'procid'} } values %h) {
  	print join("\t",
  	    @{$_}{qw/tstamp svtrid procid reqtype reqobject status cltrid/}).
	    "\n";
  }

Register a new nameserver:

  eval {
  	$jreq->do_request('ns-create', 'Host' => 'a.ns.example.net',
  	    'IP' => '192.168.13.7');
  };
  print STDERR "ns-create error: $@\n" if ($@);

Maybe some more examples are needed here :)

=head1 ERRORS

All the user-invoked methods die on any Joker.com errors with
a suitable error message placed in $@.

=head1 SEE ALSO

I<https://joker.com/faq/category/39/22-dmapi.html> - the Joker.com DMAPI
documentation

=head1 BUGS

=over 4

=item *

Reorder the methods placing the user-serviceable ones first.

=item *

Move C<WWW::Domain::Registry::Loggish> to a separate distribution?

=item *

Better error handling; exceptions?  Error.pm?  Something completely
different?  Croak?

=item *

Croak instead of die here and there.

=back

=head1 HISTORY

The C<WWW::Domain::Registry::Joker> class was written by Peter Pentchev
in 2007.

=head1 AUTHOR

Peter Pentchev, E<lt>roam@ringlet.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 - 2009 by Peter Pentchev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
