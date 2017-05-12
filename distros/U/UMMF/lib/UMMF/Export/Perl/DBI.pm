package UMMF::Export::Perl::DBI;

use 5.6.0;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2004/03/29 };
our $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Export::Perl::DBI - Old DBI forwards-compatibility.

=head1 SYNOPSIS

=head1 DESCRIPTION

This package provides tools for old versions of DBI.

=head1 USAGE

use DBI;
use UMMF::Export::Perl::DBI;

=head1 EXPORT

None exported.

=head1 TO DO

=over 4

=back

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2004/03/29

=head1 SEE ALSO

L<DBI|DBI>,

=head1 VERSION

$Revision: 1.2 $

=head1 METHODS

=cut

#######################################################################

# use base qw(NOTHING);

#######################################################################

use DBI;

#######################################################################
# Backward compatiability with DBI 1.14.
#

if ( ! UNIVERSAL::can('DBI::db', 'selectall_hashref') 
#     || $DBI::VERSION eq '1.42'
 ) 
{
  eval q{
    package DBI::db;

    #print STDERR "Adding selectall_hashref\n";

    sub selectall_hashref
    {
      my ($dbh, $stmt, $key) = @_;

      my %hash;

      # $DB::single = 1;

      my $sth = ref($stmt) ? $stmt : $dbh->prepare($stmt);
      $sth->execute();

      while ( my $row = $sth->fetchrow_hashref() ) {
        die("Fetched row is not a hash") unless ref($row) eq 'HASH';
        $hash{$row->{$key}} = $row;
      }

      $sth->finish;

      wantarray ? %hash : \%hash;
    }

  };
  die($@) if $@;
}


if ( ! UNIVERSAL::can('DBI::db', 'selectrow_hashref') 
#     || $DBI::VERSION eq '1.42'
 ) 
{
  eval q{
    package DBI::db;
    
    #print STDERR "Adding selectrow_hashref\n";

    sub selectrow_hashref
    {
      my ($dbh, $stmt) = @_;

      my %hash;

      # $DB::single = 1;

      my $sth = ref($stmt) ? $stmt : $dbh->prepare($stmt);
      $sth->execute();

      my $row = $sth->fetchrow_hashref();

      $sth->finish;

      $row;
    }

  };
  die($@) if $@;
}


#######################################################################

1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

