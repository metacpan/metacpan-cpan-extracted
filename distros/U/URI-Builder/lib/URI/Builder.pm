package URI::Builder;

use strict;
use warnings;

=head1 NAME

URI::Builder - URI objects optimised for manipulation

=head1 SYNOPSIS

    my $uri = URI::Builder->new(
        scheme => 'http',
        host   => 'www.cpan.org',
    );

    $uri->path_segments(qw( misc cpan-faq.html ));

    say $uri->as_string; # http://www.cpan.org/misc/cpan-faq.html

=head1 VERSION

0.04

=cut

our $VERSION = '0.04';

=head1 DESCRIPTION

This class is a close relative of L<URI>, but while that class is optimised
for parsing, this is optimised for building up or modifying URIs. To that end
objects of this class represent their URIs in sections, each of which are
independently mutable, that then need to be serialised to form a string. In
contrast, C<URI> uses a fully-formed string internally which must be parsed
afresh each time a mutation is performed on it.

At the moment only http and https URIs are known to work correctly, support
for other schemes may follow later.

=cut

use URI;
use Scalar::Util qw( blessed );
use Carp qw( confess );

# Utility functions
sub _flatten {
    return map {
        ref $_ eq 'ARRAY' ? _flatten(@$_)
      : ref $_ eq 'HASH'  ? _flatten_hash($_)
      : $_
    } @_ = @_;
}

sub _flatten_hash {
    my $hash = shift;

    return map {
        my ($k, $v) = ($_, $hash->{$_});
        $v = '' unless defined $v;
        map { $k => $_ } _flatten $v
    } keys %$hash;
}

use overload ('""' => \&as_string, fallback => 1);

=head1 ATTRIBUTES

The following attributes relate closely with the URI methods of the same
names.

=over

=item * scheme

=item * userinfo

=item * host

=item * port

=item * path_segments

=item * query_form

=item * query_keywords

=item * fragment

=back

In addition the C<query_separator> attribute defines how C<query_form> fields
are joined. It defaults to C<';'> but can be usefully set to '&'.

The accessors for these attributes have a similar interface to the L<URI>
methods, that is to say that they return old values when new ones are set.
Those attributes that take a list of values: C<path_segments>, C<query_form>
and C<query_keywords> all return plain lists but can be passed nested array
references.

=cut

my (@uri_fields, %listish, @fields);

BEGIN {
    # Fields that correspond to methods in URI
    @uri_fields = qw(
        scheme
        userinfo
        host
        port
        path_segments
        query_form
        query_keywords
        fragment
    );

    # Fields that contain lists of values
    %listish = map { $_ => 1 } qw(
        path_segments
        query_form
        query_keywords
    );

    # All fields
    @fields = ( @uri_fields, qw( query_separator ));

    # Generate accessors for all fields:
    for my $field (@fields) {
        my $glob = do { no strict 'refs'; \*$field };

        *$glob = $listish{$field} ? sub {
            my $self = shift;
            my @old = @{ $self->{$field} || []};
            $self->{$field} = [ _flatten @_ ] if @_;
            return @old;
        }
        : sub {
            my $self = shift;
            my $old = $self->{$field};
            $self->{$field} = shift if @_;
            return $old;
        };
    }
}

=head1 METHODS

=head2 new

The constructor.

In addition to the attributes listed above, a C<uri> argument can be passed as
a string or a L<URI> object, which will be parsed to popoulate any missing
fields.

    # a cpan URL without its path
    my $uri = URI::Builder->new(
        uri => 'http://www.cpan.org/SITES.html',
        path_segments => [],
    );

Non-attribute arguments that match other methods in the class will cause those
methods to be called on the object. This means that what we internally regard
as composite attributes can be specified directly in the constructor.

    # Implicitly populate path_segments:
    my $uri = URI::Builder->new( path => 'relative/path' );

Unrecognised arguments cause an exception.

=cut

sub new {
    my $class = shift;
    my %opts = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    $opts{query_separator} ||= ';';

    if (my $uri = $opts{uri}) {
        $uri = $class->_inflate_uri($uri);

        for my $field (@uri_fields) {
            if (!defined $opts{$field} && (my $code = $uri->can($field))) {
                $opts{$field} =
                  $listish{$field} ? [ $code->($uri) ] : $code->($uri);
            }
        }
    }

    $_ = [ _flatten $_ ]
        for grep defined && ref ne 'ARRAY', @opts{ keys %listish };

    # Still no scheme? Default to http
    # $opts{scheme} ||= 'http';

    my $self = bless { map { $_ => $opts{$_} } @fields }, $class;

    delete @opts{@fields};

    for my $field (sort keys %opts) {
        if (my $method = $self->can($field)) {
            $method->($self, _flatten delete $opts{$field});
        }
    }

    if (my @invalid = sort keys %opts) {
        confess "Unrecognised fields in constructor: ", join ', ', @invalid;
    }

    return $self;
}

# Turn various things into URI objects
sub _inflate_uri {
    my ($self, $thing) = @_;

    if (blessed $thing) {
        if ($thing->isa('URI')) {
            return $thing;
        }
        elsif ($thing->isa(__PACKAGE__)) {
            return $thing->uri;
        }
        else {
            return URI->new("$thing");
        }
    }
    else {
        return URI->new($thing);
    }
}

=head2 abs

    $absolute_uri = $relative_uri->abs($base_uri)

Returns a new L<URI::Builder> object as an absolute URL based on the given
base URI.

Implemented as a wrapper of L<URI/abs>.

=cut

sub abs {
    my ($self, $base, @args) = @_;
    my $class = ref $self;

    return $class->new(uri => $self->uri->abs($self->_inflate_uri($base), @args));
}


=head2 rel

    $relative_uri = $absolute_uri->rel($base_uri)

Returns a new L<URI::Builder> object denoting the relative URI compared with
the base URI.

Implemented as a wrapper of L<URI/rel>.

=cut

sub rel {
    my ($self, $base) = @_;
    my $class = ref $self;

    return $class->new(uri => $self->uri->rel($self->_inflate_uri($base)));
}

=head2 clone

Returns a new object with all attributes copied.

=cut

sub clone {
    my $self = shift;

    my %clone = %$self;
    for my $list ( keys %listish ) {
        $clone{$list} &&= [ @{ $clone{$list} || [] } ];
    }

    return ref($self)->new(%clone);
}

=head2 as_string

Returns the URI described by the object as a string. This is built up from the
individual components each time it's called.

This is also used as the stringification overload.

=cut

sub as_string {
    my $self = shift;

    my @parts;

    if (my $authority = $self->authority) {
        if (my $scheme = $self->scheme) {
            push @parts, "$scheme:";
        }

        $authority =~ s/:@{[ $self->default_port ]}\z//;

        push @parts, "//$authority";
    }

    if (my $path = $self->path) {
        $path =~ s{^(?!/)}{/} if @parts;
        push @parts, $path;
    }

    if (my $query = $self->query) {
        push @parts, "?$query";
    }

    if (my $fragment = $self->fragment) {
        push @parts, "#$fragment";
    }

    return join('', @parts);
}

=head2 uri

Returns a version of this object as a L<URI> object.

=cut

sub uri {
    my $self = shift;

    return URI->new($self->as_string);
}

=head2 default_port

Returns the default port for the current object's scheme. This is obtained
from the appropriate L<URI> subclass. See L<URI/default_port>.

=head2 secure

Returns true if the current scheme is a secure one, false otherwise. See
L<URI/secure>.

=cut

sub _implementor {
    my $self = shift;

    return URI::implementor($self->scheme || 'http');
}

sub default_port { shift->_implementor->default_port }
sub secure       { shift->_implementor->secure       }

=head2 authority

Returns the 'authority' section of the URI. In our case this is obtained by
combining C<userinfo>, C<host> and C<port> together as appropriate.

Note that this is a read-only operation.

=cut

sub authority {
    my $self = shift;
    my ($user, $host) = ($self->userinfo, $self->host_port);

    return $host ? $user ? "$user\@$host" : $host : '';
}

=head2 host_port

Returns the host and port in a single string.

=cut

sub host_port {
    my $self = shift;
    my ($host, $port) = ($self->host, $self->port);

    return $host ? $port ? "$host:$port" : $host : '';
}

=head2 path

Returns the path portion of the URI as a string.

Can be assigned to to populate C<path_segments>.

Leading, trailing and doubled slashes are represented faithfully using empty
path segments.

=cut

sub path {
    my $self = shift;

    my $old = join '/', $self->path_segments;

    if (@_) {
        my @segments = split '/', shift, -1;
        $self->path_segments(@segments);
    }

    return $old;
}

=head2 query

Returns a string representation of the query. This is obtained from either
C<query_form> or C<query_keywords>, in that order.

If an argument is passed, it is parsed to populate C<query_form>.

=cut

sub query {
    my ($self, $query) = @_;

    my @new;
    if ($query) {
        # Parse the new query string using a URI object
        @new = URI->new("?$query", $self->scheme)->query_form;
    }

    unless (defined wantarray) {
        # void context, don't bother building the query string
        $self->query_form(@new);
        return;
    }

    my $old;
    if (my @form = $self->query_form) {
        push @form, '' if @form % 2;
        my $uri = URI->new;
        $uri->query_form(\@form, $self->query_separator);
        $old = $uri->query();
    }
    else {
        $old = join '+', $self->query_keywords;
    }

    $self->query_form(@new);

    return $old;
}

=head2 path_query

Returns a string representation of the path plus the query string. See
L<URI/path_query>.

=cut

sub path_query {
    my $self = shift;
    my ($path, $query) = ($self->path, $self->query);

    my $old = $path . ($query ? "?$query" : '');

    if (@_) {
        my $uri = URI->new($_[0]);
        $self->$_([ $uri->$_ ]) for qw( path_segments query_form );
    }

    return $old
}

=head2 query_param

    @keys       = $uri->query_param
    @values     = $uri->query_param($key)
    @old_values = $uri->query_param($key, @new_values);

This works exactly like the method of the same name implemented in
L<URI::QueryParam>.

With no arguments, all unique query field names are returned

With one argument, all values for the given field name are returned

With more than one argument, values for the given key (first argument) are set
to the given values (remaining arguments). Care is taken in this case to
preserve the ordering of the fields.

=cut

sub query_param {
    my ($self, $key, @values) = @_;
    my @form = $self->query_form;

    if ($key) {
        my @indices = grep $_ % 2 == 0 && $form[$_] eq $key, 0 .. $#form;
        my @old_values = @form[ map $_ + 1, @indices ];

        if (@values) {
            @values = _flatten @values;
            splice @form, pop @indices, 2 while @indices > @values;

            my $last_index = @indices ? $indices[-1] + 2 : @form;

            while (@values && @indices) {
                splice @form, shift @indices, 2, $key, shift @values;
            }

            if (@values) {
                splice @form, $last_index, 0, map { $key => $_ } @values;
            }

            $self->query_form(@form);
        }

        return wantarray ? @old_values : $old_values[0];
    }
    else {
        my %seen;
        return grep !$seen{$_}++, map $form[$_], grep $_ % 2 == 0, 0 .. $#form;
    }
}

=head2 query_param_append

    $uri->query_param_append($key, @values)

Appends fields to the end of the C<query_form>. Returns nothing.

=cut

sub query_param_append {
    my ($self, $key, @values) = @_;

    $self->query_form($self->query_form, map { $key => $_ } _flatten @values);

    return;
}

=head2 query_param_delete

    @old_values = $uri->query_param_delete($key)

Removes all fields with the given key from the C<query_form>.

=cut

sub query_param_delete {
    my ($self, $key) = @_;

    return $self->query_param($key, []);
}

=head2 query_form_hash

    $hashref     = $uri->query_form_hash
    $old_hashref = $uri->query_form_hash(\%new_hashref)

A hash representation of the C<query_form>, with multiple values represented
as arrayrefs.

=cut

sub query_form_hash {
    my $self = shift;
    my @new;

    if (my %form = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_) {
        @new = _flatten_hash(\%form);
    }

    unless (defined wantarray) {
        # void context, don't bother building the hash
        $self->query_form(@new);
        return;
    }

    my %form = map {
        my @values = $self->query_param($_);
        ( $_ => @values == 1 ? $values[0] : \@values );
    } $self->query_param;

    $self->query_form(@new) if @new;

    return \%form;
}

=head1 TODO

The following URI methods are currently not implemented:

=over

=item * as_iri

=item * ihost

=back

=head1 LICENSE

L<perlartistic>

=cut

1;

__END__

canonical
default_port
via URI::_server: _host_escape
via URI::_server: _port
via URI::_server: _uric_escape
via URI::_server: as_iri
via URI::_server: host
via URI::_server: host_port
via URI::_server: ihost
via URI::_server: port
via URI::_server: uri_unescape
via URI::_server: userinfo
via URI::_server -> URI::_generic: _check_path
via URI::_server -> URI::_generic: _no_scheme_ok
via URI::_server -> URI::_generic: _split_segment
via URI::_server -> URI::_generic: abs
via URI::_server -> URI::_generic: authority
via URI::_server -> URI::_generic: path
via URI::_server -> URI::_generic: path_query
via URI::_server -> URI::_generic: path_segments
via URI::_server -> URI::_generic: rel
via URI::_server -> URI::_generic -> URI: (!=
via URI::_server -> URI::_generic -> URI: (""
via URI::_server -> URI::_generic -> URI: ()
via URI::_server -> URI::_generic -> URI: (==
via URI::_server -> URI::_generic -> URI: STORABLE_freeze
via URI::_server -> URI::_generic -> URI: STORABLE_thaw
via URI::_server -> URI::_generic -> URI: _init
via URI::_server -> URI::_generic -> URI: _init_implementor
via URI::_server -> URI::_generic -> URI: _obj_eq
via URI::_server -> URI::_generic -> URI: _scheme
via URI::_server -> URI::_generic -> URI: as_string
via URI::_server -> URI::_generic -> URI: clone
via URI::_server -> URI::_generic -> URI: eq
via URI::_server -> URI::_generic -> URI: fragment
via URI::_server -> URI::_generic -> URI: implementor
via URI::_server -> URI::_generic -> URI: new
via URI::_server -> URI::_generic -> URI: new_abs
via URI::_server -> URI::_generic -> URI: opaque
via URI::_server -> URI::_generic -> URI: scheme
via URI::_server -> URI::_generic -> URI: secure
via URI::_server -> URI::_generic -> URI::_query: equery
via URI::_server -> URI::_generic -> URI::_query: query
via URI::_server -> URI::_generic -> URI::_query: query_form
via URI::_server -> URI::_generic -> URI::_query: query_keywords
