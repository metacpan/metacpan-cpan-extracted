#!perl

use strict;
use warnings;
#use Test::Exception;
use Test::More 0.98;
#use Test::RandomResult;

use DBI;
use DBD::SQLite;
use File::Temp qw(tempfile);
use WordList::DBI;

my ($tempfh, $tempname) = tempfile();
my $dbh = DBI->connect("dbi:SQLite:dbname=$tempname", undef, undef, {RaiseError=>1});
$dbh->do("CREATE TABLE t1 (word TEXT NOT NULL)");
$dbh->do("INSERT INTO t1 VALUES ('aa')");
$dbh->do("INSERT INTO t1 VALUES ('bb')");
$dbh->do("INSERT INTO t1 VALUES ('cc')");

subtest "basics" => sub {
    my $wl = WordList::DBI->new(dbh=>$dbh, query=>"SELECT word FROM t1 ORDER BY word");
    is_deeply($wl->first_word, "aa");
    is_deeply($wl->next_word, "bb");
    $wl->reset_iterator;
    is_deeply($wl->next_word, "aa");
    is_deeply($wl->next_word, "bb");
    is_deeply($wl->next_word, "cc");
    is_deeply($wl->next_word, undef);

    like([$wl->pick]->[0], qr/\A(aa|bb|cc)\z/);

    is_deeply([$wl->all_words], [qw/aa bb cc/]);
};

# XXX test param:dsn

done_testing;
