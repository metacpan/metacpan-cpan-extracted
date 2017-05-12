package XML::SAX::Tap;
{
  $XML::SAX::Tap::VERSION = '0.46';
}
# ABSTRACT: Tap a pipeline of SAX processors


use base qw( XML::SAX::Machine );


use strict;
use Carp;


sub new {
    my $proto = shift;
    my $options = @_ && ref $_[-1] eq "HASH" ? pop : {};

    my $stage_number = 0;
    my @machine_spec = (
        [ "Intake", "XML::Filter::Tee"  ],
        map( [ "Stage_" . $stage_number++, $_ ], @_ ),
    );

    push @{$machine_spec[$_]}, "Stage_" . $_
        for 0..$#machine_spec-1 ;

    ## Pushing this last means that the Exhaust will get
    ## events after Stage_0
    push @{$machine_spec[0]}, "Exhaust";

    return $proto->SUPER::new( @machine_spec, $options );
}



1;

__END__

=pod

=head1 NAME

XML::SAX::Tap - Tap a pipeline of SAX processors

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    use XML::SAX::Machines qw( Pipeline Tap ) ;

    my $m = Pipeline(
        "UpstreamFilter",
        Tap( "My::Reformatter", \*STDERR ),
        "DownstreamFilter",
    );

    my $m = Pipeline(
        "UpstreamFilter",
        Tap( "| xmllint --format -" ),
        "DownstreamFilter",
    );

=head1 DESCRIPTION

XML::SAX::Tap is a SAX machine that passes each event it receives on to
a brach handler and then on down to it's main handler.  This allows
debugging output, logging output, validators, and other processors (and
machines, of course) to be placed in a pipeline.  This differs from
L<XML::Filter::Tee>, L<XML::Filter::SAXT> and L<XML::SAX::Distributer>
in that a tap is also a pipeline; it contains the processoring that
handles the tap.

It's like L<XML::Filter::Tee> in that the events are not buffered; each
event is sent first to the tap, and then to the branch (this is
different from XML::SAX::Dispatcher, which buffers the events).

It's like XML::SAX::Pipeline in that it contains a series of processors
in a pipeline; these comprise the "tapping" processors:

            +----------------------------------------------+
            |                  Tap instance                |
            |                                              |
            |  Intake                                      |
            |  +-----+    +---------+        +---------+   |
 upstream --+->| Tee |--->| Stage_0 |--...-->| Stage_N |   |
            |  +-----+    +---------+        +---------+   |
            |         \                                    |
            |          \                          Exhaust  |
            |           +----------------------------------+--> downstream
            |                                              |
            +----------------------------------------------+

The events are not copied, since they may be data structures that are
difficult or impossibly to copy properly, like parts of a C-based DOM
implementation.

Events go to the tap first so that you can validate events using a tap
that throws exceptions and they will be acted on before the tap's
handler sees them.

This machine has no C<Exhaust> port (see L<XML::SAX::Machine> for
details about C<Intake> and C<Exhaust> ports).

=head1 NAME

XML::SAX::Tap - Tap a pipeline of SAX processors

=head1 METHODS

=over

=item new

    my $tap = XML::SAX::Tap->new( @tap_processors, \%options );

=back

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

    Copyright 2002, Barrie Slaymaker, All Rights Reserved

You may use this module under the terms of the Artistic, GNU Public, or
BSD licenses, as you choose.

=head1 AUTHORS

=over 4

=item *

Barry Slaymaker

=item *

Chris Prather <chris@prather.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Barry Slaymaker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
