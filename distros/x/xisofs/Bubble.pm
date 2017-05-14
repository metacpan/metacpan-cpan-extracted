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
#
#   Bubble.pm will be available soon as a stand-alone module.

package Bubble;

use Tk;
use strict;
use Carp;

sub new {
	my ($this,%args) = @_;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	$self->initialize(\%args);
	return $self;
}

#--------------------
# Initialise Defaults
#--------------------

sub initialize
{
	my ($self,$args) = @_;

	@{$self->{options}} = (
		'relief',
		'foreground',
		'background',
		'bordercolour',
		'bordersize',
		'font',
		'icon',
		'iconalign',
		'xoffset',
		'yoffset',
		'delay',
		'state',
		'contents');

	${$self->{relief}}{'default'} = 'flat';
	${$self->{foreground}}{'default'} = 'white';
	${$self->{background}}{'default'} = 'red';
	${$self->{bordercolour}}{'default'} = 'black';
	${$self->{bordersize}}{'default'} = '1';
	${$self->{font}}{'default'} = 'fixed';
	${$self->{icon}}{'default'} = '';
	${$self->{iconalign}}{'default'} = 'left';
	${$self->{xoffset}}{'default'} = 12;
	${$self->{yoffset}}{'default'} = 12;
	${$self->{delay}}{'default'} = 1000;
	${$self->{state}}{'default'} = 'normal';
	${$self->{contents}}{'default'} = 'full';

	$self->get_options('default', $args);
}

#----------------------------
# Attach a window to a widget
#----------------------------

sub attach {
	my ($self, $parent, %args) = @_;

	my $popup = $parent->Toplevel;
	$popup->overrideredirect(1);
	$popup->withdraw;

	${$self->{text}}{$popup} = $args{'-text'}
		if (defined($args{'-text'}));
	${$self->{textvariable}}{$popup} = $args{'-textvariable'}
		if (defined($args{'-textvariable'}));

	$self->copy_options($popup);
	$self->get_options($popup,\%args);

	${$self->{status}}{$popup} = 0;

	my $icn = ${$self->{icon}}{$popup};

	if (length($icn) > 0)
	{
		unless (defined(${$self->{pixmap}}{$icn}))
		{
			${$self->{pixmap}}{$icn} =
				$popup->Pixmap(-file => $icn);
		}
	}

	my ($frm,$borderfrm);

	if ((${$self->{contents}}{$popup} eq 'full') ||
		(${$self->{contents}}{$popup} eq 'partial'))
	{
		$borderfrm = $popup->Frame(
			-background => ${$self->{bordercolour}}{$popup},
			-borderwidth => 0,
			-relief => 'flat')->pack;
	
		$frm = $borderfrm->Frame(
			-background => ${$self->{background}}{$popup},
			-borderwidth => 1,
			-relief => ${$self->{relief}}{$popup})->pack(
				-padx => ${$self->{bordersize}}{$popup},
				-pady => ${$self->{bordersize}}{$popup});
	}

	if (${$self->{contents}}{$popup} eq 'full')
	{
		if (length(${$self->{icon}}{$popup}) > 0)
		{
			$frm->Label(
				-background => ${$self->{background}}{$popup},
				-image => $self->{pixmap}{${$self->{icon}}{$popup}})->pack(
					-side => ${$self->{iconalign}}{$popup});
		}
	
		if (defined($args{'-text'}))
		{
			my $text = $frm->Label(
				-background => ${$self->{background}}{$popup},
				-foreground => ${$self->{foreground}}{$popup},
				-font => ${$self->{font}}{$popup},
				-text => ${$self->{text}}{$popup})->pack(-side => 'left');
		}
		elsif (defined($args{'-textvariable'}))
		{
			my $text = $frm->Label(
				-background => ${$self->{background}}{$popup},
				-foreground => ${$self->{foreground}}{$popup},
				-font => ${$self->{font}}{$popup},
				-textvariable => ${$self->{textvariable}}{$popup})->pack(-side => 'left');
		}
		else
		{
			croak "Either -text, or -textvariable must be specified";
		}
	}

	$parent->bind('<Enter>',['Bubble::activate',$self,Ev('X'),Ev('Y'),$popup]);
	$parent->bind('<Leave>',['Bubble::popleave',$self,Ev('X'),Ev('Y'),$popup]);
	$parent->bind('<Motion>',['Bubble::popmove',$self,Ev('X'),Ev('Y'),$popup]);
	$parent->bind('<Button>',['Bubble::popleave',$self,Ev('X'),Ev('Y'),$popup]);
	$popup->bind('<Leave>',['Bubble::popleave',$self,Ev('X'),Ev('Y'),$popup]);

	if (${$self->{contents}}{$popup} eq 'partial')
	{
		return $frm;
	}
	else
	{
		return $popup;
	}
}

#----------------------
# re-configure a widget
#----------------------

sub configure
{
	my ($self, %args) = @_;


}

#------------------------------------------
# Activate, ie start waiting the delay time
#------------------------------------------

sub activate
{
	my ($w,$self,$x,$y,$parent) = @_;

	return if (${$self->{state}}{$parent} eq 'disabled');

	${$self->{status}}{$parent} = 1;
	${$self->{after}}{$parent} = 
		$parent->after(${$self->{delay}}{$parent},sub{popup($self,$parent,
			$x+${$self->{xoffset}}{$parent},$y+${$self->{yoffset}}{$parent})});
}

#-----------------------
# Show the bubble window
#-----------------------

sub popup
{
	my ($self,$parent,$x,$y) = @_;

	return if (${$self->{status}}{$parent} == 0);
	$parent->geometry("+$x+$y");
	$parent->deiconify();
	$parent->raise;
	${$self->{status}}{$parent} = 2;
}

#--------------------------------
# Pointer have moved out the area
#--------------------------------

sub popleave
{
	my ($w,$self,$x,$y,$parent) = @_;

	if (${$self->{status}}{$parent} == 1)
	{
		$parent->afterCancel(${$self->{after}}{$parent})
	}

	$parent->withdraw;
	${$self->{status}}{$parent} = 0;
}

#----------------------------------
# Pointer has moved within the area
#----------------------------------

sub popmove
{
	my ($w,$self,$x,$y,$parent) = @_;

	return if (${$self->{state}}{$parent} eq 'disabled');

	if (${$self->{status}}{$parent} == 1)
	{
		$parent->afterCancel(${$self->{after}}{$parent})
	}
	else
	{
		$parent->withdraw;
	}

	$parent->withdraw;
	${$self->{after}}{$parent} = 
		$parent->after(${$self->{delay}}{$parent},sub{popup($self,$parent,
			$x+${$self->{xoffset}}{$parent},$y+${$self->{yoffset}}{$parent})});

	${$self->{status}}{$parent} = 1;
}

#----------------------------
# Sort out any options passed
#----------------------------

sub get_options
{
	my ($self, $index,$args) = @_;

	foreach(@{$self->{options}})
	{
		${$self->{$_}}{$index} = delete $$args{"-$_"}
			if (defined($$args{"-$_"}));
	}

	if (${$self->{icon}}{$index} eq 'none')
	{
		delete ${$self->{icon}}{$index};
	}
}

#-------------------------
# Copy the default options
#-------------------------

sub copy_options
{
	my ($self,$index) = @_;

	foreach(@{$self->{options}})
	{
		${$self->{$_}}{$index} = ${$self->{$_}}{'default'};
	}
}
1;

__END__

=head1 NAME

Tk::Bubble - Pop up help windows

=head1 SYNOPSYS

use Tk::Bubble;

...

$bubble = new Bubble(<options..>);

$bubble->attach(<widget>,<options>);

$bubble->configure(<widget>,<options>);

=head1 DESCRIPTION

B<Bubble> is a bubble help system (or sometimes called tooltips/balloon help)
which allows a window to be displayed after a certain amount of time. This
window will vanish if the mouse is moved or a button is pressed.

=head1 CREATE OBJECT

To use the bubble help, a new bubble object must first be created.
I<$bubble = new Bubble(options);>. The following options are available and
will be used as defaults for any popup windows created with this
object.

=over 4

=item B<-background>

Specifies the background colour of the window. The default is
'red'.

=item B<-bordercolour>

Specifies the colour of the border around the popup window. The default
is 'black'.

=item B<-bordersize>

Specifies the size of the border around the popup window in pixels. The
default is 1.

=item B<-contents>

This specifies how the window will be drawn. I<full> which is the default
will draw the popup window using the parameters supplied. I<partial> will 
draw the border and the inner window as specified, but not add any text.
I<none> will simply create the framework for the popup button, but not
actually create anything. This option is useful if you have a complex
popup window to draw, as the attach will return the innermost object which
can be use to add any other objects.

=item B<-delay>

This is the delay in milliseconds before the window is displayed. The default 
is 1000.

=item B<-font>

This is the font to be used for the text. The default is 'fixed'.

=item B<-foreground>

This is the foreground colour for the popup window. The default is 'white'.

=item B<-icon>

This will add an icon to the popup window. It must be an XPM image. It
will be aligned in the window as specified by I<-iconalign>. The default
is no icon.

=item B<-iconalign>

This specifies the alignment of the icon. It can be one of I<left>, I<right>, 
I<top> and I<bottom>. The default is 'left'.

=item B<-relief>

This specifies the relief of the window inside the border. It can be any of
the normally support relief values and by default is 'flat'.

=item B<-state>

This is either I<normal> or I<disabled>. This affects all popup windows 
in this object and the default is 'normal'.

=item B<-xoffset>

This is how many pixels in the x direction the popup window is offset
from the mouse pointer. The default is 12.

=item B<-yoffset>

This is how many pixels in the y direction the popup window is offset
from the mouse pointer. The default is 12.

=back

=head1 AUTHOR

Steve Sherwood <pariah@netcomuk.co.uk>

=cut
