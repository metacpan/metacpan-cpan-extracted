package WWW::CheckHTML;
use strict;
use warnings;
use HTTP::Tiny;
use Method::Signatures;
use Time::Piece;
use YAML::XS qw/LoadFile/;
use Carp qw/croak/;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;
use Email::Sender::Transport::SMTP;

=head1 NAME

WWW::CheckHTML - check remote website HTML and send email alert via SMTP if check fails. 

=head1 VERSION

Version 0.05

=cut

BEGIN {
    require Exporter;
    our $VERSION = 0.05;
    our @ISA     = qw(Exporter);
    our @EXPORT  = qw(checkPage);
}

=head1 SYNOPSIS

L<WWW::CheckHTML> exports a subroutine called checkPage to check remote web pages are retrievable and that they contain a specific HTML pattern. It will send an email via an SMTP server with the error found if either the page is not retrievable or the HTML pattern match fails.

    use WWW::CheckHTML;
    
    checkPage('http://www.google.com', '<title>', 'sillymoos@cpan.org', '/home/sillymoose/sendmail.yaml');

=head1 CONFIGURATION

L<WWW::CheckHTML> requires a yaml configuration file. The configuration file should have the following key / pair values:

=over

=item *

from_email - this is the sending email address from which alerts will be sent

=item *

host - this is the SMTP host address for the sending email (e.g. smtp.google.com)

=item *

username - this is the sending email account username

=item *

password - this is the sending email account password

=item *

timeout - the number of seconds to wait before terminating the HTTP request. This is the only optional parameter and defaults to 30 seconds if not provided.

=back

Example yaml configuration file

    ---
    host: smtp.google.com
    username: sillymoos
    password: itsasecret
    from_email: sillymoos@gmail.com
    timeout: 20

=head1 SUBROUTINES

=head2 checkPage

Requires a url, regex pattern, an email address and optionally a path to a yaml configuration file. If the yaml filepath is not provided the checkPage method will search for 'sendmail.yaml' in the current directory context. checkPage initiates an HTTP get request for the url and if successful, will try to match the HTML regex pattern against the retrieved HTML. If either check fails, it will send an alert email to the email address provided.

=cut

my $CONFIG;

func checkPage( $url, $htmlPattern, $emailAddress, $yamlConfigPath? = 'sendmail.yaml') {

    # read sendmail.yaml
    $CONFIG =
      -e $yamlConfigPath
    ? LoadFile($yamlConfigPath)
    : croak "Error no sendmail.yaml not found $!";

      unless ( $CONFIG->{username}
        and $CONFIG->{password}
        and $CONFIG->{host} )
    {
        croak "Missing mandatory values in sendmail.yaml $!";
    }
    my $timeout = $CONFIG->{timeout} || 30;
    my $response = HTTP::Tiny->new(timeout => $timeout)->get($url);
      my $t        = localtime;
      my $datetime = $t->strftime;
      unless ( $response->{success} ) {
        _sendEmail(
            $emailAddress,
            'CheckHTML error',
"Error retrieving $url at $datetime. HTTP response: $response->{reason}\n",
        );
        return 0;
    }
    unless ( $response->{content} =~ /$htmlPattern/ ) {
        _sendEmail(
            $emailAddress,
            'CheckHTML error',
            "Error $url retrieved but HTML pattern not found at $datetime\n",
        );
        return 0;
    }
    return 1;
  }

  func _sendEmail( $emailAddress, $subject, $body ) {
    my $email = Email::Simple->create(
        header => [
            To      => $emailAddress,
            From    => 'alerts.checkhtml@gmail.com',
            Subject => $subject,
        ],
        body => $body,
    );

      my $transport = Email::Sender::Transport::SMTP->new(
        {
            host          => $CONFIG->{host},
            ssl           => 1,
            sasl_username => $CONFIG->{username},
            sasl_password => $CONFIG->{password},
        }
      );
      sendmail( $email, { transport => $transport } );
  }

  1;

=head1 AUTHOR

David Farrell, C<< <sillymoos at cpan.org> >>, L<perltricks.com|http://perltricks.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-checkhtml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-CheckHTML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::CheckHTML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-CheckHTML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-CheckHTML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-CheckHTML>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-CheckHTML/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Farrell.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of WWW::CheckHTML
