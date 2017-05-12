use Test::More;
use Test::Mojo::Pg;
use File::Basename;
my $host = 'ananke';
my $sql1 = dirname(__FILE__) . '/db1.sql';

unless ( $ENV{TEST_MOJO_PG_LIVE} ) {
  plan skip_all => "Live tests by default are skipped.";
}

isa_ok my $d1 = Test::Mojo::Pg->new(host => 'ananke', db => 'mydb'), 'Test::Mojo::Pg';
$d1->verbose(1);
ok $d1->construct;
ok $d1->deconstruct;
isa_ok my $d2 =  Test::Mojo::Pg->new(host => 'ananke', db => 'mydb', migsql => $sql1), 'Test::Mojo::Pg';
ok $d2->construct;
ok $d2->deconstruct;

isa_ok my $d3 =  Test::Mojo::Pg->new(host => 'ananke',
                                     db => 'mydb',
                                     migsql => $sql1,
                                     username => 'foo',
                                     password => 'foo'), 'Test::Mojo::Pg';
$d3->verbose(1);
ok $d3->construct;
ok $d3->deconstruct;


done_testing();
