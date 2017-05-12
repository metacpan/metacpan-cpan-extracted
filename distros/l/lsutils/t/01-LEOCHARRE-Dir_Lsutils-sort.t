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

   $r = sort_by_stat( $statnum, @rels );
   ok $r, "sort_by_stat() $statnum";
   ok ref $r, "got ref";
   warn "## by stat $statnum\n";
   map { warn "  - $_\n" } @$r;

   @r = sort_by_stat( $statnum, @rels );
   ok @r, "sort_by_stat() list context";
   
   ok( ( @r == @rels ), "got count expected");
   warn "\n\n";

}

no strict 'refs';


for my $subname ( qw/sort_by_atime sort_by_mtime sort_by_size sort_by_ctime/ ){
   my (@r,$r);

   $r = &$subname( @rels );
   ok $r, "subname: $subname";
   ok ref $r, "got ref";
   warn "## $subname: \n";
   map { warn "  - $_\n" } @$r;

   @r = &$subname( @rels );
   ok @r, "sort_by_stat() list context";
   
   ok( ( @r == @rels ), "got count expected");
   warn "\n\n";

}












sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


