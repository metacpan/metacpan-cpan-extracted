use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }
package Test::Reporter::Transport::Legacy;
our $VERSION = '1.59'; # VERSION

1;

# ABSTRACT: Legacy Test::Reporter::Transport modules


# vim: ts=2 sts=2 sw=2 et:

__END__
=pod

=head1 NAME

Test::Reporter::Transport::Legacy - Legacy Test::Reporter::Transport modules

=head1 VERSION

version 1.59

=head1 DESCRIPTION

This distribution contains legacy L<Test::Reporter> transport modules from
when the CPAN Testers project still accepted test report from email.  As
email submission has been discontinued, these module have been split out
from the main Test::Reporter distribution.

They are available for historical record and are not needed for CPAN Testers.
They are provided on CPAN in case someone has built a custom testing solution
using Test::Reporter and these modules and still needs them.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-reporter-transport-legacy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Test-Reporter-Transport-Legacy>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<http://github.com/dagolden/test-reporter-transport-legacy>

  git clone http://github.com/dagolden/test-reporter-transport-legacy

=head1 AUTHORS

=over 4

=item *

Adam J. Foxson <afoxson@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Kirrily "Skud" Robert <skud@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Richard Soderberg <rsod@cpan.org>

=item *

Kurt Starsinic <Kurt.Starsinic@isinet.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Authors and Contributors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

