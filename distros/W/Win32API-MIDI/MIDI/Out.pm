#!/usr/local/bin/perl
#
#	Out.pm : utility functions for Win32API::MIDI::Out
#
#	Copyright (c) 2003 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

package Win32API::MIDI::Out;
my $ver = '$Id: Out.pm,v 1.1 2003-03-29 17:37:42-05 hiroo Exp $';

=head1 NAME

Win32API::MIDI::Out - Utility Functions for Win32API::MIDI::Out

=head1 DESCRIPTION

Most of feature of Win32API::MIDI::Out are documented in
Win32API::MIDI.  Some utility functions are documented here.

=cut

use Carp;
use strict;

use Exporter ();
use vars qw($VERSION);
$VERSION = $ver =~ m/\s+(\d+\.\d+)\s+/;

=over 4

=item C<$midiOut-E<gt>SysEX(System_Exclusive_Data)>

Outputs MIDI System Exclusive data.

  Example:
	# Turn General MIDI System On
	$midiout->SysEX("\xf0\x7e\x7f\x09\x01\xf7");

=back

=cut

sub Win32API::MIDI::Out::SysEX {
    my ($self, $m) = @_;
    # struct midiHdr
    my $midiHdr = pack ("PL4PL6",
			$m,	# lpData
			length $m, # dwBufferLength
			0, 0, 0, undef, 0, 0);
    # make a pointer to struct midiHdr
    # cf. perlpacktut in Perl 5.8.0 or later (http://www.perldoc.com/)
    my $lpMidiOutHdr = unpack('L!', pack('P',$midiHdr));
    my $r;
    $r = $self->PrepareHeader($lpMidiOutHdr);
    unless ($r) {
	carp "PrepareHeader: ", $self->GetErrorText();
	return $r;
    }
    $r = $self->LongMsg($lpMidiOutHdr);
    unless ($r) {
	carp "LongMsg: ", $self->GetErrorText();
	return $r;
    }
    $r = $self->UnprepareHeader($lpMidiOutHdr);
    unless ($r) {
	carp "UnprepareHeader: ", $self->GetErrorText();
	return $r;
    }
}

=head1 AUTHOR

Hiroo Hayashi, E<lt>hiroo.hayashi@computer.orgE<gt>

=head1 SEE ALSO

=over 4

=item Win32API::MIDI

=item Win32API::MIDI::SysEX

=back

=head1 BUGS

If you find bugs, report to the author.

=cut

1;
