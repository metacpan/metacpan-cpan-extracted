use Test::More tests => 7;

BEGIN {
use_ok( 'XML::Atom::App' );
}

diag( "Testing XML::Atom::App $XML::Atom::App::VERSION source functionality" );

my $feed = XML::Atom::App->new({
    'id'    => 1, # this is a bad id don't use it in real life
    'title' => 'test',
    'particles' => [
        {
            'id' => 1, # Should use a read id in an actual application
            'content' => 'entry from elsewhere',
            'title' => 'Entry from Elsewhere',
            'source' => {
                'author' => { name => 'Wade' },
                'category' => [
                    {term=>'news', label=>'News'},
                ],
                rights => 'Copyright 2008',
            },
        },
    ],
});

isa_ok( $feed, 'XML::Atom::App' );
my ($entry) = $feed->entries();
isa_ok( $entry, 'XML::Atom::Entry' );

# Have to do this mess because XML::Atom does not return a source-type object.
my $entry_xml = $entry->as_xml;
like( $entry_xml, qr/<source>/, 'source tag exists' );
like( $entry_xml, qr/<category[^>]*term=.news./, 'category is correct' );
like( $entry_xml, qr/<rights>Copyright 2008/, 'Rights are there.' );
like( $entry_xml, qr/<name>Wade/, 'Author is there.' );

