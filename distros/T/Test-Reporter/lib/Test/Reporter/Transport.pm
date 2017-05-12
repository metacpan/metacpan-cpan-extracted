use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }
package Test::Reporter::Transport;

our $VERSION = '1.62';

sub new     { die "Not implemented" }

sub send    { die "Not implemented" }

1;

# ABSTRACT: base class for Test::Reporter transports

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Reporter::Transport - base class for Test::Reporter transports

=head1 VERSION

version 1.62

=head1 SYNOPSIS

    # Defines API that must be implemented by subclasses

    my $sender = Test::Reporter::Transport::Subclass->new( @args );

    $sender->send( $report )

=head1 DESCRIPTION

Transport subclasses provide the means by which CPAN Testers reports are 
transmitted to the CPAN Testers mailing list.

This module is an abstract base class that define an API for
Test::Reporter::Transport subclasses.  Individual subclasses MUST 
implement the methods described below.

=head1 USAGE

A transport method is specified to Test::Reporter using the C<transport>
option.  The C<transport> option expects just the module "suffix" that follows
C<Test::Reporter::Transport>.  For example:

    # use Test::Reporter::Transport::Null for transport
    my $report = Test::Reporter->new(
        transport => 'Null'
    );

Configuration of the transport is specified with the C<transport_args>
option:

    my $report = Test::Reporter->new(
        transport => 'File',
        transport_args => [ dir => '/tmp' ],
    );

These may also be specified with the C<transport> or C<transport_args> methods:

    $report->transport_args( dir => '/tmp' );

These may also be combined in the C<transport> method itself:

    $report->transport( 'File', dir => '/tmp' );

=head1 METHODS

The terms 'may', 'must', 'should', etc. used below have their usual RFC
meanings.

=head2 new

    my $sender = $subclass->new( @args );

The C<new> method is the object constructor.  It MAY take a list of any
necessary configuration options.  It MUST return a transport object if one
is successfully created or undef if the object can not be created. 

=head2 send

    $sender->send( $report );

The C<send> method MUST take a Test::Reporter object as its only argument.  It
MUST return true if the report is successfully sent.  It SHOULD die with a
message describing the failure if a report cannot be sent.  It MUST NOT return
a true value if the report cannot be sent.

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
