#!perl

#   11.scroll.t

use strict;
use warnings;
use English qw{-no_match_vars};
use Test::More 0.94;

use Tk;
use Tk::ROSyntaxText;

my $mw = eval { MainWindow->new(
    -title => q{Tk::ROSyntaxText: 11.scroll.t},
); };

if ($mw) {
    plan tests => 3;
}
else {
    plan skip_all => q{No display detected.};
}

my $rosyn = eval { $mw->ScrlROSyntaxText(-dark_style => 1); };

ok(! $EVAL_ERROR, q{Test widget instantiaton})
    or diag $EVAL_ERROR;

eval { $rosyn->pack(-fill => q{both}, -expand => 1); };

ok(! $EVAL_ERROR, q{Test widget packing})
    or diag $EVAL_ERROR;

my $code_for_scrolling = <<'END_CODE';
package Tk::ROSyntaxText;

use strict;
use warnings;

our $VERSION = '1.000';

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
    -foreground         => q{#ffffff},
    -background         => q{#000000},
    -shek_Alert         => [ -background => q{#000000}, -foreground => q{#66ff66} ],
    -shek_BaseN         => [ -background => q{#000000}, -foreground => q{#0099ff} ],
    -shek_BString       => [ -background => q{#000000}, -foreground => q{#cc99ff} ],
    -shek_Char          => [ -background => q{#000000}, -foreground => q{#9966cc} ],
    -shek_Comment       => [ -background => q{#000000}, -foreground => q{#666666} ],
    -shek_DataType      => [ -background => q{#000000}, -foreground => q{#0066ff} ],
    -shek_DecVal        => [ -background => q{#000000}, -foreground => q{#00ccff} ],
    -shek_Error         => [ -background => q{#000000}, -foreground => q{#ff3333} ],
    -shek_Float         => [ -background => q{#000000}, -foreground => q{#339999} ],
    -shek_Function      => [ -background => q{#000000}, -foreground => q{#00ffff} ],
    -shek_IString       => [ -background => q{#000000}, -foreground => q{#ff6699} ],
    -shek_Keyword       => [ -background => q{#000000}, -foreground => q{#ffff00} ],
    -shek_Normal        => [ -background => q{#000000}, -foreground => q{#ffffff} ],
    -shek_Operator      => [ -background => q{#000000}, -foreground => q{#cc6633} ],
    -shek_Others        => [ -background => q{#000000}, -foreground => q{#cc9966} ],
    -shek_RegionMarker  => [ -background => q{#000000}, -foreground => q{#99ccff} ],
    -shek_Reserved      => [ -background => q{#000000}, -foreground => q{#9999ff} ],
    -shek_String        => [ -background => q{#000000}, -foreground => q{#00cc00} ],
    -shek_Variable      => [ -background => q{#000000}, -foreground => q{#33cccc} ],
    -shek_Warning       => [ -background => q{#000000}, -foreground => q{#ff9933} ],
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


...
END_CODE

eval { $rosyn->insert($code_for_scrolling); };

ok(! $EVAL_ERROR, q{Test text insertion})
    or diag $EVAL_ERROR;

my $exit_button
    = $mw->Button(-text => q{Exit}, -command => sub { exit; })->pack();

if (! $ENV{CPAN_TEST_AUTHOR}) {
    $exit_button->invoke();
}

MainLoop;

