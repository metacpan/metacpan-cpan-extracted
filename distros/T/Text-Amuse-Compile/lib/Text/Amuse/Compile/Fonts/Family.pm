package Text::Amuse::Compile::Fonts::Family;
use utf8;
use strict;
use warnings;
use Types::Standard qw/Str Enum StrMatch InstanceOf Bool HashRef ArrayRef/;
use Moo;
use Text::Amuse::Utils;

=head1 NAME

Text::Amuse::Compile::Fonts::Family - font family object

=head1 ACCESSORS

=head2 name

The font family name. Required.

=head2 desc

The font family description. Arbitrary string. Required.

=head2 type

The font type: must be serif, sans or mono.

=head1 FONT FILES

These accessors aren't strictly required. If provided, they should be
an instance of L<Text::Amuse::Compile::Fonts::File>.

=head2 regular

=head2 italic

=head2 bold

=head2 bolditalic

=head2 languages

An optional arrayref of language codes.

=head1 METHODS

=head2 has_files

Return true if all the 4 font slots are filled. This means we know the
physical location of the files, not just its name.

=head2 is_sans

Return true if the family is a sans font

=head2 is_mono

Return true if the family is a mono font

=head2 is_serif

Return true if the family is a serif font

=head2 font_files

Return an arrayref with the four L<Text::Amuse::Compile::Fonts::File>
objects.

=head2 language_names

An arrayref with the C<language> codes mapped to their babel equivalent.

=head2 has_languages

Return true if the font family has languages set.

=head2 for_babel_language($babel_lang)

=head2 for_language_code($iso_code)

Return true if the family has the given language set (babel and iso version)

=head2 babel_font_name

=head2 babel_font_options

=cut


has name => (is => 'ro',
             isa => StrMatch[ qr{\A[a-zA-Z0-9 ]+\z} ],
             required => 1);

has desc => (is => 'ro',
             isa => Str,
             required => 1);

has type => (is => 'ro',
             required => 1,
             isa => Enum[qw/serif sans mono/]);

has regular    => (is => 'ro', isa => InstanceOf[qw/Text::Amuse::Compile::Fonts::File/]);
has italic     => (is => 'ro', isa => InstanceOf[qw/Text::Amuse::Compile::Fonts::File/]);
has bold       => (is => 'ro', isa => InstanceOf[qw/Text::Amuse::Compile::Fonts::File/]);
has bolditalic => (is => 'ro', isa => InstanceOf[qw/Text::Amuse::Compile::Fonts::File/]);

has has_files => (is => 'lazy', isa => Bool);

sub _build_has_files {
    my $self = shift;
    if ($self->regular &&
        $self->italic &&
        $self->bold &&
        $self->bolditalic) {
        return 1;
    }
    return 0;
}

has languages => (is => 'ro', isa => ArrayRef, default => sub { [] });

has language_names => (is => 'lazy', isa => ArrayRef);

sub _build_language_names {
    my $self = shift;
    return [ map { Text::Amuse::Utils::get_latex_lang($_) } @{ $self->languages } ];
}

has babel_font_args => (is => 'lazy', isa => HashRef);

sub _build_babel_font_args {
    my $self = shift;
    my $name = $self->name;
    my @args;
    if ($self->has_files) {
        my $regular;
        if ($self->regular->dirname  =~ m/\A([A-Za-z0-9\.\/_-]+)\z/) {
            push @args, Path => $1;
            $name = $regular = $self->regular->basename_and_ext;
        }
        else {
            warn $self->regular->dirname . " does not look like a path which can be embedded." .
              " Please make sure the fonts are installed in a standard TeX location\n";
        }
        if ($regular) {
            my %shapes = (
                          bold => 'BoldFont',
                          italic => 'ItalicFont',
                          bolditalic => 'BoldItalicFont',
                         );
            foreach my $shape (sort keys %shapes) {
                if (my $file = $self->$shape->basename_and_ext) {
                    push @args, $shapes{$shape}, $file;
                }
            }
        }
    }
    return {
            name => $name,
            opts => \@args,
           };
}

sub babel_font_name {
    shift->babel_font_args->{name};
}

sub babel_font_options {
    my ($self, @args) = @_;
    die "args must come in pairs" if @args % 2;
    push @args, @{$self->babel_font_args->{opts} || [] };
    my @list;
    while (my @pair = splice @args, 0, 2) {
        push @list, join('=', @pair);
    }
    return join(",%\n ", @list)
}

sub is_serif {
    return shift->type eq 'serif';
}

sub is_mono {
    return shift->type eq 'mono';
}

sub is_sans {
    return shift->type eq 'sans';
}

sub font_files {
    my $self = shift;
    return [ $self->regular, $self->italic, $self->bold, $self->bolditalic ];
}

sub has_languages {
    return scalar(@{shift->language_names});
}

sub for_babel_language {
    my ($self, $lang) = @_;
    return scalar(grep { $lang eq $_ } @{$self->language_names});
}

sub for_language_code {
    my ($self, $lang) = @_;
    return scalar(grep { $lang eq $_ } @{$self->languages});
}


1;
