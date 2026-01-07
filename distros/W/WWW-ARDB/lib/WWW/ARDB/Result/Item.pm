package WWW::ARDB::Result::Item;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: Item result object for WWW::ARDB

use Moo;
use Types::Standard qw( Str Int Num ArrayRef HashRef Maybe );
use namespace::clean;

our $VERSION = '0.001';

has id => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has description => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

has rarity => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

has type => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

has value => (
    is      => 'ro',
    isa     => Maybe[Num],
    default => sub { undef },
);

has weight => (
    is      => 'ro',
    isa     => Maybe[Num],
    default => sub { undef },
);

has stack_size => (
    is      => 'ro',
    isa     => Maybe[Int],
    default => sub { undef },
);

has icon => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

has found_in => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has maps => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has breakdown => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has crafting => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has updated_at => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

has _raw => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

sub from_hashref {
    my ($class, $data) = @_;

    return $class->new(
        id          => $data->{id},
        name        => $data->{name},
        description => $data->{description},
        rarity      => $data->{rarity},
        type        => $data->{type},
        value       => $data->{value},
        weight      => $data->{weight},
        stack_size  => $data->{stackSize},
        icon        => $data->{icon},
        found_in    => $data->{foundIn} // [],
        maps        => $data->{maps} // [],
        breakdown   => $data->{breakdown} // [],
        crafting    => $data->{crafting} // [],
        updated_at  => $data->{updatedAt},
        _raw        => $data,
    );
}

sub icon_url {
    my $self = shift;
    return unless $self->icon;
    return 'https://ardb.app' . $self->icon if $self->icon =~ m{^/};
    return $self->icon;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::Result::Item - Item result object for WWW::ARDB

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $item = $api->item('acoustic_guitar');

    print $item->name;          # "Acoustic Guitar"
    print $item->rarity;        # "legendary"
    print $item->type;          # "quick use"
    print $item->value;         # 7000
    print $item->icon_url;      # Full URL to icon

=head1 NAME

WWW::ARDB::Result::Item - Item result object for WWW::ARDB

=head1 ATTRIBUTES

=head2 id

String. Unique identifier.

=head2 name

String. Display name.

=head2 description

String or undef. Item description.

=head2 rarity

String or undef. Rarity level (legendary, epic, rare, uncommon, common).

=head2 type

String or undef. Item category.

=head2 value

Number or undef. Item value.

=head2 weight

Number or undef. Item weight.

=head2 stack_size

Integer or undef. Maximum stack size.

=head2 icon

String or undef. Path to icon image.

=head2 found_in

ArrayRef. Locations where item can be found.

=head2 maps

ArrayRef. Maps where item appears.

=head2 breakdown

ArrayRef. Components when item is broken down (detail endpoint only).

=head2 crafting

ArrayRef. Crafting requirements (detail endpoint only).

=head2 updated_at

String or undef. ISO 8601 timestamp of last update.

=head1 METHODS

=head2 from_hashref($data)

Class method. Creates an Item object from API response data.

=head2 icon_url

Returns the full URL to the item's icon, or undef if no icon.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-ardb>

  git clone https://github.com/Getty/p5-www-ardb.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
