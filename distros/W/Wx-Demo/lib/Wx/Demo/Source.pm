package Wx::Demo::Source;

use strict;

use Wx qw(:stc :textctrl :font wxDefaultPosition wxDefaultSize
          wxNO_FULL_REPAINT_ON_RESIZE wxLayout_LeftToRight);

our @ISA = ( eval 'require Wx::STC' ) ? 'Wx::StyledTextCtrl' : 'Wx::TextCtrl';

sub new {
    my( $class, $parent ) = @_;
    my $self;

    if( $class->isa( 'Wx::TextCtrl' ) ) {
        $self = $class->SUPER::new
          ( $parent, -1, '', wxDefaultPosition, wxDefaultSize,
            wxTE_READONLY|wxTE_MULTILINE|wxNO_FULL_REPAINT_ON_RESIZE );
    } else {
        $self = $class->SUPER::new( $parent, -1, [-1, -1], [300, 300] );
        
        my $font = Wx::wxMAC() 
                   ? Wx::Font->new( 12, wxMODERN, wxNORMAL, wxNORMAL, 0, 'Monaco' )
                   : Wx::Font->new( 10, wxTELETYPE, wxNORMAL, wxNORMAL);
        $self->SetFont( $font );
        $self->StyleSetFont( wxSTC_STYLE_DEFAULT, $font );
        $self->StyleClearAll();

        $self->StyleSetForeground( wxSTC_PL_DEFAULT,      Wx::Colour->new(0x00, 0x00, 0x7f));
        $self->StyleSetForeground( wxSTC_PL_ERROR,        Wx::Colour->new(0xff, 0x00, 0x00));
        $self->StyleSetForeground( wxSTC_PL_COMMENTLINE,  Wx::Colour->new(0x00, 0x7f, 0x00)); # line green
        $self->StyleSetForeground( wxSTC_PL_POD,          Wx::Colour->new(0x7f, 0x7f, 0x7f));
        $self->StyleSetForeground( wxSTC_PL_NUMBER,       Wx::Colour->new(0x00, 0x7f, 0x7f));
        $self->StyleSetForeground( wxSTC_PL_WORD,         Wx::Colour->new(0x00, 0x00, 0x7f));
        $self->StyleSetForeground( wxSTC_PL_STRING,       Wx::Colour->new(0xff, 0x7f, 0x00)); # orange
        $self->StyleSetForeground( wxSTC_PL_CHARACTER,    Wx::Colour->new(0x7f, 0x00, 0x7f));
        $self->StyleSetForeground( wxSTC_PL_PUNCTUATION,  Wx::Colour->new(0x00, 0x00, 0x00));
        $self->StyleSetForeground( wxSTC_PL_PREPROCESSOR, Wx::Colour->new(0x7f, 0x7f, 0x7f));
        $self->StyleSetForeground( wxSTC_PL_OPERATOR,     Wx::Colour->new(0x00, 0x00, 0x7f)); # dark blue
        $self->StyleSetForeground( wxSTC_PL_IDENTIFIER,   Wx::Colour->new(0x00, 0x00, 0xff)); # bright blue
        $self->StyleSetForeground( wxSTC_PL_SCALAR,       Wx::Colour->new(0x7f, 0x00, 0x7f)); # purple
        $self->StyleSetForeground( wxSTC_PL_ARRAY,        Wx::Colour->new(0x40, 0x80, 0xff)); # light blue
        $self->StyleSetForeground( wxSTC_PL_HASH,         Wx::Colour->new(0x00, 0x80, 0xff));
        # wxSTC_PL_SYMBOLTABLE (15)
        # missing SCE_PL_VARIABLE_INDEXER (16)  
        $self->StyleSetForeground( wxSTC_PL_REGEX,        Wx::Colour->new(0xff, 0x00, 0x7f)); # red
        $self->StyleSetForeground( wxSTC_PL_REGSUBST,     Wx::Colour->new(0x7f, 0x7f, 0x00)); # light olive
        # wxSTC_PL_LONGQUOTE (19)
        # wxSTC_PL_BACKTICKS (20)
        # wxSTC_PL_DATASECTION (21)
        # wxSTC_PL_HERE_DELIM (22)
        $self->StyleSetForeground( wxSTC_PL_HERE_Q,       Wx::Colour->new(0x7f, 0x00, 0x7f));
        # wxSTC_PL_HERE_QQ (24)
        # wxSTC_PL_HERE_QX (25)
        $self->StyleSetForeground( wxSTC_PL_STRING_Q,     Wx::Colour->new(0x7f, 0x00, 0x7f));
        $self->StyleSetForeground( wxSTC_PL_STRING_QQ,    Wx::Colour->new(0xff, 0x7f, 0x00)); # orange
        # wxSTC_PL_STRING_QX  (28)
        # wxSTC_PL_STRING_QR  (29)
        $self->StyleSetForeground( wxSTC_PL_STRING_QW,         Wx::Colour->new(0x7f, 0x00, 0x7f));

        # missing:
        #define SCE_PL_POD_VERB 31
        #define SCE_PL_SUB_PROTOTYPE 40
        #define SCE_PL_FORMAT_IDENT 41
        #define SCE_PL_FORMAT 42


        #Set a style 12 bold
        $self->StyleSetBold(12,  1);

        # Apply tag style for selected lexer (blue)
        $self->StyleSetSpec( wxSTC_H_TAG, "fore:#0000ff" );

        $self->SetLexer( wxSTC_LEX_PERL );
    }

    $self->SetLayoutDirection( wxLayout_LeftToRight )
      if $self->can( 'SetLayoutDirection' );

    return $self;
}

sub set_source {
    my( $self ) = @_;

    if( $self->isa( 'Wx::TextCtrl' ) ) {
        $self->SetValue( $_[1] );
    } else {
        $self->SetText( $_[1] );
    }
}

1;
