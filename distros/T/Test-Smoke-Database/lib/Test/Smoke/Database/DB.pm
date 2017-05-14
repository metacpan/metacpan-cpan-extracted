package Test::Smoke::Database::DB;

# Test::Smoke::Database::DB
# Copyright 2003 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2004/04/19 17:49:35 $
# $Log: DB.pm,v $
# Revision 1.10  2004/04/19 17:49:35  alian
# fix on warnings
#
# Revision 1.9  2004/04/14 22:35:43  alian
# display address of cgi at end of run
#
# Revision 1.8  2003/11/07 17:34:53  alian
# Change display at import
#
# Revision 1.7  2003/09/16 15:41:50  alian
#  - Update parsing to parse 5.6.1 report
#  - Change display for lynx
#  - Add top smokers
#
# Revision 1.6  2003/08/19 10:37:24  alian
# Release 1.14:
#  - FORMAT OF DATABASE UPDATED ! (two cols added, one moved).
#  - Add a 'version' field to filter/parser (Eg: All perl-5.8.1 report)
#  - Use the field 'date' into filter/parser (Eg: All report after 07/2003)
#  - Add an author field to parser, and a smoker HTML page about recent
#    smokers and their available config.
#  - Change how nbte (number of failed tests) is calculate
#  - Graph are done by month, no longuer with patchlevel
#  - Only rewrite cc if gcc. Else we lost solaris info
#  - Remove ccache info for have less distinct compiler
#  - Add another report to tests
#  - Update FAQ.pod for last Test::Smoke version
#  - Save only wanted headers for each nntp articles (and save From: field).
#  - Move away last varchar field from builds to data
#
# Revision 1.5  2003/08/15 15:10:42  alian
# Set osver here is not needed
#
# Revision 1.4  2003/08/14 08:48:35  alian
# Don't save line with only t | ? | -
#
# Revision 1.3  2003/08/08 14:27:59  alian
# Update POD documentation
#
# Revision 1.2  2003/08/07 18:01:44  alian
# Update read_all to speed up requests
#
# Revision 1.1  2003/08/06 18:50:41  alian
# New interfaces with DB.pm & Display.pm
#

use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use DBI;
use Data::Dumper;
use Carp qw(cluck);
use File::Basename;
use Sys::Hostname;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = ('$Revision: 1.10 $ ' =~ /(\d+\.\d+)/)[0];
use vars qw/$debug $verbose $limit/;
#$limite = 0;

#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new   {
  my $class = shift;
  my $self = {};
  my $indexer = shift;
  bless $self, $class;
  $self->{DBH} = $indexer->{DBH};
  $self->{CGI} = $indexer->{opts}->{cgi};
  $debug = ($indexer->{opts}->{debug} ? 1 : 0);
  $verbose = ($indexer->{opts}->{verbose} ? 1 : 0);
  $limit = $indexer->{opts}->{limit};
  return $self;
}

#------------------------------------------------------------------------------
# DESTROY
#------------------------------------------------------------------------------
sub DESTROY {
  $_[0]->{DBH}->disconnect if ($_[0]->{DBH});
  if ($verbose) {
    print scalar(localtime),": Over. Consult result at:\nhttp://",
      ($ENV{SERVER_NAME} || hostname()),"/cgi-bin/smoke_db.cgi\n";
  }
}

#------------------------------------------------------------------------------
# rundb
#------------------------------------------------------------------------------
sub rundb(\%\%) {
  my ($self,$cmd,$nochomp) = @_;
  my $ret = 1;
  foreach (split(/;/, $cmd)) {
    $_=~s/\n//g if (!$nochomp);
    next if (!$_ or $_ eq ';');
    print "mysql <-\t$_\n" if ($debug);
    if (!$self->{DBH}->do($_)) {
      print STDERR "Error $_: $DBI::errstr!\n";
      $ret = 0;
    }
  }
  return $ret;
}

#------------------------------------------------------------------------------
# read_all
#------------------------------------------------------------------------------
sub read_all(\%) {
  my $self = shift;
  my $cgi = $self->{CGI};
  return {} if (!$self->{DBH});
  my ($req,%h2);

  # $a is SQL restriction on database
  my $a;
  if ($cgi->param('smoke')) { $a.="smoke =".$cgi->param('smoke'); }
  else { $a.="smoke >=$limit"; }
  foreach my $o ('cc','ccver','os','osver','archi','date','version') {
    my $v = $cgi->param($o) || $cgi->param($o.'_fil') 
      || $cgi->cookie($o) || undef;
    next if (!$v or $v eq 'All');
    $a.=" and " if ($a);
    if ($o eq 'date') { $a.="$o>'$v' "; }
    else { $a.="$o='$v' "; }
  }

  # Select id of build for failure & details
  my $list_id;
  if ($cgi->param('failure') || ($cgi->param('last'))) {
    my $req = "select id from builds ";
    $req.="where $a" if ($a);
    my $ref_lid = $self->{DBH}->selectcol_arrayref($req) ||
      print "On $req: $DBI::errstr\n";
    $list_id = join("," , @$ref_lid);
  }

  # Failure
  my (%failure, %matrix);
  if ($cgi->param('failure') || $cgi->param('last')) {
    $req = "select idbuild,matrix";
    $req.=",failure" if ($cgi->param('failure'));
    $req.=" from data";
    if ($list_id) { $req.=" where idbuild in (".$list_id.")"; }
    my $ref_failure = $self->{DBH}->selectall_arrayref($req) ||
      print "On $req: $DBI::errstr\n";
    foreach my $ra (@$ref_failure) {
      $matrix{$ra->[0]} = $ra->[1];
      $failure{$ra->[0]} = $ra->[2] if $cgi->param('failure');
    }
  }

  # Detailed results
  if ($cgi->param('last')) {
    $req = "select idbuild,configure,result from configure ";
    if ($list_id) { $req.=" where idbuild in (".$list_id.")"; }
    my $ref_result = $self->{DBH}->selectall_arrayref($req) ||
      print "On $req: $DBI::errstr\n";
    foreach my $ra (@$ref_result) {
      $h2{$ra->[0]}{$ra->[1]} = $ra->[2];
    }
  }

  # Each times, read config
  $req = <<EOF;
select id,os,osver,archi,cc,ccver,date,smoke,nbc,nbco,
       nbcm,nbcf,nbcc,nbte
from builds
EOF
   $req.="where $a" if ($a);
  my $st = $self->{DBH}->prepare($req);
  $st->execute || print STDERR $req,"<br>";
  my %h;
  while (my ($id,$os,$osver,$archi,$cc,$ccver,$date,$smoke,$nbc,$nbco,
	     $nbcm,$nbcf,$nbcc,$nbte)=
	 $st->fetchrow_array) {
    $os=lc($os);
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{date}=$date;
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{id} = $id;
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{nbc} = $nbc;
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{nbco} = $nbco;
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{nbcf} = $nbcf;
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{nbcc} = $nbcc;
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{nbcm} = $nbcm;
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{nbte} = $nbte;
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{nbtt} =
      $nbcf + $nbcm + $nbco + $nbcc;
    # $failure
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{failure} =
      $failure{$id} if ($failure{$id});
    # build
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{build} = $h2{$id}
      if $h2{$id};
    # matrix
    $h{$os}{$osver}{$archi}{$cc}{$ccver}{$smoke}{matrix} = $matrix{$id}
      if $matrix{$id};
  }
  $st->finish;
  return \%h;
}


#------------------------------------------------------------------------------
# read_smokers
#------------------------------------------------------------------------------
sub read_smokers(\%) {
  my $self = shift;
  my %smokers;
  my $req =" select distinct author from builds where date > DATE_SUB(NOW(), INTERVAL 6 MONTH)";
  my $ref = $self->{DBH}->selectcol_arrayref($req) || return undef;
  foreach (@$ref) {
    $req = "select distinct os,osver,archi,cc,ccver, count(*) from builds where author='$_' ".
      " and date > DATE_SUB(NOW(), INTERVAL 6 MONTH) group by 1,2,3,4,5 order by 1,2,3,4,5";
    $smokers{$_} = $self->{DBH}->selectall_arrayref($req) || return undef;
  }
  return \%smokers;
}

#------------------------------------------------------------------------------
# read_top_smokers
#------------------------------------------------------------------------------
sub read_top_smokers{
  my $self = shift;
  my $lim = shift || 20;
  my $req = "select distinct author,count(*) from builds where date ".
    "group by 1 order by 2 desc limit $lim";
  return $self->{DBH}->selectall_arrayref($req) || undef;
}

#------------------------------------------------------------------------------
# distinct
#------------------------------------------------------------------------------
sub distinct(\%$) {
  my ($self, $col)=@_;
  my $req = "select distinct $col from builds where smoke>=$limit 
             order by $col";
  return $self->{DBH}->selectcol_arrayref($req) || undef;
}

#------------------------------------------------------------------------------
# nb
#------------------------------------------------------------------------------
sub nb(\%) {
  my $self = shift;
  my $req = "select count(*) from builds";
  $req .=" where smoke >= $limit" if $limit;
  return $self->one_shot($req);
}

#------------------------------------------------------------------------------
# last50
#------------------------------------------------------------------------------
sub last50(\%) {
  my $self = shift;
  my $req = 'select max(smoke)-50 from builds';
  return $self->one_shot($req);
}

#------------------------------------------------------------------------------
# one_shot
#------------------------------------------------------------------------------
sub one_shot(\%$) {
  my ($self, $req) = @_;
  return if (!$self->{DBH});
  my $row_ary = $self->{DBH}->selectrow_arrayref($req) || return undef;
  print STDERR $req,"\n", Data::Dumper->Dump([$row_ary]) if $debug;
  return $row_ary->[0] || undef;
}

#------------------------------------------------------------------------------
# add_to_db
#------------------------------------------------------------------------------
sub add_to_db(\%\%) {
  my ($self, $ref)=@_;
  return if (!ref($ref) || ref($ref) ne 'HASH' || !$ref->{os});
  my ($nbco, $nbcf, $nbcm, $nbcc)=(0,0,0,0);
  my ($cc,$ccf,$f,$r) = ($ref->{cc}||' ',$ref->{ccver} || ' ',
			 $ref->{failure},$ref->{report});
  foreach ($cc,$ccf,$f,$r) { if ($_) { s/'/\\'/g; s/^\s*//g; }}
  # Count make test ok / build fail in make / configure fail / make test fail
  foreach my $c (keys %{$$ref{build}}) {
    foreach (split(/ /,$$ref{build}{$c})) {
      if ($_ eq 'O') { $nbco++; }
      elsif ($_ eq 'F') { $nbcf++; }
      elsif ($_ eq 'm') { $nbcm++; }
      elsif ($_ eq 'c') { $nbcc++; }
    }
  }
  my $pass = (($nbcf || $nbcm || $nbcc) ? 0 : 1);
  printf( "\t =>%25s %s %5s (%s) %s\n",
	  $ref->{os}." ".$ref->{osver}, ($pass ? "PASS" : "FAIL"),
	  $ref->{version}, basename($ref->{file}), $ref->{date}) if $verbose;
  # Ajout des infos sur le host
  my $v2 = ($ref->{matrix} ? join("|", @{$ref->{matrix}}) : '');
  my $req = "INSERT INTO builds(";
  $req.= 'id,' if ($ref->{id});
  $req.= "os,osver,cc,ccver,date,smoke,version,author,nbc,nbco,nbcf,nbcm,nbcc,nbte,archi) ".
    "VALUES (";
  $req.= "$ref->{id}," if ($ref->{id});
  $req.= <<EOF;
'$ref->{os}',
'$ref->{osver}',
'$cc',
'$ccf',
EOF
  $req.= ($ref->{date} ? "'$ref->{date}'" : 'NOW()');
  $req.= <<EOF;
,$ref->{smoke},
'$ref->{version}','
EOF
  $req.= ($ref->{author} ? $ref->{author} : 'anonymous');
  $req.= <<EOF;
',$ref->{nbc},
$nbco,
$nbcf,
$nbcm,
$nbcc,
$ref->{nbte},
'$ref->{archi}')
EOF

  print STDERR $req if $debug;
  my $st = $self->{DBH}->prepare($req);
  if (!$st->execute) {
    print STDERR "SQL: $req\n", Data::Dumper->Dump([$ref]);
    cluck($DBI::errstr);
    return;
  }
  # id du test
  my $id =  $st->{'mysql_insertid'};
  $ref->{id}=$id;
  print STDERR Data::Dumper->Dump([$ref]) if $debug;

  # Ajout des details des erreurs
  $r = ' ' if (!$r);
  $f = ' ' if (!$f);
  $req = <<EOF;
INSERT INTO data(idbuild,failure,matrix)
VALUES ($id, '$f','$v2')
EOF
    $self->rundb($req,1) || print STDERR "On $req\n";

  # Ajout des options du configure
  foreach my $config (keys %{$$ref{build}}) {
    my $co = $config; $co=~s/'/\\'/g;
    my $v = $$ref{build}{$config};
    $v=~s/'/\\'/g;
    $req = <<EOF;
INSERT INTO configure (idbuild,configure,result)
VALUES ($id,'$co','$v')
EOF
 #   print $req,"\n";
    $self->rundb($req,1) or print STDERR "On $req\n";
  }
  return ($DBI::errstr ? 0 : 1);
}

__END__

#------------------------------------------------------------------------------
# POD DOC
#------------------------------------------------------------------------------


=head1 NAME

Test::Smoke::Database::DB - Interface for smoke database

=head1 SYNOPSIS

  my $a = new Test::Smoke::Database;
  $a->db->rundb("SQL request");

=head1 DESCRIPTION

This module give all mysql method for manipulate smoke database

=head1 SEE ALSO

L<admin_smokedb>, L<Test::Smoke::Database>,
L<http://www.alianwebserver.com/perl/smoke/smoke_db.cgi>

=head1 METHODS

=over 4

=item B<new> I<hash reference>

Construct a new Test::Smoke::Database object and return it. This call too
connect method of DBD::Mysql and store dbh in $self->{DBH} except if 
key I<no_dbconnect> is found in I<hash reference>. Disconnect method is
auto called with DESTROY call if needed.

=item B<rundb> I<SQL request>

This will do like $dbh->do, but several request can be put in SQL request,
separated by ';'. Return 1 on sucess, 0 if one of request failed. If failed,
reason is printed on STDERR.

=back

=head2 Private methods

=over 4

=item B<read_all>

=back

=head1 VERSION

$Revision: 1.10 $

=head1 AUTHOR

Alain BARBET with some help from Abe Timmerman

=cut

1;
