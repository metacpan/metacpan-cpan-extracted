package Text::Amuse::Compile::Fonts::Family;
use utf8;
use strict;
use warnings;
use Types::Standard qw/Str Enum StrMatch InstanceOf/;
use Moo;

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

sub has_files {
    my $self = shift;
    if ($self->regular &&
        $self->italic &&
        $self->bold &&
        $self->bolditalic) {
        return 1;
    }
    return 0;
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

1;
