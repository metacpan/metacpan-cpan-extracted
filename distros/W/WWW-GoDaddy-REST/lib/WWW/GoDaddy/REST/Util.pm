package WWW::GoDaddy::REST::Util;

use strict;
use warnings;

use JSON qw();
use Sub::Exporter -setup => {
    exports => [
        qw( abs_url
            add_filters_to_url
            build_complex_query_url
            is_json
            json_decode
            json_encode
            json_instance
            )
    ]
};
use URI;
use URI::QueryParam;

sub is_json {
    my $json    = shift;
    my $handler = json_instance(@_);

    eval { my $perl = json_decode($json); };
    if ($@) {
        return 0;
    }
    else {
        return 1;
    }
}

sub json_encode {
    my $perl    = shift;
    my $handler = json_instance(@_);
    return $handler->encode($perl);
}

sub json_decode {
    my $json    = shift;
    my $handler = json_instance(@_);
    return $handler->decode($json);
}

sub json_instance {

    my $inst = JSON->new;

    if ( @_ == 1 && UNIVERSAL::isa( $_[0], "JSON" ) ) {
        return $_[0];
    }
    elsif (@_) {
        while ( my ( $key, $value ) = each %{@_} ) {
            $inst->property( $key => $value );
        }
    }
    else {
        $inst->convert_blessed(1);
        $inst->allow_nonref(1);
    }
    return $inst;
}

sub abs_url {
    my $api_base = shift;
    my $url      = shift;

    $url =~ s|^/||;
    $api_base =~ s|/*$|/|;

    return URI->new_abs( $url, $api_base );
}

sub add_filters_to_url {
    my ( $url, $filters ) = @_;

    my $uri = URI->new($url);
    foreach my $field ( sort keys %{$filters} ) {
        my $field_filters = $filters->{$field};

        next unless $field_filters;

        if ( ref($field_filters) eq 'ARRAY' ) {

            # a query could look like so:
            # {
            #   'myField' => [
            #       { modifier => 'ne', value => 'apple' },
            #       { value => 'orange' } # implicit 'eq'
            #   ]
            # }
            foreach my $filter ( @{$field_filters} ) {
                my $modifier = $filter->{modifier} || 'eq';
                my $value = $filter->{value};
                if ( $modifier eq 'eq' ) {
                    $uri->query_param_append( $field => $value );
                }
                else {
                    $uri->query_param_append( sprintf( '%s_%s', $field, $modifier ) => $value );
                }
            }
        }
        else {

            # a query could look like so:
            # {
            #   'myField' => 'apple'
            # }
            $uri->query_param_append( $field => $field_filters );
        }
    }
    return $uri->as_string;
}

sub build_complex_query_url {
    my ( $url, $filter, $params ) = @_;

    $filter ||= {};
    $params ||= {};

    $url = add_filters_to_url( $url, $filter );

    if ( exists $params->{'sort'} ) {
        $params->{'order'} ||= 'asc';
    }

    my $uri = URI->new($url);
    while ( my ( $key, $value ) = each %{$params} ) {
        $uri->query_param( $key => $value );
    }

    return $uri->as_string;

}

1;

=head1 NAME

WWW::GoDaddy::REST::Util - Mostly URL tweaking utilities for this package

=head1 SYNOPSIS

  use WWW::GoDaddy::REST::Util qw/ abs_url add_filters_to_url /;

  # http://example.com/v1/asdf
  abs_url('http://example.com/v1','/asdf');

  # http://example.com?sort=asc&fname=Fred
  add_filters_to_url('http://example.com?sort=asc',{ 'fname' => [ { 'value': 'Fred' } ] });

=head1 DESCRIPTION

Utilities used commonly in this package.  Most have to do with URL manipulation.

=head1 FUNCTIONS

=over 4

=item is_json

Given a json string, return true if it is parsable, false otherwise.

If you need to control the parameters to the L<JSON> module, simply
pass additional parameters. These will be passed unchanged to C<json_instance>.

Example:

  my $yes = is_json('"asdf"');
  my $yes = is_json('{"key":"value"}');
  my $no  = is_json('dafsafsadfsdaf');

=item json_decode

Given a json string, return the perl data structure.  This will C<die()> if it
can not be parsed.

If you need to control the parameters to the L<JSON> module, simply
pass additional parameters. These will be passed unchanged to C<json_instance>.

Example:

  my $hashref = json_decode('{"key":"value"}');

=item json_encode

Given a perl data structure, return the json string.  This will C<die()> if it
can not be serialized.

If you need to control the parameters to the L<JSON> module, simply
pass additional parameters. These will be passed unchanged to C<json_instance>.

Example:

  my $json = json_encode({ 'key' => 'value' });

=item json_instance

Returns C<JSON> instance.  If no parameters are given the following
defaults are set: C<convert_blessed>, C<allow_nonref>.

If called with one parameter, it is assumed to be a C<JSON> instance
and this is returned instead of building a new one.

If called with more than one parameter, it is assumed to be key/value
pairs and will be passed to the JSON C<property> method two by two.

Example:

  $j = json_instance(); #defaults
  $j = json_instance( JSON->new ); #pass through
  $j = json_instance( 'convert_blessed' => 1, 'allow_nonref' => 1 ); # set properies

=item abs_url

Given a base and path fragment, generate an absolute url with the two
joined.

Example:

  # http://example.com/v1/asdf
  abs_url('http://example.com/v1','/asdf');

=item add_filters_to_url

Given a url and a query filter, generate a url with the filter
query parameters added.

Filter syntax can be seen in the docs for L<WWW::GoDaddy::REST>.

Example:

  add_filters_to_url('http://example.com?sort=asc',{ 'fname' => [ { 'value': 'Fred' } ] });
  # http://example.com?sort=asc&fname=Fred

=item build_complex_query_url

Return a modified URL string given a URL, an optional filter spec, and optional
query parameter hash.

If you specify a sort, then an order parameter will be filled in if not present, and
and sort or order query parameters in the input string will be replaced.

All other query parameters (filters etc) will be appended to the query parameters
of the input URL instead of replacing.

Example:

    build_complex_query_url(
      'http://example.com',
      {
        'foo' => 'bar'
      },
      {
        'sort' => 'surname'
      }
    );
    # http://example.com?foo=bar&sort=surname&order=asc

=back

=head1 EXPORTS

None by default.

=head1 AUTHOR

David Bartle, C<< <davidb@mediatemple.net> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014 Go Daddy Operating Company, LLC

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.

=cut

