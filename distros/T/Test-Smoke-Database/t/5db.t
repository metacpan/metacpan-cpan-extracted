# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 2.t'


use Test::More;
use Test::Smoke::Database;
use Data::Dumper;
use File::Basename qw(basename dirname);

use strict;

my ($user, $password, $db);
# for graph test
my @file = qw!0.html 17500.html last50.html cpan.html cpan/1_perl_version.png
	      cpan/2_os.png cpan/3_os58.png cpan/4_os56.png cpan/5_os55.png!;
my @file2 = qw!3_nb_smoke.png 5_configure_by_os.png 7_conftested.png
               4_nb_configure.png 6_nb_os_by_smoke.png 90_os.png!;
my %file3 = ( "last50/4_nb_configure.png" => 1,
	      "last50/3_nb_smoke.png"     => 1 );
my @dir = qw!0 17500 last50!;
my $nbii = 64; # number of parsed reports

my $rep; 

# Count how many test
my $d = "cat t/result_normal";
$rep = eval `$d`;
my $tt = 0;
foreach my $f (keys %$rep) {
  $tt+= $#{$$rep{$f}}+1;
}

if (-e '.m') {
  plan tests => ($tt+ 9 + ($#file+1) + (($#file2+1)*3) - ((keys %file3)));
} else {
  plan skip_all => 'No advanced test asked at Makefile creation!';
}
if (open(F,".m")) {
  my $l = <F>; chomp($l);
  ($user, $password, $db) = split(/\t/, $l);
  close(F);
}
my $t = new Test::Smoke::Database({user     => $user, 
				   password => $password,
                                   database => $db,
                                   debug    => 0,
                                   limit    => 0,
                                   dir      => "t/rpt",
				   cgi      => new CGI
                                  });
ok($t, "Test::Smoke::Database defined with a database");
my $cmd = "$^X -Iblib/lib blib/script/admin_smokedb --user=$user --database=$db ";
$cmd.=" --password=$password " if ($password);

cmp_ok(system($cmd.'--create'),'==', 0, "admin_smokedb can create database");

cmp_ok($t->parse_import, "==", $nbii, "Parsing reports by parse_import");

cmp_ok(system($cmd.'--clear'),'==', 0, "admin_smokedb can clear database");

my %res;
ok(!$t->db->add_to_db, "Test::Smoke::Database->add_to_db null");

foreach my $f (keys %$rep) {
 cmp_ok($t->db->add_to_db($rep->{$f}[0]),'==',1, 
	"Test::Smoke::Database->add_to_db $f");
}
cmp_ok($t->db->nb, '==', scalar keys %$rep, 
	"Test::Smoke::Database->db->nb return good result");

ok($t->HTML->filter, "Test::Smoke::Database->HTML->filter return something");
ok($t->HTML->display, "Test::Smoke::Database->HTML->filter return something");

# graph tests. Need GD-Graph.
eval("use GD::Graph::mixed");
if ($@) {
  SKIP: {
   skip "You don't have GD-Graph installed !",
	((($#file2+1)*3) - ((keys %file3)) + ($#file+1));
   ok(1,"fake test");
  }
} else {
  $t->build_graph;
  foreach (@file) {
    if (/cpan/) {
     TODO: {
       local $TODO= "www interface of cpan tester has moved";
       cmp_ok(-e $_,"==",1, "Exist $_") or diag("on $_");
     }
    } else {
      cmp_ok(-e $_,"==",1, "Exist $_") 
	?  unlink($_)
	: diag("on $_");
    }
  }

  foreach (@file2) {
    foreach my $t (@dir) {
      my $f = $t.'/'.$_;
      next if ($file3{$f});
       (cmp_ok(-e $f,"==",1, "Exist $f") && unlink($f)) || diag("On $f");
      }
    }
  foreach (@dir) { rmdir($_); }
  rmdir("cpan");
}

# Drop database
cmp_ok(system($cmd.'--drop'),'==',0, "admin_smokedb can drop database");
