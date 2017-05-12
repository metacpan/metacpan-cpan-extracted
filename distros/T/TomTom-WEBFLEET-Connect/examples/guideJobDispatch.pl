#!/usr/bin/perl -Ilib -w

#
# Copyright (c) 2006-2010, TomTom International B.V.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the TomTom nor the names of its
#   contributors may be used to endorse or promote products derived from this
#   software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

=head1 NAME

guideJobDispatch - Using C<TomTom::WEBFLEET::Connect> to dispatch jobs

=head1 SYNOPSIS

 guideJobDispatch.pl [options]

   Options:
     --accout     Account name (required)
     --username   User name (required)
     --password   Password (required)
     --dsn        Data Source name
     --dbuid      Data Source user name
     --dbpwd      Data Source password
     --trace      Enable trace output (URL, response)
     --xml        Output data as XML
     --help|?     Show help
     --man        Show manual

=head1 DESCRIPTION

B<guideJobDispatch> accompanies the WEBFLEET.connect Developer Guide - Job Dispatch. See this guide in the WEBFLEET.connect downloads section online to learn more about this example.

=head1 SEE ALSO

L<TomTom::WEBFLEET::Connect>

=head1 COPYRIGHT

Copyright 2010 TomTom International B.V.

All rights reserved.

=cut

use strict;
use DBI;
use TomTom::WEBFLEET::Connect;
use Getopt::Long;

my %opt = ();
GetOptions(\%opt,
  'account=s', 'username=s', 'password=s',
  'dsn=s', 'dbuid=s', 'dbpwd=s',
  'trace!', 'xml', 'man');

my $dbh = DBI->connect('DBI:'.$opt{dsn}, $opt{dbuid}, $opt{dbpwd});
my $wfc = new TomTom::WEBFLEET::Connect(%opt);

my $sth = $dbh->prepare('select * from jobs where jobsent = false');
$sth->execute;
my @jobs;
while (my $h = $sth->fetchrow_hashref) {
  push @jobs, {%$h};
}

$sth = $dbh->prepare('update jobs set jobsent=true where jobid = ?');
foreach my $h (@jobs) {
  my $r;
  if (defined $h->{ttaddress}) {
    $r = $wfc->sendDestinationOrder(
	  objectno=>$h->{ttobject},
      orderid=>$h->{jobid},
      ordertext=>$h->{jobtext},
      addrnr=>$h->{ttaddress});
  } else {
    $r = $wfc->sendOrder(
	  objectno=>$h->{ttobject},
      orderid=>$h->{jobid},
      ordertext=>$h->{jobtext});
  }
  if ($r->is_success) {
    $sth->execute($h->{jobid});
  }
}

$sth = $dbh->prepare('update jobs set ttcompleted=true, ttcompletiontime=? where jobid=?');
my $r = $wfc->showOrderReport(range_pattern=>'d0',useISO8601=>'true');
if ($r->is_success) {
  foreach my $i (@{$r->content_arrayref}) {
    $sth->execute($i->{orderstate_time}, $i->{orderid}) if ($i->{orderstate} =~ '[34]01');
  }
}
