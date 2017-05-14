package Test::Smoke::Database;

# Test::Smoke::Database - Add / parse /display perl reports smoke database
# Copyright 2003 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2004/04/19 17:48:23 $
# $Log: Database.pm,v $
# Revision 1.18  2004/04/19 17:48:23  alian
# update to 1.17
#
# Revision 1.17  2004/04/14 22:37:47  alian
# change url for eg of cgi
#
# Revision 1.16  2003/11/07 17:42:22  alian
# Avoid warnings when create graph
#
# Revision 1.15  2003/09/16 15:41:50  alian
#  - Update parsing to parse 5.6.1 report
#  - Change display for lynx
#  - Add top smokers
#
# Revision 1.14  2003/08/19 10:37:24  alian
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


use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use DBI;
use News::NNTPClient;
use Data::Dumper;
use Test::Smoke::Database::Graph;
use Test::Smoke::Database::DB;
use Test::Smoke::Database::Display;
use Test::Smoke::Database::Parsing;
use Carp qw(cluck);
use File::Basename;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '1.17';

my $limite = 18600;
#$limite = 0;

#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new($$)   {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->{opts} = shift || {};
  my $driver = "DBI:mysql:database=".($self->{opts}->{database} || 'test').
    ";host=localhost;port=3306";
  if (!$self->{opts}->{no_dbconnect}) {
    $self->{DBH} = DBI->connect($driver,
				$self->{opts}->{user},
				$self->{opts}->{password} || undef)
      || die "Can't connect to Mysql:$driver:$!\n";
  }
  if (defined($self->{opts}->{limit})) {
    $self->{opts}->{limit} = 0 if ( $self->{opts}->{limit} eq 'All');
    $limite = $self->{opts}->{limit};
  } else { $limite = 0; }
  $self->{DB} = new Test::Smoke::Database::DB($self);
  $self->{HTML} = new Test::Smoke::Database::Display($self);
  print scalar(localtime),
    ": New run with Test::Smoke::Database version $VERSION\n"
      if ($self->{opts}->{verbose});
  return $self;
}

#------------------------------------------------------------------------------
# db
#------------------------------------------------------------------------------
sub db(\%) { return $_[0]->{DB}; }

#------------------------------------------------------------------------------
# HTML
#------------------------------------------------------------------------------
sub HTML(\%) { return $_[0]->{HTML}; }


#------------------------------------------------------------------------------
# build_graph
#------------------------------------------------------------------------------
sub build_graph(\%) {
  my $self = shift;
  print scalar(localtime),": Create graph\n"
    if ($self->{opts}->{verbose});
  eval("use GD::Graph::mixed");
  if ($@) {
    print scalar(localtime),
      ": You don't seem to have GD::Graph, aborted graph\n"
	if ($self->{opts}->{verbose});
    return;
  }
  my $c = new CGI;
  # Last 50 smoke
  my $last50 = $self->db->last50;
  # Begin, perl-5.9, last 50 smoke
  my %limit = (0 =>'Since smoke 11613', 
	       17500=>'Perl 5.9', 
	       $last50=>'Last 50 smoke');
  my %limit2 = %limit;
  $limit2{cpan}= 'CPAN modules';
  $limit2{"last50"}=$limit2{$last50};
  delete $limit2{$last50};
  foreach my $mt (keys %limit) {
    my $mtx = $mt;
    $mtx = "last50" if ($mt == $last50);
    my $graph = new Test::Smoke::Database::Graph($self->{DBH}, $self,$mt, $mtx);
    $graph->percent_configure();
    $graph->percent_configure_all();
    $graph->configure_per_os();
    $graph->smoke_per_os();
    $graph->configure_per_smoke();
    $graph->os_by_smoke();
    $graph->success_by_os();
    $graph->create_html($mtx, \%limit2, $c);
  }

  my $graph = new Test::Smoke::Database::Graph($self->{DBH}, $self,undef, "cpan");
  $graph->stats_cpan() &&
    $graph->create_html("cpan", \%limit2, $c);
}


#------------------------------------------------------------------------------
# rename_rpt
#------------------------------------------------------------------------------
sub rename_rpt {
  my $self = shift;
  my $nb = 0;
  print scalar(localtime),": Rename report with his nntp id\n"
    if ($self->{opts}->{verbose});
  foreach my $f (glob($self->{opts}->{dir}."/*.rpt")) {
    my $e=`grep 'for [ 1234567890.]*patch' $f`;
    if ($e=~/for [\d\.]* ?patch (\d+)/) {
      if (-e "$f.$1") { unlink($f); }
      else {
	print "Rename $f $1\n" if ($self->{opts}->{debug});
	`mv $f $f.$1`;
	$nb++;
      }
    }
  }
  return $nb;
}

#------------------------------------------------------------------------------
# suck_ng
#------------------------------------------------------------------------------
sub suck_ng {
  my $self = shift;
  my @good = qw!From Date Subject Return-Path!;
  print scalar(localtime),": Suck newsgroup on $self->{opts}->{nntp_server}\n"
    if ($self->{opts}->{verbose});
  # Find last id on dir
  my $max=0;
  my @l = glob($self->{opts}->{dir}."/*");
  foreach (@l) { $max=$1 if (/\/(\d*)\.rpt/ && $1 > $max); }
  print "NNTP max id is $max ($#l files in $self->{opts}->{dir})\n"
    if ($self->{opts}->{debug});

  # Connect on ng
  my $c = new News::NNTPClient($self->{opts}->{nntp_server});
  return undef if (!$c->ok);

  # Fetch last - first
  my ($first, $last) = ($c->group("perl.daily-build.reports"));
  #print "Max:$max first:$first last:$last\n";
  if ($max) {
    if ($max == $last) {
      print scalar(localtime),": No new report on perl.daily-build.reports\n"
	if ($self->{opts}->{verbose});
      $self->rename_rpt();
      return;
    }
    else { $first = $max; }
  }

  while( $first <= $last) {
    open(F,">$self->{opts}->{dir}/$first.rpt") 
      or die "Can't create $self->{opts}->{dir}/$first.rpt:$!\n";
    my @buf = $c->article($first);
    my ($ok,$isreport,$entete,$buf)=(0,1,1);
    foreach (@buf) {
      if (/In-Reply-To/) { $isreport=0; last;}
      if (m!^$!) { $entete=0; }
      if ($entete) {
	foreach my $e (@good) {
	  print F $_ if (/^$e/);
	}
      } else { print F $_; }
    }
    close(F);
    if (!$isreport) { unlink("$first.rpt"); }
    $first++;
  }
  $self->rename_rpt();
}

#------------------------------------------------------------------------------
# parse_import
#------------------------------------------------------------------------------
sub parse_import {
  my $self = shift;
  Test::Smoke::Database::Parsing::parse_import($self);
}

__END__

#------------------------------------------------------------------------------
# POD DOC
#------------------------------------------------------------------------------


=head1 NAME

Test::Smoke::Database - Add / parse /display perl reports smoke database

=head1 SYNOPSIS

  $ admin_smokedb --create --suck --import --update_archi
  $ lynx http://localhost/cgi-bin/smoke_db.cgi
 

=head1 DESCRIPTION

This module help to build an application that parses smoke-reports for
perl-current and puts the results in a database. This allows for a simple
overview of the build status on as wide a variety of supported platforms 
(operating system/architecture) as possible.

This distribution come with 2 perl scripts:

=over

=item admin_smokedb

Fetch / Import smoke report in a mysql database. See L<admin_smokedb>

=item smoke_db.cgi

A www interface to browse this smoke database. Use method from 
L<Test::Smoke::Database::Display>.

=back

=head1 SEE ALSO

L<admin_smokedb>, L<Test::Smoke::Database::FAQ>, L<Test::Smoke>,
L<http://cpanplus.keradel.com/cgi-bin/smoke_db.cgi>, 
L<http://db.test-smoke.org/>

=head1 METHODS

=over 4

=item B<new> I<hash reference>

Construct a new Test::Smoke::Database object and return it. This call too
connect method of DBD::Mysql and store dbh in $self->{DBH} except if 
key I<no_dbconnect> is found in I<hash reference>. Then all SQL request will
be done thru L<Test::Smoke::Database::DB>.

=back

=head2 Actions for admin_smokedb

See L<admin_smokedb>

=over 4

=item B<parse_import>

Wrapper. See L<Test::Smoke::Database::Parsing>

=item B<suck_ng>

Fetch new report from perl.daily-build.reports

=back

=head2 Private methods

=over 4

=item B<rename_rpt>

Rename fetched report to add no of smoke in name of file.
For all reports found, this will append at end of name the number of smoke.
After that all *. and *.rpt file will be deleted. This method is auto. called
after B<fetch> method.

=back

=head1 VERSION

$Revision: 1.18 $

=head1 AUTHOR

Alain BARBET with some help from Abe Timmerman

=cut

1;
