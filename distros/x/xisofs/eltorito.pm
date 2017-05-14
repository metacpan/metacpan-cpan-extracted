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

package eltorito;

use wcenter;

sub display
{
	my ($parent) = @_;
	my $text;

	$parent->Busy;
	my $popup = $parent->Toplevel;
	$popup->title("El Torito Bootable CD Options");
	$popup->configure(-background => 'grey80');

	wcenter::offset($popup,114,178);

	$popup->Label(
		-font => '-adobe-times-*-*-*-*-18-*-*-*-*-*-*-*',
		-background => 'grey80',
		-foreground => 'red4',
		-text => 'El Torito Bootable CD Options',
		-wraplength => '5.0i')->pack(
			-padx => 5,
			-pady => 5,
			-side => 'top');

	my $outerFrame = $popup->Frame(
		-relief => 'flat',
		-borderwidth => 0,
		-background => 'grey80')->pack(
			-padx => 10,
			-pady => 10,
			-side => 'top',
			-expand => 'yes',
			-fill => 'both');

	my $popFrame = $outerFrame->Frame(
		-relief => 'sunken',
		-borderwidth => 1,
		-background => 'grey70')->pack(
			-side => 'top',
			-expand => 'yes',
			-fill => 'both');

	# The boot image
	my $bootFrame = $popFrame->Frame(
		-background => 'grey70')->pack(
			-side => 'top',
			-fill => 'x');

	my $bootLabel = $bootFrame->Label(
		-text => 'Boot Image',
		-background => 'grey70')->pack(
			-padx => 5,
			-side => 'left');

	$bootLabel->bind('<Button-3>' =>
	sub {
		help::display($parent, 'help23');
	});

	my $bootEntry = $bootFrame->Entry(
		-relief => 'sunken',
		-borderwidth => 2,
		-width => 40,
		-highlightthickness => 0,
		-background => 'PapayaWhip')->pack(
			-padx => 5,
			-pady => 2,
			-side => 'right');

	$bootEntry->bind('<Button-3>' =>
	sub {
		help::display($parent, 'help23');
	});

	# The boot catalog
	my $catalogFrame = $popFrame->Frame(
		-background => 'grey70')->pack(
			-side => 'top',
			-fill => 'x');

	my $catalogLabel = $catalogFrame->Label(
		-text => 'Boot Catalog',
		-background => 'grey70')->pack(
			-padx => 5,
			-side => 'left');

	$catalogLabel->bind('<Button-3>' =>
	sub {
		help::display($parent, 'help24');
	});

	my $catalogEntry = $catalogFrame->Entry(
		-relief => 'sunken',
		-borderwidth => 2,
		-width => 40,
		-highlightthickness => 0,
		-background => 'PapayaWhip')->pack(
			-padx => 5,
			-pady => 2,
			-side => 'right');

	$catalogEntry->bind('<Button-3>' =>
	sub {
		help::display($parent, 'help24');
	});

		
	$popup->Button(
		-command => sub{
			apply_changes($bootEntry, $catalogEntry);
			destroy $popup
		},
		-borderwidth => 1,
		-text => 'Ok',
		-background => 'grey80',
		-activebackground => 'grey80',
		-highlightthickness => 0)->pack(
			-pady => 5,
			-side => 'bottom');

	$bootEntry->insert('end',$main::dataField{'bootimage'});
	$catalogEntry->insert('end',$main::dataField{'bootcatalog'});
	$parent->Unbusy;
}

sub apply_changes
{
	my ($bootEntry, $catalogEntry) = @_;

	my $bt = get $bootEntry;
	my $cat = get $catalogEntry;

	if ($bt ne $main::dataField{'bootimage'})
	{
		$main::dataField{'bootimage'} = $bt;
		$main::changed = 1;
		main::set_title();
	}

	if ($cat ne $main::dataField{'bootcatalog'})
	{
		$main::dataField{'bootcatalog'} = $cat;
		$main::changed = 1;
		main::set_title();
	}
}

1;
