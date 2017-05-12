package XML::LibXML::Cache::Base;
{
  $XML::LibXML::Cache::Base::VERSION = '0.12';
}
use strict;

# ABSTRACT: Base class for XML::LibXML caches

use URI;
use XML::LibXML 1.59;

our $input_callbacks = XML::LibXML::InputCallback->new();
$input_callbacks->register_callbacks([
    \&_match_cb,
    \&_open_cb,
    \&_read_cb,
    \&_close_cb,
]);

my $deps_found;

sub new {
    my $class = shift;

    my $self = {
        cache => {},
        hits  => 0,
    };

    return bless($self, $class);
}

sub cache_hits {
    my $self = shift;

    return $self->{hits};
}

sub _cache_lookup {
    my ($self, $filename, $get_item) = @_;

    my $item = $self->_cache_read($filename);

    if ($item) {
        ++$self->{hits};
        return $item;
    }

    $deps_found = {};

    $item = $get_item->($filename);

    $self->_cache_write($filename, $item);

    $deps_found = undef;

    return $item;
}

sub _cache_read {
    my ($self, $filename) = @_;

    my $cache_rec = $self->{cache}{$filename}
        or return ();

    my ($item, $deps) = @$cache_rec;

    # check sizes and mtimes of deps_found

    while (my ($path, $attrs) = each(%$deps)) {
        my @stat = stat($path);
        my ($size, $mtime) = @stat ? ($stat[7], $stat[9]) : (-1, -1);

        return () if $size != $attrs->[0] || $mtime != $attrs->[1];
    }

    return $item;
}

sub _cache_write {
    my ($self, $filename, $item) = @_;

    my $cache = $self->{cache};

    if ($deps_found) {
        $cache->{$filename} = [ $item, $deps_found ];
    }
    else {
        delete($cache->{$filename});
    }
}

# Handling of dependencies

# We register an input callback that never matches but records all URIs
# that are accessed during parsing.

sub _match_cb {
    my $uri_str = shift;

    return undef if !$deps_found;

    my $uri = URI->new($uri_str, 'file');
    my $scheme = $uri->scheme;

    if (!defined($scheme) || $scheme eq 'file') {
        my $path = $uri->path;
        my @stat = stat($path);
        $deps_found->{$path} = @stat ?
            [ $stat[7], $stat[9] ] :
            [ -1, -1 ];
    }
    else {
        # Unsupported URI, disable caching
        $deps_found = undef;
    }

    return undef;
}

# should never be called
sub _open_cb { die('open callback called unexpectedly'); }
sub _read_cb { die('read callback called unexpectedly'); }
sub _close_cb { die('close callback called unexpectedly'); }

1;



=pod

=head1 NAME

XML::LibXML::Cache::Base - Base class for XML::LibXML caches

=head1 VERSION

version 0.12

=head1 DESCRIPTION

Base class for the document and style sheet caches.

=head1 METHODS

=head2 new

Only used by subclasses.

=head2 cache_hits

    my $hits = $cache->cache_hits;

Return the number of cache hits.

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


