package Test::Net::Connect;

# Copyright (c) 2005 Nik Clayton
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

use warnings;
use strict;

use Test::Builder;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(connect_ok connect_not_ok);

my $Test = Test::Builder->new;

use Net::hostent;
use Socket;
use IO::Socket::INET;

my @FIELDS = qw(host port proto);
my %FIELDS = map { $_ => 1 } @FIELDS;

sub import {
  my($self) = shift;
  my $pack = caller;

  $Test->exported_to($pack);
  $Test->plan(@_);

  $self->export_to_level(1, $self, qw(connect_ok connect_not_ok));
}

=head1 NAME

Test::Net::Connect - Test::Builder based tests for network connectivity

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Test::Net::Connect tests => 3;

    connect_ok({ host => 'smtp.example.com', port => 25,
                 proto => 'tcp' }, 'Check tcp://smtp.example.com:25');

    # proto defaults to 'tcp', the test name can be omitted, and the
    # port can be appended to the host name
    connect_ok({ host => 'smtp.example.com:25' });

    connect_not_ok({ host => 'localhost:23' },
                   'Telnet connections should not be accepted locally');

Test::Net::Connect B<automatically> exports C<connect_ok()> and
C<connect_not_ok()> to make it easier to test whether or not a network
connection can be made from this host to a port on another host using
TCP or UDP.

Test::Net::Connect uses Test::Builder, so plays nicely with Test::Simple,
Test::More, and other Test::Builder based modules.

=head1 FUNCTIONS

=head2 connect_ok($spec, [ $test_name ]);

connect_ok() tests that a connection to a host, given in C<$spec>, can
be made.

The specification is a hashref that contains one or more keys.  Valid
keys are C<host>, C<port>, and C<proto>.  Each value associated with
the key is the value that entry is supposed to have.

=over 4

=item host

Specifies the hostname or IP address to connect to.  If a hostname is
given then the A records for that host will be retrieved and connections
will be made to B<all> the A records in turn.  If any of them fail then
the test fails.

C<host> is mandatory.

=item port

Specifies the port to connect to.  The port may also be specified by
appending a colon C<:> and the port number to the C<host> value.  If
this is done then C<port> is optional, otherwise C<port> is mandatory.

=item proto

The protocol to use.  C<tcp> and C<udp> are the only valid values.  This
key is optional, and defaults to C<tcp> if it is not specified.

=back

The C<$test_name> is optional.  If it is not present then a sensible one
is generated following the form

    Connecting to $proto://$host:$port

=cut

sub connect_ok {
  my($spec, $test_name) = @_;
  return unless _check_spec($spec, $test_name);

  $test_name = _gen_default_test_name($spec) unless defined $test_name;

  return unless _dns_lookup($spec, $test_name);

  my @diag = ();

  foreach my $address (@{$spec->{_addresses}}) {
    my $sock = IO::Socket::INET->new(PeerAddr => $address,
				     PeerPort => $spec->{port},
				     Proto    => $spec->{proto},
				     Timeout  => 5,
				     Type     => SOCK_STREAM);

    if(! defined $sock) {
      push @diag, "    Connection to $spec->{proto}://$address:$spec->{port} failed: $!";
    } else {
      close $sock;
    }
  }

  delete $spec->{_addresses};

  if(@diag) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag(@diag);
    return $ok;
  }

  return $Test->ok(1, $test_name);
}

=head2 connect_not_ok($spec, [ $test_name ]);

connect_not_ok() tests that a connection to a host, given in $spec, can
not be made.

The arguments are handled in the same manner as for connect_ok().

B<NOTE:> connect_not_ok() will fail (C<not ok>) if the given host is not
in the DNS.
DNS.

=cut

sub connect_not_ok {
  my($spec, $test_name) = @_;
  return unless _check_spec($spec, $test_name);

  $test_name = _gen_default_test_name($spec) unless defined $test_name;

  return unless _dns_lookup($spec, $test_name);

  my @diag = ();

  foreach my $address (@{$spec->{_addresses}}) {
    my $sock = IO::Socket::INET->new(PeerAddr => $address,
				     PeerPort => $spec->{port},
				     Proto    => $spec->{proto},
				     Timeout  => 5,
				     Type     => SOCK_STREAM);

    if(defined $sock) {
      push @diag, "    Connection to $spec->{proto}://$address:$spec->{port} succeeded";
      close($sock);
    }
  }

  delete $spec->{_addresses};

  if(@diag) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag(@diag);
    return $ok;
  }

  return $Test->ok(1, $test_name);
}

sub _check_spec {
  my($spec, $test_name) = @_;
  my $sub = (caller(1))[3];

  $sub =~ s/Test::Net::Connect:://;

  if(! defined $spec) {
    my $ok = $Test->ok(0, "$sub()");
    $Test->diag("    $sub() called with no arguments");
    return $ok;
  }

  if(ref($spec) ne 'HASH') {
    $test_name = defined $test_name ? $test_name : "$sub()";
    my $ok = $Test->ok(0, $test_name);
    $Test->diag("    First argument to $sub() must be a hash ref");
    return $ok;
  }

  if(! exists $spec->{host} or ! defined $spec->{host}
     or $spec->{host} =~ /^\s*$/) {
    $test_name = defined $test_name ? $test_name : "$sub()";
    my $ok = $Test->ok(0, $test_name);
    $Test->diag("    $sub() called with no hostname");
    return $ok;
  }

  $spec->{proto} ||= 'tcp';

  if($spec->{host} =~ /:/) {
    ($spec->{host}, $spec->{port}) = $spec->{host} =~ /([^:]+):(.*)/;
  }

  if(! defined $spec->{port} or $spec->{port} =~ /^\s*$/) {
    $test_name = defined $test_name ? $test_name : "$sub()";
    my $ok = $Test->ok(0, $test_name);
    $Test->diag("    $sub() called with no port");
    return $ok;
  }

  if(! defined $test_name) {
    $test_name = "Connecting to $spec->{proto}://$spec->{host}:$spec->{port}";
  }

  my @diag = ();

  foreach my $field (keys %$spec) {
    if(! exists $FIELDS{$field}) {
      push @diag, "    Invalid field '$field' given";
    }
  }

  if(@diag) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag(@diag);
    return $ok;
  }

  return 1;
}

sub _dns_lookup {
  my($spec, $test_name) = @_;

  $spec->{_addresses} = [];

  # If we've been handed a single IP address use that.  Otherwise,
  # look up all the IP addresses for the host
  if($spec->{host} =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
    push @{$spec->{_addresses}}, $spec->{host};
  } else {
    my $h = gethostbyname($spec->{host});

    if($h) {
      push @{$spec->{_addresses}}, map { inet_ntoa($_) } @{$h->addr_list()};
    } else {
      my $ok = $Test->ok(0, $test_name);
      $Test->diag("    DNS lookup for '$spec->{host}' failed");
      return $ok;
    }
  }

  return 1;
}

sub _gen_default_test_name {
  my $spec = shift;

  return "Connecting to $spec->{proto}://$spec->{host}:$spec->{port}";
}

=head1 EXAMPLES

Verify that port 25 can be reached on all the A records for
C<smtp.example.com>.

    connect_ok({ host => 'smtp.example.com', port => 25, 
                 proto => 'tcp' }, "Checking mail to smtp.example.com");

Do the same thing, but shorter.

    connect_ok({ host => 'smtp.example.com:25' });

Verify that the local SSH daemon is responding.

    connect_ok({ host => '127.0.0.1:22' });

Verify that the host www.example.com is not running a server on port 80.

    connect_not_ok({ host => 'www.example.com:80' });

=head1 SEE ALSO

Test::Simple, Test::Builder, IO::Socket::INET.

=head1 AUTHOR

Nik Clayton, nik@FreeBSD.org

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-net-connect@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Net-Connect>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005 Nik Clayton
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

=cut

1; # End of Test::Net::Connect
