use Test::Simple 'no_plan';
use strict;
use lib './lib';
require 't/testing.pl';
use Cwd;
use vars qw($_part $cwd);
use LEOCHARRE::Dir::Lsutils ':all';
$cwd = cwd();

cleanup();

my @rels = setup();
ok @rels;
my $rcount = @rels;


ok_part('sorting.. ');


for my $statnum ( qw/7 8 9 8 10/ ){
   my (@r,$r);

   $r = most_by_stat( $statnum, @rels );

   ok $r, "most_by_stat() $statnum";
   warn "## most by stat $statnum : $r\n";

   @r = most_by_stat( $statnum, @rels );
   ok @r, "most_by_stat() list context";

   warn " # - in list context: @r\n";
   
   warn "\n\n";


   $r = least_by_stat( $statnum, @rels );
   ok $r, "least_by_stat() $statnum";
   warn "## least by stat $statnum: $r\n";

   @r = least_by_stat( $statnum, @rels );
   ok @r, "least_by_stat() list context";

   warn " # - in list context: @r\n";
   
   warn "\n\n";

}

no strict 'refs';






ok_part('direct subs , shortcuts..');

for my $subname ( qw/newest oldest biggest smallest/ ){
   my (@r,$r);

   $r = &$subname( @rels );
   ok $r, "subname: $subname";
   
   warn "## $subname, got $r\n";

   @r = &$subname( @rels );
   ok @r, "$subname () list context";
   
   warn " # Got: @r\n\n";

}












sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


