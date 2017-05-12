package Test::Mail;

use warnings;
use strict;

use Carp;
use Mail::Header;

require Exporter;

=head1 NAME

Test::Mail - Test framework for email applications

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS


    use Test::Mail
    my $tm = Test::Mail->new( logfile => $logfile );
    $tm->accept();
    sub first_test { }
    sub second_test { }
    ...

=head1 DESCRIPTION

Test::Mail provides a framework for testing applications which send and
receive email.

A typical example of an email application might send a notification to a
certain email address, setting certain headers in certain ways and
having certain content in the body of the email.  It would be nice to be
able to test these things automatically, however most email applications
are currently tested by visual inspection of the email received.

Test::Mail allows you to automate the testing of email applications by
piping any relevant email through a Test::Mail script.

"Relevant" email is identified by the presence of an X-Test-Mail:
header.  You should set this email in your application or whatever you
use to generate the mail.

    X-Test-Mail: birthday_notification

The value of that header is the name of a subroutine which
exists in your Test::Mail script.  The subroutine contains Test::More
tests to run on the email:

    sub birthday_notification {
        is($header->get("From:"), 'birthdays@example.com', "From address check");
        like($body, qr/Today's Birthdays/, "Email body check");
    }

This allows you to have tests for multiple different kinds of email in
one script.

Note that $header and $body are set by Test::Mail for your convenience.
$header is a Mail::Header object.  $body is the body of the email as a
single string.  MIME attachments etc are not supported (yet).

The results of the tests run are output to the logfile you specify, and
look something like this:

    # test results for birthday_notification for <msgid1234@example.com>
    ok 1 - From address check
    ok 2 - Email body check

    # test results for support_request for <msgid5678@example.com>
    ok 1 - To address check
    not ok 2 - Subject line
    not ok 3 - Included ticket number
    ok 4 - Body contains plain text

Note that while these are roughly similar to normal CPAN test output
conventions, counting only occurs on a per-email basis

=head2 Sending incoming mail to Test::Mail

To call Test::Mail, simply put a suitable filter in your .procmailrc,
Mail::Audit script, or whatever you use to filter your email.  Here's
how I'd do it with Mail::Audit:

    if ($mail->{obj}->head->get("X-Test-Mail")) {
        $mail->pipe("testmail.pl");
    }

If for some reason you want to test mail that doesn't already have an
X-Test-Mail: header, you could do something like:

    if ($mail->{subject} =~ /test/i) {
        $mail->{obj}->head->add("X-Test-Mail", "subject_auto");
        $mail->pipe("testmail.pl");
    }

=head2 Unaddressed issues

The above is a rough outline of version 1.  There are several issues I
don't yet know how to deal with, which I'm listing here just in case
anyone has any good ideas:

=over 4

=item *

Sending output somewhere more useful than a logfile

=item *

Integrating into a real "test suite" that's friendly to Test::Harness

=item *

Handling MIME in a suitable way

=back

=head1 METHODS

=head2 new()

Constructor method.  Takes a hash of arguments.  The only current argument is
"logfile" which is the file to which test logs will be sent.

=cut

sub new {
    shift;
    my (%args) = @_;
    my $self = \%args;

    bless $self;
    return $self;
}

=head2 accept()

Accept a single email and test it.  Doesn't take any args.

This will run the email through whatever subroutine is described in the
"X-Test-Mail" header.

=cut

sub accept {
    my ($self) = @_;

    $self->{header} = new Mail::Header \*STDIN, Modify => 0, MailFrom => 'IGNORE';
    $self->{header}->unfold();          # Recombine multi-line headers

    {
        # Slurp in the message body in one fell swoop
        local $/;
        undef $/;
        $self->{body} = <STDIN>;
    }

    my $sub = $self->{header}->get("X-Test-Mail:");
    my $msgid = $self->{header}->get("Message-ID:");
    chomp ($sub, $msgid);

    open LOG, ">>$self->{logfile}"
        or croak "Can't open $self->{logfile}: $!";

    print LOG "\n# Test results for $sub for $msgid\n";
    print LOG "# ", scalar localtime, "\n";

    my ($package) = caller;

    *Test::Simple::TESTOUT = \*LOG;
    *Test::Simple::TESTERR = \*LOG;
    *Test::More::TESTERR   = \*LOG;
    eval qq(
        package $package; 
        use Test::More 'no_plan';
        &${package}::$sub;
    );
}

=head2 header()

Convenience accessor method for the header of the email. Returns a Mail::Header
object.

=cut

sub header {
    my ($self) = @_;
    return $self->{header};
}

=head2 body()

Convenience accessor method for the body of the email.  Returns a plain text
string.

=cut

sub body {
    my ($self) = @_;
    return $self->{body};
}

return 1;

=head1 AUTHOR

Kirrily Robert, C<< <skud at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-mail at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mail>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Mail

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Mail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Mail>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Mail>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Mail>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Kirrily Robert, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Test::Mail
