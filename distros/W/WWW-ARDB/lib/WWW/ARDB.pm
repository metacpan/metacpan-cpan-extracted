package WWW::ARDB;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: Perl client for the ARC Raiders Database API (ardb.app)

use Moo;
use LWP::UserAgent;
use JSON::MaybeXS qw( decode_json );
use Carp qw( croak );
use namespace::clean;

our $VERSION = '0.001';
our $DEBUG = $ENV{WWW_ARDB_DEBUG};

use WWW::ARDB::Cache;
use WWW::ARDB::Request;
use WWW::ARDB::Result::Item;
use WWW::ARDB::Result::Quest;
use WWW::ARDB::Result::ArcEnemy;

has ua => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_ua',
);

sub _build_ua {
    my $self = shift;
    return LWP::UserAgent->new(
        agent   => 'WWW-ARDB/' . $VERSION,
        timeout => 30,
    );
}

has request => (
    is      => 'ro',
    lazy    => 1,
    default => sub { WWW::ARDB::Request->new },
);

has cache => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_cache',
);

sub _build_cache {
    my $self = shift;
    return WWW::ARDB::Cache->new(
        $self->cache_dir ? (cache_dir => $self->cache_dir) : ()
    );
}

has use_cache => (
    is      => 'ro',
    default => 1,
);

has cache_dir => (
    is => 'ro',
);

has debug => (
    is      => 'ro',
    default => sub { $DEBUG // 0 },
);

# Items

sub items {
    my ($self, %params) = @_;
    my $data = $self->_fetch('items', $self->request->items(%params), %params);
    return $self->_to_objects($data, 'WWW::ARDB::Result::Item');
}

sub items_raw {
    my ($self, %params) = @_;
    return $self->_fetch('items', $self->request->items(%params), %params);
}

sub item {
    my ($self, $id, %params) = @_;
    my $data = $self->_fetch("items/$id", $self->request->item($id, %params), %params);
    return $self->_to_object($data, 'WWW::ARDB::Result::Item');
}

sub item_raw {
    my ($self, $id, %params) = @_;
    return $self->_fetch("items/$id", $self->request->item($id, %params), %params);
}

# Quests

sub quests {
    my ($self, %params) = @_;
    my $data = $self->_fetch('quests', $self->request->quests(%params), %params);
    return $self->_to_objects($data, 'WWW::ARDB::Result::Quest');
}

sub quests_raw {
    my ($self, %params) = @_;
    return $self->_fetch('quests', $self->request->quests(%params), %params);
}

sub quest {
    my ($self, $id, %params) = @_;
    my $data = $self->_fetch("quests/$id", $self->request->quest($id, %params), %params);
    return $self->_to_object($data, 'WWW::ARDB::Result::Quest');
}

sub quest_raw {
    my ($self, $id, %params) = @_;
    return $self->_fetch("quests/$id", $self->request->quest($id, %params), %params);
}

# ARC Enemies

sub arc_enemies {
    my ($self, %params) = @_;
    my $data = $self->_fetch('arc-enemies', $self->request->arc_enemies(%params), %params);
    return $self->_to_objects($data, 'WWW::ARDB::Result::ArcEnemy');
}

sub arc_enemies_raw {
    my ($self, %params) = @_;
    return $self->_fetch('arc-enemies', $self->request->arc_enemies(%params), %params);
}

sub arc_enemy {
    my ($self, $id, %params) = @_;
    my $data = $self->_fetch("arc-enemies/$id", $self->request->arc_enemy($id, %params), %params);
    return $self->_to_object($data, 'WWW::ARDB::Result::ArcEnemy');
}

sub arc_enemy_raw {
    my ($self, $id, %params) = @_;
    return $self->_fetch("arc-enemies/$id", $self->request->arc_enemy($id, %params), %params);
}

# Helper methods

sub find_item_by_name {
    my ($self, $name) = @_;
    my $items = $self->items;
    my $lc_name = lc($name);
    for my $item (@$items) {
        return $item if lc($item->name) eq $lc_name;
    }
    return;
}

sub find_item_by_id {
    my ($self, $id) = @_;
    return $self->item($id);
}

sub find_quest_by_title {
    my ($self, $title) = @_;
    my $quests = $self->quests;
    my $lc_title = lc($title);
    for my $quest (@$quests) {
        return $quest if lc($quest->title) eq $lc_title;
    }
    return;
}

sub find_arc_enemy_by_name {
    my ($self, $name) = @_;
    my $enemies = $self->arc_enemies;
    my $lc_name = lc($name);
    for my $enemy (@$enemies) {
        return $enemy if lc($enemy->name) eq $lc_name;
    }
    return;
}

sub clear_cache {
    my ($self, $endpoint) = @_;
    $self->cache->clear($endpoint);
}

# Internal methods

sub _fetch {
    my ($self, $endpoint, $http_request, %params) = @_;

    if ($self->use_cache) {
        my $cached = $self->cache->get($endpoint, \%params);
        if ($cached) {
            $self->_debug("Cache hit for $endpoint");
            return $cached;
        }
    }

    $self->_debug("Fetching $endpoint from API");
    my $response = $self->ua->request($http_request);

    unless ($response->is_success) {
        croak "API request failed: " . $response->status_line;
    }

    my $data = decode_json($response->decoded_content);

    if ($self->use_cache) {
        $self->cache->set($endpoint, \%params, $data);
    }

    return $data;
}

sub _to_objects {
    my ($self, $data, $class) = @_;
    return [] unless $data;
    return [] unless ref($data) eq 'ARRAY';
    return [ map { $class->from_hashref($_) } @$data ];
}

sub _to_object {
    my ($self, $data, $class) = @_;
    return unless $data;
    return unless ref($data) eq 'HASH';
    return $class->from_hashref($data);
}

sub _debug {
    my ($self, $msg) = @_;
    return unless $self->debug;
    warn "[WWW::ARDB] $msg\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB - Perl client for the ARC Raiders Database API (ardb.app)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::ARDB;

    my $api = WWW::ARDB->new;

    # Get all items
    my $items = $api->items;
    for my $item (@$items) {
        printf "%s (%s) - %s\n", $item->name, $item->rarity // 'n/a', $item->type;
    }

    # Get specific item with full details
    my $item = $api->item('acoustic_guitar');
    print $item->description;

    # Get all quests
    my $quests = $api->quests;

    # Get specific quest
    my $quest = $api->quest('picking_up_the_pieces');
    print $quest->title;

    # Get all ARC enemies
    my $enemies = $api->arc_enemies;

    # Get specific enemy with drop table
    my $enemy = $api->arc_enemy('wasp');
    print $enemy->name;

=head1 DESCRIPTION

WWW::ARDB provides a Perl interface to the ARC Raiders Database API at L<https://ardb.app>.

The API provides information about items, quests, and ARC enemies from the
ARC Raiders game.

B<Note:> Per the API documentation, you should store response data using your
own storage solution and refresh it periodically. This module provides caching
to help with that.

=head1 NAME

WWW::ARDB - Perl client for the ARC Raiders Database API (ardb.app)

=head1 ATTRIBUTES

=head2 ua

The L<LWP::UserAgent> instance used for HTTP requests.

=head2 use_cache

Boolean, default true. Whether to cache API responses.

=head2 cache_dir

Optional custom directory for cache files.

=head2 debug

Boolean, default false. Enable debug output. Can also be set via
C<$ENV{WWW_ARDB_DEBUG}>.

=head1 METHODS

=head2 items

    my $items = $api->items;

Returns an ArrayRef of L<WWW::ARDB::Result::Item> objects.

=head2 item($id)

    my $item = $api->item('acoustic_guitar');

Returns a single L<WWW::ARDB::Result::Item> with complete data.

=head2 quests

    my $quests = $api->quests;

Returns an ArrayRef of L<WWW::ARDB::Result::Quest> objects.

=head2 quest($id)

    my $quest = $api->quest('picking_up_the_pieces');

Returns a single L<WWW::ARDB::Result::Quest> with complete data.

=head2 arc_enemies

    my $enemies = $api->arc_enemies;

Returns an ArrayRef of L<WWW::ARDB::Result::ArcEnemy> objects.

=head2 arc_enemy($id)

    my $enemy = $api->arc_enemy('wasp');

Returns a single L<WWW::ARDB::Result::ArcEnemy> with complete data including
drop table.

=head2 find_item_by_name($name)

    my $item = $api->find_item_by_name('Acoustic Guitar');

Case-insensitive search for an item by name.

=head2 find_quest_by_title($title)

    my $quest = $api->find_quest_by_title('Picking Up The Pieces');

Case-insensitive search for a quest by title.

=head2 find_arc_enemy_by_name($name)

    my $enemy = $api->find_arc_enemy_by_name('Wasp');

Case-insensitive search for an ARC enemy by name.

=head2 clear_cache($endpoint)

    $api->clear_cache('items');
    $api->clear_cache;  # clear all

Clear cached responses.

=head1 RAW METHODS

Each endpoint also has a C<*_raw> variant that returns the raw API response
as a Perl data structure:

    my $data = $api->items_raw;
    my $data = $api->item_raw('acoustic_guitar');
    my $data = $api->quests_raw;
    my $data = $api->quest_raw('picking_up_the_pieces');
    my $data = $api->arc_enemies_raw;
    my $data = $api->arc_enemy_raw('wasp');

=head1 ATTRIBUTION

Applications using data from ardb.app must include attribution as per the
API documentation. Please include a disclaimer crediting ardb.app with a
link back to the source.

=head1 SEE ALSO

L<https://ardb.app>, L<https://ardb.app/developers/api>

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
