#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use xDT::Record;
use xDT::RecordType;

plan tests => 4;

isa_ok my $record = xDT::Record->new("01380006311\r\n"), 'xDT::Record';
$record->set_record_type(xDT::RecordType->new(id => 8000));

is $record->get_id, 8000, 'id should be 8000';
is $record->get_length, '013', 'length should be 013';
is $record->get_value, '6311', 'value should be 6311';

done_testing;
