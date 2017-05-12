
use Test::More tests => 11;

use Dancer qw(!pass);
use Web::DataService;

my ($ds, @vocabs, @formats, @values, $rs);

eval {
    
    Web::DataService->set_mode('quiet');
    
    $ds = Web::DataService->new({ name => 'a', title => 'Test',
				  features => 'standard', special_params => 'standard' });
    
    $ds->define_vocab(
	{ name => 'testvocab', title => 'Test vocabulary' },
	    "This vocabulary is for testing purposes only.");
    
    @vocabs = $ds->list_vocabs;
    
    $ds->define_format(
	{ name => 'json', doc_node => 'formats/json', title => 'JSON' },
	    "The JSON format is intended primarily to support client applications.",
	{ name => 'test', doc_node => 'formats/text', title => 'Test format',
	  module => 'Web::DataService::Plugin::Text', content_type => 'test' },
	    "This dummy format is for testing purposes only.");
    
    @formats = $ds->list_formats;
    
    $ds->define_node(
	{ path => '/', title => 'Test documentation',
	  public_access => 1 },
	{ path => 'foo', title => 'Foo', output => 'basic' });
    
    $ds->define_block( 'basic' =>
	{ output => 'foo' },
	     "Test field 'foo'",
	{ output => 'bar' },
	     "Test field 'bar'");
    
    $ds->define_ruleset( 'foo' =>
	{ param => 'bar' },
	    "Test param 'bar'",
	{ optional => 'baz' },
	    "Test param 'baz'");
    
    $rs = $ds->ruleset_defined('foo');
    
    $ds->define_set( 'testset' =>
	{ value => 'foo', maps_to => 'fooA' },
	    "Value 'foo'",
	{ value => 'bar', maps_to => 'barA' },
	    "Value 'bar'");
    
    @values = $ds->list_set_values('testset');
};

ok( !$@, 'basic definitions' ) or diag( "    message was: $@" );

isa_ok( $ds, 'Web::DataService', 'web service object' );

is( scalar(@vocabs), 2, 'number of vocabs' );

isa_ok( $ds->{vocab}{testvocab}, 'Web::DataService::Vocab', 'vocabulary object' );

is( scalar(@formats), 2, 'number of formats' );

isa_ok( $ds->{format}{test}, 'Web::DataService::Format', 'format object' );

is( scalar(@values), 2, 'number of set elements' );

isa_ok( $ds->{set}{testset}, 'Web::DataService::Set', 'set object' );

is( $ds->node_attr('/', 'title'), 'Test documentation', 'root node attribute' );

is_deeply( $ds->node_attr('foo', 'output'), ['basic'], 'set-type node attribute' );

is( $ds->node_attr('foo', 'public_access'), 1, 'inherited node attribute' );

