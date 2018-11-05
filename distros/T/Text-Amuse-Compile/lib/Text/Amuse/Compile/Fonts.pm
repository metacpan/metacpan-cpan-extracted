package Text::Amuse::Compile::Fonts;
use utf8;
use strict;
use warnings;
use Types::Standard qw/ArrayRef InstanceOf/;
use JSON::MaybeXS qw/decode_json/;
use Text::Amuse::Compile::Fonts::Family;
use Text::Amuse::Compile::Fonts::File;
use Moo;

=head1 NAME

Text::Amuse::Compile::Fonts - class for fonts management

=head1 SYNOPSIS

    # hash to hold the fonts file, where $wd is the font directory
    my %fontfiles = map { $_ => File::Spec->catfile($wd, $_ . '.otf') } (qw/regular italic
                                                                            bold bolditalic/);
    my $fonts = Text::Amuse::Compile::Fonts->new([
                                                  {
                                                   name => 'Example Serif',
                                                   type => 'serif',
                                                   desc => 'example font',
                                                   regular => $fontfiles{regular},
                                                   italic => $fontfiles{italic},
                                                   bold => $fontfiles{bold},
                                                   bolditalic => $fontfiles{bolditalic},
                                                  },
                                                  # more fonts here
                                                 ]);
    # or you can pass the same structure if you got it serialized to
    # json and saved to a file.
    my $fonts = Text::Amuse::Compile::Fonts->new($json_file);
    my @fonts = $fonts->all_fonts;


=head1 DESCRIPTION

This class has the purpose to hold the list of available fonts, which
has to be provided to the constructor via a json file or as an
arrayref of L<Text::Amuse::Compile::Fonts::Family> objects.

To build a json file with some default fonts, you may want to try
L<the muse-create-font-file.pl> script installed with this
distribution.

=head1 CONSTRUCTOR

=head2 new($file_or_arrayref_with_fonts)

The constructor accept either a file or an arrayref with fonts specifications.

Each font specification is used to construct a
L<Text::Amuse::Compile::Fonts::Family> object, which in turn may
contain L<Text::Amuse::Compile::Fonts::File> objects.

Keys of the hashref inside the arrayref:

=over 4

=item name

The name of the font. This is the system name, something that
fontconfig will understand. You can try with fc-list to see if you can
find it. Mandatory.

=item type

The type of the file. Can be either C<serif>, C<sans> or C<mono>.
Mandatory.

=item desc

An optional free form description.

=item regular

The path to the regular font file (.ttf or .otf or .woff)

=item italic

The path to the italic font file (.ttf or .otf or .woff)

=item bold

The path to the bold font file (.ttf or .otf or .woff)

=item bolditalic

The path to the bolditalic font file (.ttf or .otf or .woff)

=back

Please note that the paths to the files are optional. They are used
only for the EPUB generation, when the files are embedded in the final
file.

Also note that the name of the fonts is not arbitrary. Fontconfig
needs to recognize it for a successful LaTeX compilation.

=head1 ACCESSORS

=head2 list

The arrayref with the L<Text::Amuse::Compile::Fonts::Family> objects.

=head1 METHODS

=head2 all_fonts

Return the list of fonts, as a plain list

=head2 serif_fonts

As above, but only the serif fonts

=head2 mono_fonts

As above, but only the mono fonts

=head2 sans_fonts

As above, but only the sans fonts

=head2 all_fonts_with_files

Return the list of fonts which have the paths to the font file.

=head2 serif_fonts_with_files

As above, but only the serif fonts

=head2 mono_fonts_with_files

As above, but only the mono fonts

=head2 sans_fonts_with_files

As above, but only the sans fonts

=head2 default_font_list

Return an arrayref with the default font definitions

=head1 INTERNALS

=head2 BUILDARGS

Construct the font list from either the data structure or the file path.

=cut

has list => (is => 'ro',
             isa => ArrayRef[InstanceOf['Text::Amuse::Compile::Fonts::Family']]);

sub all_fonts {
    my $self = shift;
    return @{$self->list};
}

sub serif_fonts {
    my $self = shift;
    return grep { $_->is_serif } @{$self->list};
}

sub mono_fonts {
    my $self = shift;
    return grep { $_->is_mono } @{$self->list};
}

sub sans_fonts {
    my $self = shift;
    return grep { $_->is_sans } @{$self->list};
}

sub all_fonts_with_files {
    my $self = shift;
    return grep { $_->has_files } @{$self->list};
}

sub serif_fonts_with_files {
    my $self = shift;
    return grep { $_->is_serif && $_->has_files } @{$self->list};
}

sub sans_fonts_with_files {
    my $self = shift;
    return grep { $_->is_sans && $_->has_files } @{$self->list};
}

sub mono_fonts_with_files {
    my $self = shift;
    return grep { $_->is_mono && $_->has_files } @{$self->list};
}

sub BUILDARGS {
    my ($class, $arg) = @_;
    my $list;
    if ($arg) {
        if (my $ref = ref($arg)) {
            if ($ref eq 'ARRAY') {
                $list = $arg;
            }
            else {
                die "Argument to ->new must be either a file or an arrayref";
            }
        }
        else {
            eval {
                open (my $fh, '<', $arg) or die "Cannot open $arg $!";
                local $/ = undef;
                my $body = <$fh>;
                close $fh;
                $list = decode_json($body);
            };
            $list = undef if $@;
        }
    }
    $list ||= $class->default_font_list;
    my @out;
    foreach my $fontref (@$list) {
        my $font = { %$fontref }; # do a copy do avoid mangling the argument.
        if ($font->{name} and $font->{type}) {
            $font->{desc} ||= $font->{name};
            foreach my $type (qw/regular bold italic bolditalic/) {
                if (my $file = delete $font->{$type}) {
                    my $obj = Text::Amuse::Compile::Fonts::File->new(file => $file,
                                                                     shape => $type
                                                                    );
                    $font->{$type} = $obj;
                }
            }
            push @out, Text::Amuse::Compile::Fonts::Family->new(%$font);
        }
    }
    return { list => \@out };
}

sub default_font_list {
    return [
            {
             name => 'CMU Serif',
             desc => 'Computer Modern',
             type => 'serif',
            },
            {
             name => 'DejaVu Serif',
             name => 'DejaVu Serif',
             type => 'serif',
            },
            {
             name => 'FreeSerif',
             name => 'FreeSerif',
             type => 'serif',
            },
            {
             name => 'Linux Libertine O',
             desc => 'Linux Libertine',
             type => 'serif',
            },
            {
             name => 'TeX Gyre Termes',
             desc => 'TeX Gyre Termes (Times)',
             type => 'serif',
            },
            {
             name => 'TeX Gyre Pagella',
             desc => 'TeX Gyre Pagella (Palatino)',
             type => 'serif',
            },
            {
             name => 'TeX Gyre Schola',
             desc => 'TeX Gyre Schola (Century)',
             type => 'serif',
            },
            {
             name => 'TeX Gyre Bonum',
             desc => 'TeX Gyre Bonum (Bookman)',
             type => 'serif',
            },
            { name => 'Coelacanth',     desc => 'Coelacanth (no bolditalic)', type => 'serif' },
            { name => 'Alegreya',       desc => 'Alegreya',       type => 'serif' },
            { name => 'Arvo',           desc => 'Arvo',           type => 'serif' },
            { name => 'Lora',           desc => 'Lora',           type => 'serif' },
            { name => 'Merriweather',   desc => 'Merriweather',   type => 'serif' },
            { name => 'Vollkorn',       desc => 'Vollkorn',       type => 'serif' },
            # arabic
            { name => 'Amiri',          desc => 'Amiri',          type => 'serif' },
            { name => 'Scheherazade',   desc => 'Scheherazade',   type => 'serif' },
            {
             name => 'Antykwa Poltawskiego',
             desc => 'Antykwa Półtawskiego',
             type => 'serif',
            },
            {
             name => 'Antykwa Torunska',
             desc => 'Antykwa Toruńska',
             type => 'serif',
            },
            {
             name => 'Charis SIL',
             desc => 'Charis SIL (Bitstream Charter)',
             type => 'serif',
            },
            {
             name => 'PT Serif',
             desc => 'Paratype (cyrillic)',
             type => 'serif',
            },
            {
             name => 'Noto Serif',
             desc => 'Noto Serif',
             type => 'serif',
            },
            {
             name => 'Gentium Book Basic',
             desc => 'Gentium',
             type => 'serif',
            },
            {
             name => 'Cormorant Garamond',
             desc => 'Garamond',
             type => 'serif',
            },
            {
             name => 'CMU Sans Serif',
             desc => 'Computer Modern Sans Serif',
             type => 'sans',
            },
            {
             name => 'TeX Gyre Heros',
             desc => 'TeX Gyre Heros (Helvetica)',
             type => 'sans',
            },
            {
             name => 'TeX Gyre Adventor',
             desc => 'TeX Gyre Adventor (Avant Garde Gothic)',
             type => 'sans',
            },
            {
             name => 'Iwona',
             desc => 'Iwona',
             type => 'sans',
            },
            {
             name => 'DejaVu Sans',
             desc => 'DejaVu Sans',
             type => 'sans',
            },
            {
             name => 'PT Sans',
             desc => 'PT Sans (cyrillic)',
             type => 'sans',
            },
            {
             name => 'Noto Sans',
             desc => 'Noto Sans',
             type => 'sans',
            },
            { name => 'Alegreya Sans',   desc => 'Alegreya Sans',   type => 'sans' },
            { name => 'Archivo Narrow',  desc => 'Archivo Narrow',  type => 'sans' },
            { name => 'Fira Sans',      desc => 'Fira Sans',      type => 'sans' },
            { name => 'Karla',          desc => 'Karla',          type => 'sans' },
            { name => 'Libre Franklin', desc => 'Libre Franklin', type => 'sans' },
            { name => 'Poppins',        desc => 'Poppins',        type => 'sans' },
            { name => 'Rubik',          desc => 'Rubik',          type => 'sans' },
            { name => 'Source Sans Pro',  desc => 'Source Sans Pro',  type => 'sans' },
            {
             name => 'CMU Typewriter Text',
             desc => 'Computer Modern Typewriter Text',
             type => 'mono',
            },
            {
             name => 'DejaVu Sans Mono',
             desc => 'DejaVu Sans Mono',
             type => 'mono',
            },
            {
             name => 'TeX Gyre Cursor',
             desc => 'TeX Gyre Cursor (Courier)',
             type => 'mono',
            },
            { name => 'Anonymous Pro', desc => 'Anonymous Pro', type => 'mono' },
            { name => 'Space Mono',    desc => 'Space Mono',    type => 'mono' },
           ];
}


1;
