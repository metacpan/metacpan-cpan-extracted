package Test2::Harness::Schema;
use strict;
use warnings;

use Carp qw/confess/;

use Test2::Harness::Util::HashBase qw/-test/;

sub supports   { 0 }
sub can_insert { 0 }
sub can_fetch  { 0 }

sub run_fetch  { confess "'run_fetch' not implemented" }
sub run_insert { confess "'run_insert' not implemented" }
sub run_poll   { confess "'run_poll' not implemented" }
sub run_list   { confess "'run_list' not implemented" }

sub job_fetch  { confess "'job_fetch' not implemented" }
sub job_insert { confess "'job_insert' not implemented" }
sub job_poll   { confess "'job_poll' not implemented" }
sub job_list   { confess "'job_list' not implemented" }

sub event_fetch  { confess "'event_fetch' not implemented" }
sub event_insert { confess "'event_insert' not implemented" }
sub event_poll   { confess "'event_poll' not implemented" }
sub event_list   { confess "'event_list' not implemented" }

1;
