package URL::Normalize;
use Moose;
use namespace::autoclean;

use URI qw();
use URI::QueryParam qw();

=head1 NAME

URL::Normalize - Normalize/optimize URLs.

=head1 VERSION

Version 0.43

=cut

our $VERSION = '0.43';

=head1 SYNOPSIS

    use URL::Normalize;

    my $normalizer = URL::Normalize->new( 'http://www.example.com/display?lang=en&article=fred' );

    # Normalize the URL
    $normalizer->make_canonical;
    $normalizer->remove_directory_index;
    $normalizer->remove_empty_query;

    # Get the normalized version back
    my $url = $normalizer->url;

=cut

=head1 DESCRIPTION

When writing a web crawler, for example, it's always very costly to check if a
URL has been fetched/seen when you have millions or billions of URLs in a
database.

This module can help you create a unique "ID" of a URL, which you can use as a
key in a key/value-store; the key is the normalized URL, whereas all the URLs
that refers to the normalized URL are part of the value (normally an array or
hash);

    'http://www.example.com/' = {
        'http://www.example.com:80/'        => 1,
        'http://www.example.com/index.html' => 1,
        'http://www.example.com/?'          => 1,
    }

Above, all the URLs inside the hash normalizes to the key if you run these
methods:

=over 4

=item * C<make_canonical>

=item * C<remove_directory_index>

=item * C<remove_empty_query>

=back

This is NOT a perfect solution.

If you normalize a URL using all the methods in this module, there is a high
probability that the URL will stop "working." This is merely a helper module
for those of you who wants to either normalize a URL using only a few of the
safer methods, and/or for those of you who wants to generate a possibly unique
"ID" from any given URL.

=head1 CONSTRUCTORS

=head2 new( $url )

Constructs a new URL::Normalize object:

    my $normalizer = URL::Normalize->new( 'http://www.example.com/some/path' );

You can also send in just the path:

    my $normalizer = URL::Normalize->new( '/some/path' );

The latter is NOT recommended, though, and hasn't been tested properly. You
should always give URL::Normalize an absolute URL by using L<URI>'s C<new_abs>.

=cut

=head1 METHODS

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( url => $_[0] );
    }
    else {
        return $class->$orig( @_ );
    }
};

=head2 url

Get the current URL, preferably after you have run one or more of the
normalization methods.

=cut

has 'url' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    writer   => '_set_url',
);

has 'dir_index_regexps' => (
    traits  => [ 'Array' ],
    isa     => 'ArrayRef[Str]',
    is      => 'rw',
    handles => {
        'add_dir_index_regexp' => 'push',
    },
    default => sub {
        [
            '/default\.aspx?',
            '/default\.html\.aspx?',
            '/default\.s?html?',
            '/home\.s?html?',
            '/index\.cgi',
            '/index\.html\.aspx?',
            '/index\.html\.php',
            '/index\.jsp',
            '/index\.php\d?',
            '/index\.pl',
            '/index\.s?html?',
            '/welcome\.s?html?',
        ];
    },
);

=head2 URI

Returns a L<URI> representation of the current URL.

=cut

has 'URI' => (
    isa => 'URI',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        my $URI = eval {
            URI->new( $self->url )->canonical;
        };

        if ( $@ ) {
            Carp::carp( "Failed to create a URI object from URL '" . $self->url . "'" );
        }

        return $URI;
    },
);

=head2 make_canonical

Just a shortcut for URI::URL->new->canonical->as_string, and involves the
following steps (at least):

=over 4

=item * Converts the scheme and host to lower case.

=item * Capitalizes letters in escape sequences.

=item * Decodes percent-encoded octets of unreserved characters.

=item * Removes the default port (port 80 for http).

=back

Example:

    my $normalizer = URL::Normalize->new(
        url => 'HTTP://www.example.com:80/%7Eusername/',
    );

    $normalizer->make_canonical;

    print $normalizer->url; # http://www.example.com/~username/

=cut

sub make_canonical {
    my $self = shift;

    if ( my $URI = $self->URI ) {
        $self->_set_url( $URI->canonical->as_string );
    }
    else {
        Carp::carp( "Can't make non-URI URLs canonical." );
    }
}

=head2 remove_dot_segments

The C<.>, C<..> and C<...> segments will be removed and "folded" (or
"flattened", if you prefer) from the URL.

This method does NOT follow the algorithm described in L<RFC 3986: Uniform
Resource Indentifier|http://tools.ietf.org/html/rfc3986>, but rather flattens
each path segment.

Also keep in mind that this method doesn't (because it can't) account for
symbolic links on the server side.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/../a/b/../c/./d.html',
    );

    $normalizer->remove_dot_segments;

    print $normalizer->url; # http://www.example.com/a/c/d.html

=cut

sub remove_dot_segments {
    my $self = shift;

    if ( my $URI = $self->URI ) {
        my $path = $URI->path;

        my @new_segments = ();

        foreach my $segment ( split('/', $path) ) {
            if ( $segment eq '.' || $segment eq '...' ) {
                next;
            }

            if ( $segment eq '..' ) {
                pop( @new_segments );
                next;
            }

            push( @new_segments, $segment );
        }

        my $new_path = join( '/', @new_segments );
        $new_path .= '/' if ( $new_path !~ m,/$, && $path =~ m,/$, );
        $new_path  = '/' . $new_path unless ( $new_path =~ m,^/, );

        $URI->path( $new_path );

        $self->_set_url( $URI->as_string );
    }
}

=head2 remove_directory_index

Removes well-known directory indexes, eg. C<index.html>, C<default.asp> etc.
This method is case-insensitive.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/index.cgi?foo=/',
    );

    $normalizer->remove_directory_index;

    print $normalizer->url; # http://www.example.com/?foo=/

The default regular expressions for matching a directory index are:

=over 4

=item * C<default\.aspx?>

=item * C<default\.html\.aspx?>

=item * C<default\.s?html?>

=item * C<home\.s?html?>

=item * C<index\.cgi>

=item * C<index\.html\.aspx?>

=item * C<index\.html\.php>

=item * C<index\.jsp>

=item * C<index\.php\d?>

=item * C<index\.pl>

=item * C<index\.s?html?>

=item * C<welcome\.s?html?>

=back

You can override these by sending in your own list of regular expressions
when creating the URL::Normalizer object:

    my $normalizer = URL::Normalize->new(
        url               => 'http://www.example.com/index.cgi?foo=/',
        dir_index_regexps => [ 'MyDirIndex\.html' ], # etc.
    );

You can also choose to add regular expressions after the URL::Normalize
object has been created:

    my $normalizer = URL::Normalize->new(
        url               => 'http://www.example.com/index.cgi?foo=/',
        dir_index_regexps => [ 'MyDirIndex\.html' ], # etc.
    );

    # ...

    $normalizer->add_directory_index_regexp( 'MyDirIndex\.html' );

=cut

sub remove_directory_index {
    my $self = shift;

    if ( my $URI = $self->URI ) {
        if ( my $path = $URI->path ) {
            foreach my $regex ( @{$self->dir_index_regexps} ) {
                $path =~ s,$regex,/,i;
            }

            $URI->path( $path );
        }

        $self->_set_url( $URI->as_string );
    }
}

=head2 sort_query_parameters

Sorts the URL's query parameters alphabetically.

Uppercased parameters will be lowercased DURING sorting, but the parameters
will be in the original case AFTER sorting. If there are multiple values for
one parameter, the key/value-pairs will be sorted as well.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/?b=2&c=3&a=0&A=1',
    );

    $normalizer->sort_query_parameters;

    print $normalizer->url; # http://www.example.com/?a=0&A=1&b=2&c=3

=cut

sub sort_query_parameters {
    my $self = shift;

    if ( my $URI = $self->URI ) {
        if ( $URI->as_string =~ m,\?, ) {
            my $query_hash     = $URI->query_form_hash || {};
            my $query_string   = '';
            my %new_query_hash = ();

            foreach my $key ( sort { lc($a) cmp lc($b) } keys %{$query_hash} ) {
                my $values = $query_hash->{ $key };
                unless ( ref $values ) {
                    $values = [ $values ];
                }

                foreach my $value ( @{$values} ) {
                    push( @{ $new_query_hash{lc($key)}->{$value} }, $key );
                }
            }

            foreach my $sort_key ( sort keys %new_query_hash ) {
                foreach my $value ( sort keys %{$new_query_hash{$sort_key}} ) {
                    foreach my $key ( @{$new_query_hash{$sort_key}->{$value}} ) {
                        $query_string .= $key . '=' . $value . '&';
                    }
                }
            }

            $query_string =~ s,&$,,;

            $URI->query( $query_string );
        }

        $self->_set_url( $URI->as_string );
    }
}

=head2 remove_duplicate_query_parameters

Removes duplicate query parameters, i.e. where the key/value combination is
identical with another key/value combination.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/?a=1&a=2&b=4&a=1&c=4',
    );

    $normalizer->remove_duplicate_query_parameters;

    print $normalizer->url; # http://www.example.com/?a=1&a=2&b=3&c=4

=cut

sub remove_duplicate_query_parameters {
    my $self = shift;

    if ( my $URI = $self->URI ) {
        my %seen      = ();
        my @new_query = ();

        foreach my $key ( $URI->query_param ) {
            my @values = $URI->query_param( $key );

            foreach my $value ( @values ) {
                unless ( $seen{$key}->{$value} ) {
                    push( @new_query, { key => $key, value => $value } );
                    $seen{$key}->{$value}++;
                }
            }
        }

        my $query_string = '';
        foreach ( @new_query ) {
            $query_string .= $_->{key} . '=' . $_->{value} . '&';
        }

        $query_string =~ s,&$,,;

        $URI->query( $query_string );

        $self->_set_url( $URI->as_string );
    }
}

=head2 remove_empty_query_parameters

Removes empty query parameters, i.e. where there are keys with no value. This
only removes BLANK values, not values considered to be no value, like zero (0).

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/?a=1&b=&c=3',
    );

    $normalizer->remove_empty_query_parameters;

    print $normalizer->url; # http://www.example.com/?a=1&c=3

=cut

sub remove_empty_query_parameters {
    my $self = shift;

    if ( my $URI = $self->URI ) {
        foreach my $key ( $URI->query_param ) {
            my @values = $URI->query_param( $key );

            $URI->query_param_delete( $key );

            foreach my $value ( @values ) {
                if ( defined $value && length $value ) {
                    $URI->query_param_append( $key, $value );
                }
            }
        }

        $self->_set_url( $URI->as_string );
    }
}

=head2 remove_empty_query

Removes empty query from the URL.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/foo?',
    );

    $normalizer->remove_empty_query;

    print $Normalize->url; # http://www.example.com/foo

=cut

sub remove_empty_query {
    my $self = shift;

    my $url = $self->url;
    $url =~ s,\?$,,;

    $self->_set_url( $url );
}

=head2 remove_fragment

Removes the fragment from the URL, but only if seems like they are at the end
of the URL.

For example C<http://www.example.com/#foo> will be translated to
C<http://www.example.com/>, but C<http://www.example.com/#foo/bar> will stay
the same.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/bar.html#section1',
    );

    $normalizer->remove_fragment;

    print $normalizer->url; # http://www.example.com/bar.html

=cut

sub remove_fragment {
    my $self = shift;

    my $url = $self->url;

    $url =~ s{#(?:/|[^?/]*)$}{};

    $self->_set_url( $url );
}

=head2 remove_fragments

Like C<remove_fragment>, but removes EVERYTHING after a C<#>.

=cut

sub remove_fragments {
    my $self = shift;

    my $url = $self->url;

    $url =~ s/#.*//;

    $self->_set_url( $url );
}

=head2 remove_duplicate_slashes

Remove duplicate slashes from the URL.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/foo//bar.html',
    );

    $normalizer->remove_duplicate_slashes;

    print $normalizer->url; # http://www.example.com/foo/bar.html

=cut

sub remove_duplicate_slashes {
    my $self = shift;

    if ( my $URI = $self->URI ) {
        my $path = $URI->path;

        $path =~ s,/+,/,g;

        $URI->path( $path );

        $self->_set_url( $URI->as_string );
    }
}

=head2 remove_query_parameter

Convenience method for removing a specific parameter from the URL. If
the parameter is mentioned multiple times (?a=1&a=2), all occurences
will be removed.

=cut

sub remove_query_parameter {
    my $self  = shift;
    my $param = shift;

    return $self->remove_query_parameters( [$param] );
}

=head2 remove_query_parameters

Convenience method for removing multiple parameters from the URL. If the
parameters are mentioned multiple times (?a=1&a=2), all occurences will be
removed.

=cut

sub remove_query_parameters {
    my $self   = shift;
    my $params = shift || [];

    if ( my $URI = $self->URI ) {
        foreach my $param ( @{$params} ) {
            $URI->query_param_delete( $param );
        }

        $self->_set_url( $URI->as_string );
    }
}

=head1 SEE ALSO

=over 4

=item * L<URI::Normalize>

=item * L<URI>

=item * L<URI::URL>

=item * L<URI::QueryParam>

=item * L<RFC 3986: Uniform Resource Indentifier|http://tools.ietf.org/html/rfc3986>

=item * L<Wikipedia: URL normalization|http://en.wikipedia.org/wiki/URL_normalization>

=back

=head1 AUTHOR

Tore Aursand, C<< <toreau at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the web interface at L<https://github.com/toreau/URL-Normalize/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URL::Normalize

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URL-Normalize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URL-Normalize>

=item * Search CPAN

L<http://search.cpan.org/dist/URL-Normalize/>

=back

=head1 LICENSE AND COPYRIGHT

The MIT License (MIT)

Copyright (c) 2012-2021 Tore Aursand

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

__PACKAGE__->meta->make_immutable;

1; # End of URL::Normalize
