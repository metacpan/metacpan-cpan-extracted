# -*- perl -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN {
  local @_ = "$FindBin::Bin/.."; do "$FindBin::Bin/../t_lib.pl";
}

(my $app_root = untaint_any(__FILE__)) =~ s/\.psgi/\.d/;

use mro 'c3';
use YATT::Lite::WebMVC0::SiteApp -as_base;
use YATT::Lite::WebMVC0::Partial::Session2 -as_base;
use Plack::Session::State::Cookie ();
use Plack::Session::Store::DBI ();
use DBD::SQLite;

my $DBH;
{
  $DBH = DBI->connect("dbi:SQLite::memory:", '', '', +{sqlite_unicode => 1, RaiseError => 1, PrintError => 0, AutoCommit => 1});

  $DBH->do(<<END);
CREATE TABLE sessions (
    id           CHAR(72) PRIMARY KEY,
    session_data TEXT
);
END
}

{
  my MY $dispatcher = do {
    my @args = (app_ns => 'MyYATT'
                , app_root => $app_root
                , doc_root => "$app_root/public"
                , session_state => Plack::Session::State::Cookie->new(
                  httponly => 1,
                  session_key => "sid",
                )
                , session_store => [DBI => get_dbh => sub {$DBH}],
              );
    MY->new(@args);
  };

  return $dispatcher->to_app;
}
