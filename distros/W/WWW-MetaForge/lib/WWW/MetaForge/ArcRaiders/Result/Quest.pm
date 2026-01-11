package WWW::MetaForge::ArcRaiders::Result::Quest;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Quest result object
our $VERSION = '0.002';
use Moo;
use Types::Standard qw(Str Int ArrayRef HashRef Maybe);
use namespace::clean;

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

has type => (
  is  => 'ro',
  isa => Maybe[Str],
);

has description => (
  is  => 'ro',
  isa => Maybe[Str],
);

has objectives => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [] },
);

has required_items => (
  is      => 'ro',
  isa     => ArrayRef[HashRef],
  default => sub { [] },
);

has rewards => (
  is      => 'ro',
  isa     => ArrayRef[HashRef],
  default => sub { [] },
);

has xp_reward => (
  is  => 'ro',
  isa => Maybe[Int],
);

has reputation_reward => (
  is  => 'ro',
  isa => Maybe[Int],
);

has next_quest => (
  is  => 'ro',
  isa => Maybe[Int],
);

has prev_quest => (
  is  => 'ro',
  isa => Maybe[Int],
);

has last_updated => (
  is  => 'ro',
  isa => Maybe[Str],
);

has _raw => (
  is  => 'ro',
  isa => HashRef,
);

sub from_hashref {
  my ($class, $data) = @_;
  return $class->new(
    id                => $data->{id},
    name              => $data->{name},
    type              => $data->{type},
    description       => $data->{description},
    objectives        => $data->{objectives} // [],
    required_items    => $data->{requiredItems} // [],
    rewards           => $data->{rewards} // [],
    xp_reward         => $data->{xpReward},
    reputation_reward => $data->{reputationReward},
    next_quest        => $data->{nextQuest},
    prev_quest        => $data->{prevQuest},
    last_updated      => $data->{lastUpdated},
    _raw              => $data,
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::Result::Quest - Quest result object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $quests = $api->quests(type => 'StoryQuest');
  for my $quest (@$quests) {
      say $quest->name;
      say "  " . $_ for $quest->objectives->@*;
  }

=head1 DESCRIPTION

Represents a quest from the ARC Raiders game.

=head2 id

Quest identifier (string slug).

=head2 name

Quest name.

=head2 type

Quest type (e.g., "StoryQuest", "SideQuest").

=head2 description

Quest description text.

=head2 objectives

ArrayRef of objective strings.

=head2 required_items

ArrayRef of required items: C<[{ item => "Name", quantity => 5 }]>.

=head2 rewards

ArrayRef of rewards: C<[{ item => "Name", quantity => 1 }, { coins => 500 }]>.

=head2 xp_reward

Experience points reward.

=head2 reputation_reward

Reputation points reward.

=head2 next_quest

ID of next quest in chain.

=head2 prev_quest

ID of previous quest in chain.

=head2 last_updated

ISO timestamp of last data update.

=head2 from_hashref

  my $quest = WWW::MetaForge::ArcRaiders::Result::Quest->from_hashref(\%data);

Construct from API response.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-metaforge/issues>.

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
