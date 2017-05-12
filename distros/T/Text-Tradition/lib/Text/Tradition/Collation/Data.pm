package Text::Tradition::Collation::Data;
use Moose;
use Graph;
use Text::Tradition::Datatypes;

has 'sequence' => (
    is => 'ro',
    isa => 'Graph',
    default => sub { Graph->new() },
    handles => {
    	paths => 'edges',
    },
    );
    
has 'relations' => (
	is => 'ro',
	isa => 'Text::Tradition::Collation::RelationshipStore',
	handles => {
		relationships => 'relationships',
		related_readings => 'related_readings',
		get_relationship => 'get_relationship',
		del_relationship => 'del_relationship',
		equivalence => 'equivalence',
		equivalence_graph => 'equivalence_graph',
		relationship_types => 'types'
	},
	writer => '_set_relations',
	);

has 'readings' => (
	isa => 'HashRef[Text::Tradition::Collation::Reading]',
	traits => ['Hash'],
    handles => {
        reading     => 'get',
        _add_reading => 'set',
        del_reading => 'delete',
        has_reading => 'exists',
#        reading_keys => 'keys',
        readings   => 'values',
    },
    default => sub { {} },
	);

has 'wit_list_separator' => (
    is => 'rw',
    isa => 'Str',
    default => ', ',
    );

has 'baselabel' => (
    is => 'rw',
    isa => 'Str',
    default => 'base text',
    );

has 'linear' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
    );
    
has 'ac_label' => (
    is => 'rw',
    isa => 'Str',
    default => ' (a.c.)',
    );
    
has 'wordsep' => (
	is => 'rw',
	isa => 'Str',
	default => ' ',
	);
	
has 'direction' => (
	is => 'ro',
	isa => 'TextDirection', 
	default => 'LR',
	writer => 'change_direction',
	);
    
has 'start' => (
	is => 'ro',
	isa => 'Text::Tradition::Collation::Reading',
	writer => '_set_start',
	weak_ref => 1,
	);

has 'end' => (
	is => 'ro',
	isa => 'Text::Tradition::Collation::Reading',
	writer => '_set_end',
	weak_ref => 1,
	);
	
has 'cached_table' => (
	is => 'rw',
	isa => 'HashRef',
	predicate => 'has_cached_table',
	clearer => 'wipe_table',
	);
	
has '_graphcalc_done' => (
	is => 'rw',
	isa => 'Bool',
	default => undef,
	); 

1;
