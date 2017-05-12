package indirect::TestCompilationError;
use strict;
use warnings;
no indirect 'fatal';
sub foo { $bar }
baz $_;
sub qux { $ook }
1
