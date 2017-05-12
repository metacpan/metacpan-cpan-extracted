#
# This file is part of WWW-DaysOfWonder-Memoir44
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package WWW::DaysOfWonder::Memoir44::Types;
# ABSTRACT: various types used in the distribution
$WWW::DaysOfWonder::Memoir44::Types::VERSION = '3.000';
use Moose::Util::TypeConstraints;

enum Board  => [ qw{ beach country winter desert } ];
enum Format => [ qw{ standard brkthru overlord } ];
enum Source => [ qw{ game approved classified public } ];

subtype 'Int_0_3',
    as 'Int',
    where   { $_>=0 && $_<=3 },
    message { "Integer should be between 0 and 3\n" };

coerce 'Int_0_3',
    from 'Int',
    via { 0+$_ };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DaysOfWonder::Memoir44::Types - various types used in the distribution

=head1 VERSION

version 3.000

=head1 DESCRIPTION

This module defines and exports the types used by other modules of the
distribution.

The exported types are:

=over 4

=item Board - the scenario board. Can be one of C<beach>, C<country>,
C<winter> or C<desert>.

=item Format - the scenario format. Can be one of C<standard>,
C<brkthru> or C<overlord>.

=item Int_0_3 - an integer with value 0, 1, 2 or 3.

=item Source - the scenario source. Can be one of C<game> (shipped with
the board game itself), C<classified> (printed by days of wonders),
C<approved> (officially approved by days of wonder) and C<public>
(provided by other users).

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
