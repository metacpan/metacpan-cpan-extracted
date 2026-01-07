package WWW::ARDB::Result::Quest;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: Quest result object for WWW::ARDB

use Moo;
use Types::Standard qw( Str Int Num ArrayRef HashRef Maybe );
use namespace::clean;

our $VERSION = '0.001';

has id => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has title => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has description => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

has maps => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has steps => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has trader => (
    is      => 'ro',
    isa     => Maybe[HashRef],
    default => sub { undef },
);

has required_items => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has rewards => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has xp_reward => (
    is      => 'ro',
    isa     => Maybe[Num],
    default => sub { undef },
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
        id             => $data->{id},
        title          => $data->{title},
        description    => $data->{description},
        maps           => $data->{maps} // [],
        steps          => $data->{steps} // [],
        trader         => $data->{trader},
        required_items => $data->{requiredItems} // [],
        rewards        => $data->{rewards} // [],
        xp_reward      => $data->{xpReward},
        updated_at     => $data->{updatedAt},
        _raw           => $data,
    );
}

sub trader_name {
    my $self = shift;
    return unless $self->trader;
    return $self->trader->{name};
}

sub trader_type {
    my $self = shift;
    return unless $self->trader;
    return $self->trader->{type};
}

sub map_names {
    my $self = shift;
    return [ map { $_->{name} } @{$self->maps} ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::Result::Quest - Quest result object for WWW::ARDB

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $quest = $api->quest('picking_up_the_pieces');

    print $quest->title;           # "Picking Up The Pieces"
    print $quest->trader_name;     # "Shani"
    print $quest->trader_type;     # "Security"

    for my $step (@{$quest->steps}) {
        printf "- %s (x%d)\n", $step->{title}, $step->{amount};
    }

=head1 NAME

WWW::ARDB::Result::Quest - Quest result object for WWW::ARDB

=head1 ATTRIBUTES

=head2 id

String. Unique identifier.

=head2 title

String. Quest title.

=head2 description

String or undef. Quest description/narrative.

=head2 maps

ArrayRef. Available maps/locations for the quest.

=head2 steps

ArrayRef of HashRefs. Quest objectives with C<title> and C<amount>.

=head2 trader

HashRef or undef. Quest giver information with C<id>, C<name>, C<type>,
C<description>, C<image>, C<icon>.

=head2 required_items

ArrayRef. Items needed to complete the quest.

=head2 rewards

ArrayRef. Quest completion rewards (detail endpoint only).

=head2 xp_reward

Number or undef. Experience points awarded.

=head2 updated_at

String or undef. ISO 8601 timestamp of last update.

=head1 METHODS

=head2 from_hashref($data)

Class method. Creates a Quest object from API response data.

=head2 trader_name

Returns the quest giver's name, or undef.

=head2 trader_type

Returns the quest giver's type/profession, or undef.

=head2 map_names

Returns an ArrayRef of map names where the quest is available.

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
