#----> Experimental Perl 6 editor
package Editor::Perl6;

use strict;
use warnings;

# Load Wx::Scintilla
use Wx::Scintilla 0.34 ();
use base 'Wx::Scintilla::TextCtrl';
use Wx qw(:everything);
use Wx::Event;

# Override the constructor to Enable Perl 6 support in the editor
sub new {
	my ( $class, $parent ) = @_;
	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ 750, 700 ] );

	# Set the font
	my $font = Wx::Font->new( 10, wxTELETYPE, wxNORMAL, wxNORMAL );
	$self->SetFont($font);
	$self->StyleSetFont( Wx::Scintilla::STYLE_DEFAULT, $font );
	$self->StyleClearAll();

	# Set the various Perl 6 lexer colors
	$self->StyleSetForeground( Wx::Scintilla::wxSCINTILLA_P6_DEFAULT,  Wx::Colour->new( 0x00, 0x00, 0x00 ) );
	$self->StyleSetForeground( Wx::Scintilla::wxSCINTILLA_P6_COMMENT,  Wx::Colour->new( 0x00, 0x7f, 0x00 ) );
	$self->StyleSetForeground( Wx::Scintilla::wxSCINTILLA_P6_STRING,  Wx::Colour->new( 0xff, 0x7f, 0x00 ) );
	$self->StyleSetBold( Wx::Scintilla::wxSCINTILLA_P6_COMMENT, 1);

	# set the lexer to Perl 6
	$self->SetLexer(Wx::Scintilla::wxSCINTILLA_LEX_PERL6);

	my $keywords = ["use say"];
	$self->SetKeyWords(0, $keywords);

	$self->SetText(<<"EXAMPLE");
=pod begin
This is pod
=pod end

# Perl 6 example
use v6;
say "Hello world from Perl 6!";

EXAMPLE
	$self->SetFocus;

	return $self;
}

package Perl6EditorApp;

use strict;
use warnings;
use Wx;
use base 'Wx::App';

sub OnInit {
	my $self = shift;

	my $frame = Wx::Frame->new(undef, -1, 'Perl 6 Editor!');
	my $editor = Editor::Perl6->new($frame);
	$frame->Show(1);
	return 1;
}

# Create the application object, and pass control to it.
package main;
my $app = Perl6EditorApp->new;
$app->MainLoop;
