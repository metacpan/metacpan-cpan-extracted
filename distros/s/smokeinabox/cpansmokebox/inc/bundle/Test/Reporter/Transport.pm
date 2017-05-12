# 
# This file is part of Test-Reporter
# 
# This software is copyright (c) 2010 by Authors and Contributors.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }
package Test::Reporter::Transport;
our $VERSION = '1.57';
# ABSTRACT: base class for Test::Reporter transports

sub new     { die "Not implemented" }

sub send    { die "Not implemented" }

1;



=pod

=head1 NAME

Test::Reporter::Transport - base class for Test::Reporter transports

=head1 VERSION

version 1.57

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

    # use Test::Reporter::Transport::Net::SMTP for transport
    my $report = Test::Reporter->new(
        transport => 'Net::SMTP'
    );

    # use Test::Reporter::Transport::Mail::Send for transport
    my $report = Test::Reporter->new(
        transport => 'Mail::Send'
    );

Configuration of the transport is specified with the C<transport_args>
option:

    my $report = Test::Reporter->new(
        transport => 'Net::SMTP::TLS',
        transport_args => [ User => 'John', Password => '123' ],
    );

These may also be specified with the C<transport> or C<transport_args> methods:

    $report->transport_args( User => 'John', Password => '123' );

These may also be combined in the C<transport> method itself:

    $report->transport( 'Net::SMTP::TLS', User => 'John', Password => '123');

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

  Adam J. Foxson <afoxson@pobox.com>
  David Golden <dagolden@cpan.org>
  Kirrily "Skud" Robert <skud@cpan.org>
  Ricardo Signes <rjbs@cpan.org>
  Richard Soderberg <rsod@cpan.org>
  Kurt Starsinic <Kurt.Starsinic@isinet.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Authors and Contributors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


