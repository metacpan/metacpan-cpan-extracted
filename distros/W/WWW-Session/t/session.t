#!perl

use Test::More tests => 51;
use Test::Exception;

use_ok('WWW::Session');

lives_ok { WWW::Session->add_storage('File',{path => '.'}) } 'File storage added';
lives_ok { WWW::Session->serialization_engine('JSON') } 'JSON serialization configured';

{ #find
	note("tests for save() & find()");
	
	my $session = WWW::Session->new('123',{a => 1, b => 2});

	ok(defined $session,"Session created");

	is($session->sid(),'123','Sid ok');

	is($session->get('a'),1,'Value for a is correct');
	is($session->get('b'),2,'Value for b is correct');
	
	$session->save();
	
	my $session2 = WWW::Session->find('123');
	
	ok(defined $session2,"Session found after save");
	
	is($session2->sid(),'123','Sid for session 2ok');

	is($session2->get('a'),1,'Value for a from session2 is correct');
	is($session2->get('b'),2,'Value for b from session2 is correct');
	
	$session2->destroy();
	$session->destroy();
}


{ #find or create
	note("tests for save() & find_or_create()");
	
	my $session = WWW::Session->new('123',{a => 1, b => 2});

	ok(defined $session,"Session created");

	is($session->sid(),'123','Sid ok');

	is($session->get('a'),1,'Value for a is correct');
	is($session->get('b'),2,'Value for b is correct');
	
	$session->save();
	
	my $session2 = WWW::Session->find_or_create('123',{a => 3, c => 4});
	
	ok(defined $session2,"Session found after save");
	
	is($session2->sid(),'123','Sid for session 2ok');

	is($session2->get('a'),3,'Value for a from session2 is correct');
	is($session2->get('b'),2,'Value for b from session2 is correct');
	is($session2->get('c'),4,'Value for c from session2 is correct');
	
	$session2->destroy();
	$session->destroy();
}


{ #simple set
	note("tests for set() without filters");
	
	my $session = WWW::Session->new('123',{a => 1, b => 2});

	ok(defined $session,"Session created");

	is($session->sid(),'123','Sid ok');

	is($session->get('a'),1,'Value for a is correct');
	is($session->get('b'),2,'Value for b is correct');
	
	$session->set('a',3);
	
	is($session->get('a'),3,'Value for a after set is correct');
	
	$session->save();
	
	my $session2 = WWW::Session->find('123');
	
	ok(defined $session2,"Session found after save");
	
	is($session2->sid(),'123','Sid for session 2ok');

	is($session2->get('a'),3,'Value for a from session2 is correct');
	is($session2->get('b'),2,'Value for b from session2 is correct');
	
	$session2->destroy();
	$session->destroy();
}


{ #autosave - on
	note("tests for autosave(1)");
	
	#see it if works with autosave enabled 
	{
		my $session = WWW::Session->new('autosave1',{a => 1, b => 2});
		ok(defined $session,"Session sample 1 created");
	}
	
	my $session2 = WWW::Session->find('autosave1');
	ok(defined $session2,"Session found after autosavesave");
	$session2->destroy();
}

{ #autosave - off
	note("tests for autosave(0)");
	
	WWW::Session->autosave(0);
	#see it if works with autosave enabled 
	{
		my $session = WWW::Session->new('autosave2',{a => 1, b => 2});
		ok(defined $session,"Session sample 2 created");
	}
	
	my $session2 = WWW::Session->find('autosave2');
	is($session2,undef,"Session not found with autosavesave disabled");
	
	WWW::Session->autosave(1);
}

{ #destroy
	note("tests for autosave(3)");
	
	#see it if works with autosave enabled 
	my $session = WWW::Session->new('autosave3',{a => 1, b => 2});
	ok(defined $session,"Session sample31 created");
	
	$session->save();
	
	$session->destroy();
	
	is($session,undef,"Session object destroyed by destroy()");
	
	$session = WWW::Session->find('autosave3');
	
	is($session,undef,"Session not found after destroy()");
}


{ #filters 
	
	note("Filters tests");
	
	WWW::Session->setup_field('age',filter => [18..20] );
	
	my $session = WWW::Session->new('filter_test1',{});
		
	ok($session->set('age',20),'Value 20 for age accepted');
	
	ok(! $session->set('age',15),'Value 15 for age refused!');
	
	$session->destroy();
	
	WWW::Session->setup_field('age',filter => sub { $_[0] > 18 } );
	
	$session = WWW::Session->new('filter_test1',{});
		
	ok($session->set('age',20),'Value 20 for age accepted (test2)');
	
	ok(! $session->set('age',15),'Value 15 for age refused! (test2)');
	
	$session->destroy();
}

{ #inflate/deflate 
	
	note("inflate/deflate tests");
	
	WWW::Session->setup_field('user',
							  filter => {isa => "WWW::Session::MockObject"},
							  inflate => sub { return WWW::Session::MockObject->new($_[0]) },
							  deflate => sub { return $_[0]->id() }
							 );
	
	my $session = WWW::Session->new('inflate_test1',{});
	
	ok( $session->set('user',WWW::Session::MockObject->new(1)),"ISA filter passed" );
	
	lives_ok { $session->save(); } "Save with deflate works";
	
	my $session2 = WWW::Session->find('inflate_test1');
	
	my $user = $session2->get('user');
	
	isa_ok($user,"WWW::Session::MockObject","User inflated");
	
	is($user->id(),1,"user id verified");
	is($user->a(),1,"user property a verified");
	is($user->b(),2,"user property b verified");
	
	ok(! $session2->set('user','string'),'User must be an object');
	
	$session2->destroy();
	$session->destroy();
}


{ #autoload
	
	note("autoload tests");
	
	my $session = WWW::Session->new('autoload1',{a=>1,b=>2});
	
	is($session->a(),1,'Get works');
	is($session->b(3),3,"Set works");
	is($session->c(),undef,"Get on unknown values is undef");
	is($session->c(4),4,"Set on unknown values works");
	
	$session->destroy();
}


package WWW::Session::MockObject;

sub new {
	my ($class,$id) = @_;
	
	my %data = (
		1 => { a=>1, b=>2},
		2 => { a=>3, b=>4},
	);

	my $self = {
				id => $id,
				data => $data{$id},
	};
	
	bless $self, $class;
		
	return $self;
}
	
sub id { return $_[0]->{id} }
sub a { return $_[0]->{data}->{a} }
sub b { return $_[0]->{data}->{b} }

1;