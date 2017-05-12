#!perl

use Test::More;
use Test::Exception;

use_ok('WWW::Session');

lives_ok { WWW::Session->add_storage('File',{path => '.'}) } 'File storage added';
lives_ok { WWW::Session->serialization_engine('JSON') } 'JSON serialization configured';

{ #before_set_value 
	
	note("before_set_value");

	WWW::Session->setup_field('age',trigger => {
	    before_set_value => sub { $_[1]++ },
	});
	
	my $session = WWW::Session->new('trigger_test_before_set_value',{});
		
	ok($session->set('age',20),'Value 20 for age accepted');
	
	is($session->get('age'),21,'before_set_value trigger worked');
	
	$session->destroy();
}


{ #after_set_value 
	
	note("after_set_value");

	WWW::Session->setup_field('age',trigger => {
	    after_set_value => sub { $_[1]++; $_[0]->set('x',1); },
	});
	
	my $session = WWW::Session->new('trigger_test_after_set_value',{});
		
	ok($session->set('age',20),'Value 20 for age accepted');
	
	is($session->get('x'),1,'after_set_value trigger worked');
	
	is($session->get('age'),20,'after_set_value trigger did not change the value');
	
	$session->destroy();
}


{ #before_delete
	
	note("before_delete");

	WWW::Session->setup_field('age',trigger => {
	    before_delete => sub { $_[0]->set('x',2) },
	});
	
	my $session = WWW::Session->new('trigger_test_before_delete',{});
		
	ok($session->set('age',20),'Value 20 for age accepted');
	
	is($session->delete('age'),20,'Delete returned previous value');

	is($session->get('age'),undef,'Delete worked');
	
	is($session->get('x'),2,'before_delete trigger worked');
	
	$session->destroy();
}


{ #after_delete
	
	note("after_delete");

	WWW::Session->setup_field('age',trigger => {
	    after_delete => sub { $_[0]->set('x',3) },
	});
	
	my $session = WWW::Session->new('trigger_test_after_delete',{});
		
	ok($session->set('age',20),'Value 20 for age accepted');
	
	is($session->delete('age'),20,'Delete returned previous value');

	is($session->get('age'),undef,'Delete worked');
	
	is($session->get('x'),3,'before_delete trigger worked');
	
	$session->destroy();
}

done_testing();