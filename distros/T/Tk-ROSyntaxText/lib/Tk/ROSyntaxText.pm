package Tk::ROSyntaxText;

use strict;
use warnings;

our $VERSION = '1.001';

use Tk;
use base qw{Tk::Derived Tk::ROText};

use Syntax::Highlight::Engine::Kate::All;
use Syntax::Highlight::Engine::Kate 0.06;
use Carp;

Construct Tk::Widget q{ROSyntaxText};

my %DEFAULT_SHEK_OPTION_FOR = (
    Alert        => [ -background => q{#ffffff}, -foreground => q{#0000ff} ],
    BaseN        => [ -background => q{#ffffff}, -foreground => q{#007f00} ],
    BString      => [ -background => q{#ffffff}, -foreground => q{#c9a7ff} ],
    Char         => [ -background => q{#ffffff}, -foreground => q{#ff00ff} ],
    Comment      => [ -background => q{#ffffff}, -foreground => q{#7f7f7f} ],
    DataType     => [ -background => q{#ffffff}, -foreground => q{#0000ff} ],
    DecVal       => [ -background => q{#ffffff}, -foreground => q{#00007f} ],
    Error        => [ -background => q{#ffffff}, -foreground => q{#ff0000} ],
    Float        => [ -background => q{#ffffff}, -foreground => q{#00007f} ],
    Function     => [ -background => q{#ffffff}, -foreground => q{#007f00} ],
    IString      => [ -background => q{#ffffff}, -foreground => q{#ff0000} ],
    Keyword      => [ -background => q{#ffffff}, -foreground => q{#7f007f} ],
    Normal       => [ -background => q{#ffffff}, -foreground => q{#000000} ],
    Operator     => [ -background => q{#ffffff}, -foreground => q{#ffa500} ],
    Others       => [ -background => q{#ffffff}, -foreground => q{#b03060} ],
    RegionMarker => [ -background => q{#ffffff}, -foreground => q{#96b9ff} ],
    Reserved     => [ -background => q{#ffffff}, -foreground => q{#9b30ff} ],
    String       => [ -background => q{#ffffff}, -foreground => q{#ff0000} ],
    Variable     => [ -background => q{#ffffff}, -foreground => q{#0000ff} ],
    Warning      => [ -background => q{#ffffff}, -foreground => q{#0000ff} ],
);

my $MAX_OUTPUT_FRAG_LENGTH = 127; # arbitrary
my $DEFAULT_ENGINE_SYNTAX_TYPE = q{Normal};
my $ERR_BAD_ENGINE_SYNTAX_TYPE
    = q{Unknown type (%s) encountered for text (%s). Using default.};

my $DEFAULT_BG = q{#ffffff};
my $DEFAULT_FG = q{#000000};
my $DEFAULT_FONT = [qw{
    -family Courier -size 10 -weight normal -slant roman
    -underline 0 -overstrike 0
}];
my @DEFAULT_SPACING = qw{-spacing1 1 -spacing2 2 -spacing3 2};

my $TAG_NAME_PREFIX = q{shek_};
my $SHEK_OPTION_PREFIX = q{-shek_};
my (%tag_name_for, %shek_option_name_for);

my %DARK_STYLE = (
    -foreground => q{#ffffff},
    -background => q{#000000},
    -shek_Alert =>
        [ -background => q{#000000}, -foreground => q{#66ff66} ],
    -shek_BaseN =>
        [ -background => q{#000000}, -foreground => q{#0099ff} ],
    -shek_BString =>
        [ -background => q{#000000}, -foreground => q{#cc99ff} ],
    -shek_Char =>
        [ -background => q{#000000}, -foreground => q{#9966cc} ],
    -shek_Comment =>
        [ -background => q{#000000}, -foreground => q{#666666} ],
    -shek_DataType =>
        [ -background => q{#000000}, -foreground => q{#0066ff} ],
    -shek_DecVal =>
        [ -background => q{#000000}, -foreground => q{#00ccff} ],
    -shek_Error =>
        [ -background => q{#000000}, -foreground => q{#ff3333} ],
    -shek_Float =>
        [ -background => q{#000000}, -foreground => q{#339999} ],
    -shek_Function =>
        [ -background => q{#000000}, -foreground => q{#00ffff} ],
    -shek_IString =>
        [ -background => q{#000000}, -foreground => q{#ff6699} ],
    -shek_Keyword =>
        [ -background => q{#000000}, -foreground => q{#ffff00} ],
    -shek_Normal =>
        [ -background => q{#000000}, -foreground => q{#ffffff} ],
    -shek_Operator =>
        [ -background => q{#000000}, -foreground => q{#cc6633} ],
    -shek_Others =>
        [ -background => q{#000000}, -foreground => q{#cc9966} ],
    -shek_RegionMarker =>
        [ -background => q{#000000}, -foreground => q{#99ccff} ],
    -shek_Reserved =>
        [ -background => q{#000000}, -foreground => q{#9999ff} ],
    -shek_String =>
        [ -background => q{#000000}, -foreground => q{#00cc00} ],
    -shek_Variable =>
        [ -background => q{#000000}, -foreground => q{#33cccc} ],
    -shek_Warning =>
        [ -background => q{#000000}, -foreground => q{#ff9933} ],
);

sub Populate {
    my ($self, $args) = @_;

    $self->SUPER::Populate($args);

    $self->ConfigSpecs(
        q{-char_subs}         => [qw{PASSIVE charSubs CharSubs}, {}],
        q{-custom_config}     => [qw{PASSIVE customConfig CustomConfig}, {}],
        q{-dark_style}        => [qw{PASSIVE darkStyle DarkStyle}, 0],
        q{-syntax_lang}       => [qw{PASSIVE syntaxLang SyntaxLang Perl}],

        q{-shek_Alert}        => [qw{PASSIVE shekAlert ShekAlert},
                                    $DEFAULT_SHEK_OPTION_FOR{Alert}],
        q{-shek_BaseN}        => [qw{PASSIVE shekBaseN ShekBaseN},
                                    $DEFAULT_SHEK_OPTION_FOR{BaseN}],
        q{-shek_BString}      => [qw{PASSIVE shekBString ShekBString},
                                    $DEFAULT_SHEK_OPTION_FOR{BString}],
        q{-shek_Char}         => [qw{PASSIVE shekChar ShekChar},
                                    $DEFAULT_SHEK_OPTION_FOR{Char}],
        q{-shek_Comment}      => [qw{PASSIVE shekComment ShekComment},
                                    $DEFAULT_SHEK_OPTION_FOR{Comment}],
        q{-shek_DataType}     => [qw{PASSIVE shekDataType ShekDataType},
                                    $DEFAULT_SHEK_OPTION_FOR{DataType}],
        q{-shek_DecVal}       => [qw{PASSIVE shekDecVal ShekDecVal},
                                    $DEFAULT_SHEK_OPTION_FOR{DecVal}],
        q{-shek_Error}        => [qw{PASSIVE shekError ShekError},
                                    $DEFAULT_SHEK_OPTION_FOR{Error}],
        q{-shek_Float}        => [qw{PASSIVE shekFloat ShekFloat},
                                    $DEFAULT_SHEK_OPTION_FOR{Float}],
        q{-shek_Function}     => [qw{PASSIVE shekFunction ShekFunction},
                                    $DEFAULT_SHEK_OPTION_FOR{Function}],
        q{-shek_IString}      => [qw{PASSIVE shekIString ShekIString},
                                    $DEFAULT_SHEK_OPTION_FOR{IString}],
        q{-shek_Keyword}      => [qw{PASSIVE shekKeyword ShekKeyword},
                                    $DEFAULT_SHEK_OPTION_FOR{Keyword}],
        q{-shek_Normal}       => [qw{PASSIVE shekNormal ShekNormal},
                                    $DEFAULT_SHEK_OPTION_FOR{Normal}],
        q{-shek_Operator}     => [qw{PASSIVE shekOperator ShekOperator},
                                    $DEFAULT_SHEK_OPTION_FOR{Operator}],
        q{-shek_Others}       => [qw{PASSIVE shekOthers ShekOthers},
                                    $DEFAULT_SHEK_OPTION_FOR{Others}],
        q{-shek_RegionMarker} => [qw{PASSIVE shekRegionMarker ShekRegionMarker},
                                    $DEFAULT_SHEK_OPTION_FOR{RegionMarker}],
        q{-shek_Reserved}     => [qw{PASSIVE shekReserved ShekReserved},
                                    $DEFAULT_SHEK_OPTION_FOR{Reserved}],
        q{-shek_String}       => [qw{PASSIVE shekString ShekString},
                                    $DEFAULT_SHEK_OPTION_FOR{String}],
        q{-shek_Variable}     => [qw{PASSIVE shekVariable ShekVariable},
                                    $DEFAULT_SHEK_OPTION_FOR{Variable}],
        q{-shek_Warning}      => [qw{PASSIVE shekWarning ShekWarning},
                                    $DEFAULT_SHEK_OPTION_FOR{Warning}],
    );

    $self->configure(
        -background => $DEFAULT_BG,
        -foreground => $DEFAULT_FG,
        -font => $DEFAULT_FONT,
        @DEFAULT_SPACING,
    );
}

sub Tk::Widget::ScrlROSyntaxText {
    my ($parent, @options) = @_;

    my %default_options = (
        -wrap       => q{none},
        -scrollbars => q{osoe},
    );

    return $parent->Scrolled('ROSyntaxText' => (%default_options, @options));
}

sub insert {
    my ($self, $text) = @_;

    $self->delete(q{1.0} => q{end});

    $self->SUPER::insert(q{1.0} => q{});

    $self->_insert_highlighted_text($text);

    return;
}

sub _insert_highlighted_text {
    my ($self, $text) = @_;

    foreach my $shek_name (keys %DEFAULT_SHEK_OPTION_FOR) {
        $tag_name_for{$shek_name} = $TAG_NAME_PREFIX . $shek_name;
        $shek_option_name_for{$shek_name} = $SHEK_OPTION_PREFIX . $shek_name;
    }

    my $ro_engine = $self->_get_syntax_engine();

    my $rh_subs = $ro_engine->substitutions();
    my $have_subs = %{$rh_subs} ? 1 : 0;

    $self->_configure_tags($ro_engine->formatTable());

    my @frag_type_pairs = $ro_engine->highlight($text);

    while (@frag_type_pairs) {
        my $frag = shift @frag_type_pairs;
        my $type = shift @frag_type_pairs;

        if (! (defined($type) && $type)) {
            $type = $DEFAULT_ENGINE_SYNTAX_TYPE;
        }

        if (exists $tag_name_for{$type}) {
            my $output_text
                = $have_subs
                ? join(q{}, map { exists($rh_subs->{$_}) ? $rh_subs->{$_} : $_
                            } split(//, $frag))
                : $frag;

            $self->SUPER::insert(q{insert}, $output_text, $tag_name_for{$type});
        }
        else {
            my $out_frag = length($frag) > $MAX_OUTPUT_FRAG_LENGTH
                ? substr($frag, 0, $MAX_OUTPUT_FRAG_LENGTH - 4) . q{ ...}
                : $frag;
            croak sprintf($ERR_BAD_ENGINE_SYNTAX_TYPE => $type, $out_frag);
        }
    }

    $self->update();

    return;
}

sub _configure_tags {
    my ($self, $rh_format) = @_;

    foreach my $shek_name (keys %DEFAULT_SHEK_OPTION_FOR) {
        $self->tagConfigure(
            $tag_name_for{$shek_name}, @{$rh_format->{$shek_name}}
        );
    }

    return;
}

sub _get_syntax_engine {
    my ($self) = @_;

    $self->_customise_configuration();

    my $lang = $self->cget(q{-syntax_lang});
    my $rh_subs = $self->cget(q{-char_subs});
    my $rh_format = {
        map { $_ => $self->cget($shek_option_name_for{$_})
        } keys %shek_option_name_for
    };

    my $ro_engine = Syntax::Highlight::Engine::Kate->new(
        language        => $lang,
        substitutions   => $rh_subs,
        format_table    => $rh_format,
    );

    return $ro_engine;
}

sub _customise_configuration {
    my ($self) = @_;

    my %custom_config = %{$self->cget(q{-custom_config})};

    if (exists $custom_config{q{-dark_style}}) {
        $self->configure(
            q{-dark_style} => delete($custom_config{q{-dark_style}})
        );
    }

    if (exists $custom_config{q{-custom_config}}) {
        my $discard = delete($custom_config{q{-custom_config}});
    }

    my %new_config_for = (
        ( $self->cget(q{-dark_style}) ? %DARK_STYLE : () ),
        %custom_config
    );

    foreach my $option (keys %new_config_for) {
        $self->configure($option => $new_config_for{$option});
    }

    return;
}


1;

__END__

=head1 NAME

Tk::ROSyntaxText - Read-only text widget with syntax highlighting


=head1 VERSION

This document describes Tk::ROSyntaxText version 1.001


=head1 SYNOPSIS

    use Tk;
    use Tk::ROSyntaxText;
    
    my $syntax = $parent->ROSyntaxText(%options);
    
    $syntax->pack();
    
    $syntax->insert($text);
    
    # For scrollbars to be automatically added (when required)
    
    my $scrolling_syntax = $parent->ScrlROSyntaxText(%options);


=head1 DESCRIPTION

B<Tk::ROSyntaxText> is a read-only text widget that applies syntax
highlighting to its data.

I<Tk::ROSyntaxText> inherits from L<< C<Tk::ROText>|Tk::ROText >>
which, in turn, inherits from L<< C<Tk::Text>|Tk::Text >>.

The syntax parsing is carried out via
L<< C<Syntax::Highlight::Engine::Kate>|Syntax::Highlight::Engine::Kate >>.

Highlighting is achieved through L<< C<Tk::Text>|Tk::Text >> options to
change colours, embolden text and so on. See the section on
L<< I<Highlighting>|/"Highlighting" >> below for a further discussion.

There are many applications where this widget would be useful: a subset
is listed in the L<< I<Applications>|/"Applications" >> section below.


=head2 Highlighting

If a I<Tk::ROSyntaxText> widget is created without any options, it will
have the default syntax hightlighting used by
L<< C<Syntax::Highlight::Engine::Kate>|Syntax::Highlight::Engine::Kate >>
but without any italicised or emboldened text.

    my $syntax = $parent->ROSyntaxText();

This is a white background with variables, keywords, comments, etc. presented
in a variety of colours.

For those who prefer a dark background, set the I<-dark_style> option to a
TRUE value:

    my $syntax = $parent->ROSyntaxText(-dark_style => 1);

This is a black background with the syntax elements in a variety of colours
tailored to the darker background.

Finer control over the colours requires additional options (see
L<< I<Options>|/"Options" >> below). In general, if only one or two default
options are to be altered, it's probably easiest to use these directly
when the widget is created:

    my $syntax = $parent->ROSyntaxText(-opt1 => val1, -opt2 => val2);

For a large number of changes, or when multiple widgets are to be used, or if
a completely customised look-and-feel is required, the I<-custom_config>
option may prove to be more useful:

    my %options = (
        -option1 => value1,
        ...
        -optionN => valueN
    );
    
    my $syntax = $parent->ROSyntaxText(-custom_config => \%options);

I<NOTE:> You may include any options that appear in the
L<< I<Options>|/"Options" >> section in the I<-custom_config> option list.
However, two options are handled specially: see I<-custom_config> under
L<< I<Widget-specific Options>|/"Widget-specific Options" >> for details.

B<IMPORTANT:> To tweak the I<-dark_style> configuration, when the
I<-dark_style> option has been used explicitly, the I<-custom_config>
option must be used:

    my $syntax = $parent->ROSyntaxText(-dark_style => 1,
                                       -custom_config => \%options);

An easier way of handling this is to add C<-dark_style =E<gt> 1> to the
I<-custom_config> option list (the position in the list is immaterial):

    my %options = (
        -option1    => value1,
        ...
        -dark_style => 1,
        ...
        -optionN    => valueN
    );
    
    my $syntax = $parent->ROSyntaxText(-custom_config => \%options);

In addition to colour, other aspects of the presentation may be changed via the
I<-font> option. This may be done globally, e.g.

    -font => [qw{-family Times -size 12 -weight bold -slant italic}]

or for a specific syntax type, e.g.

    -shek_Comment => [
        -background => q{#0000ff},
        -foreground => q{#c0c0c0},
        -font => [ -slant => 'italic' ],
    ]

The defaults (for I<Tk::ROSyntaxText>) are:

    Font:       Courier
    Size:       10
    Weight:     normal (i.e. not bold)
    Slant:      roman (i.e. upright, not italic)
    Underline:  NO
    Overstrike: NO


=head2 Applications

Applications for I<Tk::ROSyntaxText> might include:

=over 4

=item * The B<[ See Code ]> pages in the widget demo

=item * Documentation viewers such as TkMan

=item * A CPAN module code viewer

=item * Source code viewers for revision control system repositories

=item * WWW markup viewer

=item * XML source code viewer

=item * Configuration settings viewer

=item * A generic document viewer which reconfigures itself based on MIME type

=back


=head1 INTERFACE 

=head2 Constructors

=head3 Tk::ROSyntaxText

    my $syntax = $parent->ROSyntaxText(%options);

=over 4

=item C<$parent>

Parent widget, e.g. Frame, Main window, etc.

=item C<%options>

Instantiation options - see L<< I<Options>|/"Options" >> below.

=item C<$syntax>

Newly created C<Tk::ROSyntaxText> widget.

=back

=head3 Tk::Widget::ScrlROSyntaxText

    my $scrolled_syntax = $parent->ScrlROSyntaxText(%options);

=over 4

=item C<$parent>

Parent widget, e.g. Frame, Main window, etc.

=item C<%options>

Instantiation options - see L<< I<Options>|/"Options" >> below.

=item C<$scrolled_syntax>

Newly created C<Tk::ROSyntaxText> widget with I<scrollbars>.

=back


=head2 Options

Available options are broken up into four categories:

=over 4

=item * L<< I<Standard Options>|/"Standard Options" >>

Options available to most widgets, such as I<-borderwidth> and I<-padx>.

=item * L<< I<Inherited Options>|/"Inherited Options" >>

Options specific to text widgets, such as I<-height> and I<-tabs>.

=item * L<< I<Scrollbar Options>|/"Scrollbar Options" >>

Options specific to I<TK::ROSyntaxText> widgets created with scrollbars.

=item * L<< I<Widget-specific Options>|/"Widget-specific Options" >>

Options specific to I<TK::ROSyntaxText>.

=back


=head3 Standard Options

Some standard options are configured, as indicated below;
the remainder retain their default values.

=over 4

=item B<< C<-background> >>

Configured by C<Tk::ROSyntaxText>. Starting value:

    -background => q{#ffffff}

=item B<< C<-borderwidth> >>

=item B<< C<-cursor> >>

=item B<< C<-exportselection> >>

=item B<< C<-font> >>

Configured by C<Tk::ROSyntaxText>. Starting value:

    -font => [qw{
        -family     Courier
        -size       10
        -weight     normal
        -slant      roman
        -underline  0
        -overstrike 0
    }]

=item B<< C<-foreground> >>

Configured by C<Tk::ROSyntaxText>. Starting value:

    -foreground => q{#000000}

=item B<< C<-highlightbackground> >>

=item B<< C<-highlightcolor> >>

=item B<< C<-highlightthickness> >>

=item B<< C<-padx> >>

=item B<< C<-pady> >>

=item B<< C<-relief> >>

=item B<< C<-selectbackground> >>

=item B<< C<-selectborderwidth> >>

=item B<< C<-selectforeground> >>

=item B<< C<-setgrid> >>

=item B<< C<-takefocus> >>

=item B<< C<-xscrollcommand> >>

=item B<< C<-yscrollcommand> >>

=back


=head3 Inherited Options

Some inherited options are configured, as indicated below;
the remainder retain their default values.

=over 4

=item B<< C<-height> >>

=item B<< C<-spacing1> >>

Configured by C<Tk::ROSyntaxText>. Starting value:

    -spacing1 => 1

=item B<< C<-spacing2> >>

Configured by C<Tk::ROSyntaxText>. Starting value:

    -spacing2 => 2

=item B<< C<-spacing3> >>

Configured by C<Tk::ROSyntaxText>. Starting value:

    -spacing3 => 2

=item B<< C<-state> >>

=item B<< C<-tabs> >>

=item B<< C<-width> >>

=item B<< C<-wrap> >>

Normally left as the default but see
L<< I<Scrollbar Options>|/"Scrollbar Options" >> below.

=back


=head3 Scrollbar Options

These options only pertain to a C<Tk::ROSyntaxText> widget instantiated as:

    my $scrolling_syntax = $parent->ScrlROSyntaxText(%options);

=over 4

=item B<< C<-scrollbars> >>

Configured by C<Tk::ROSyntaxText>. Starting value:

    -scrollbars => q{osoe}

=item B<< C<-wrap> >>

Configured by C<Tk::ROSyntaxText>. Starting value:

    -wrap => q{none}

=back


=head3 Widget-specific Options

=over 4

=item B<< C<-char_subs> >>

This option provides a mapping of characters to substitute text.
It is typically used for characters that need to be I<escaped>
to prevent interpretation by the output medium.

An example is the less-than sign (E<lt>) which would be converted to
C<&lt;> before being output to HTML; and to C<< EE<lt>ltE<gt> >>
before being output to POD.

As a point of interest, you can map characters outside of the set
normally referred to as I<printable> characters. For instance, you
can map tabs:

    -char_subs => { "\t" => 'TAB' }

You can map newlines and carriage returns:

    -char_subs => { "\n" => 'NL', "\r" => 'CR' }

although that will almost certainly mess up the overall layout of the text.

I<Default:> C<{}>

=item B<< C<-custom_config> >>

This option takes a hashref of option/value pairs. Any options listed in
the L<< I<Options>|/"Options" >> section may be used; however, two options
are handled specially:

=over 4

=item * I<-dark_style>

A I<-dark_style> option that is included in the I<-custom_config> hashref
will override any other I<-dark_style> option (whether the implicit FALSE
default value or an explicit TRUE or FALSE value). No warning is emitted.

=item * I<-custom_config>

A I<-custom_config> option nested inside another I<-custom_config> option
is simply ignored. No warning is emitted.

=back

See L<< I<Highlighting>|/"Highlighting" >> above for further discussion.

I<Default:> C<{}>

=item B<< C<-dark_style> >>

This is a boolean option. When set to a TRUE value, the background
is changed to black and the foreground colours of the syntax elements
are tailored to this darker background.

See L<< I<Highlighting>|/"Highlighting" >> above for further discussion.

I<Default:> C<0>

=item B<< C<-syntax_lang> >>

This is the language whose syntax you are highlighting.
It might be a programming language, a markup language or
something else with a formal syntax.
C<Syntax::Highlight::Engine::Kate> has 
L<< Plugins|Syntax::Highlight::Engine::Kate/"PLUGINS" >>
for over 100 languages.

I<Default:> C<Perl>

=back


=head4 The C<-shek_*> Options

All syntax parsing is carried out via
L<< C<Syntax::Highlight::Engine::Kate>|Syntax::Highlight::Engine::Kate >>
(whose initials are SHEK: hence the I<-shek_> prefix).

The part after this prefix matches one of the syntax types identified by
C<Syntax::Highlight::Engine::Kate>, e.g. Comment, Keyword, String, etc.

The value of each option is an B<arrayref> of key/value pairs.

Each key/value pair affects how its associated text type is highlighted.

For instance, to make the syntax type I<Error>
appear as yellow text on a red background:

    -shek_Error => [
        -background => q{#ff0000},
        -foreground => q{#ffff00},
    ]

To make this stand out even more with emboldened text:

    -shek_Error => [
        -background => q{#ff0000},
        -foreground => q{#ffff00},
        -font => [qw{-weight bold}]
    ]

As a further example, say you wanted comments in the Times font with
italicised silver text on a blue background:

    -shek_Comment => [
        -background => q{#0000ff},
        -foreground => q{#c0c0c0},
        -font => [qw{-family Times -slant italic}]
    ]

Here's the list of C<-shek_*> options:

=over 4

=item B<< C<-shek_Alert> >>

=item B<< C<-shek_BaseN> >>

=item B<< C<-shek_BString> >>

=item B<< C<-shek_Char> >>

=item B<< C<-shek_Comment> >>

=item B<< C<-shek_DataType> >>

=item B<< C<-shek_DecVal> >>

=item B<< C<-shek_Error> >>

=item B<< C<-shek_Float> >>

=item B<< C<-shek_Function> >>

=item B<< C<-shek_IString> >>

=item B<< C<-shek_Keyword> >>

=item B<< C<-shek_Normal> >>

=item B<< C<-shek_Operator> >>

=item B<< C<-shek_Others> >>

=item B<< C<-shek_RegionMarker> >>

=item B<< C<-shek_Reserved> >>

=item B<< C<-shek_String> >>

=item B<< C<-shek_Variable> >>

=item B<< C<-shek_Warning> >>


=back


=head2 Methods

=head3 insert()

    $self->insert($text);

=over 4

=item C<$self>

An instance of I<Tk::ROSyntaxText>.

=item C<$text>

The text whose syntax is to be highlighted.

=item Context: C<void>

=back

B<IMPORTANT!> I<< C<Tk::ROSyntaxText::insert()> overrides
C<Tk::Text::insert()> >>

Differences to note:

=over 4

=item I<No insertion point>

You can't specify an I<index>.

=item I<No tags>

You can't specify a I<tagList>.

=item I<No list>

You can't specify a list of text items.

=back

Each invocation of C<insert()> causes all text currently in the widget
to be deleted. The text indicated in C<insert()>'s argument is then
displayed (in the now empty widget) with its syntax highlighted.


=head1 DIAGNOSTICS

=over

=item C<< Unknown type (%s) encountered for text (%s). Using default. >>

L<< C<Syntax::Highlight::Engine::Kate>|Syntax::Highlight::Engine::Kate >>
flags portions of text according to type: I<String>, I<Comment> and so on.
In this instance, an unknown type was encountered. The text has still
been displayed, but without any highlighting. The most likely cause would
be some change in I<Syntax::Highlight::Engine::Kate>. Please report this
bug - see L<< I<BUGS AND LIMITATIONS>|/"BUGS AND LIMITATIONS" >> below for
details of how to do this - thankyou.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Tk::ROSyntaxText requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over 4

=item L<< C<Syntax::Highlight::Engine::Kate>|Syntax::Highlight::Engine::Kate >> 0.06

=item L<< C<Test::More>|Test::More >> 0.94

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs to C<bug-tk-rosyntaxtext@rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Ken Cotterill  C<< <kcott@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Ken Cotterill C<< <kcott@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 SEE ALSO

=over 4

=item Related I<Tk> modules

L<< C<Tk::ROText>|Tk::ROText >>,
L<< C<Tk::Text>|Tk::Text >>,
L<< C<Tk::Scrolled>|Tk::Scrolled >>,
L<< C<Tk::options>|Tk::options >>

=item Tk POD documentation for fonts

L<< C<font>|http://search.cpan.org/~srezic/Tk-804.029/pod/Font.pod >>

=item L<< C<Syntax::Highlight::Engine::Kate>|Syntax::Highlight::Engine::Kate >>

All syntax parsing is performed via this module.

=item Article: Writing a Kate Highlighting XML File

F<http://www.kate-editor.org/article/writing_a_kate_highlighting_xml_file>
Note the I<Available Default Styles> section.

=item The Kate Handbook

F<http://docs.kde.org/development/en/kdesdk/kate/index.html>

=back


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

