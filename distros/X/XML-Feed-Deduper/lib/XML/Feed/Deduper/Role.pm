package XML::Feed::Deduper::Role;
use strict;
use warnings;

use Digest::MD5 ();

use Mouse::Role;

has compare_body => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

# $engine->find_entry($id) => md5hash
requires 'find_entry';
# $engine->create_entry($id, $digest) => undef
requires 'create_entry';

no Mouse::Role;

sub id_for {
    my ($self, $entry) = @_;
    if ($entry->modified) {
        return join ":", $entry->link, $entry->modified;
    } else {
        return $entry->link;
    }
}

sub is_new {
    my ( $self, $entry ) = @_;

    my $exists = $self->find_entry( $self->id_for($entry) ) or return 1;

    if ( $self->compare_body ) {
        return $exists ne _digest($entry);
    }
    else {
        return 0;
    }
}

sub add {
    my ( $self, $entry ) = @_;
    $self->create_entry( $self->id_for($entry), _digest($entry) );
}

sub _digest {
    my $entry = shift;
    my $content = ($entry->title||'') . ($entry->content||'');
    utf8::encode($content) if utf8::is_utf8($content);
    my $digest = Digest::MD5::md5_hex($content);
    return $digest;
}

1;
