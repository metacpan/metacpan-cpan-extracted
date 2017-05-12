
use 5.006;
use strict;
use B::Deparse;
use Data::Dumper;
use Test;

use lib qw(./t);

use define WARNINGS => {};

BEGIN {
  plan tests => 18;
  warn <<___;

**********************************************
***  These tests generate a few warnings.  ***
***           Do not be afraid.            ***
**********************************************
___
  $SIG{__WARN__} = sub { 
    my ($text) = @_;
    if ($text =~ /(constant|constant subroutine) ([\w:]+) redefined/) {
      # test BAZ warning
      WARNINGS->{$1}{$2}++;
      warn $text;
    }
    else {
      warn $text;
    }
  }
}


use define FOO => 1;
use define BAR => 0;
no  define BAZ =>;

use define QUX => 0..10;
use define {
  MUX => 1,
  MIX => 2,
  PIX => 3,
};

# some tests are also in this module
use MyModule1;
use MyModule2;

# simple tests
ok( FOO, 1 );
ok( BAR, 0 );
ok( BAZ, undef );
ok( (QUX)[4], 4 );
ok( MUX + MIX + PIX, 6 ); 

# no AFTER use 
no define GOO =>;
ok( ref GOO, 'MyModule2' );

# no AFTER use in same module
use define ZUM => 1;
no  define ZUM =>;
ok( ZUM, 1 );
ok( WARNINGS->{constant}{'main::ZUM'}, 1 );

# use AFTER no.
no  define ZOG =>;
# Implementation provides that "no define" does not produce constant 
# subroutines, otherwise ZOG would be undef here
ok( ZOG, 1 );
use define ZOG => 1;
ok( ZOG, 1 );
ok( WARNINGS->{constant}{'main::ZOG'}, 1 );

# no "constant subroutine redefined" warnings should have been emitted by Perl
ok( WARNINGS->{'constant subroutine'}, undef );

# check for proper constant folding optimizations
my $deparse = B::Deparse->new();
my $body = $deparse->coderef2text(\&MyModule1::test);
ok( ($body =~ /return 1 \+ BAZ \+ 0;/), 1 );

# check hashref definition style
