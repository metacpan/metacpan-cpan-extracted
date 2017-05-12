package WWW::GoDaddy::REST::Shell::GraphCommand;

use strict;
use warnings;

use Carp;
use GraphViz;
use GraphViz::Data::Grapher;
use Sub::Exporter -setup => {
    exports => [qw(run_graph smry_graph help_graph comp_graph)],
    groups  => { default => [qw(run_graph smry_graph help_graph comp_graph)] }
};

sub run_graph {
    my ( $self, @args ) = @_;

    my @opts    = grep {/=/} @args;
    my @schemas = grep {/^=/} @args;

    my $client = $self->client;

    my @plot_schemas;

    if (@schemas) {
        foreach (@schemas) {
            if ( !$client->schema($_) ) {
                warn("'$_' is not a recognized schema");
                return 0;
            }
            push @plot_schemas, $client->schema($_);
        }
    }
    else {
        @plot_schemas = @{ $client->schemas() };
    }

    do_graphviz( $self, @plot_schemas );

}

sub outgoing_edges {
    my ( $self, @plot_schemas ) = @_;

    my @outgoing;

    my %dupe_edge_detect;

    foreach my $s (@plot_schemas) {

        # first do the resource fields
        foreach my $field ( $s->resource_field_names ) {
            my ( $container, $type )
                = $s->resource_field_type( $field,
                { auto_upconvert_reference => 1, qualify_schema_types => 1 } );

            if ( $type =~ /^http/ ) {
                my $complex_type = $self->client->schema($type);
                my $complex_name = $complex_type->id();
                my $arrowhead    = ( !$container or $container eq 'reference' ) ? "normal" : "inv";
                my $arrowtail    = "none";

                my $from = $s->id;
                my $to   = $complex_name;

                my $edge_key = join '', sort ( $from, $to );

                my $edge = {
                    'from'      => $from,
                    'to'        => $to,
                    'arrowhead' => $arrowhead,
                    'arrowtail' => $arrowtail,
                    'via'       => 'field'
                };

                $dupe_edge_detect{$edge_key} ||= [];
                push @{ $dupe_edge_detect{$edge_key} }, $edge;
            }
        }
        my %resource_actions = %{ $s->f('resourceActions') };
        while ( my ( $action, $action_data ) = each(%resource_actions) ) {
            my $input_schema = $self->client->schema( $action_data->{input} || '' );
            if ($input_schema) {
                my $from      = $input_schema->id;
                my $to        = $s->id;
                my $arrowhead = 'dot';
                my $arrowtail = 'none';

                my $edge_key = join '', sort ( $from, $to );
                my $edge = {
                    'from'      => $from,
                    'to'        => $to,
                    'arrowhead' => $arrowhead,
                    'arrowtail' => $arrowtail,
                    'via'       => 'action',
                    'style'     => 'dotted',
                    'label'     => $action
                };
                $dupe_edge_detect{$edge_key} ||= [];
                push @{ $dupe_edge_detect{$edge_key} }, $edge;
            }
            my $output_schema = $self->client->schema( $action_data->{output} || '' );
            if ($output_schema) {
                my $from      = $s->id;
                my $to        = $output_schema->id;
                my $arrowhead = 'dot';
                my $arrowtail = 'none';

                my $edge_key = join '', sort ( $from, $to );
                my $edge = {
                    'from'      => $from,
                    'to'        => $to,
                    'arrowhead' => $arrowhead,
                    'arrowtail' => $arrowtail,
                    'via'       => 'action',
                    'style'     => 'dotted',
                    'label'     => $action
                };
                $dupe_edge_detect{$edge_key} ||= [];
                push @{ $dupe_edge_detect{$edge_key} }, $edge;
            }
        }
    }

    while ( my ( $edge_key, $edge_dupe ) = each %dupe_edge_detect ) {
        my $size = @$edge_dupe;
        if ( $size == 1 ) {
            push @outgoing, @$edge_dupe;
        }
        elsif ( $size == 2 ) {

            # make the edge be double arrowed to prevent too
            # many edges from making a mess on the screen
            my ( $a, $b ) = @$edge_dupe;
            my $new_edge = {
                'from'      => $a->{from},
                'to'        => $a->{to},
                'arrowhead' => $a->{arrowhead},
                'arrowtail' => $b->{arrowhead},    # this ones head is the other ones tail
                'via'       => $a->{via},
            };
            push @outgoing, $new_edge;
        }
        else {
            warn("unexpect edge duplication count: $size");
            push @outgoing, @$edge_dupe;
        }
    }

    return @outgoing;
}

sub do_graphviz {
    my ( $self, @plot_schemas ) = @_;

    my $graph = GraphViz->new();
    $graph->add_node( $_->id ) foreach @plot_schemas;
    foreach my $edge ( outgoing_edges( $self, @plot_schemas ) ) {
        $graph->add_edge(
            $edge->{from} => $edge->{to},
            arrowhead     => $edge->{arrowhead},
            arrowtail     => $edge->{arrowtail},
            style => $edge->{style} || 'solid',
            fontsize => $edge->{via} eq 'action' ? 8 : 12,
            label => $edge->{label} || ''
        );
    }
    $self->page( $graph->as_dot );

    return 1;
}

sub smry_graph {
    return "generate schema relationship graph for Graphviz or OmniGraffle"
}

sub help_graph {
    return <<HELP
Output a relationship graph of all of the schemas so that you can visualize
their relationships to one another.

This can be done for a single schema, non recursive; or for all schemas.

Usage:
gdapi-shell --config=yourconfig.yml graph > graph.dot
graph
graph [schema]
HELP
}

sub comp_graph {
    my $self = shift;
    return $self->schema_completion(@_);
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

u=cut
