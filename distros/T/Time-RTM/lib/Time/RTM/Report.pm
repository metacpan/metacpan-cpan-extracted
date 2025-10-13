##############################################################################
#
#  Time::RTM runtime metrics
#  2024 (c) Vladi Belperchinov-Shabanski "Cade" <cade@noxrun.com>
#
#  DISTRIBUTED UNDER GPLv2
#
##############################################################################
package Time::RTM::Report;

use 5.006;
use strict;
use Carp;
use Data::Tools;
use Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw( 
                  rtm_report_main
              
                  print_report_from_file
                );

our $VERSION = '1.15';
our $DEBUG;

##############################################################################

# usage: perl -MTime::RTM::Report -e 'rtm_report_main(@ARGV)' -- -s MS /path/to/file/rtm.log

my $help_text = <<END;
usage: $0 <options>
options:
    -s sortkey     -- sort by: C  -- count
                               D  -- delta time (total used time)
                               MD -- median delta time
                               MS -- median speed, count per second
                               AD -- average delta time
                               AS -- average speed, count per second
    -p metric-path -- show single metric-path dispersion, example:
                               -p DB/SELECT/USERS_TABLE
                               -p NETWORK
                               -p DISK/IO
    -r metric-path -- shows dispersion for metric-path (see -p)
    -l level       -- limit display metric-level
    -d             -- increase DEBUG level (can be used multiple times)
    --             -- end of options
notes:
  * options cannot be grouped: must be -f -d instead of -fd
END

my %SORT_OPTS = ( 
                  C  => 'count', 
                  D  => 'delta time (total used time)', 
                  MD => 'median delta time', 
                  MS => 'median speed, count per second', 
                  AD => 'average delta time', 
                  AS => 'average speed, count per second',
                );

my $opt_sort  = 'D';
my $opt_level;
my $opt_metric_path;
my $opt_dispersion;

sub rtm_report_main
{
  if( @_ == 0 )
    {
    print $help_text;
    exit;
    }

  my @args;
  while( @_ )
    {
    $_ = shift;
    if( /^--+$/io )
      {
      push @args, @_;
      last;
      }
    if( /^-s/ )
      {
      my $s = uc shift;
      $opt_sort = $s if exists $SORT_OPTS{ $s };
      print STDERR "status: option: sort by $SORT_OPTS{ $s }\n";
      next;
      }
    if( /^-p/ )
      {
      $opt_metric_path = shift;
      print STDERR "status: option: metric path set to [$opt_metric_path]\n";
      next;
      }
    if( /^-r/ )
      {
      $opt_metric_path = shift;
      $opt_dispersion++;
      print STDERR "status: option: dispersion graph requested for [$opt_metric_path]\n";
      next;
      }
    if( /^-l/ )
      {
      $opt_level = shift;
      $opt_level = undef if $opt_level < 1 or $opt_level > 1024; # upper level funny high :)
      print STDERR "status: max metric-level is set to [$opt_level]\n";
      next;
      }
    if( /^-d/ )
      {
      $DEBUG++;
      print STDERR "status: option: debug level raised, now is [$DEBUG]\n";
      next;
      }
    if( /^(--?h(elp)?|help)$/io )
      {
      print $help_text;
      exit;
      }
    if( /^-/ )
      {
      die "error: unknown option [$_]\n";
      }  
    push @args, $_;
    }

  die "error: dispersion graph requested but no metric-path was given, use -p\n" if $opt_dispersion and ! $opt_metric_path;

  print_report_from_file( shift @args );
}

##############################################################################

# TODO: move to Time::RTM::Report
sub print_report_from_file
{
  my $fn = shift;
  die "cannot print Time::RTM report from file via the object interface\n" if ref $fn;

  my $DATA = {};
  open( my $if, '<', $fn );
  while(<$if>)
    {
    next unless /\[RTM:([^\]]+)\]/;
    my $d = { map { split /=/ } split /;/, $1};
    $d->{ 'D' } = sprintf( "%.6f", $d->{ 'D' } );
    my @k = split /\//, $d->{ 'K' };
    my $data = $DATA;
    while( @k )
      {
      my $k = shift @k;
      $data->{ $k } ||= {};
#      push @{ $data->{ $k }{ '@' }{ '@D' } }, $d->{ 'D' };
      $data = $data->{ $k };
      }
    push @{ $data->{ '@' }{ '@D' } }, $d->{ 'D' };
    }

  my @metric_path = split /\//, $opt_metric_path;

  __precalc_level( $DATA );

  my @table;
  if( $opt_dispersion )
    {
    push @table, [ 'DTIME', 'COUNT', 'OPS/sec', 'PERCENT', 'FREQUENCY' ];
    __format_dispersion( $DATA, \@table, \@metric_path );
    }
  else
    {  
    push @table, [ 'METRIC KEY PATH', 'COUNT', 'TIME', 'MED', 'MED/sec', 'AVG', 'AVG/sec', 'MIN', 'MAX' ];
    __format_level( $DATA, $opt_sort, \@table, (@metric_path > 0 ? \@metric_path : undef) );
    }
  print format_ascii_table( \@table );
}

sub __precalc_level
{
  my $data  = shift;
  my $sort  = shift;
  my $level = shift || 0;

  for my $e ( grep { ! /\@/ } keys %$data )
    {
    __precalc_item( $data->{ $e }{ '@' } );
    __precalc_level( $data->{ $e }, $sort, $level + 1 );
    }
}

sub __precalc_item
{
  my $hr = shift;

  return 0 unless exists $hr->{ '@D' };
  
  my @d = sort { $a <=> $b } @{ $hr->{ '@D' } };
  my $s;
  $s += $_ for @d;

  $hr->{ 'C'  } = @d;     # count
  $hr->{ 'D'  } = $s;     # total delta time
  $hr->{ 'DI' } = $d[ 0]; # minimum delta time
  $hr->{ 'DX' } = $d[-1]; # maximum delta time
  
  $hr->{ 'MD' } = $d[ @d / 2 ]; # median delta
  $hr->{ 'MS' } = 1 / $hr->{ 'MD' }; # median speed
  
  $hr->{ 'AD' } = $s / @d; # average delta
  $hr->{ 'AS' } = 1 / $hr->{ 'AD' }; # average speed
  
  return 1;
}

sub __format_level
{
  my $data  = shift;
  my $sort  = shift;
  my $table = shift;
  my $path  = shift;
  my $level = shift || 0;

  return if $opt_level > 0 and $level > $opt_level - 1;

  for my $e ( sort { $data->{ $b }{ '@' }{ $sort } <=> $data->{ $a }{ '@' }{ $sort } || $a cmp $b } grep { ! /\@/ } keys %$data )
    {
    next if $path and $path->[ $level ] and $path->[ $level ] ne $e;
    my @row;
    push @row, ( ' ' x ( $level * 4 ) ) . $e;
    push( @row, $data->{ $e }{ '@' }{ 'C' }, map { sprintf "%.6f", $data->{ $e }{ '@' }{ $_ } } qw[ D MD MS AD AS DI DX ] ) if $data->{ $e }{ '@' }{ 'C' };
    push @$table, \@row;
    __format_level( $data->{ $e }, $sort, $table, $path, $level + 1 );
    }
}

sub __format_dispersion
{
  my $data  = shift;
  my $table = shift;
  my $path  = shift;

  my @p = @$path;
  my $d = $data;
  while( @p )
    {
    my $p = shift @p;
    $d = $d->{ $p };
    die "error: [$p] part of metric-path [@$path] does not exist\n" unless $d;
    }

  $d = $d->{ '@' };

  my $slots = 21;
  
  my $di = $d->{ 'DI' };
  my $dx = $d->{ 'DX' };
  
  my $p = ( $dx - $di ) / $slots;
  
  my $c;
  my $x;
  my %s;
  for( @{ $d->{ '@D' } } )
    {
    my $k = int( ( $_ - $di ) / $p )*$p + $di;
    my $v = ++$s{ sprintf( "%.6f", $k ) };
    $x = $v if $v > $x;
    $c++;
    }

  for my $k ( sort { $a <=> $b } keys %s )
    {
    my $v = $s{ $k };
    push @$table, [ $k, $v, sprintf( "%.6f", 1/$k ), sprintf( "%.1f", 100 * $v / $c ), "*" x int( 42 * $v / $x ) ];
    }
}

1;

=pod

=head1 NAME

Time::RTM::Report is used with Time::RTM. 
See Time::RTM manual.

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@noxrun.com> <cade@cpan.org>

  http://cade.noxrun.com

=cut
