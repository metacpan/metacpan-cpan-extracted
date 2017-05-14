#   xisofs v1.3 Perl/Tk Interface to mkisofs / cdwrite
#   Copyright (c) 1997 Steve Sherwood (pariah@netcomuk.co.uk)
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

package help;

use wcenter;

sub display
{
	my ($parent, $filename) = @_;
	my $text;

	my $popup = $parent->Toplevel;
	$popup->title("help ($filename)");
	$popup->configure(-background => 'grey80');

	wcenter::offset($popup,90,130);

	if (open(IN,"$main::ROOT/help/$filename"))
	{
		chomp($text = <IN>);
		close(IN);
	}
	else
	{
		$text = "$main::ROOT/$filename : $!";
	}

	my $popFrame = $popup->Frame(
		-relief => 'sunken',
		-borderwidth => 1,
		-background => 'PapayaWhip')->pack(
			-padx => 10,
			-pady => 10,
			-side => 'top',
			-fill => 'both');

	$popFrame->Label(
		-background => 'PapayaWhip',
		-text => $text,
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-pady => 5,
			-anchor => 'w',
			-side => 'top');

	$popup->Button(
		-command => sub{destroy $popup},
		-borderwidth => 1,
		-text => 'Dismiss',
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-side => 'bottom');
}

1;
