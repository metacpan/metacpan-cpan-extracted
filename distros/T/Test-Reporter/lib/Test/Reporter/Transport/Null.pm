use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }
package Test::Reporter::Transport::Null;

our $VERSION = '1.62';

use base 'Test::Reporter::Transport';

sub new {
  return bless {}, shift;
}

sub send {
  return 1; # do nothing
}

1;

# ABSTRACT: Null transport for Test::Reporter

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Reporter::Transport::Null - Null transport for Test::Reporter

=head1 VERSION

version 1.62

=head1 SYNOPSIS

    my $report = Test::Reporter->new(
        transport => 'Null',
    );

=head1 DESCRIPTION

This module provides a "null" transport option that does nothing when
C<send()> is called.

=head1 USAGE

See L<Test::Reporter> and L<Test::Reporter::Transport> for general usage
information.

=for Pod::Coverage new send

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

This software is copyright (c) 2015 by Authors and Contributors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
