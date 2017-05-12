use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();

ok 1;

if (1){
   warn "# skipping..";
   exit;
}

require 'bin/textrender';


ok(1);

my $t = TextRender->new;

ok($t,'TextRender new');

ok_part('getting font list.. might take a while..');
my @fonts = $t->abs_fonts;
ok( @fonts, 'abs_fonts()');



















sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}



