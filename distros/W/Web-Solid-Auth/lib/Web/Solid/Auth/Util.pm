package Web::Solid::Auth::Util;

use Moo;
use Attean;
use Attean::RDF qw(iri);

our $GNAME = 'http://graph-name/'; 

sub parse_turtle {
    my ($self, $turtle) = @_;

    my $store  = Attean->get_store('Memory')->new();
    my $parser = Attean->get_parser('Turtle')->new();
    
    my $iter = $parser->parse_iter_from_bytes($turtle);

    return undef unless $iter;

    my $graph = iri($GNAME);
    my $quads = $iter->as_quads($graph);

    $store->add_iter($quads);

    my $model = Attean::QuadModel->new( store => $store );

    return $model;
}

sub sparql {
    my ($self, $model, $sparql, $cb) = @_;

    my $s = Attean->get_parser('SPARQL')->new();
    my ($algebra) = $s->parse($sparql);
    my $graph = iri($GNAME);
    my $results = $model->evaluate($algebra, $graph);

    while (my $r = $results->next) {
        $cb->($r);
    }
}

1;
