package WWW::GoDaddy::REST::Shell::QueryCommand;

use strict;
use warnings;

use Carp;
use List::MoreUtils qw( natatime );
use Sub::Exporter -setup => {
    exports => [qw(run_query smry_query help_query comp_query)],
    groups  => { default => [qw(run_query smry_query help_query comp_query)] }
};

sub run_query {
    my ( $self, $schema_name, @args ) = @_;

    my $usage = "Usage: query [schema] [[field] [modifier] [value]] ...\n";

    if ( !$schema_name ) {
        warn($usage);
        return 0;
    }

    my $client = $self->client();
    my $schema = $client->schema($schema_name);
    if ( !$schema ) {
        warn("'$schema_name' is not a recognized schema");
        return 0;
    }

    if ( !$schema->is_queryable ) {
        warn(
            "This schema has no 'collection' link. It does not look like it can be queried.  You can always try using a direct URL as a way around this if you know a URL exists to query this."
        );
        return 0;
    }

    my @filters = grep { !/=/ } @args;
    my %uri_params = map { split '=' } grep {/=/} @args;

    if ( @filters % 3 != 0 ) {
        warn($usage);
        return 0;
    }

    my $iterator = natatime 3, @filters;

    my $filter = {};
    while ( my ( $field, $cmp, $value ) = $iterator->() ) {
        $filter->{$field} ||= [];
        push @{ $filter->{$field} },
            {
            'modifier' => $cmp,
            'value'    => $value
            };
    }

    my $collection = eval { $client->query( $schema_name, $filter, \%uri_params ); };
    if ($@) {
        if ( UNIVERSAL::isa( $@, 'WWW::GoDaddy::REST::Resource' ) ) {
            $self->page( $@->to_string(1) . "\n" );
        }
        else {
            carp($@);
        }
        return 0;
    }

    $self->page( $collection->to_string(1) . "\n" );
    return 1;
}

sub smry_query {
    return "search for items in a schema"
}

sub help_query {
    return <<HELP
Search for items in a collection of a given schema.

Usage:
query [schema] [[field] [modifier] [value]] ... [[arbitrary=param] [arbitrary=param]] ...

Example:
query user fname eq john
query pancakes limit=10
HELP
}

sub comp_query {
    my ( $self, $word, $line, $start ) = @_;

    my @words  = $self->line_parsed($line);
    my $client = $self->client();

    my $comp_schema = ( @words < 2 or ( @words == 2 and $start < length($line) ) );
    if ($comp_schema) {
        return grep { index( $_, $word ) == 0 }
            grep { $client->schema($_)->is_queryable } $self->schema_names();
    }

    my $schema_name = $words[1];
    my $schema      = $client->schema($schema_name);
    if ( !$schema ) {

        # bad schema name - bail
        return ();
    }

    my %filters = %{ $schema->f('collectionFilters') };

    my $comp_field = ( ( @words + 1 ) % 3 == 0 or ( @words % 3 == 0 and $start < length($line) ) );
    if ($comp_field) {
        my @fields = sort keys %filters;
        return grep { index( $_, $word ) == 0 } @fields;
    }

    my $comp_modifier
        = ( ( @words + 1 ) % 3 == 1 or ( @words % 3 == 1 and $start < length($line) ) );
    if ($comp_modifier) {
        my $in_field_named = ( @words % 3 == 1 ) ? $words[-2] : $words[-1];
        if ( !$filters{$in_field_named} ) {

            # bad field name - bail
            return ();
        }
        my @modifiers = sort @{ $filters{$in_field_named}->{modifiers} };
        return ( grep { index( $_, $word ) == 0 } @modifiers );
    }

    return ();

}

1;

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
