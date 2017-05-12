package WWW::Domain::Registry::Joker::Response;

use 5.006;
use strict;
use warnings;

use WWW::Domain::Registry::Joker::Loggish;

our @ISA = qw(WWW::Domain::Registry::Joker::Loggish);

our $VERSION = '0.04';

=head1 NAME

WWW::Domain::Registry::Joker::Response - parse a DMAPI response

=head1 SYNOPSIS

  use WWW::Domain::Registry::Joker::Response;

  $r = new WWW::Domain::Registry::Joker::Response();
  $r->parse($resp);
  print "$r->{Proc-Id}: $r->{'Status-Code'} $r->{Status-Text}\n";

=head1 DESCRIPTION

The C<WWW::Domain::Registry::Joker::Response> class is a helper parser
for the HTTP responses returned by the Joker.com DMAPI.  It examines
a response object, extracts the status and error flags, codes, and
descriptive messages, and makes them available as Perl object members.

=head1 METHODS

The C<WWW::Domain::Registry::Joker::Response> class defines the
following methods:

=over 4

=item new ()

Initialize a C<WWW::Domain::Registry::Joker::Response> object.
No user-serviceable parameters inside.

=cut

sub new($ %)
{
	my ($proto, %param) = @_;
	my $self;

	$self = WWW::Domain::Registry::Joker::Loggish::new($proto,
		'code'		=> 1337,
		'msg'		=> '(no status text)',
		'status'	=> '(no status line)',
		'success'	=> 0,
		%param,
	);
	return $self;
}

=item parse ( RESPONSE )

Parse a C<HTTP::Response> from the DMAPI and store the result code,
message, error, etc. into the respective fields of the object.
In addition to the C<code>, C<msg>, C<status>, and C<success> members
described above, the C<parse()> method may also set the C<Version>,
C<Proc-Id>, C<Status-Text>, C<Status-Code>, C<Error>, and any other
result description members as listed in the DMAPI specification.

=cut

sub parse($ $)
{
	my ($self, $resp) = @_;
	my ($in_data, $var, $val);
	my (@r, @data);

	die("No response object passed to ".ref($self)."->parse()\n")
	    unless defined($resp);
	$self->debug("parsing a response - '".ref($resp)."'");
	if (index(ref($resp), '::') == -1 || !$resp->isa('HTTP::Response')) {
		die("Not a HTTP response object in ".ref($self)."->parse()\n");
	}

	$self->{'success'} = $resp->is_success();
	$self->{'status'} = $resp->status_line();
	undef $self->{'Status-Code'};
	undef $self->{'Status-Text'};
	@r = split("\n", $resp->content());
	$self->debug(scalar(@r)." content lines");
	foreach (@r) {
		s/[\r\n]+$//;
		if ($in_data) {
			$self->debug("- data line $_");
			push @data, $_;
			next;
		}
		$self->debug("- line $_");
		if ($_ eq '') {
			$self->debug("- - end of header");
			$in_data = 1;
			next;
		} elsif (!/^([\w-]+):\s+(.*)$/) {
			$self->debug("- - bad format!");
			next;
		}
		($var, $val) = ($1, $2);
		if (defined($self->{$var})) {
			$self->{$var} .= " / $val";
		} else {
			$self->{$var} = $val;
		}
	}
	$self->{'data'} = [ @data ];
	if (defined($self->{'Status-Code'})) {
		$self->{'code'} = $self->{'Status-Code'};
	} else {
		$self->{'code'} = 1337;
	}
	if (defined($self->{'Status-Text'})) {
		$self->{'msg'} = $self->{'Status-Text'};
	} else {
		$self->{'msg'} = '(no status text)';
	}
	$self->debug("=== DMAPI response: is_success $self->{success} ".
	    "status line '$self->{status}', status code: $self->{code}, ".
	    "status text: '$self->{msg}', ".
	    "data lines ".scalar(@{$self->{'data'}})."\n");
	return 1;
}

=back

=head1 EXAMPLES

Create an object and parse an HTTP response:

  $r = new WWW::Domain::Registry::Joker::Response();
  eval {
  	$r->parse($resp);
  };
  if ($@) {
  	print STDERR "Could not parse the DMAPI response: $@\n";
  } elsif (!$r->{'success'}) {
  	print STDERR "DMAPI error: code $r->{code}, text $r->{msg}\n";
  	print STDERR "DMAPI error message: $r->{Error}\n"
  	    if $r->{'Error'};
  } else {
  	print "Successful DMAPI request: $r->{code} $r->{msg}\n";
  	print "Tracking process ID: $r->{Proc-ID}\n" if $r->{'Proc-ID'};
  }

=head1 ERRORS

The C<parse()> method will die on invalid input:

=over 4

=item *

no response parameter passed in;

=item *

the response parameter was not an C<HTTP::Response> or compatible object.

=back

If the response object is a valid DMAPI response, its C<success>, C<code>,
C<msg>, C<Error>, and other attributes are exposed as members of
the C<WWW::Domain::Registry::Joker::Response> object as shown above.

=head1 SEE ALSO

L<WWW::Domain::Registry::Joker>, L<HTTP::Response>

I<https://joker.com/faq/category/39/22-dmapi.html> - the Joker.com DMAPI
documentation

=head1 BUGS

None known so far ;)

=head1 HISTORY

The C<WWW::Domain::Registry::Joker::Response> class was written by
Peter Pentchev in 2007.

=head1 AUTHOR

Peter Pentchev, E<lt>roam@ringlet.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Peter Pentchev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
