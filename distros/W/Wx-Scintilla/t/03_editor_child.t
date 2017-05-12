#!/usr/bin/perl

use strict;

BEGIN {
	$^W = 1;
}

use Test::More;

BEGIN {
	unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}
plan( tests => 3 );

#----> My first scintilla Wx editor :)
package My::Scintilla::Editor;

# Load Wx::Scintilla
use Wx::Scintilla (); # replaces use Wx::STC
use base 'Wx::Scintilla::TextCtrl'; # replaces Wx::StyledTextCtrl

use Wx qw(:everything);
use Wx::Event;

# Override the constructor to Enable Perl support in the editor
sub new {
	my ( $class, $parent ) = @_;
	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ 750, 700 ] );

	# Set the font
	my $font = Wx::Font->new( 10, wxTELETYPE, wxNORMAL, wxNORMAL );
	$self->SetFont($font);
	$self->StyleSetFont( Wx::Scintilla::STYLE_DEFAULT, $font );
	$self->StyleClearAll();

	# Set the various Perl lexer colors
	$self->StyleSetForeground( 0,  Wx::Colour->new( 0x00, 0x00, 0x7f ) );
	$self->StyleSetForeground( 1,  Wx::Colour->new( 0xff, 0x00, 0x00 ) );
	$self->StyleSetForeground( 2,  Wx::Colour->new( 0x00, 0x7f, 0x00 ) );
	$self->StyleSetForeground( 3,  Wx::Colour->new( 0x7f, 0x7f, 0x7f ) );
	$self->StyleSetForeground( 4,  Wx::Colour->new( 0x00, 0x7f, 0x7f ) );
	$self->StyleSetForeground( 5,  Wx::Colour->new( 0x00, 0x00, 0x7f ) );
	$self->StyleSetForeground( 6,  Wx::Colour->new( 0xff, 0x7f, 0x00 ) );
	$self->StyleSetForeground( 7,  Wx::Colour->new( 0x7f, 0x00, 0x7f ) );
	$self->StyleSetForeground( 8,  Wx::Colour->new( 0x00, 0x00, 0x00 ) );
	$self->StyleSetForeground( 9,  Wx::Colour->new( 0x7f, 0x7f, 0x7f ) );
	$self->StyleSetForeground( 10, Wx::Colour->new( 0x00, 0x00, 0x7f ) );
	$self->StyleSetForeground( 11, Wx::Colour->new( 0x00, 0x00, 0xff ) );
	$self->StyleSetForeground( 12, Wx::Colour->new( 0x7f, 0x00, 0x7f ) );
	$self->StyleSetForeground( 13, Wx::Colour->new( 0x40, 0x80, 0xff ) );
	$self->StyleSetForeground( 17, Wx::Colour->new( 0xff, 0x00, 0x7f ) );
	$self->StyleSetForeground( 18, Wx::Colour->new( 0x7f, 0x7f, 0x00 ) );
	$self->StyleSetBold( 12, 1 );
	$self->StyleSetSpec( Wx::Scintilla::SCE_H_TAG, "fore:#0000ff" );

	# set the lexer to Perl 5
	$self->SetLexer(Wx::Scintilla::SCLEX_PERL);

	my $text = 'Hello world, Scintilla';
	$self->SetText($text);
	main::ok( $text eq $self->GetText, 'SetText, GetText work' );
	$self->SetFocus;

	return $self;
}

package MyTimer;

use vars qw(@ISA); @ISA = qw(Wx::Timer);

sub Notify {
	my $self  = shift;
	my $frame = Wx::wxTheApp()->GetTopWindow;
	$frame->Destroy;
	main::ok( 1, "Timer works.. Destroyed frame!" );
}

#----> DEMO EDITOR APPLICATION

# First, define an application object class to encapsulate the application itself
package DemoEditorApp;

use strict;
use warnings;
use Wx;
use base 'Wx::App';

# We must override OnInit to build the window
sub OnInit {
	my $self = shift;

	my $frame = $self->{frame} = Wx::Frame->new(
		undef,                        # no parent window
		-1,                           # no window id
		'My First Scintilla Editor!', # Window title
	);

	my $editor = My::Scintilla::Editor->new(
		$frame,                       # Parent window
	);
	main::ok( $editor, 'Editor instance created' );

	# Uncomment this to observe the test
	# $frame->Show(1);

	MyTimer->new->Start( 500, 1 );

	return 1;
}

# Create the application object, and pass control to it.
package main;
my $app = DemoEditorApp->new;
$app->MainLoop;
