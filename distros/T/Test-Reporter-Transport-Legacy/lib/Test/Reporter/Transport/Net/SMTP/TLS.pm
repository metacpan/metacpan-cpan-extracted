use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }
package Test::Reporter::Transport::Net::SMTP::TLS;
our $VERSION = '1.59'; # VERSION

use Test::Reporter::Transport::Net::SMTP;
our @ISA = qw/Test::Reporter::Transport::Net::SMTP/;

use Net::SMTP::TLS;

1;

# ABSTRACT: Authenticated SMTP transport for Test::Reporter



=pod

=head1 NAME

Test::Reporter::Transport::Net::SMTP::TLS - Authenticated SMTP transport for Test::Reporter

=head1 VERSION

version 1.59

=head1 SYNOPSIS

    my $report = Test::Reporter->new(
        transport => 'Net::SMTP::TLS',
        transport_args => [ User => 'Joe', Password => '123' ],
    );

=head1 DESCRIPTION

This module transmits a Test::Reporter report using Net::SMTP::TLS.

=head1 USAGE

See L<Test::Reporter> and L<Test::Reporter::Transport> for general usage
information.

=head2 Transport Arguments

    $report->transport_args( @args );

Any transport arguments are passed through to the Net::SMTP::TLS constructer.

=head1 METHODS

These methods are only for internal use by Test::Reporter.

=head2 new

    my $sender = Test::Reporter::Transport::Net::SMTP::TLS->new( 
        @args 
    );

The C<new> method is the object constructor.   

=head2 send

    $sender->send( $report );

The C<send> method transmits the report.  

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


__END__


