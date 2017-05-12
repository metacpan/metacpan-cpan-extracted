# Copyright 2009, 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Distlinks.
#
# Distlinks is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Distlinks is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Distlinks.  If not, see <http://www.gnu.org/licenses/>.

package App::Distlinks::DBI;
use strict;
use warnings;
use DBD::SQLite;
use File::HomeDir;
use List::MoreUtils;
use base 'Class::Singleton';
use base 'DBI';

our $VERSION = 11;

my $verbose = 0;

sub _new_instance {
  my ($class) = @_;

  my $home_directory = File::HomeDir->my_home
    || die "No home directory found by File::HomeDir\n";

  my $db_filename = File::Spec->catfile ($home_directory, '.distlinks.sqdb');
  if ($verbose) { print "database $db_filename\n"; }

  my $dbh = $class->connect ("dbi:SQLite:dbname=$db_filename",
                             '', '', {RaiseError=>1});
  $dbh->func(90_000, 'busy_timeout');  # 90 seconds
  $dbh->{'private_App_Distlinks'}->{'filename'} = $db_filename;
  $dbh->do ('PRAGMA foreign_keys = 1');

  if (! $dbh->table_exists ('page')) {
    print "Create $db_filename\n";

    $dbh->do (<<'HERE');
CREATE TABLE page (
    url            TEXT    NOT NULL   PRIMARY KEY,
    timestamp      TEXT    NOT NULL,
    is_success     BOOLEAN NOT NULL,
    status_code    INTEGER NOT NULL,
    status_line    TEXT    NOT NULL,
    etag           TEXT               DEFAULT NULL,
    last_modified  TEXT               DEFAULT NULL,
    redir_location TEXT               DEFAULT NULL,
    anchors        BOOLEAN NOT NULL   DEFAULT FALSE)
HERE
    # index for faster expiry checking
    $dbh->do (<<'HERE');
CREATE INDEX page_timestamp_index ON page (timestamp)
HERE

    $dbh->do (<<'HERE');
CREATE TABLE anchor (
    url            TEXT    NOT NULL,
    anchor         TEXT    NOT NULL,
    PRIMARY KEY (url, anchor),
    FOREIGN KEY(url) REFERENCES page(url) ON DELETE CASCADE)
HERE
  }

  return $dbh;

  #   if (0) {
  #     my $count = 0;
  #     foreach my $url (keys %nodb_urls) {
  #       $count += $dbh->do ('DELETE FROM page WHERE url LIKE ?',
  #                           undef,
  #                           "$url%");
  #     }
  #     if ($count != 0) {
  #       print "$count no-db urls deleted\n";
  #     }
  #   }
}

package App::Distlinks::DBI::db;
use strict;
use warnings;
use URI;
use Regexp::Common;
use base 'DBI::db';

#------------------------------------------------------------------------------
# page records

sub read_page {
  my ($dbh, $url, $anchor) = @_;
  $url = URI->new($url)->canonical;

  if (defined $anchor) {
    my $sth = $dbh->prepare_cached
      ('SELECT * FROM anchor WHERE url=? and anchor=?');
    my $info = $dbh->selectrow_hashref($sth,undef,$url,$anchor);
    if ($info) {
      $info->{'is_success'} = 1;
      $info->{'status_code'} = 200;
      $info->{'anchors'} = 1;
      return $info;
    }
  }
  my $info;
  if (defined $anchor) {
    my $sth = $dbh->prepare_cached
      ('SELECT * FROM page LEFT JOIN anchor ON page.url = anchor.url
      WHERE page.url=?');
    $sth->execute($url);
    $info = $sth->fetchrow_hashref;
    $info->{'have_anchors'} = [];
    if ($info && defined $info->{'anchor'}) {
      push @{$info->{'have_anchors'}}, delete $info->{'anchor'};
      while (my $more = $sth->fetchrow_hashref) {
        push @{$info->{'have_anchors'}}, $more->{'anchor'};
      }
    }
    $sth->finish;
    $info->{'anchor_not_found'} = 1;

  } else {
    my $sth = $dbh->prepare_cached ('SELECT * FROM page WHERE url=?');
    $info = $dbh->selectrow_hashref($sth,undef,$url);
  }
  return ($info || {});
}

sub read_anchors {
  my ($dbh, $url) = @_;
  my $sth = $dbh->prepare_cached
    ('SELECT anchor FROM anchor WHERE url=?');
  return $dbh->selectcol_arrayref($sth,undef,$url);
}


sub write_page {
  my ($dbh, $info) = @_;
  $dbh->call_with_transaction
    (sub {
       my $url = $info->{'url'};
       $url = URI->new($url)->canonical;

       { my $sth  = $dbh->prepare_cached ('DELETE FROM anchor WHERE url = ?');
         $sth->execute ($url);
       }
       { my $sth  = $dbh->prepare_cached ('DELETE FROM page WHERE url = ?');
         $sth->execute ($url);
       }

       {
         my $sth  = $dbh->prepare_cached
           ('INSERT INTO page (url,timestamp,
                             is_success,status_code,status_line,
                             etag,last_modified,
                             redir_location,anchors)
                       VALUES(?,?, ?,?,?, ?,?, ?,?)');
         $sth->execute ($url, timestamp_now(),
                        $info->{'is_success'} ? 1 : 0,
                        $info->{'status_code'},
                        $info->{'status_line'},
                        $info->{'etag'},
                        $info->{'last_modified'},
                        $info->{'redir_location'},
                        $info->{'anchors'} ? 1 : 0);
       }
       if (my $anchors = $info->{'anchors'}) {
         my $sth = $dbh->prepare_cached
           ('INSERT INTO anchor (url,anchor) VALUES(?,?)');
         foreach my $anchor (List::MoreUtils::uniq (@$anchors)) {
           $sth->execute ($url, $anchor);
         }
       }
     });
}

my $expire_days = 30;

sub expire {
  my ($dbh, $always_print) = @_;
  # always expire file:// urls so as to recheck on next run
  $dbh->do ('DELETE FROM page WHERE url LIKE \'file://%\'');

  my $count = $dbh->do
    ('DELETE FROM page WHERE timestamp < ? OR timestamp > ?',
     undef,
     timestamp_range ($expire_days * 86400));
  $count += 0; # numize '0E0' return when none deleted

  if ($count || $always_print) {
    my ($kept) = $dbh->selectrow_array('SELECT COUNT(*) FROM page');
    my ($anchors) = $dbh->selectrow_array('SELECT COUNT(*) FROM anchor');
    print "expired $count links, kept $kept (with $anchors anchors)\n";
  }
  return $count;
}

sub vacuum {
  my ($dbh) = @_;
  my $db_filename = $dbh->{'private_App_Distlinks'}->{'filename'};
  my $old_size = -s $db_filename;
  my $old_kbytes = int (($old_size + 1023) / 1024);
  $dbh->do ('VACUUM');
  my $new_size = -s $db_filename;
  my $new_kbytes = int (($new_size + 1023) / 1024);
  print "vacuum database to now ${new_kbytes}k (was ${old_kbytes}k)\n";
}

sub recheck {
  my ($dbh, $url) = @_;
  my $count = 0;
  if ($url =~ /^$RE{net}{domain}$/) {
    my $pattern = "%$url/%";
    $count = $dbh->do ('DELETE FROM page WHERE url LIKE ?', undef, $pattern);
  } else {
    $count = $dbh->do ('DELETE FROM page WHERE url = ?', undef, $url);
  }
  $count += 0; # numize '0E0' return when none deleted
  print "recheck $count links\n";
}


#------------------------------------------------------------------------------
# transaction

# rollback() can get errors too, like database gone away.  They end up
# thrown in preference to the original error.
#
sub call_with_transaction {
  my $dbh = shift;
  my $subr = shift;

  if ($dbh->{'AutoCommit'}) {
    my $commit = App::Distlinks::DBI::Commit->new ($dbh);
    $dbh->begin_work;
    if (wantarray) {
      my @ret = $subr->(@_);
      $commit->ok;
      return @ret;
    } else {
      my $ret = $subr->(@_);
      $commit->ok;
      return $ret;
    }

  } else {
    return $subr->(@_);
  }
}
{
  package App::Distlinks::DBI::Commit;
  sub new {
    my ($class, $dbh) = @_;
    return bless { dbh => $dbh,
                   method => 'rollback',
                 }, $class;
  }
  sub ok {
    my ($self) = @_;
    $self->{'method'} = 'commit';
  }
  sub DESTROY {
    my ($self) = @_;
    my $method = $self->{'method'};
    $self->{'dbh'}->$method;
  }
}

# return true if $dbh contains a table called $table
sub table_exists {
  my ($dbh, $table) = @_;
  my $sth = $dbh->table_info (undef, undef, $table, undef);
  my $exists = $sth->fetchrow_arrayref ? 1 : 0;
  $sth->finish;
  return $exists;
}

#------------------------------------------------------------------------------
# timestamps

# return strings ($lo, $hi)
sub timestamp_range {
  my ($seconds) = @_;
  my $t = time();
  my $lo = $t - $seconds;
  my $hi = $t + 6*3600; # 2 hours future
  return (timet_to_timestamp($lo),
          timet_to_timestamp($hi));
}
sub timestamp_now {
  return timet_to_timestamp(time());
}
sub timet_to_timestamp {
  my ($t) = @_;
  my @gmtime = gmtime($t) or die "Oops, gmtime($t) not supported";
  require POSIX;
  return POSIX::strftime ('%Y-%m-%d %H:%M:%S+00:00', @gmtime);
}
sub timestamp_to_timet {
  my ($timestamp) = @_;
  my ($year, $month, $day, $hour, $minute, $second)
    = split /[- :+]/, $timestamp;
  require Time::Local;
  return Time::Local::timegm
    ($second, $minute, $hour, $day, $month-1, $year-1900);
}

package App::Distlinks::DBI::st;
use strict;
use warnings;
use base 'DBI::st';

1;
__END__
