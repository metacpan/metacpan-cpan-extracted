use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);

ok(
  !eval { require lib::with::preamble::example::strict; 1 },
  'strict example dies'
);

like($@, qr{Global symbol "\$orz" requires explicit package name(?: \([^)]+\))? at \S+lib/with/preamble/example/strict.pm line 3}, 'Error has right name and line');
