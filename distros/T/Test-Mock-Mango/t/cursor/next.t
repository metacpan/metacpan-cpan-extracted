#!/usr/bin/env perl

use Test::More;
use Mango;

use Test::Mock::Mango;
use Test::Mock::Mango::Cursor;

subtest "Blocking syntax" => sub {
	my $cursor = undef;

	$cursor = Test::Mock::Mango::Cursor->new;
	is $cursor->next->{name}, 'Homer Simpson', 'Get next doc';
	is $cursor->next->{name}, 'Marge Simpson', 'Get next doc';
	is $cursor->next->{name}, 'Bart Simpson',  'Get next doc';
	is $cursor->next->{name}, 'Lisa Simpson',  'Get next doc';
	is $cursor->next->{name}, 'Maggie Simpson','Get next doc';
	is $cursor->next, undef, 'Out of docs';

	$Test::Mock::Mango::error = 'oh noes';
	$cursor = Test::Mock::Mango::Cursor->new;
	is $cursor->next, undef, 'returns undef as expected';
	is $Test::Mock::Mango::error, undef, 'error reset';
};


subtest "Non blocking syntax" => sub {
	my $cursor = Test::Mock::Mango::Cursor->new;

	$cursor->next( sub {
		my ($self,$err,$doc) = @_;
		is($doc->{name}, 'Homer Simpson', 'Get next doc');
	});

	$cursor->next( sub {
		my ($self,$err,$doc) = @_;
		is($doc->{name}, 'Marge Simpson', 'Get next doc');
	});

	$cursor->next( sub {
		my ($self,$err,$doc) = @_;
		is($doc->{name}, 'Bart Simpson', 'Get next doc');
	});

	$cursor->next( sub {
		my ($self,$err,$doc) = @_;
		is($doc->{name}, 'Lisa Simpson',  'Get next doc');
	});

	$cursor->next( sub {
		my ($self,$err,$doc) = @_;
		is($doc->{name}, 'Maggie Simpson',  'Get next doc');
	});

	$cursor->next( sub {
		my ($self,$err,$doc) = @_;
		is($doc, undef, 'Out of docs');
	});	


	$Test::Mock::Mango::error = 'oh noes';
	$cursor = Test::Mock::Mango::Cursor->new;
	$cursor->next( sub {
		my ($self,$err,$doc) = @_;
		is $doc, undef, 'returns undef as expected';
		is $err, 'oh noes', 'error returned as expected';
		is $Test::Mock::Mango::error, undef, 'error reset';
	});		
	
};


done_testing();
