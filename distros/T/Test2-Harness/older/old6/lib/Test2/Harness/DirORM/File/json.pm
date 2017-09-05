package Test2::Harness::DirORM::File::json;
use strict;
use warnings;

use Carp qw/croak/;
use Test2::Harness::Util::JSON qw/encode_json decode_json/;

use parent 'Test2::Harness::DirORM::File';
use Test2::Harness::HashBase;

sub decode { shift; decode_json(@_) }
sub encode { shift; encode_json(@_) }

sub reset_line { croak "line reading is disabled for json files" }
sub read_line  { croak "line reading is disabled for json files" }

1;
