use strict;
use warnings;
use DBI;
use FindBin;
use File::Basename;

my $dbpath = "$FindBin::Bin/var/db/site.db";
my $schema = "$FindBin::Bin/sql/site.schema.sql";

my $connector = sub {
  my $was_missing = ! -e $dbpath;
  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbpath", '', ''
                         , +{sqlite_unicode => 1});
  chmod 0664, $dbpath if $was_missing;
  $dbh;
};

my $dbh;
{
  $dbh = $connector->();
  my $sql = do {local (@ARGV, $/) = $schema; scalar <>};
  $dbh->do($sql);
}

use Session::ExpiryFriendly::Store::DBI;

return +{
    session_store => Session::ExpiryFriendly::Store::DBI->new(dbh => $dbh),
};
