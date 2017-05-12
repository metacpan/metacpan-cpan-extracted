# -*-perl-*-
#use Test::More tests => 8;
use Test::More qw(no_plan);
use Data::Dumper;

my $expect = {
	        1 => {
		      'date' => '23.12.2000 10:33:02',
		      'note' => 'any new text'
		     },
	        2 => {
		      'date' => '03.02.2004 18:13:52',
		      'note' => 'yet whatever you mean'
		     }
	       };


BEGIN { use_ok "NOTEDB" };
require_ok("NOTEDB");
my $key = '01010101';
my $alg = 'Rijndael';

foreach my $CR (1 .. 0) {
  $NOTEDB::crypt_supported = $CR;
  
  SKIP: {
    skip "no crypt", 1 if $CR; # FIXME: for some weird reason, crypto doesn't work with ::binary?
    eval { require NOTEDB::binary; };
    skip "Fatal, skipping test for NOTEDB::binary", 1 if $@;
    unlink "t/binary.out";
    my $db = new NOTEDB::binary(dbname => "t/binary.out");
    $db->use_crypt($key, $alg) if $CR;
    ok(ref($db), "Database object loaded");
    &wrdb($db, "NOTEDB::binary");
  }

  SKIP: {
    eval { require NOTEDB::general; };
    skip "Config::General not installed, skipping test for NOTEDB::general", 1 if $@;
    unlink "t/general.out";
    my $db2 = NOTEDB::general->new(dbname => "t/general.out");
    $db2->use_crypt($key, $alg) if $CR;
    ok(ref($db2), "Database object loaded");
    &wrdb($db2, "NOTEDB::general");
  }

  SKIP: {
    eval { require NOTEDB::text; };
    skip "Storable not installed, skipping test for NOTEDB::text", 1 if $@;
    unlink "t/test.out";
    my $db3 = NOTEDB::text->new(dbname => "t/text.out");
    $db3->use_crypt($key, $alg) if $CR;
    ok(ref($db3), "Database object loaded");
    &wrdb($db3, "NOTEDB::text");
  }

  SKIP: {
    eval { require NOTEDB::dumper; };
    skip "Data::Dumper not installed, skipping test for NOTEDB::dumper", 1 if $@;
    unlink "t/dumper.out";
    my $db4 = NOTEDB::dumper->new(dbname => "t/dumper.out");
    $db4->use_crypt($key, $alg) if $CR;
    ok(ref($db4), "Database object loaded");
    &wrdb($db4, "NOTEDB::dumper");
  }

  SKIP: {
    eval { require NOTEDB::dbm; };
    skip "DB_File not installed, skipping test for NOTEDB::dbm", 1 if $@;
    unlink "t/note.dbm";
    unlink "t/date.dbm";
    my $db5 = NOTEDB::dbm->new(dbname => "t");
    $db5->use_crypt($key, $alg) if $CR;
    ok(ref($db5), "Database object loaded");
    &wrdb($db5, "NOTEDB::dbm");
  }
}

SKIP: {
  eval { require NOTEDB::pwsafe3; };
  skip "Crypt::PWSafe3 not installed, skipping test for NOTEDB::pwsafe3", 1 if $@;
  unlink "t/pwsafe3.out";
  my $db6 = NOTEDB::pwsafe3->new(dbname => "t/pwsafe3.out");
  $db6->{key} = "01010101";
  ok(ref($db6), "Database object loaded");
  &wrdb3($db6, "NOTEDB::pwsafe3");
}

sub wrdb {
  my ($db, $name) = @_;
  is_deeply($db->{use_cache}, undef, "$name: Chache disabled");

  $db->set_new(1, $expect->{1}->{note}, $expect->{1}->{date});
  my ($note, $date) = $db->get_single(1);
  like($note, qr/any new text/, "$name: Retrieve newly written entry content");
  like($date, qr/^\d\d/,        "$name: Retrieve newly written entry date");

  $db->set_new(2, $expect->{2}->{note}, $expect->{2}->{date});

  my $next = $db->get_nextnum();
  is_deeply($next, 3, "$name: Get next note id");

  my %all = $db->get_all();
  is_deeply($expect, \%all, "$name: Get all notes hash") or diag(Dumper(\%all));
}

sub wrdb3 {
  my ($db, $name) = @_;
  is_deeply($db->{use_cache}, undef, "$name: Chache disabled");
 
  my $ex3 = $expect;
  my $n = $db->get_nextnum; 
  $db->set_new($n, $ex3->{1}->{note}, $ex3->{1}->{date});
  $ex3->{$n} = delete $ex3->{1};

  my ($note, $date) = $db->get_single($n);
  like($note, qr/any new text/, "$name: Retrieve newly written entry content");
  like($date, qr/^\d\d/,        "$name: Retrieve newly written entry date");

  $n = $db->get_nextnum; 
  $db->set_new($n, $ex3->{2}->{note}, $ex3->{2}->{date});
  $ex3->{$n} = delete $ex3->{2};

  # hack db file mtime, since we're too fast here
  $db->{mtime} = 0;

  my %all = $db->get_all();
  # hack %all to that it passes the next test
  foreach my $n (keys %all) {
    chomp $all{$n}->{note};
  }

  is_deeply($ex3, \%all, "$name: Get all notes hash") or diag(Dumper(\%all));
}

