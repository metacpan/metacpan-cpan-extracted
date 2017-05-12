package FormatTests;

# abstract superclass for FormatTest::{XML,JSON}

use strict;
use warnings;
use Test::More;

my $_abstract_sub = sub {
   die "implement me";
};




sub num_sales     { $_abstract_sub->(); }
sub num_all_sales { $_abstract_sub->(); }
sub get_col       { $_abstract_sub->(); }
sub to_hash       { $_abstract_sub->(); }





sub has_none {
   my $self = shift;
   my $r = shift;
   is($r->code(), 400, 'http 400');
   my $list = $self->to_hash($r->content());
   my $error_code = $self->error_code($list);
   ok($error_code eq 'RECORD_NOT_FOUND', "none found, as expected");
}



sub has_records {
   my $self = shift;
   my $r = shift;
   my $record_type = shift;
   is($r->code(), 200, 'http 200');
   my $list = $self->to_hash($r->content());
   my $num_records = $self->count_records($list, $record_type);
   ok($num_records > 0 , "got $num_records $record_type");
   return $num_records;
}


1;
