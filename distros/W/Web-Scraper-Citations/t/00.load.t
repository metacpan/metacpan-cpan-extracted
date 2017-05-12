use Test::More; # -*-cperl-*-

use lib qw(../lib lib);

BEGIN {
  use_ok( 'Web::Scraper::Citations' );
}

diag( "Testing Web::Scraper::Citations $Web::Scraper::Citations::VERSION" );

my $person;
my $id = "gFxqc64AAAAJ";
eval {
  $person = Web::Scraper::Citations->new( $id ); #That's me
};

if ( $person ) {
  isa_ok( $person, "Web::Scraper::Citations");
}

my $test_file;
my $file_name = "citations-jj.html";
if ( -e $file_name ) {
  $test_file =  $file_name;
} elsif  ( -e "t/$file_name" ) {
  $test_file = "t/$file_name";
} else {
  done_testing( "Can't find test file" )
}

$person = Web::Scraper::Citations->new( "file:$test_file" ); #from file
ok( $person->name =~ /Merelo/, "Name OK");
is( $person->id, $id, "ID OK");
is( $person->affiliation, "Professor of Computer Architecture, University of Granada", "Affiliation OK");
ok( $person->h >= 26, "h OK" );
my %stats = %{$person->profile_stats};
ok( keys( %stats ) > 0, "Stats returned" );
ok( $stats{'h'} == $person->h, "Returned singing" );
done_testing();
