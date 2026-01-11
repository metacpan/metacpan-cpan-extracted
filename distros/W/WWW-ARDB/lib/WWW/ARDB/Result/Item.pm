package WWW::ARDB::Result::Item;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: Item result object for WWW::ARDB

use Moo;
use Types::Standard qw( Str Int Num ArrayRef HashRef Maybe );
use namespace::clean;

our $VERSION = '0.002';


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

version 0.002

=head1 SYNOPSIS

    my $item = $api->item('acoustic_guitar');

    print $item->name;          # "Acoustic Guitar"
    print $item->rarity;        # "legendary"
    print $item->type;          # "quick use"
    print $item->value;         # 7000
    print $item->icon_url;      # Full URL to icon

=head1 DESCRIPTION

Result object representing an item from the ARC Raiders Database. Created via
L<WWW::ARDB> methods like C<items()> and C<item()>.

=head2 id

String. Unique identifier for the item (e.g., C<acoustic_guitar>).

=head2 name

String. Display name of the item.

=head2 description

String or undef. Item description text.

=head2 rarity

String or undef. Rarity level: C<legendary>, C<epic>, C<rare>, C<uncommon>, C<common>.

=head2 type

String or undef. Item category (e.g., C<quick use>, C<weapon>, C<armor>).

=head2 value

Number or undef. Item value in credits.

=head2 weight

Number or undef. Item weight.

=head2 stack_size

Integer or undef. Maximum stack size for the item.

=head2 icon

String or undef. Path to icon image (use C<icon_url()> for full URL).

=head2 found_in

ArrayRef of Strings. Locations where this item can be found.

=head2 maps

ArrayRef. Maps where this item appears.

=head2 breakdown

ArrayRef of HashRefs. Components obtained when breaking down this item.
Only populated for detail endpoint (C<item($id)>).

=head2 crafting

ArrayRef of HashRefs. Materials required to craft this item.
Only populated for detail endpoint (C<item($id)>).

=head2 updated_at

String or undef. ISO 8601 timestamp of last update.

=head2 from_hashref

    my $item = WWW::ARDB::Result::Item->from_hashref($data);

Class method. Constructs an Item object from API response data (HashRef).

=head2 icon_url

    my $url = $item->icon_url;

Returns the full URL to the item's icon image, or undef if no icon is set.
Automatically prepends C<https://ardb.app> to relative paths.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-ardb/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
