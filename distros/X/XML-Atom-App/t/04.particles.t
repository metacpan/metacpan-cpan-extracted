use Test::More tests => 8;

eval 'use DateTime;';
plan skip_all => 'DateTime required for testing RFC 3339 date stringification' if $@;

BEGIN {
use_ok( 'XML::Atom::App' );
}

diag( "Testing XML::Atom::App $XML::Atom::App::VERSION particle funtionality" );

my $particles = [
    {
        'title' => 'entry 1',
        'id'    => 1, # this is a bad id don't use it in real life
        'content' => 'entry 1 content',
        'author' => {
             'name' => 'Dan',  
        },
    },
    {
        'title' => 'entry 2',
        'id'    => 2, # this is a bad id don't use it in real life
        'content' => 'entry 2 content',
        'author' => {
             'name' => 'Dan',  
        },
    },
];

my $feed = XML::Atom::App->new(
    'id'    => 1, # this is a bad id don't use it in real life
    'title' => 'test',    
);

ok ( !$feed->entries(), 'empty intially');

$feed->create_from_atomic_structure( $particles );
ok ( $feed->entries() == 2, 'has particles');

$feed->clear_particles();
ok ( !$feed->entries(), 'clear_particles() removes particles');
ok ( $feed->{'time_of_last_create_from_atomic_structure'} == 0, 'clear_particles() resets time key');

$feed->create_from_atomic_structure( $particles );
$feed->create_from_atomic_structure( $particles );
ok ( $feed->entries() == 2, 'particles cleared ok');

$feed->create_from_atomic_structure( $particles, {'do_not_clear_particles'=> 1} );
ok( $feed->entries() == 4, 'do_not_clear_particles leaves existing in place');
ok( $feed->output_with_headers('hello') eq "Content-length: 5\nContent-type: application/atom+xml\n\nhello", 'output_with_headers() w/ arg');

# diag "Sample output of output_with_headers()";
# diag( $feed->output_with_headers() );
