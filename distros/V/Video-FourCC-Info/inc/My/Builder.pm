# My::Builder
#  A local Module::Build subclass for building the database
#
# $Id: Builder.pm 8633 2009-08-18 16:00:58Z FREQUENCY@cpan.org $

package My::Builder;

use strict;
use warnings;

use base 'Module::Build';

use Cwd ();
use File::Spec ();
use Carp ();

use DBI ();
use DBD::SQLite ();

my $ORIG_DIR = Cwd::cwd();

# These are utility commands for getting into and out of our build directory
sub _chdir_or_die {
  my $dir = File::Spec->catfile(@_);
  chdir $dir or Carp::croak("Failed to chdir to $dir: $!");
}
sub _chdir_back {
  chdir $ORIG_DIR or Carp::croak("Failed to chdir to $ORIG_DIR: $!");
}

sub ACTION_code {
  my ($self) = @_;

  _chdir_or_die('lib', 'Video', 'FourCC');

  unless (-f 'codecs.dat') {
    print "Opening database source file\n";
    open(my $fh, '<', 'source-data.sql') or die("Failed: $!\n");

    my $dbh = DBI->connect(
      'dbi:SQLite:dbname=codecs.dat',
      'notused', # cannot be null, or DBI complains
      'notused',
      {
        RaiseError => 1,
        PrintError => 0,
      }
    );

    # Use a transaction for faster insertion
    $dbh->begin_work;

    print "Creating database structure\n";
    $dbh->do(q{
      CREATE TABLE fourcc
      (
        fourcc char(4) NOT NULL,
        "owner" varchar(100),
        registered date,
        description varchar(200) NOT NULL, 
        CONSTRAINT fourcc_pkey PRIMARY KEY (fourcc)
      );
      CREATE UNIQUE INDEX idx_fourcc ON fourcc (fourcc);
    });

    # This slurps the entire source file into memory -- this is less than
    # efficient, but builds don't take long and ~60KB isn't bad.
    print "Inserting database data\n";
    while (<$fh>) {
      chomp $_;
      $dbh->do($_);
    }
    $dbh->commit;

    # Vacuum the resulting database
    print "Optimizing database\n";
    $dbh->do('VACUUM fourcc');

    print "Writing database\n";
    $dbh->disconnect;
  }

  _chdir_back();

  return $self->SUPER::ACTION_code;
}

sub ACTION_clean {
  my ($self) = @_;

  my $rc = $self->SUPER::ACTION_clean;
  _chdir_or_die('lib', 'Video', 'FourCC');

  if (-f 'codecs.dat') {
    print "Deleting generated database\n";
    unlink('codecs.dat') or die "Failed: $!\n";
  }

  _chdir_back();


  return $rc;
}

1;
