package cet;

use 5.008_005;
use strict;
use warnings FATAL => 'all';

=head1 NAME

cet - console emphasis tool

=head1 VERSION

Version 2.02

=cut

our $VERSION = '2.02';


=head1 SYNOPSIS

 cet.pl REGEX1 [COLOR1] [REGEX2 [COLOR2]] ... [REGEXn [COLORn]]


=head1 DESCRIPTION

cet.pl is a command line tool for visually emphasizing text in log files
etc. by colorizing the output matching regular expressions.


=head1 USAGE

REGEX is any regular expression recognized by Perl. For some shells
this must be enclosed in double quotes ("") to prevent the shell from
interpolating special characters like * or ?.

COLOR is any ANSI color string accepted by Term::ANSIColor, such as
'green' or 'bold red'.

Any number of REGEX-COLOR pairs may be specified. If the number of
arguments is odd (i.e. no COLOR is specified for the last REGEX) cet.pl
will use 'bold yellow'.

Overlapping rules are supported. For characters that match multiple rules,
only the last rule will be applied.


=head1 EXAMPLES

In a system log, emphasize the words "error" and "ok":

=over

tail -f /var/log/messages | cet.pl error red ok green

=back

In a mail server log, show all email addresses between <> in white,
successes in green:

=over

tail -f /var/log/maillog | cet.pl "(?<=\<)[\w\-\.]+?\@[\w\-\.]+?(?=\>)" "bold white" "stored message|delivered ok" "bold green"

=back

In a web server log, show all URIs in yellow:

=over

tail -f /var/log/httpd/access_log | cet.pl "(?<=\"get).+?\s"

=back

=head1 BUGS AND LIMITATIONS

Multi-line matching is not implemented.

All regular expressions are matched without case sensitivity.


=head1 EXPORT

Nothing. You should not attempt to use this module for anything. Perhaps
what you are really looking for is the script: B<cet>


=head1 AUTHOR

Andreas Lund, E<lt>floyd@atc.noE<gt>, C Hutchinson, E<lt>taint@cpan.orgE<gt>


=head1 MAINTAINER

C Hutchinson C<taint at cpan.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cet at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=cet>. I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc cet


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=cet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/cet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/cet>

=item * Search CPAN

L<http://search.cpan.org/dist/cet/>

=back


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT

Copyright 2009-2013 Andreas Lund
Copyright 2013 C Hutchinson

=head1 LICENSE

This program is free software;  you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; # End of cet
