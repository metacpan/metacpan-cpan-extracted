##############################################################################
#
#  Time::RTM runtime metrics
#  2024 (c) Vladi Belperchinov-Shabanski "Cade" <cade@noxrun.com>
#
#  DISTRIBUTED UNDER GPLv2
#
##############################################################################
package Time::RTM;

use 5.006;
use strict;
use Carp;
use Time::RTM::Scope;

our $VERSION = '1.14';

our %ATTRS =  (
              log             => 1,
              logfile         => 1,
              );

sub new
{
  my $class = shift;

  my $self = { RTM => [] };
  bless $self;
  $self->attr( @_ );
  return $self;
}

sub attr
{
  my $self = shift;

  croak "bad number of attribute/value pairs" unless @_ == 0 or @_ % 2 == 0;
  my @ret;
  my %h = @_;
  for( keys %h )
    {
    croak "invalid attribute name: $_" unless $ATTRS{ $_ };
    $self->{ $_ } = $h{ $_ } if defined $h{ $_ };
    push @ret, $self->{ $_ };
    }
  return @ret;
}

sub begin_scope
{
  my $self = shift;
  
  return new Time::RTM::Scope( $self, @_ );
}

sub __add_dt
{
  my $self = shift;

  my $key  = shift;
  my $st   = shift;
  my $dt   = shift;

  push @{ $self->{ 'RTM' } }, "[RTM:K=$key;S=$st;D=$dt]";
}

sub save
{
  my $self = shift;

  open( my $of, $self->{ 'logfile' } );
  $of->print( $_, "\n" ) for @{ $self->{ 'RTM' } };
  close( $of );
  @{ $self->{ 'RTM' } }= ();
}

sub get_data
{
  my $self = shift;

  return $self->{ 'RTM' };
}

1;

=pod

=head1 NAME

Time::RTM - Run-time metrics stats

=head1 SYNOPSIS

  use Time::RTM;

  my $rtm = new Time::RTM logfile => '/tmp/rtm.log';
  
  {
    my $_r = $rtm->begin_scope( 'DB/SELECT/CARS_MAP' );
    # do work, select tables :)
  }
  # end of scope:
  # $_r stats will be recorded internally into $rtm and $_r discarded
  
  # you can force recording of stats with deleting $_r before end of scope:
  undef $_r;
  # or:
  $_r->stop();
  
  # $_r can be restarted with new stats:
  $_r->restart();
  
  
  # to write down currently recorded stats to the logfile:
  $rtm->save();

  # which will also flush current data and will record new one
  $rtm->begin_scope( 'HANDLERS/h_select/TRIPS' );
  # etc.

  # you can also access anytime the internal log and send it somewhere else:
  my $rtm_array_ref = $rtm->get_data();
  # then save @$rtm_array_ref to a database or send tp a dot matrix printer
  # you also can flush it after save and continue using $rtm with new data:
  @$rtm_array_ref = ();
  $rtm->begin_scope( 'FILE/IO' );
  

  # to view stats from the logfile:
  # in a shell prompt:
  perl -MTime::RTM::Report -e 'rtm_report_main(@ARGV)' -- /tmp/rtm.log
  
  # to get help:
  perl -MTime::RTM::Report -e 'rtm_report_main(@ARGV)' -- -h
  
  # or create small perl, rtm.pl:
            #!/usr/bin/perl
            use strict;
            use Time::RTM::Report;
            rtm_report_main(@ARGV)
            
  # then:
  rtm.pl -l 3 -p DB/SELECT -s MS /tmp/rtm.log
  # will printf report of all DB/SELECT branches, up to level 3 with 
  # sorting by median speed, see "rtm.pl -h" for more details
  
  # sample report looks like:
  +------------------------------------------------------------------------+
  | METRIC KEY PATH        | COUNT | TIME       | MED      | MED/sec       |
  +------------------------------------------------------------------------+
  | NETWORK                | 21441 | 272.743691 | 0.000491 |   2036.659878 |
  |     SOCK_REQUEST       |  7249 |  92.968934 | 0.000478 |   2092.050209 |
  |     SOCK_RESPONSE      |  6943 |   0.834674 | 0.000067 |  14925.373134 |
  | MAIN_LOOP              |  6943 |  79.945274 | 0.000195 |   5128.205128 |
  |     PROCESS_XT_MSG     |  6943 |  79.945274 | 0.000195 |   5128.205128 |
  |         CONNECT        |   306 |  75.680687 | 0.245800 |      4.068348 |
  |         SELECT         |   317 |   0.924200 | 0.002907 |    343.997248 |
  |         LANG           |   306 |   0.098311 | 0.000297 |   3367.003367 |
  |         NEXT           |  4738 |   0.867704 | 0.000171 |   5847.953216 |
  | HANDLERS               |  6628 |  79.287188 | 0.000127 |   7874.015748 |
  |     h_connect          |   306 |  75.634023 | 0.245563 |      4.072275 |
  |     h_update           |    12 |   0.038996 | 0.003227 |    309.885342 |
  |         TASKS          |     6 |   0.019931 | 0.003396 |    294.464075 |
  |         ZZ_SESSIONS    |     6 |   0.019065 | 0.003227 |    309.885342 |
  |     h_select           |   317 |   0.838763 | 0.002643 |    378.357927 |
  |         TASKS          |     4 |   0.011384 | 0.003209 |    311.623559 |
  |         CERTS          |     6 |   0.014033 | 0.002339 |    427.533134 |
  |         TRIPS          |     3 |   0.002698 | 0.001012 |    988.142292 |
  |     h_finish           |   317 |   0.009083 | 0.000027 |  37037.037037 |
  | DB                     | 14635 |   9.172849 | 0.000086 |  11627.906977 |
  |     INSERT             |     3 |   0.005676 | 0.001802 |    554.938957 |
  |         CARS_MAP       |     3 |   0.005676 | 0.001802 |    554.938957 |
  |     SELECT             |  6200 |   8.692144 | 0.001143 |    874.890639 |
  |         TASKS          |     4 |   0.007903 | 0.001705 |    586.510264 |
  |         USER_DATA      |  1224 |   1.386472 | 0.000938 |   1066.098081 |
  |         CARS_MAP       |  1224 |   1.253929 | 0.000826 |   1210.653753 |
  |     UPDATE             |     7 |   0.008143 | 0.001111 |    900.090009 |
  |         CARS_SIDS      |     7 |   0.008143 | 0.001111 |    900.090009 |
  |     FREEID             |     6 |   0.006308 | 0.000970 |   1030.927835 |
  |         TASKS          |     3 |   0.004149 | 0.001324 |    755.287009 |
  +------------------------------------------------------------------------+

  rtm.pl -p DB/SELECT -s MS /tmp/rtm.log
  +------------------------------------------------------------------------+
  | METRIC KEY PATH        | COUNT | TIME       | MED      | MED/sec       |
  +------------------------------------------------------------------------+
  | DB                     | 14635 |   9.172849 | 0.000086 |  11627.906977 |
  |     SELECT             |  6200 |   8.692144 | 0.001143 |    874.890639 |
  |         TASKS          |     4 |   0.007903 | 0.001705 |    586.510264 |
  |         USER_DATA      |  1224 |   1.386472 | 0.000938 |   1066.098081 |
  |         CARS_MAP       |  1224 |   1.253929 | 0.000826 |   1210.653753 |
  +------------------------------------------------------------------------+

  rtm.pl -p DB -l 2 -s MS /tmp/rtm.log
  +------------------------------------------------------------------------+
  | METRIC KEY PATH        | COUNT | TIME       | MED      | MED/sec       |
  +------------------------------------------------------------------------+
  | DB                     | 14635 |   9.172849 | 0.000086 |  11627.906977 |
  |     INSERT             |     3 |   0.005676 | 0.001802 |    554.938957 |
  |     SELECT             |  6200 |   8.692144 | 0.001143 |    874.890639 |
  |     UPDATE             |     7 |   0.008143 | 0.001111 |    900.090009 |
  |     FREEID             |     6 |   0.006308 | 0.000970 |   1030.927835 |
  +------------------------------------------------------------------------+

  # get dispersion graph for metric-path
  rtm.pl -p DB/SELECT -r /tmp/rtm.log
  status: option: dispersion graph requested
  status: option: metric path set to [DB/SELECT]
  +------------------------------------------------------------------------+
  | DTIME    | OPS/sec     | PERCENT | FREQUENCY                           |
  +------------------------------------------------------------------------+
  | 0.000143 | 6993.006993 |    67.0 | *********************************** |
  | 0.001585 |  630.914826 |    28.4 | **************                      |
  | 0.003028 |  330.250991 |     4.1 | **                                  |
  | 0.004470 |  223.713647 |     0.2 |                                     |
  | 0.005913 |  169.118891 |     0.1 |                                     |
  +------------------------------------------------------------------------+


=head1 DESCRIPTION

This module records time slices used by pieces of code. More docs to follow :)

=head1 GITHUB REPOSITORY


  https://github.com/cade-vs/perl-time-rtm
  
  git clone https://github.com/cade-vs/perl-time-rtm


=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@noxrun.com> <cade@cpan.org>

  http://cade.noxrun.com

=head1 COPYRIGHT AND LICENSE

This software is (c) 2024 by Vladi Belperchinov-Shabanski E<lt>cade@noxrun.comE<gt> E<lt>cade@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
