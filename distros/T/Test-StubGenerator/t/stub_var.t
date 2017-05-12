#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN {
  eval "use Test::Warn";
  plan skip_all => 'Test::Warn required for tests' if $@;
}

plan tests => 5;

use_ok( 'Test::StubGenerator' );

my $source = 'sub hithere { return \"hello\" }';
ok( my $stub = Test::StubGenerator->new( { source => \$source, tidy => 0, }  ),
    'can call new' );

ok( my $output = $stub->gen_testfile, 'got output' ),
warnings_like { $stub->gen_testfile() } [ qr/No packages found/ ];

my $expected = return_var_expected();

is( $output, $expected, 'got back what we were expecting' );

sub return_var_expected {
  return <<'END_EXPECTED';
#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;


# And now to test the methods/subroutines.
ok( hithere(), 'can call hithere() without params' );


END_EXPECTED
}
