#!/usr/bin/env perl
use warnings;
use strict;

#	runtime construction
#
#	usually, the object tree representing the gui is built and then passed to
#	display for rendering.  it is also possible to construct the gui after
#	calling display with the following pattern:
#
#		display sub {$_[0]->appendChild(...)};
#
#	inside the subroutine passed to display, both $_[0] and $_ are set to
#	the innermost container object necessary to display a window.  in XUL that
#	is just Window(), and in HTML it would be HTML( BODY() )
#
#	the program that follows is a more complex example:

use XUL::Gui;

display sub {
	my $self = shift;

	$self->resizeTo(200, 200);

	$self->align = 'center';
	$self->pack  = 'center';

	$self->appendChildren(
		Label('hello, world!'),
		Button(
            id        => 'quit',
			label     => 'quit',
			oncommand => sub {
				print "goodbye, world\n" unless $XUL::Gui::TESTING;
				quit;
			},
            delay {
                ID(quit)->click if $XUL::Gui::TESTING;
            }
		)
	);
};
