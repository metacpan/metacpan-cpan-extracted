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

{
  my $dbh = $connector->();
  my $sql = do {local (@ARGV, $/) = $schema; scalar <>};
  $dbh->do($sql);
}

use Plack::Session::State::Cookie ();
# use Plack::Session::Store::DBI ();

return +{
  # Direct object
  session_state =>
  Plack::Session::State::Cookie->new(httponly => 1)

  # [$pluginName => @args]
  , session_store =>
  [
    DBI => get_dbh => $connector
  ]
};
