package WWW::ARDB::Cache;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: File-based cache for WWW::ARDB

use Moo;
use Types::Standard qw( Str InstanceOf );
use Path::Tiny qw( path );
use Digest::MD5 qw( md5_hex );
use JSON::MaybeXS qw( encode_json decode_json );
use namespace::clean;

our $VERSION = '0.001';

has cache_dir => (
    is      => 'lazy',
    isa     => InstanceOf['Path::Tiny'],
    coerce  => sub { ref $_[0] ? $_[0] : path($_[0]) },
    builder => '_build_cache_dir',
);

sub _build_cache_dir {
    my $self = shift;

    my $base;
    if ($^O eq 'MSWin32') {
        $base = path($ENV{LOCALAPPDATA} || $ENV{APPDATA} || $ENV{HOME});
    } else {
        $base = path($ENV{XDG_CACHE_HOME} || "$ENV{HOME}/.cache");
    }

    my $dir = $base->child('ardb');
    $dir->mkpath unless $dir->exists;

    return $dir;
}

has namespace => (
    is      => 'ro',
    isa     => Str,
    default => 'default',
);

sub get {
    my ($self, $endpoint, $params) = @_;

    my $file = $self->_cache_file($endpoint, $params);
    return unless $file->exists;

    my $content = $file->slurp_utf8;
    my $cached = decode_json($content);

    return $cached->{data};
}

sub set {
    my ($self, $endpoint, $params, $data) = @_;

    my $file = $self->_cache_file($endpoint, $params);
    $file->parent->mkpath unless $file->parent->exists;

    my $cache_data = {
        timestamp => time(),
        endpoint  => $endpoint,
        data      => $data,
    };

    $file->spew_utf8(encode_json($cache_data));
}

sub clear {
    my ($self, $endpoint) = @_;

    if ($endpoint) {
        my $pattern = $self->_cache_key($endpoint, {});
        $pattern =~ s/_[a-f0-9]+$//;
        for my $file ($self->cache_dir->children) {
            if ($file->basename =~ /^\Q$pattern\E/) {
                $file->remove;
            }
        }
    } else {
        for my $file ($self->cache_dir->children) {
            $file->remove if $file->is_file;
        }
    }
}

sub _cache_key {
    my ($self, $endpoint, $params) = @_;

    my $key = $self->namespace . '_' . $endpoint;
    $key =~ s/[\/\s]/_/g;

    if ($params && %$params) {
        my $param_str = encode_json($params);
        $key .= '_' . md5_hex($param_str);
    }

    return $key;
}

sub _cache_file {
    my ($self, $endpoint, $params) = @_;

    my $key = $self->_cache_key($endpoint, $params);
    return $self->cache_dir->child($key . '.json');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::Cache - File-based cache for WWW::ARDB

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::ARDB::Cache;

    my $cache = WWW::ARDB::Cache->new;

    # Store data
    $cache->set('items', {}, $data);

    # Retrieve data
    my $cached = $cache->get('items', {});

    # Clear specific endpoint
    $cache->clear('items');

    # Clear all
    $cache->clear;

=head1 DESCRIPTION

This module provides file-based caching for API responses. Cache files are
stored in the XDG cache directory on Unix systems or LOCALAPPDATA on Windows.

=head1 NAME

WWW::ARDB::Cache - File-based cache for WWW::ARDB

=head1 ATTRIBUTES

=head2 cache_dir

Path::Tiny object for the cache directory. Defaults to C<~/.cache/ardb> on
Unix or C<%LOCALAPPDATA%/ardb> on Windows.

=head2 namespace

String prefix for cache keys. Defaults to C<default>.

=head1 METHODS

=head2 get($endpoint, \%params)

Retrieve cached data for an endpoint. Returns undef if not cached.

=head2 set($endpoint, \%params, $data)

Store data in cache.

=head2 clear($endpoint)

Clear cached data. If C<$endpoint> is provided, only clears that endpoint.
Otherwise clears all cached data.

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
