package Text::Amuse::Compile::Fonts::Selected;
use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/InstanceOf Enum/;

=head1 NAME

Text::Amuse::Compile::Fonts::Selected - simple class to hold selected fonts

=head1 ACCESSORS

All are read-only instances of L<Text::Amuse::Compile::Fonts::Family>.

=head2 main

=head2 sans

=head2 mono

=head2 size

=head1 METHODS

=head2 compose_polyglossia_fontspec_stanza(lang => 'english', others => [qw/russian farsi/], bidi => 1)

The place to produce this stanza is a bit weird, but fontspec and
polyglossia are tighly coupled.

Named arguments:

=over 4

=item lang

The main language.

=item others

The other languages as arrayref

=item bidi

Boolean if bidirectional

=item is_slide

Boolean if for beamer

=back

=cut

has mono => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has sans => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has main => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has size => (is => 'ro', default => sub { 10 }, isa => Enum[9..14]);

sub compose_polyglossia_fontspec_stanza {
    my ($self, %args) = @_;

    my @out;

    push @out, <<'STANDARD';
\usepackage{microtype}
\usepackage{graphicx}
\usepackage{alltt}
\usepackage{verbatim}
\usepackage[shortlabels]{enumitem}
\usepackage{tabularx}
\usepackage[normalem]{ulem}
\def\hsout{\bgroup \ULdepth=-.55ex \ULset}
% https://tex.stackexchange.com/questions/22410/strikethrough-in-section-title
% Unclear if \protect \hsout is needed. Doesn't looks so
\DeclareRobustCommand{\sout}[1]{\texorpdfstring{\hsout{#1}}{#1}}
\usepackage{wrapfig}

% avoid breakage on multiple <br><br> and avoid the next [] to be eaten
\newcommand*{\forcelinebreak}{\strut\\*{}}

\newcommand*{\hairline}{%
  \bigskip%
  \noindent \hrulefill%
  \bigskip%
}

% reverse indentation for biblio and play

\newenvironment*{amusebiblio}{
  \leftskip=\parindent
  \parindent=-\parindent
  \smallskip
  \indent
}{\smallskip}

\newenvironment*{amuseplay}{
  \leftskip=\parindent
  \parindent=-\parindent
  \smallskip
  \indent
}{\smallskip}

\newcommand*{\Slash}{\slash\hspace{0pt}}

STANDARD

    unless($args{is_slide}) {
        push @out, <<'HYPERREF';
% http://tex.stackexchange.com/questions/3033/forcing-linebreaks-in-url
\PassOptionsToPackage{hyphens}{url}\usepackage[hyperfootnotes=false,hidelinks,breaklinks=true]{hyperref}
\usepackage{bookmark}
HYPERREF
    }

    push @out, "\\usepackage{fontspec}";
    push @out, "\\usepackage{polyglossia}";

    # main language
    my $orig_lang = $args{lang} || 'english';

    my %aliases = (
                   # pre texlive-2020
                   # macedonian => 'russian',
                   serbian => 'croatian',
                  );

    my $lang = $aliases{$orig_lang} || $orig_lang;
    my %langs = ($lang => 1, map { $aliases{$_} || $_  => 1 } @{ $args{others} || [] } );

    push @out, "\\setmainlanguage{$lang}";
    if (my @other_langs = sort grep { $_ ne $lang } keys %langs) {
        push @out, sprintf('\\setotherlanguages{%s}', join(",", @other_langs));
    }

    foreach my $slot (qw/main mono sans/) {
        # original lang
        push @out, "\\set${slot}font" . $self->_fontspec_args($slot => $lang);
    }

    foreach my $l (sort keys %langs) {
        push @out, "\\newfontfamily\\${l}font" . $self->_fontspec_args(main => $l);
    }

    if ($args{bidi}) {
        push @out, '\\usepackage{bidi}';
    }

    # if disabled, use
    # \newcommand{\footnoteB}[1]{\{\{#1\}\}}

    if ($args{enable_secondary_footnotes}) {
    # bigfoot after bidi
        push @out, <<'BIGFOOT';
% footnote handling
\usepackage[fragile]{bigfoot}
\usepackage{perpage}
\DeclareNewFootnote{default}
BIGFOOT
    }

    push @out, <<'MUSE';
MUSE
    return join("\n", @out);
}

sub _shape_mapping {
    return +{
             bold => 'BoldFont',
             italic => 'ItalicFont',
             bolditalic => 'BoldItalicFont',
            };
}

has definitions => (is => 'lazy');

sub _build_definitions {
    my $self = shift;
    my %definitions;
    foreach my $slot (qw/mono sans main/) {
        my $font = $self->$slot;
        my %definition = (
                          name => $font->name,
                          attr => { $slot eq 'main' ? () : (Scale => 'MatchLowercase' ) },
                         );
        if ($font->has_files) {
            $definition{name} = $font->regular->basename_and_ext;

            my $dirname = $font->regular->dirname;

            # if $dirname have spaces, etc., skip it, and let's hope
            # tex will find them anyway.
            if ($font->regular->dirname  =~ m/\A([A-Za-z0-9\.\/_-]+)\z/) {
                $definition{attr}{Path} = $1;
            }
            else {
                warn $font->regular->dirname . " does not look like a path which can be embedded." .
                  " Please make sure the fonts are installed in a standard TeX location\n";
            }

            my %map = %{$self->_shape_mapping};
            foreach my $method (keys %map) {
                $definition{attr}{$map{$method}} = $font->$method->basename_and_ext;
            }
        }
        $definitions{$slot} = \%definition;
    }
    return \%definitions;
}

sub _fontspec_args {
    my ($self, $slot, $language) = @_;
    $language ||= 'english';
    my %scripts = (
                   macedonian => 'Cyrillic',
                   russian    => 'Cyrillic',
                   farsi      => 'Arabic',
                   arabic     => 'Arabic',
                   hebrew     => 'Hebrew',
                  );
    my $def = $self->definitions->{$slot} or die "bad usage, can't find $slot";
    my $script = $scripts{$language} || 'Latin';
    my @list = ("Script=$script", "Ligatures=TeX");
    my @shapes = sort values %{ $self->_shape_mapping };
    foreach my $att (qw/Scale Path/, @shapes) {
        if (my $v = $def->{attr}->{$att}) {
            push @list, "$att=$v";
        }
    }
    return sprintf('{%s}[%s]', $def->{name}, join(",%\n ", @list));
}

1;
