package Anticaptcha;

$VERSION = "1.02";
sub Version { $VERSION; }

require 5.010;
require Anticaptcha::Request;

1;

__END__

=encoding utf-8

=head1 NAME

Anticaptcha - A Perl implementation of the anti-captcha API

=head1 SYNOPSIS

  use Anticaptcha;
  print "This is Anticaptcha-$Anticaptcha::VERSION\n";

=head1 DESCRIPTION

The Anticaptcha is a Perl module which provides a simple and consistent
application programming interface (API) to the anti-captcha.com service.

The main features of the library are:

=over 3

=item *

Support API version 2 (https://anticaptcha.atlassian.net/wiki/display/API/API+v.2+Documentation).

=back

=head1 EXAMPLE

  # Create a anticaptcha object
  use Anticaptcha;
  my $Anticaptcha = Anticaptcha::Request->new(
    clientKey => '123abc123abc123abc112abc123abc123',
    responce => 'json'
  );

  # Get account balance in JSON format
  my $balance_json = $Anticaptcha->getBalance();
  print $balance_json,"\n";

See L<Anticaptcha::Request> for more documentation and examples.

=head1 COPYRIGHT

  Copyright 2016, Alexander Mironov

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
