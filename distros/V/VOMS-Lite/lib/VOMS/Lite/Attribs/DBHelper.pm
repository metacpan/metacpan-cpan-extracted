package VOMS::Lite::Attribs::DBHelper;

use 5.004;
use strict;
use warnings;
use DBI;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
%EXPORT_TAGS = ( );
@EXPORT_OK = qw( GetAttrib );
@EXPORT = ( );
$VERSION = '0.20';

##################################################

sub GetAttrib {
  my ($database,$host,$port,$db_user,$db_pass,$role,$group,$ca,$dn,$function) = @_;
  my $datasource="dbi:mysql:database=$database;host=$host;port=$port";   #;sid=XE -- oracle?

  my $dbh;
  eval { $dbh=DBI->connect($datasource, "$db_user", "$db_pass", {AutoCommit=>0,RaiseError=>1}); };
  if ($@) { print STDERR "$@"; return (); }

  my $query;
  my $sth;
  my @Attribs;
  my $version;
  my $uid="userid"; #= "uid" for old version of DB "userid" for new.
  my @ca=($ca);
  my @dn=($dn);
  if    ( $ca =~ s|/userid=|/uid=|g ) { push @ca,$ca; }
  elsif ( $ca =~ s|/uid=|/userid=|g ) { push @ca,$ca; }
  if    ( $dn =~ s|/userid=|/uid=|g ) { push @dn,$dn; }
  elsif ( $dn =~ s|/uid=|/userid=|g ) { push @dn,$dn; }

  ($version)=$dbh->selectrow_array("SELECT version FROM version");
  if    ( $version == 1 ) { $uid="uid"; }
  elsif ( $version != 2 ) { return undef; }
  if ( $function eq "attributes" ) {
    $query="SELECT groups.dn as groupname, role, capability, groups.gid
            FROM groups, usr, ca, m left join roles on roles.rid = m.rid left join capabilities on capabilities.cid = m.cid
            WHERE groups.gid = m.gid AND usr.$uid = m.$uid AND usr.ca = ca.cid AND ca.ca = ? AND usr.dn = ?";
  } elsif ( $function eq "all" ) {
    $query="SELECT usr.dn as username, role, groups.dn as groupname, capability, groups.gid
            FROM groups, usr, ca, m left join roles on roles.rid = m.rid left join capabilities on capabilities.cid = m.cid
            WHERE groups.gid = m.gid AND usr.$uid = m.$uid AND usr.ca = ca.cid AND ca.ca = ? AND usr.dn = ?";
  } elsif ( $function eq "role" ) {
    $query="SELECT usr.dn as username, role, groups.dn as groupname, capability, groups.gid
            FROM groups, usr, ca, m left join roles on roles.rid = m.rid left join capabilities on capabilities.cid = m.cid
            WHERE groups.gid = m.gid AND usr.$uid = m.$uid AND roles.role = '$role' AND usr.ca = ca.cid AND ca.ca = ? AND usr.dn = ?";
  } elsif ( $function eq "group" ) {
    $query="SELECT usr.dn as username, role, groups.dn as groupname, capability, groups.gid
            FROM groups, usr, ca, m left join roles on roles.rid = m.rid left join capabilities on capabilities.cid = m.cid
            WHERE groups.gid = m.gid AND usr.$uid = m.$uid AND groups.dn = '$group' AND usr.ca  = ca.cid AND ca.ca = ? AND usr.dn = ? AND m.rid is NULL";
  } elsif ( $function eq "groupandrole" ) {
    $query="SELECT usr.dn as username, role, groups.dn as groupname, capability, groups.gid
            FROM groups, usr, ca, m left join roles on roles.rid = m.rid left join capabilities on capabilities.cid = m.cid
            WHERE groups.gid = m.gid AND usr.$uid = m.$uid AND roles.role = '$role' AND groups.dn = '$group' AND usr.ca  = ca.cid AND ca.ca = ? AND usr.dn = ?";
  } else { $dbh->disconnect; return undef; }

  $sth=$dbh->prepare($query);

# Build up attributes
  foreach $ca (@ca) {
    foreach $dn (@dn) {
      $sth->execute( ($ca,$dn) );
      while ( 1 ) {
        my $hashref=$sth->fetchrow_hashref();
        last if ( ! defined $hashref );
        my %row=%$hashref;
        my $Attrib=$row{"groupname"}."/Role=".((defined $row{"role"})?$row{"role"}:"NULL")."/Capability=".((defined $row{"capability"})?$row{"capability"}:"NULL");
        my $add=1;
        foreach ( @Attribs ) { $add=0 if ($_ eq $Attrib); }
        push @Attribs, $Attrib if ( $add );
      }
    }
  }

# Do additional query
  $query="SELECT usr.dn as username, role, groups.dn as groupname, capability, groups.gid
          FROM groups, usr, ca, m left join roles on roles.rid = m.rid left join capabilities on capabilities.cid = m.cid
          WHERE groups.gid = m.gid AND usr.$uid = m.$uid AND groups.must IS NOT NULL AND usr.ca  = ca.cid AND ca.ca = ? AND usr.dn = ? AND m.rid is NULL";
  $sth=$dbh->prepare($query);

# Add these attributes to array
  foreach $ca (@ca) {
    foreach $dn (@dn) {
      $sth->execute( ($ca,$dn) );
      while ( 1 ) {
        my $hashref=$sth->fetchrow_hashref();
        last if ( ! defined $hashref );
        my %row=%$hashref;
        my $Attrib=$row{"groupname"}."/Role=".((defined $row{"role"})?$row{"role"}:"NULL")."/Capability=".((defined $row{"capability"})?$row{"capability"}:"NULL");
        my $add=1;
        foreach ( @Attribs ) { $add=0 if ($_ eq $Attrib); }
        push @Attribs, $Attrib if ( $add );
      }
    }
  }

# Get and update sequence number for certificate serial
  my $seqstr;
  eval {
#    $dbh->commit;
    my $sth2=$dbh->prepare("SELECT seq FROM seqnumber");
    $sth2->execute();
    my $hashref=$sth2->fetchrow_hashref();
    my %row=%$hashref;
    use Math::BigInt;
    my $seqno = Math::BigInt->new("0x".$row{"seq"});
    $seqno->binc();
    $seqstr = $seqno->as_hex();
    $seqstr =~ s/^0x//;
    $seqstr =~ y/a-z/A-Z/;
    $dbh->do("UPDATE seqnumber SET seq='$seqstr'");
    $dbh->commit;
  };

  if ($@) {
#      warn "Transaction aborted because $@";
      print STDERR "$@";
      eval { $dbh->rollback };
      if ($@) { print STDERR "$@"; }
      $dbh->disconnect;
      return undef;
  }

  $dbh->disconnect;
  return $seqstr,@Attribs;
}

1;
__END__

=head1 NAME

VOMS::Lite::Attribs::DBHelper - Perl extension for VOMS::Lite

=head1 SYNOPSIS

  use VOMS::Lite::DBHelper::Attribs;
  my ($IssueNo,@Attribs)=GetAttrib($database,$host,$port,$db_user,$db_pass,$role,$group,$ca,$dn,$function);

=head1 DESCRIPTION

  This helper obtains Attributes for a registered user from a VOMS mysql database.
  It returns the Attributes in a list and the issue number for those Attributes.
  The function requires:
   1,   the name of the database (usually the base Group), 
   2,3, the host and port to attach to,
   4,5, the DB username and password
   6,7, Optionally a requested role and group
   8,9, The Issuers DN of the holder's X509 cert and holder's DN strings,
   10   The function (attributes all role group groupandrole).

=head2 EXPORT

None by default.
Exports GetAttrib on request.

=head1 SEE ALSO

This module was originally designed for the SHEBANGS project at The University of Manchester.
http://www.mc.manchester.ac.uk/projects/shebangs/

Mailing list, shebangs@listserv.manchester.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
