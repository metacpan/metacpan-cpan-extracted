package Text::Amuse::Compile::Fonts::Selected;
use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/InstanceOf Enum Bool/;

=head1 NAME

Text::Amuse::Compile::Fonts::Selected - simple class to hold selected fonts

=head1 ACCESSORS

All are read-only instances of L<Text::Amuse::Compile::Fonts::Family>.

=head2 main

=head2 sans

=head2 mono

=head2 size

=head2 luatex

Boolean if running under luatex

=head2 all_fonts

The instance of L<Text::Amuse::Compile::Fonts> carrying all available
fonts.

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

=item main_is_rtl

Boolean if main language is RTL

=item is_slide

Boolean if for beamer

=item captions

Custom locale strings. See L<Text::Amuse::Utils::language_code_locale_captions>

=back

=head2 families

Return an arrayref with the C<mono>, C<sans> and C<main> objects.

=cut

has mono => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has sans => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has main => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has size => (is => 'ro', default => sub { 10 }, isa => Enum[9..14]);
has all_fonts => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts']);
has luatex => (is => 'ro', default => sub { 0 }, isa => Bool);

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
    my $main_lang = $args{lang} || 'english';
    my @langs = (@{ $args{others} || [] }, $main_lang);
    my $babel_langs = join(',', @langs) . ",shorthands=off";
    my $bidi_schema = 'basic';
    unless ($self->luatex) {
        $bidi_schema = $args{main_is_rtl} ? 'bidi-r' : 'bidi-l';
    }
    my $bidi = $args{bidi} ? ", bidi=$bidi_schema" : "";
    BABELFONTS: {
        if (Text::Amuse::Utils::has_babel_ldf($main_lang)) {
            # one or more is missing, load the main from ldf, others from ini
            if (grep { !Text::Amuse::Utils::has_babel_ldf($_) } @{ $args{others} || []}) {
                push @out, "\\usepackage[$babel_langs,provide+=*${bidi}]{babel}";
            }
            else {
                # load everything with the standard ldf
                push @out, "\\usepackage[${babel_langs}${bidi}]{babel}";
            }
        }
        else {
            push @out, "\\usepackage[$babel_langs,provide*=*${bidi}]{babel}";
        }
        my %slots = (qw/main rm
                        mono tt
                        sans sf/);
        foreach my $slot (sort keys %slots) {
            # check all the available fonts if there are language specific
            foreach my $lang (reverse @langs) {
                my $font = $self->_font_for_slot_and_lang($slot, $lang);
                my @font_opts = $slot eq 'main' ? () : (qw/Scale MatchLowercase/);
                if ($lang eq $main_lang) {
                    push @out, sprintf("\\babelfont{%s}[%s]{%s}",
                                       $slots{$slot},
                                       $font->babel_font_options(@font_opts),
                                       $font->babel_font_name);
                }
                else {
                    push @out, sprintf("\\babelfont[%s]{%s}[%s]{%s}",
                                       $lang,
                                       $slots{$slot},
                                       $font->babel_font_options(@font_opts),
                                       $font->babel_font_name);
                }
            }
        }
    }
    my %cjk = (
               japanese => 1,
               korean => 1,
               chinese => 1,
              );

    if ($cjk{$main_lang}) {
        # these will die with luatex. Too bad.
        #  right now we’re using Song for sans and Kai for sf
        # https://github.com/adobe-fonts/source-han-serif/releases/download/2.000R/SourceHanSerifCN.zip
        # https://github.com/adobe-fonts/source-han-sans/releases/download/2.004R/SourceHanSansCN.zip
        # load all languages with ini files
        push @out, "\\usepackage{xeCJK}";
        foreach my $slot (qw/main mono sans/) {
            # original lang
            my $font = $self->_font_for_slot_and_lang($slot, $main_lang);
            push @out, sprintf("\\setCJK${slot}font{%s}[%s]",
                               $font->babel_font_name,
                               $font->babel_font_options,
                              );
        }
    }
    if (my $custom = $args{captions}) {
        if (my $base = delete $custom->{_base_}) {
            foreach my $k (sort keys %$custom) {
                push @out, "\\setlocalecaption{$base}{$k}{$custom->{$k}}";
            }
        }
    }
    if ($args{has_ruby}) {
        push @out, "\\usepackage{ruby}";
    }
    push @out, '';
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
                   greek      => 'Greek',
                  );
    my $def = $self->definitions->{$slot} or die "bad usage, can't find $slot";
    my $script = $scripts{$language} || 'Latin';
    my @list = ("Ligatures=TeX");
    my @shapes = sort values %{ $self->_shape_mapping };
    foreach my $att (qw/Scale Path/, @shapes) {
        if (my $v = $def->{attr}->{$att}) {
            push @list, "$att=$v";
        }
    }
    return sprintf('{%s}[%s]', $def->{name}, join(",%\n ", @list));
}

sub families {
    my $self = shift;
    return [ $self->main, $self->mono, $self->sans ];
}

sub _font_for_slot_and_lang {
    my ($self, $slot, $lang) = @_;
    my $font = $self->$slot;
    if (my @language_specific = $self->all_fonts->fonts_for_language($slot, $lang)) {
        # there are other fonts setting the lang
        unless ($font->for_babel_language($lang)) {
            $font = $language_specific[0];
        }
    }
    return $font;
}


1;
