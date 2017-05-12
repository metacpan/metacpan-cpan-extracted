use Test::More tests => 16;

BEGIN {
use_ok( 'XML::Atom::App' );
}

diag( "Testing XML::Atom::App $XML::Atom::App::VERSION contributor functionality" );

my $single_contrib = [
    {
        'title' => 'entry 1',
        'id'    => 1, # this is a bad id don't use it in real life
        'content' => 'entry 1 content',
        'author' => {
             'name' => 'Dan',  
        },
        'contributor' => {
            'name' => 'G. Wade',
        },
    },
];

my $feed = XML::Atom::App->new({
    'id'    => 1, # this is a bad id don't use it in real life
    'title' => 'test',
    'contributor' => {
        'name' => 'Wade',
    },
});

isa_ok( ($feed->contributors())[0], 'XML::Atom::Person', 'Feed contributor is a Person' );
is( ($feed->contributors())[0]->name(), 'Wade', 'Correct name is there' );

ok ( !$feed->entries(), 'empty intially');

$feed->create_from_atomic_structure( $single_contrib );
ok ( $feed->entries() == 1, 'has particles');

my $entry = ($feed->entries())[0];
is( ($entry->contributors())[0]->name(), 'G. Wade', 'entry contributor name is correct.' );
is( ($feed->contributors())[0]->name(), 'Wade', 'Feed contributor name is still there' );


my $mult_contrib = [
    {
        'title' => 'entry 1',
        'id'    => 1, # this is a bad id don't use it in real life
        'content' => 'entry 1 content',
        'author' => {
             'name' => 'Dan',  
        },
        'contributor' => [ 
            { 'name' => 'G. Wade' },
            { 'name' => 'Fred' },
        ],
    },
];

$feed = XML::Atom::App->new({
    'id'    => 1, # this is a bad id don't use it in real life
    'title' => 'test',
    'contributor' => [ 
        { 'name' => 'Fred' },
        { 'name' => 'Bianca' },
    ],
});

my @contribs = $feed->contributors();
is( scalar(@contribs), 2, 'There are two feed contributors' );

foreach my $c ( @contribs ) {
    isa_ok( $c, 'XML::Atom::Person', 'Feed contributor is a Person' );
}
is( $contribs[0]->name(), 'Fred', '0: feed Correct name is there' );
is( $contribs[1]->name(), 'Bianca', '1: feed Correct name is there' );


$feed->create_from_atomic_structure( $mult_contrib );
ok ( $feed->entries() == 1, 'has particles');

$entry = ($feed->entries())[0];
@contribs = $entry->contributors();
is( scalar(@contribs), 2, 'There are two entry contributors' );
is( $contribs[0]->name(), 'G. Wade', '0: feed Correct name is there' );
is( $contribs[1]->name(), 'Fred', '1: feed Correct name is there' );
