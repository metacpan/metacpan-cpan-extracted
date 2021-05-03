#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use xDT::RecordType;

plan tests => 6;

can_ok 'xDT::RecordType', 'new';

subtest 'constructor array params', sub {
	isa_ok my $record_type = xDT::RecordType->new(id => 8000), 'xDT::RecordType';
	is $record_type->get_id, 8000, 'id should be correct';
};

subtest 'should set instance attributes', sub {
	isa_ok my $record_type = xDT::RecordType->new(id => 8000), 'xDT::RecordType';
	is $record_type->get_id, 8000, 'id should be correct';
	is $record_type->get_accessor, '8000', 'accessor should be 8000';
};

subtest 'should be object end', sub {
	isa_ok my $record_type = xDT::RecordType->new(id => 8003), 'xDT::RecordType';
	is $record_type->is_object_end, 1, '8003 should be end of object';
};

subtest 'should not be object end', sub {
	isa_ok my $record_type = xDT::RecordType->new(id => 8000), 'xDT::RecordType';
	ok !$record_type->is_object_end, '8000 should not be end of object';
};

subtest 'id should not be too long', sub {
	my $success = eval { xDT::RecordType->new(id => 99999) };
	ok !$success, 'too long id should result in error';
};

done_testing;
