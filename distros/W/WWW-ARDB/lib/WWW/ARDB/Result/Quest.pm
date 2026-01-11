package WWW::ARDB::Result::Quest;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: Quest result object for WWW::ARDB

use Moo;
use Types::Standard qw( Str Int Num ArrayRef HashRef Maybe );
use namespace::clean;

our $VERSION = '0.002';


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

version 0.002

=head1 SYNOPSIS

    my $quest = $api->quest('picking_up_the_pieces');

    print $quest->title;           # "Picking Up The Pieces"
    print $quest->trader_name;     # "Shani"
    print $quest->trader_type;     # "Security"

    for my $step (@{$quest->steps}) {
        printf "- %s (x%d)\n", $step->{title}, $step->{amount};
    }

=head1 DESCRIPTION

Result object representing a quest from the ARC Raiders Database. Created via
L<WWW::ARDB> methods like C<quests()> and C<quest()>.

=head2 id

String. Unique identifier for the quest (e.g., C<picking_up_the_pieces>).

=head2 title

String. Quest title.

=head2 description

String or undef. Quest description or narrative text.

=head2 maps

ArrayRef of HashRefs. Available maps/locations for this quest.

=head2 steps

ArrayRef of HashRefs. Quest objectives, each with C<title> and C<amount>.

=head2 trader

HashRef or undef. Quest giver information including C<id>, C<name>, C<type>,
C<description>, C<image>, C<icon>.

=head2 required_items

ArrayRef of HashRefs. Items needed to complete the quest.

=head2 rewards

ArrayRef of HashRefs. Quest completion rewards.
Only populated for detail endpoint (C<quest($id)>).

=head2 xp_reward

Number or undef. Experience points awarded for completing the quest.

=head2 updated_at

String or undef. ISO 8601 timestamp of last update.

=head2 from_hashref

    my $quest = WWW::ARDB::Result::Quest->from_hashref($data);

Class method. Constructs a Quest object from API response data (HashRef).

=head2 trader_name

    my $name = $quest->trader_name;

Returns the quest giver's name, or undef if no trader is set.

=head2 trader_type

    my $type = $quest->trader_type;

Returns the quest giver's type/profession (e.g., C<Security>), or undef if no
trader is set.

=head2 map_names

    my $names = $quest->map_names;

Returns an ArrayRef of map names where the quest is available.

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
