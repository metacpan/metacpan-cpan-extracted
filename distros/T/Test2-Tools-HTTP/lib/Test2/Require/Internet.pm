package Test2::Require::Internet;

use strict;
use warnings;
use 5.014;
use IO::Socket::INET;
use parent qw( Test2::Require );

# ABSTRACT: Skip tests if there is no internet access
our $VERSION = '0.12'; # VERSION


sub skip
{
  my(undef, %args) = @_;
  return 'NO_NETWORK_TESTING' if $ENV{NO_NETWORK_TESTING};

  my @pairs = @{ $args{'-tcp'} || [ 'httpbin.org', 80 ] };
  while(@pairs)
  {
    my $host = shift @pairs;
    my $port = shift @pairs;

    my $sock = IO::Socket::INET->new(
      PeerAddr => $host,
      PeerPort => $port,
      Proto    => 'tcp',
    );

    return "Unable to connect to $host:$port/tcp" unless $sock;

    $sock->close;
  }

  undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Require::Internet - Skip tests if there is no internet access

=head1 VERSION

version 0.12

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Require::Internet;
 use HTTP::Tiny;
 
 # we are safe to use the internets
 ok(HTTP::Tiny->get('http://www.example.com')->{success});
 
 done_testing;

=head1 DESCRIPTION

This test requirement will skip your test if either

=over

=item The environment variable C<NO_NETWORK_TESTING> is set to a true value

=item A connection to a particular host/port cannot be made.  The default is usually reasonable, but subject to change as the author sees fit.

=back

This module uses the standard L<Test2::Require> interface.  Only TCP checks can be made at the moment.  Other protocols/methods may be added later.

=head1 SEE ALSO

=over 4

=item L<Test::RequiresInternet>

This module provides similar functionality but does not use L<Test::Builder> or L<Test2::API>.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
