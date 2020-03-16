# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2017, 2020 Kevin Ryde

# This file is part of Upfiles.
#
# Upfiles is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Upfiles is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Upfiles.  If not, see <http://www.gnu.org/licenses/>.


# Net::FTP
# RFC 959 - ftp
# RFC 1123 - program ftp minimum requirements
# RFC 1579 - PASV
# RFC 2228 - PROT
# RFC 3659 - Extensions to FTP  (MDTM fetch, REST, MLST)
# RFC 4217 - SSL
# http://cr.yp.to/ftp.html  DJB's notes
# https://tools.ietf.org/id/draft-somers-ftp-mfxx-04.txt MFMT etc
#
# proftpd
# /usr/share/doc/proftpd-doc/modules/mod_site.html


package App::Upfiles;
use 5.010;
use strict;
use warnings;
use Carp;
use File::Spec;
use File::Spec::Unix;
use File::stat 1.02;  # for -d operator overload
use List::Util 'max';
use POSIX ();
use Locale::TextDomain ('App-Upfiles');
use Regexp::Common 'no_defaults','Emacs';

use FindBin;
my $progname = $FindBin::Script;

our $VERSION = 15;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant { DATABASE_FILENAME       => '.upfiles.sqdb',
               DATABASE_SCHEMA_VERSION => 1,

               CONFIG_FILENAME => '.upfiles.conf',

               # emacs backups, autosaves, lockfiles
               EXCLUDE_BASENAME_REGEXPS_DEFAULT => [ $RE{Emacs}{skipfile} ],

               EXCLUDE_REGEXPS_DEFAULT => [],
             };

#------------------------------------------------------------------------------
sub new {
  my $class = shift;
  return bless { total_size_kbytes  => 0,
                 total_count        => 0,
                 change_count       => 0,
                 change_size        => 0,
                 verbose            => 1,

                 exclude_regexps_default
                 => $class->EXCLUDE_REGEXPS_DEFAULT,

                 exclude_basename_regexps_default
                 => $class->EXCLUDE_BASENAME_REGEXPS_DEFAULT,

                 @_ }, $class;
}


#------------------------------------------------------------------------------
sub command_line {
  my ($self) = @_;

  my $action = '';
  my $set_action = sub {
    my ($new_action) = @_;
    if ($action) {
      croak __x('Cannot have both action {action1} and {action2}',
                action1 => "--$action",
                action2 => "--$new_action");
    }
    $action = "$new_action"; # stringize against callback object :-(
  };

  require Getopt::Long;
  Getopt::Long::Configure ('no_ignore_case',
                           'bundling');
  if (! Getopt::Long::GetOptions ('help|?'    => $set_action,
                                  'verbose:+' => \$self->{'verbose'},
                                  'V+'        => \$self->{'verbose'},
                                  'version'   => $set_action,
                                  'n|dry-run' => \$self->{'dry_run'},
                                  'recheck'   => \$self->{'recheck'},
                                  'catchup'   => \$self->{'catchup'},
                                 )) {
    return 1;
  }

  if ($self->{'verbose'} >= 2) {
    print "Verbosity level $self->{'verbose'}\n";
  }
  $action = 'action_' . ($action || 'upfiles');
  return $self->$action;
}

sub action_version {
  my ($self) = @_;
  print __x("upfiles version {version}\n",
            version => $self->VERSION);
  if ($self->{'verbose'} >= 2) {
    require DBI;
    require DBD::SQLite;
    print __x("  Perl        version {version}\n", version => $]);
    print __x("  DBI         version {version}\n", version => $DBI::VERSION);
    print __x("  DBD::SQLite version {version}\n", version => $DBD::SQLite::VERSION);
  }
  return 0;
}

sub action_help {
  my ($self) = @_;
  print __x("Usage: $progname [--options]\n");
  print __x("  --help         print this message\n");
  print __x("  --version      print version number (and module versions if --verbose=2)\n");
  print __x("  -n, --dry-run  don't do anything, just print what would be done\n");
  print __x("  --verbose, --verbose=N
                 print diagnostic info, with --verbose=2 print even more info\n");
  return 0;
}

sub action_upfiles {
  my ($self, @files) = @_;
  ### action_upfiles() ...
  ### @ARGV

  if (@ARGV) {
    # files given on command line
    @files = @ARGV;
    @files = map {File::Spec->rel2abs($_)} @files;
    ### @files
    @files = map {$_, parent_directories($_)} @files;
    ### @files
    my %hash;
    @hash{@files} = (); # hash slice
    ### %hash
    local $self->{'action_files_hash'} = \%hash;
    $self->do_config_file;

  } else {
    # all files
    $self->do_config_file;

    if (! $self->{'recheck'}) {
      print __x("changed {change_count} files {change_size_kbytes}k, total {total_count} files {total_size_kbytes}k (in 1024 byte blocks)\n",
                change_count       => $self->{'change_count'},
                change_size_kbytes => _bytes_to_kbytes($self->{'change_size'}),
                total_count        => $self->{'total_count'},
                total_size_kbytes  => $self->{'total_size_kbytes'});
    }
  }
  return 0;
}
sub _bytes_to_kbytes {
  my ($bytes) = @_;
  return POSIX::ceil($bytes/1024);
}

# return a list of the directory and all parent directories of $filename
sub parent_directories {
  my ($filename) = @_;
  my @ret;
  for (;;) {
    my $parent = File::Spec->rel2abs(File::Basename::dirname($filename));
    last if $parent eq $filename;
    push @ret, $parent;
    $filename = $parent;
  }
  return @ret;
}

#------------------------------------------------------------------------------
sub do_config_file {
  my ($self) = @_;
  my $config_filename = $self->config_filename;
  if ($self->{'verbose'} >= 2) {
    print __x("config: {filename}\n",
              filename => $config_filename);
  }
  if ($self->{'dry_run'}) {
    if ($self->{'verbose'}) { print __x("dry run\n"); }
  }
  require App::Upfiles::Conf;
  local $App::Upfiles::Conf::upf = $self;

  if (! defined (do { package App::Upfiles::Conf;
                      do $config_filename;
                    })) {
    if (! -e $config_filename) {
      croak __x("No config file {filename}",
                filename => $config_filename);
    } else {
      croak $@;
    }
  }
}
sub config_filename {
  my ($self) = @_;
  return $self->{'config_filename'} // do {
    require File::HomeDir;
    my $homedir = File::HomeDir->my_home
      // croak __('No home directory for config file (File::HomeDir)');
    return File::Spec->catfile ($homedir, $self->CONFIG_FILENAME);
  };
}

#------------------------------------------------------------------------------

my %protocol_to_class = (ftp  => 'App::Upfiles::FTPlazy',
                         ftps => 'App::Upfiles::FTPlazy',
                         sftp => 'App::Upfiles::SFTPlazy',
                        );
sub ftp {
  my ($self) = @_;
  my $protocol = $self->{'protocol'};
  my $options = $self->{'options'};

  # Here $key becomes ftp, ftp.TLS, ftps or sftp and a corresponding type of
  # lazy connection is cached.  The two ftp or ftp.TLS could be merged by
  # setting the TLS option dynamically, but expect normally to be using just
  # one or the other.
  my $key = $protocol;
  if ($protocol eq 'ftp' && $options->{'use_TLS'}) {
    $key .= '.TLS';
  }
  return ($self->{'ftp'}->{$key}
          //= do {
            my $class = $protocol_to_class{$protocol}
              or croak __x('Unrecognised protocol to remote: {protocol}',
                           protocol => $self->{'protocol'});
            require Module::Load;
            Module::Load::load($class);
            $class->new (verbose    => $self->{'verbose'},
                         copy_time  => $options->{'copy_utime'}?1:0, # for SFTP
                         ($protocol eq 'ftps'
                          ? (use_SSL => 1)
                          : (use_TLS => $options->{'use_TLS'})),
                        )
          });
}

sub ftp_connect {
  my ($self) = @_;
  my $ftp = $self->ftp;
  $ftp->ensure_all
    or croak __x("{protocol} error on {hostname}: {ftperr}",
                 protocol => $self->{'protocol'},
                 hostname => $ftp->host,
                 ftperr   => scalar($ftp->message));
}


# return ($mtime, $size) of last send of $filename to url $remote
sub db_get_mtime {
  my ($self, $dbh, $remote, $filename) = @_;
  my $sth = $dbh->prepare_cached
    ('SELECT mtime,size FROM sent WHERE remote=? AND filename=?');
  my $aref = $dbh->selectall_arrayref($sth, undef, $remote, $filename);
  $aref = $aref->[0] || return; # if no rows
  my ($mtime, $size) = @$aref;
  $mtime = timestamp_to_timet($mtime);
  return ($mtime, $size);
}

sub db_set_mtime {
  my ($self, $dbh, $remote, $filename, $mtime, $size) = @_;
  if ($self->{'verbose'} >= 2) {
    print "  database write $filename time=$mtime,size=$size\n";
  }
  $mtime = timet_to_timestamp($mtime);
  my $sth = $dbh->prepare_cached
    ('INSERT OR REPLACE INTO sent (remote,filename,mtime,size)
      VALUES (?,?,?,?)');
  $sth->execute ($remote, $filename, $mtime, $size);
}

sub db_delete_mtime {
  my ($self, $dbh, $remote, $filename) = @_;
  if ($self->{'verbose'} >= 2) {
    print "  database delete $filename\n";
  }
  my $sth = $dbh->prepare_cached
    ('DELETE FROM sent WHERE remote=? AND filename=?');
  $sth->execute ($remote, $filename);
}

sub db_remote_filenames {
  my ($dbh, $remote) = @_;
  my $sth = $dbh->prepare_cached
    ('SELECT filename FROM sent WHERE remote=?');
  return @{$dbh->selectcol_arrayref($sth, undef, $remote)};
}

# return a DBD::SQLite handle for database $db_filename
sub dbh {
  my ($self, $db_filename) = @_;

  if ($self->{'verbose'} >= 2) {
    print "database open $db_filename\n";
  }

  require DBD::SQLite;
  my $dbh = DBI->connect ("dbi:SQLite:dbname=$db_filename",
                          '', '', {RaiseError=>1});
  $dbh->func(90_000, 'busy_timeout');  # 90 seconds

  {
    my ($dbversion) = do {
      local $dbh->{RaiseError} = undef;
      local $dbh->{PrintError} = undef;
      $dbh->selectrow_array
        ("SELECT value FROM extra WHERE key='database-schema-version'")
      };
    $dbversion ||= 0;
    if ($dbversion < $self->DATABASE_SCHEMA_VERSION) {
      $self->_upgrade_database ($dbh, $dbversion, $db_filename);
    }
  }
  return $dbh;
}

sub _upgrade_database {
  my ($self, $dbh, $dbversion, $db_filename) = @_;

  if ($dbversion <= 0) {
    # dbversion=0 is an empty database
    if ($self->{'verbose'}) { print __x("initialize {filename}\n",
                                        filename => $db_filename); }
    $dbh->do (<<'HERE');
CREATE TABLE extra (
    key    TEXT  NOT NULL  PRIMARY KEY,
    value  TEXT
)
HERE
    $dbh->do (<<'HERE');
CREATE TABLE sent (
    remote    TEXT     NOT NULL,
    filename  TEXT     NOT NULL,
    mtime     TEXT     NOT NULL,
    size      INTEGER  NOT NULL,
    PRIMARY KEY (remote, filename)
)
HERE
  }

  $dbh->do ("INSERT OR REPLACE INTO extra (key,value)
             VALUES ('database-schema-version',?)",
            undef,
            $self->DATABASE_SCHEMA_VERSION);
}


#------------------------------------------------------------------------------
sub upfiles {
  my ($self, %options) = @_;

  if (! exists $options{'copy_utime'}) {
    # default
    $options{'copy_utime'} = 'if_possible';
  }

  if ($self->{'verbose'} >= 3) {
    require Data::Dumper;
    print Data::Dumper->new([\%options],['options'])->Sortkeys(1)->Dump;
  }
  my $local_dir  = $options{'local'}
    // croak __('No local directory specified');

  my $remote = $options{'remote'} // croak __('No remote target specified');
  require URI;
  if (! eval { require URI::ftps }) {
    ### use App-Upfiles-URI-ftps ...
    require App::Upfiles::URI::ftps;
    URI::implementor('ftps','App::Upfiles::URI::ftps');
  }
  my $remote_uri = ($remote =~ /^ftps:/ ? "URI::ftp" : "URI")->new($remote);
  my $remote_dir = $remote_uri->path;
  local $self->{'protocol'}   = $remote_uri->scheme;
  local $self->{'host'}       = $remote_uri->host;
  local $self->{'username'}   = $remote_uri->user;
  local $self->{'remote_dir'} = $remote_dir;
  local $self->{'options'}    = \%options;

  defined $self->{'username'}
    or croak __('No username given in remote URL');

  if ($self->{'verbose'}) {
    # TRANSLATORS: any need to translate this?  maybe the -> arrow
    print __x("{localdir} -> {protocol} {username}\@{hostname} {remotedir}\n",
              localdir  => $local_dir,
              protocol  => $self->{'protocol'},
              username  => $self->{'username'},
              hostname  => $self->{'host'},
              remotedir => $remote_dir);
  }

  # Go to local directory to notice if it doesn't exist, before attempting
  # to open/create the database.
  chdir $local_dir
    or croak __x("Cannot chdir to local directory {localdir}: {strerror}",
                 localdir => $local_dir,
                 strerror => "$!");

  my $ftp = $self->ftp;
  ($ftp->host ($self->{'host'})
   && $ftp->login ($self->{'username'})
   && $ftp->binary)
    or croak __x("{protocol} error on {hostname}: {ftperr}",
                 protocol => $self->{'protocol'},
                 hostname => $self->{'host'},
                 ftperr   => scalar($self->ftp->message));

  if ($self->{'recheck'}) {
    $self->recheck();
    return;
  }

  my $db_filename = File::Spec->catfile ($local_dir, $self->DATABASE_FILENAME);
  my $dbh = $self->dbh ($db_filename);

  {
    # initial creation of remote dir
    my ($remote_mtime, $remote_size)
      = $self->db_get_mtime ($dbh, $options{'remote'}, '/');
    if (! $remote_mtime) {
      my $unslashed = $remote_dir;
      $unslashed =~ s{/$}{};
      if ($self->{'verbose'}) {
        print __x("MKD toplevel  {dirname}\n",
                  dirname => $remote_dir);
      }

      unless ($self->{'dry_run'}) {
        $self->ftp_connect;
        $self->ftp->mkdir ($unslashed, 1)
          // croak __x("Cannot make directory {dirname}: {ftperr}",
                       dirname => $remote_dir,
                       ftperr  => scalar($self->ftp->message));
        $self->db_set_mtime ($dbh, $options{'remote'}, '/', 1, 1);
      }
    }
  }
  $ftp->cwd ($remote_dir);


  # =item C<sort_last_regexps> (arrayref of regexps)
  #
  # Patterns of filenames to sort last for uploading.  For example to upload
  # all index files last
  #
  #     upfiles (local => '/my/directory',
  #              remote => 'ftp://some-server.org/pub/fred',
  #              sort_last_regexps => [ qr{index\.html$} ]);
  #
  # The upload order is all files not "last", then all files matching the
  # first "last" regexp, then those matching the second "last" regexp, etc.
  # If a filename matches multiple regexps then the last one it matches is
  # used for its upload position.
  #
  # This option can be used to upload an index, contents list, site map,
  # etc, after uploads of content it refers to.  This suits simple
  # references (but is probably not enough for mutual dependencies).

  my $local_filenames_hash = $self->local_filenames_hash;
  my $sort_last_regexps = $options{'sort_last_regexps'};
  my @local_filenames = keys %$local_filenames_hash;
  foreach my $filename (@local_filenames) {
    foreach my $i (0 .. $#$sort_last_regexps) {
      ### $filename
      ### re: $sort_last_regexps->[$i]
      if ($filename =~ $sort_last_regexps->[$i]) {
        $local_filenames_hash->{$filename} = 10 + $i;
        ### set: 10+$i
      }
    }
  }
  @local_filenames = sort
    {$local_filenames_hash->{$a} <=> $local_filenames_hash->{$b}
     || $a cmp $b}
    @local_filenames;

  my $any_changes = 0;
  foreach my $filename (@local_filenames) {

    # Reject \r\n here so as to keep any \r\n out of the database.
    # Don't want to note a \r\n tempfile in the database, have Net::FTP
    # reject it, and then be left with the database claiming a \r\n file
    # exists and should be deleted.
    if ($filename =~ /[\r\n]/s) {
      croak __x("FTP does not support filenames with CR or LF characters: {filename}",
                filename => $filename);
    }

    if (my $action_files_hash = $self->{'action_files_hash'}) {
      my $filename_abs = File::Spec->rel2abs($filename);
      ### $filename_abs
      if (! exists $action_files_hash->{$filename_abs}) {
        next;
      }
      ### included in action_files_hash ...
    }

    if ($self->{'verbose'} >= 2) {
      print __x("local: {filename}\n", filename => $filename);
    }
    my $isdir = ($filename =~ m{/$});

    my ($remote_mtime, $remote_size)
      = $self->db_get_mtime ($dbh, $options{'remote'}, $filename);
    my $local_st = File::stat::stat($filename)
      // next; # if no longer exists
    my $local_mtime = ($isdir ? 1 : $local_st->mtime);
    my $local_size  = ($isdir ? 1 : $local_st->size);

    if ($self->{'verbose'} >= 2) {
      print "  local time=$local_mtime,size=$local_size ",
        "remote time=",$remote_mtime//'undef',
        ",size=",$remote_size//'undef',"\n";
    }

    if (defined $remote_mtime && $remote_mtime == $local_mtime
        && defined $remote_size && $remote_size == $local_size) {
      if ($self->{'verbose'} >= 2) {
        print __x("    unchanged\n");
      }
      next;
    }

    unless ($self->{'catchup'}) {
      if ($isdir) {
        # directory, only has to exist
        my $unslashed = $filename;
        $unslashed =~ s{/$}{};
        if ($self->{'verbose'}) {
          print __x("MKD  {dirname}\n",
                    dirname => $filename);
        }
        $self->{'change_count'}++;
        $any_changes = 1;
        next if $self->{'dry_run'};

        $self->ftp_connect;
        $self->ftp->mkdir ($unslashed, 1)
          // croak __x("Cannot make directory {dirname}: {ftperr}",
                       dirname => $filename,
                       ftperr  => scalar($self->ftp->message));

      } else {
        # file, must exist and same modtime
        my $size_bytes = -s $filename;
        if ($self->{'verbose'}) {
          my $size_kbytes = max (0.1, $size_bytes/1024);
          $size_kbytes = sprintf('%.*f',
                                 ($size_kbytes >= 10 ? 0 : 1), # decimals
                                 $size_kbytes);
          print __x("PUT  {filename} [{size_kbytes}k]\n",
                    filename    => $filename,
                    size_kbytes => $size_kbytes);
        }
        $self->{'change_count'}++;
        $self->{'change_size'} += $size_bytes;
        $any_changes = 1;
        next if $self->{'dry_run'};

        my $tmpname = "$filename.tmp.$$";
        if ($self->{'verbose'} >= 2) {
          print "  with tmpname $tmpname\n";
        }
        $self->db_set_mtime ($dbh, $options{'remote'}, $tmpname,
                             $local_mtime, $local_size);

        {
          $self->ftp_connect;
          my $put;
          if (my $throttle_options = $options{'throttle'}) {
            require App::Upfiles::Tie::Handle::Throttle;
            require Symbol;
            my $fh = Symbol::gensym();
            tie *$fh, 'App::Upfiles::Tie::Handle::Throttle',
              %$throttle_options;
            ### tied: $fh
            ### tied: tied($fh)
            open $fh, '<', $filename
              or croak __x("Cannot open {filename}: {strerror}",
                           filename => $filename,
                           strerror => $!);
            $put = $self->ftp->put ($fh, $tmpname);
            close $fh
              or croak __x("Error closing {filename}: {strerror}",
                           filename => $filename,
                           strerror => $!);
          } else {
            $put = $self->ftp->put ($filename, $tmpname);
          }
          $put or croak __x("Error sending {filename}: {ftperr}",
                            filename => $filename,
                            ftperr   => scalar($self->ftp->message));
        }

        if ($self->{'verbose'} >= 2) {
          print "  rename\n";
        }
        $self->ftp->rename ($tmpname, $filename)
          or croak __x("Cannot rename {filename}: {ftperr}",
                       filename => $tmpname,
                       ftperr   => scalar($self->ftp->message));
        $self->db_delete_mtime ($dbh, $options{'remote'}, $tmpname);

        $self->site_utime($filename, $local_st);
      }
    }
    $self->db_set_mtime ($dbh, $options{'remote'}, $filename,
                         $local_mtime, $local_size);
  }

  # reverse to delete contained files before their directory ...
  foreach my $filename (reverse db_remote_filenames($dbh, $options{'remote'})) {
    next if $local_filenames_hash->{$filename};
    if (my $action_files_hash = $self->{'action_files_hash'}) {
      if (! exists $action_files_hash->{$filename}) {
        next;
      }
    }
    my $isdir = ($filename =~ m{/$});

    unless ($self->{'catchup'}) {
      if ($isdir) {
        my $unslashed = $filename;
        $unslashed =~ s{/$}{};
        if ($self->{'verbose'}) { print __x("RMD  {filename}\n",
                                            filename => $filename); }
        $self->{'change_count'}++;
        $any_changes = 1;
        next if $self->{'dry_run'};

        $self->ftp_connect;
        $self->ftp->rmdir ($unslashed, 1)
          or warn "Cannot rmdir $unslashed: ", $self->ftp->message;

      } else {
        if ($self->{'verbose'}) { print __x("DELE {filename}\n",
                                            filename => $filename); }
        $self->{'change_count'}++;
        $any_changes = 1;
        next if $self->{'dry_run'};

        $self->ftp_connect;
        $self->ftp->delete ($filename)
          or warn "Cannot delete $filename: ", $self->ftp->message;
      }
    }
    $self->db_delete_mtime ($dbh, $options{'remote'}, $filename);
  }

  $ftp->all_ok
    or croak __x("ftp error on {hostname}: {ftperr}",
                 hostname => $self->{'host'},
                 ftperr   => scalar($self->ftp->message));

  if (! $any_changes) {
    if ($self->{'verbose'}) { print '  ',__('no changes'),"\n"; }
  }

  return 1;
}

# $filename is a remote filename.
# $local_st is a File::stat of the corresponding local file.
#
# Set the file modification time on remote $filename to $local_st, using the
# method (if any) specified by copy_utime, including possibly testing what
# method the server supports (MFMT, SITE UTIME, etc).
#
# When guessing the method supported on the server, the method found to work
# is stored to $options->{'copy_utime'} in order to use the same later
# without testing.
#
sub site_utime {
  my ($self, $filename, $local_st) = @_;
  my $options = $self->{'options'};
  return if ! $options->{'copy_utime'};
  return if $self->{'protocol'} eq 'sftp';

  # MFMT as per https://tools.ietf.org/id/draft-somers-ftp-mfxx-04.txt
  # MFMT YYYYMMDDhhmmss path
  #      mtime, optional .milliseconds too, not used here
  if ($options->{'copy_utime'} ne '2arg' && $options->{'copy_utime'} ne '5arg') {
    my $ret = $self->ftp->quot('MFMT',
                               timet_to_ymdhms($local_st->mtime),
                               $filename);
    if ($ret == 2) { # OK
      $options->{'copy_utime'} = 'MFMT';
      return 1;
    }

    # not OK
    # If copy_utime==MFMT then it must work,
    # otherwise anything except 500 not implemented is bad.
    # 500 not implemented with "if_possible" means keep trying.
    my $code = $self->ftp->code;
    if ($options->{'copy_utime'} eq 'MFMT' || $code != 500) {
      my $message = $self->ftp->message;
      croak __x("Cannot MFMT {filename}: {ftperr}",
                filename => $filename,
                ftperr   => $message);
    }
  }

  # SITE UTIME YYYYMMDDhhmm[ss] path
  #            mtime
  # proftpd style 2-arg
  if ($options->{'copy_utime'} ne 'MFMT' && $options->{'copy_utime'} ne '5arg') {
    my $ret = $self->ftp->site('UTIME',
                               timet_to_ymdhms($local_st->mtime),
                               $filename);
    if ($ret == 2) { # OK
      $options->{'copy_utime'} = '2arg';
      return 1;
    }

    # not OK
    # If copy_utime==2arg then it must work,
    # otherwise anything except 500 not implemented is bad.
    # 500 not implemented with "if_possible" means keep trying.
    my $code = $self->ftp->code;
    if ($options->{'copy_utime'} eq '2arg' || $code != 500) {
      my $message = $self->ftp->message;
      croak __x("Cannot 2-arg SITE UTIME {filename}: {ftperr}",
                filename => $filename,
                ftperr   => $message);
    }
  }

  # SITE UTIME path YYYYMMDDhhmm[ss] YYYYMMDDhhmm[ss] YYYYMMDDhhmm[ss] UTC
  #                 atime,           mtime,           ctime
  # pure-ftpd style
  # pure-ftpd 1.0.33 up has MFMT (and 2-arg SITE UTIME too), but this 5-arg
  # helps older versions still in use
  if ($options->{'copy_utime'} ne 'MFMT' && $options->{'copy_utime'} ne '2arg') {
    my $ret = $self->ftp->site('UTIME',
                               $filename,
                               timet_to_ymdhms($local_st->atime),
                               timet_to_ymdhms($local_st->mtime),
                               timet_to_ymdhms($local_st->ctime),
                               "UTC");
    if ($ret == 2) { # OK
      $options->{'copy_utime'} = '5arg';
      return 1;
    }

    # not OK
    # If copy_utime==5arg then it must work,
    # otherwise anything except 500 not implemented is bad.
    # 500 not implemented with "if_possible" means keep trying.
    my $code = $self->ftp->code;
    if ($options->{'copy_utime'} eq '5arg' || $code != 500) {
      my $message = $self->ftp->message;
      croak __x("Cannot 5-arg SITE UTIME {filename}: {ftperr}",
                filename => $filename,
                ftperr   => $message);
    }
  }

  if ($options->{'copy_utime'} eq 'if_possible') {
    # SITE UTIME command not available
    $options->{'copy_utime'} = 0;
    print '  ',__('(no SITE UTIME on this server)'),"\n";
    return 0;
  }

  # copy_utime is true, meaning must have one of the methods
  croak __("Cannot copy_utime, neither MFMT nor SITE UTIME available on server");
}

# Return a hashref { $filename => 1 } which is all the local filenames.
# "exclude_regexps" etc are applied.
# "action_files" etc are not applied, so local_filenames_hash is all local
# filenames, of which perhaps only some are to be acted on in this run.
#
sub local_filenames_hash {
  my ($self) = @_;
  my $options = $self->{'options'};

  # $self->{'total_size_kbytes'} = 0;
  # $self->{'total_count'}       = 0;

  my $local_dir = $options->{'local'};

  my @exclude_regexps = (@{$self->{'exclude_regexps_default'}},
                         @{$options->{'exclude_regexps'} // []});
  if ($self->{'verbose'} >= 3) {
    print "exclude regexps\n";
    foreach my $re (@exclude_regexps) { print "  $re\n"; }
  }

  my @exclude_basename_regexps = (@{$self->EXCLUDE_BASENAME_REGEXPS_DEFAULT},
                                  @{$options->{'exclude_basename_regexps'}
                                      // []});
  if ($self->{'verbose'} >= 3) {
    print "exclude basename regexps\n";
    foreach my $re (@exclude_basename_regexps) { print "  $re\n"; }
  }

  # ".upfiles.sqdb" database file
  # ".upfiles.sqdb-journal" file if interrupted on previous run
  my $database_filename = $self->DATABASE_FILENAME;
  my $database_journal_filename = $database_filename . '-journal';

  my %local_filenames_hash = ('/' => 1);
  my $wanted = sub {
    my $fullname = $File::Find::name;
    my $basename = File::Basename::basename ($fullname);

    if ($basename eq $database_filename
        || $basename eq $database_journal_filename) {
      $File::Find::prune = 1;
      return;
    }
    foreach my $exclude (@{$options->{'exclude'}}) {
      if ($basename eq $exclude) {
        $File::Find::prune = 1;
        return;
      }
    }
    foreach my $re (@exclude_basename_regexps) {
      if (defined $re && $basename =~ $re) {
        $File::Find::prune = 1;
        return;
      }
    }
    foreach my $re (@exclude_regexps) {
      if (defined $re && $fullname =~ $re) {
        $File::Find::prune = 1;
        return;
      }
    }

    my $st = File::stat::stat($fullname)
      || croak __x("Cannot stat {filename}: {strerror}",
                   filename => $fullname,
                   strerror => $!);
    unless (-d $st) {
      $self->{'total_size_kbytes'} += _bytes_to_kbytes($st->size);
      $self->{'total_count'}++;
    }
    ### $fullname
    ### size: _bytes_to_kbytes($st->size)
    ### total: $self->{'total_size_kbytes'}
    ### isdir: -d $st

    my $relname = File::Spec->abs2rel ($fullname, $local_dir);
    return if $relname eq '.';
    if (-d $fullname) {
      $relname .= '/';   # directory names foo/
    }

    $local_filenames_hash{$relname} = 1;
  };

  require File::Find;
  File::Find::find ({ wanted => $wanted,
                      no_chdir => 1,
                      preprocess => sub { sort @_ },
                    },
                    $local_dir);

  if ($self->{'verbose'} >= 3) {
    print "local filenames count $self->{'total_count'} total size $self->{'total_size_kbytes'} kbytes\n";
  }

  ### %local_filenames_hash
  return \%local_filenames_hash;
}

sub recheck {
  my ($self) = @_;
  my $options = $self->{'options'};
  my $local_filenames_hash = $self->local_filenames_hash;

  my $local_dir = $options->{'local'};
  my $db_filename = File::Spec->catfile ($local_dir, $self->DATABASE_FILENAME);
  my $dbh = $self->dbh ($db_filename);

  my $ftp = $self->ftp;
  my $remote_dir = $self->{'remote_dir'};
  my @pending_directories = ('');
  my %seen;

  my %db_filenames = map { $_ => 1 } db_remote_filenames($dbh, $options->{'remote'});
  ### %db_filenames

  my $count_remote_extra = 0;
  my $count_remote_missing = 0;

  while (@pending_directories) {
    my $dirname = shift @pending_directories;  # depth first
    ### $dirname

    my $remote_dirname = File::Spec::Unix->catdir($remote_dir, $dirname);
    if ($self->{'verbose'} >= 2) {
      print "remote dir $remote_dirname\n";
    }
    $ftp->cwd($remote_dirname);

    my @lines = $ftp->mlsd('');  # listing of current dir
    ### @lines
    if (! $ftp->ok) {
      print $ftp->message,"\n";
      return;
    }

    @lines = sort { my ($filename1) = MLSD_line_parse($a);
                    my ($filename2) = MLSD_line_parse($b);
                    $filename1 cmp $filename2;
                  } @lines;

    foreach my $line (@lines) {
      my ($filename, %facts) = MLSD_line_parse($line);
      ### $line
      ### $filename
      my $type = $facts{'type'} // '';
      if ($dirname ne '') { $filename = "$dirname/$filename"; }

      if ($type eq 'file') {
        delete $db_filenames{$filename};

        my $remote_size = $facts{'size'};
        if (! defined $remote_size) {
          print __x("{filename}  no size from server\n",
                    filename    => $filename);
          next;
        }

        my ($db_mtime, $db_size)
          = $self->db_get_mtime ($dbh, $options->{'remote'}, $filename);
        if (! defined $db_size) {
          my $modify = $facts{'modify'} // __('[unknown]');
          print __x("{filename} extra on remote (size {remote_size} modified {modify})\n",
                    filename    => $filename,
                    remote_size => $remote_size,
                    modify      => $modify);
          $count_remote_extra++;
          next;
        }

        if ($remote_size != $db_size) {
          print __x("{filename} different size (expected {db_size}, remote {remote_size})\n",
                    filename    => $filename,
                    db_size     => $db_size,
                    remote_size => $remote_size);
        }

      } elsif ($type eq 'dir') {
        my $unique = $facts{'unique'};
        if (defined $unique && $seen{$unique}++) {
          next;
        }
        push @pending_directories, $filename;
        delete $db_filenames{$filename.'/'};
      }
    }

    my $dirname_re = ($dirname eq '' ? qr{^[^/]+$} : qr{^\Q$dirname/\E[^/]+$});
    foreach my $filename (sort keys %db_filenames) {
      next unless $filename =~ $dirname_re;
      delete $db_filenames{$filename};
      if ($filename =~ m{/$}) {
        hash_delete_regexp(\%db_filenames, qr{^\Q$dirname/\E[^/]+/});
      }
      print __x("{filename} missing on remote\n",
                filename => $filename);
      $count_remote_missing++;
    }
  }

  print __x("remote extra {count_extra}, missing {count_missing}\n",
            count_extra       => $count_remote_extra,
            count_missing     => $count_remote_missing);
}

# $str is like
#   "type=file;size=2061;UNIX.mode=0644; index.html"
# Return a list ($filename, key => value, key => value, ...) which are
# the filename part and the "facts" about it.
# The fact keys are forced to lower case since RFC 3659 specifies them as
# case-insensitive.
sub MLSD_line_parse {
  my ($str) = @_;
  $str =~ /(.*?) (.*)$/ or return;
  my $facts = $1;
  my $filename = $2;
  return ($filename, MLST_facts_parse($facts));
}
# $str is the facts part like
#     type=file;size=2061;modify=20150304222544;UNIX.mode=0644; index.html
# Return a list (key => value, key => value, ...)
# The fact keys are forced to lower case since RFC 3659 specifies them as
# case-insensitive.
sub MLST_facts_parse {
  my ($str) = @_;
  return map { my ($key, $value) = split /=/, $_, 2;
               lc($key) => $value }
    split /;/, $str;
}


#------------------------------------------------------------------------------
# misc helpers

# # return size of $filename in kbytes
# sub file_size_kbytes {
#   my ($filename) = @_;
#   return _bytes_to_kbytes(-s $filename);
# }

# # return st_mtime (an integer) of $filename, or undef if unable
# sub stat_mtime {
#   my ($filename) = @_;
#   my $st = File::stat::stat($filename) // return undef;
#   return $st->mtime;
# }

# # $st is a File::stat.  Return the disk space occupied by the file, based on
# # the file size rounded up to the next whole block.
# #  my $blksize = $st->blksize || 1024;
# sub st_space {
#   my ($st) = @_;
#   my $blksize = 1024;
#   require Math::Round;
#   return scalar (Math::Round::nhimult ($blksize, $st->size));
# }

# $t is a time_t time() style seconds since the epoch.
# Return a string YYYYMMDDHHMMSS in GMT as for MFMT and SITE UTIME.
sub timet_to_ymdhms {
  my ($t) = @_;
  return POSIX::strftime ('%Y%m%d%H%M%S', gmtime($t));
}

# $t is a time_t time() style seconds since the epoch.
# Return a string like "2001-12-31 23:59:00+00:00" which is the timestamp
# format in the upfiles database.
sub timet_to_timestamp {
  my ($t) = @_;
  return POSIX::strftime ('%Y-%m-%d %H:%M:%S+00:00', gmtime($t));
}
sub timestamp_to_timet {
  my ($timestamp) = @_;
  my ($year, $month, $day, $hour, $minute, $second)
    = split /[- :+]/, $timestamp;
  require Time::Local;
  return Time::Local::timegm_modern
    ($second, $minute, $hour, $day, $month-1, $year);
}

# $href is a hashref and $re a regexp.  Delete all keys matching $re.
sub hash_delete_regexp {
  my ($href, $re) = @_;
  while (my ($key) = each %$href) {
    if ($key =~ $re) {
      delete $href->{$key};
    }
  }
}

1;
__END__

=for stopwords Upfiles Ryde

=head1 NAME

App::Upfiles -- upload files to an FTP server, for push mirroring

=head1 SYNOPSIS

 use App::Upfiles;
 exit App::Upfiles->command_line;

=head1 FUNCTIONS

=over 4

=item C<< $upf = App::Upfiles->new (key => value, ...) >>

Create and return an Upfiles object.

=item C<< $exitcode = App::Upfiles->command_line >>

=item C<< $exitcode = $upf->command_line >>

Run an Upfiles as from the command line.  Arguments are taken from C<@ARGV>
and the return is an exit status code suitable for C<exit>, meaning 0 for
success.

=back

=head1 SEE ALSO

L<upfiles>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/upfiles/index.html>

=head1 LICENSE

Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2017, 2020 Kevin Ryde

Upfiles is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Upfiles is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Upfiles.  If not, see L<http://www.gnu.org/licenses/>.

=cut
