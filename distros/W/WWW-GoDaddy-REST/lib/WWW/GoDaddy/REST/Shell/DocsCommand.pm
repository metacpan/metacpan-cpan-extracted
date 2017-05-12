package WWW::GoDaddy::REST::Shell::DocsCommand;

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [qw(run_docs smry_docs help_docs comp_docs alias_docs)],
    groups  => { default => [qw(run_docs smry_docs help_docs comp_docs alias_docs)] }
};
use Text::FormatTable;
use WWW::GoDaddy::REST::Shell::Util qw(get_resource_by_schema_or_uri);
use WWW::GoDaddy::REST::Util qw(json_encode);

sub run_docs {
    my $self = shift;

    my $usage = "Usage:\n docs [schema] [id]\n docs /uri/id\n";

    my $resource;
    if ( @_ == 1 && $self->client->schema( $_[0] ) ) {
        $resource = $self->client->schema( $_[0] );
    }
    else {
        $resource = eval { return get_resource_by_schema_or_uri( $self, @_ ); };
    }
    if ($@) {
        if ( UNIVERSAL::isa( $@, 'WWW::GoDaddy::REST::Resource' ) ) {
            $self->page( $@->to_string(1) . "\n" );
        }
        else {
            warn($@);
            warn($usage);
        }
        return 0;
    }

    eval {
        if ( $resource->type() eq 'schema' ) {
            return format_schema_docs( $self, $resource );
        }
        else {
            return format_resource_docs( $self, $resource );
        }
    };
    if ($@) {
        warn($@);
    }

}

sub smry_docs {
    return "summarize a resource or schema";
}

sub help_docs {
    return <<HELP
View a "man page" of a resource.

Usage:
docs [schema] [id]
docs [/uri/to/id]
man [schema]
HELP
}

sub comp_docs {
    my $self   = shift;
    my $client = $self->client;
    return grep { $client->schema($_)->is_queryable } $self->schema_completion(@_);
}

sub alias_docs {
    return ('man');
}

sub format_resource_docs {
    my $self     = shift;
    my $resource = shift;

    my $link_self = $resource->link('self');
    my $type      = $resource->type();
    my $type_fq   = $resource->type_fq();

    my $output = '';
    $output .= "RESOURCE\n";
    $output .= "    GET $link_self\n\n";
    $output .= "SCHEMA\n";
    $output .= "    $type - GET $type_fq\n";

    my %links = %{ $resource->links() || {} };
    if (%links) {
        $output .= "LINKS\n";
        my ($table) = $self->format_pairs(
            [ map {"    $_"} keys %links ],
            [ map {"GET $_"} values %links ],
            " - ", 1
        );
        $output .= "$table";
        $output .= "\n";
    }
    my %actions = %{ $resource->actions() || {} };
    if (%actions) {
        $output .= "EXTRA ACTIONS\n";
        my ($table) = $self->format_pairs(
            [ map {"    $_"} keys %actions ],
            [ map {"POST $_"} values %actions ],
            " - ", 1
        );
        $output .= "$table";
        $output .= "\n";
    }

    my %fields = %{ $resource->fields() };
    delete $fields{links};
    delete $fields{actions};
    if (%fields) {
        $output .= "FIELDS\n";
        my ($table) = $self->format_pairs(
            [ map {"    $_"} keys %fields ],
            [   map {
                    if   ( ref($_) ) { json_encode($_) }
                    else             {$_}
                } values %fields
            ],
            " - ",
            1
        );
        $output .= "$table";
    }

    $self->page($output);

    return 1;
}

sub format_schema_docs {
    my $self     = shift;
    my $resource = shift;

    my $link_self = $resource->link('self');
    my $type      = $resource->type();
    my $type_fq   = $resource->type_fq();

    my $output = '';
    $output .= "SCHEMA\n";
    $output .= "    GET $link_self\n\n";

    my %links = %{ $resource->links() || {} };
    if (%links) {
        $output .= "LINKS\n";
        my ($table) = $self->format_pairs(
            [ map {"    $_"} keys %links ],
            [ map {"GET $_"} values %links ],
            " - ", 1
        );
        $output .= "$table";
        $output .= "\n";
    }

    my $collection_link = $resource->link('collection');
    $output .= "COLLECTION\n";
    $output
        .= "    The collection is the URL that allows you to both search for things, as well as create new things of a particular type.\n\n";

    if ($collection_link) {
        my @methods = @{ $resource->f('collectionMethods') };
        my $methods_string = join ',', @methods;
        $methods_string .= ' ' if @methods;
        if (@methods) {
            foreach (@methods) {
                $output .= "    $_ $collection_link\n";
            }
        }
        else {
            $output .= "    $collection_link\n\n";
        }
        $output .= "\n    See the 'FIELDS' section for a list of queryable fields\n\n";

    }
    else {
        $output
            .= "    Searching is not available for this schema.  There is no\n'collection' link.\n\n";
    }

    my @fields  = sort $resource->resource_field_names();
    my %filters = %{ $resource->f('collectionFilters') };

    my $table = Text::FormatTable->new(' l | l | l | l ');
    $table->rule('-');
    $table->head( 'Name', 'Searchable', 'Flags', 'Type' );
    $table->rule('-');

    my $base_uri = $resource->client->url;

    foreach my $field_name (@fields) {
        my $field      = $resource->resource_field($field_name);
        my $filter     = $filters{$field_name};
        my $filter_ops = '-';
        if ($filter) {
            $filter_ops = join ' ', @{ $filter->{modifiers} };
        }

        my $flags = sprintf( "%s%s%s%s",
            $field->{unique}   ? 'K' : '-',
            $field->{required} ? 'R' : '-',
            $field->{create}   ? 'C' : '-',
            $field->{update}   ? 'U' : '-' );

        my @types = map { $_ =~ s|$base_uri||; $_; }
            grep {defined}
            $resource->resource_field_type( $field_name, { qualify_schema_types => 1 } );

        $table->row( $field_name, $filter_ops, $flags, ( join ' of ', @types ) );

    }
    $table->rule('-');

    my $table_text = $table->render( $self->termsize->{cols} - 4 );
    $table_text =~ s/\n/\n    /gs;
    $table_text =~ s/^/    /g;

    $output .= $table_text;

    $output
        .= "Flags: K - Unique key, R - Required, C - Allowed on create, U - Allowed on update\n";

    $self->page($output);

    return 1;
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
