use Test::More tests => 13;

BEGIN {
use_ok( 'XML::Atom::App' );
}

diag( "Testing XML::Atom::App $XML::Atom::App::VERSION" );

my $test = XML::Atom::App->new({'id'=>'123','title'=>'feed title','particles'=>[{'id'=>3,'content'=>'hello'},{'id'=>2,'content'=>'goodbye'}]});

# diag($test->as_xml);
my $author = XML::Atom::Person->new();
$author->name("dan");
$test->author( $author);
ok( $test->id() eq '123', 'id key new()');
ok( $test->title() eq 'feed title', 'title key new()');
ok( $test->link->rel() eq 'self', 'default rel=self new()');
$test->clear_particles();
# diag($test->as_xml);

ok( $test->id() eq '123', 'clear_particles() only removes entries)');

ok( ref XML::Atom::App->new() eq 'XML::Atom::App', 'ref type new()' );

ok( XML::Atom::App->new()->version() eq '1.0', 'Default to Atom 1.0' );
ok( XML::Atom::App->new({'Version'=> '0.3'})->version() eq '0.3', 'Version key in new()' );

ok( XML::Atom::App->new()->{'alert_cant'} eq '', 'no alert_cant key in new()' );
ok( XML::Atom::App->new({'alert_cant' => 'not code'})->{'alert_cant'} eq '', 'invalid alert_cant key in new()' );
ok( ref XML::Atom::App->new({'alert_cant' => sub {} })->{'alert_cant'} eq 'CODE', 'valid alert_cant key in new()' );

ok( XML::Atom::App->new()->{'time_of_last_create_from_atomic_structure'} eq 0, 'no particles' );
ok( XML::Atom::App->new({'particles' => [{'id'=>1,'content'=>'hello'},{'id'=>2,'content'=>'goodbye'}] })->{'time_of_last_create_from_atomic_structure'} > 0, 'particles implies create_from_atomic_structure()' );