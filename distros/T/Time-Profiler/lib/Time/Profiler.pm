##############################################################################
#
#  Time::Profiler
#  Vladi Belperchinov-Shabanski "Cade" <cade@biscom.net> <cade@datamax.bg>
#
#  DISTRIBUTED UNDER GPLv2
#
##############################################################################
package Time::Profiler;
use Time::HR;
use Time::Profiler::Scope;
use Data::Dumper;
use strict;

our $VERSION = '1.30';

##############################################################################

sub new
{
  my $class = shift;
  $class = ref( $class ) || $class;
  my $self = {
               'PROFILER_DATA_SINGLE' => {},
               'PROFILER_DATA_TREE'   => {},
             };
  bless $self, $class;
  return $self;
}

sub begin_scope
{
  my $self = shift;
  
  my $scope = new Time::Profiler::Scope( $self, @_ );
  $scope->start();
  
  return $scope;
}

sub report
{
  my $self = shift;

  my $hrs = $self->{ 'PROFILER_DATA_SINGLE' };
  my $hrt = $self->{ 'PROFILER_DATA_TREE'   };

  my $text;
  $text .= "\n";
  $text .= "SINGLE PROFILE SCOPES\n";
  $text .= $self->__report_level( $hrs, 0 );
  $text .= "\n";
  $text .= "TREE PROFILE SCOPES\n";
  $text .= $self->__report_level( $hrt, 0 );

  if( $self->{ 'DEBUG'  } )
    {
    $text .= "\n";
    $text .= "RAW TREE PROFILE DATA\n";
    $Data::Dumper::sortkeys = 1;
    $text .= Dumper( $hrt );
    }
  
  return $text;
}

### INTERNAL #################################################################

sub __report_level
{
  my $self  = shift;
  my $hr    = shift;
  my $level = shift;
  
  my @k = grep { ! /^:(TIME|COUNT)/ } keys %$hr;
  @k = sort { $hr->{ $b }->{ ':TIME' } <=> $hr->{ $a }->{ ':TIME' } } @k;

  #return "\n" if @k == 0;
  
  my $text;
  for my $k ( @k )
    {
    my $t = $hr->{ $k }->{ ':TIME'  };
    my $c = $hr->{ $k }->{ ':COUNT' };

    $t /= 1_000_000_000; # convert to seconds

    my $ts = $c == 1 ? 'time' : 'times';
    my $rs = sprintf( "%5s %-5s = %12.06f sec. ", $c, $ts, $t );
    $rs = ' ' x length( $rs ) if $c == 0;

    $text .= $rs . ( "|    " x $level ) . $k;
    
    $text .= "\n";  
    $text .= $self->__report_level( $hr->{ $k }, $level + 1 );
    }
  
  return $text;  
}

sub __add_dt
{
  my $self = shift;
  my $key  = shift;
  my $dt   = shift;

  my $c = 1 if $key =~ s/^\+//; # cumulative
  
  my @key = split /\//, $key;
  my $hrs = $self->{ 'PROFILER_DATA_SINGLE' };
  my $hrt = $self->{ 'PROFILER_DATA_TREE'   };
  
  if( @key == 1 ) 
    {
    # no slashes, no tree -- single scope
    $hrs->{ $key }{ ':COUNT' }++;
    $hrs->{ $key }{ ':TIME'  } += $dt;
    return;
    }

  # tree scope
  my $ck; # cumulative key
  while( my $k = shift @key )
    {
    $hrt->{ $k } ||= {};
    $hrt = $hrt->{ $k };
    $ck .= "$k/";
    next unless $c;
#    $hrs->{ $ck }{ ':COUNT' }++;
#    $hrs->{ $ck }{ ':TIME'  } += $dt;
    $hrt->{ ':COUNT' }++;
    $hrt->{ ':TIME'  } += $dt;
    }
  return if $c;  
  $hrt->{ ':COUNT' }++;
  $hrt->{ ':TIME'  } += $dt;
}

##############################################################################

=pod

=head1 NAME

Time::Profiler provides scope-automatic or manual code time measurement. 

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use Time::Profiler;

    my $pr = new Time::Profiler; # create new profiler instance

    print "begin main\n";
    # begin main:: scope measuring with automatic names
    my $_ps = $pr->begin_scope(); 

    t1();
    t2();
    sleep( 2 );

    # main:: scope will not end before reporting so must be stopped manually
    $_ps->stop(); 

    # print profiler stats
    print $pr->report(); 

    sub t1
    {   
      print "begin t1\n";
      # begin t1 function scope time measuring
      my $_ps = $pr->begin_scope();

      t2();
      sleep( 3 );
      t2();
      # t1 function scope ends here so timing will end automatically
    }

    sub t2
    {
      print "begin t2\n";
      # begin t2 function scope time measuring
      my $_ps = $pr->begin_scope();

      sleep( 1 );
      # t2 function scope ends here so timing will end automatically
    }

=head1 DESCRIPTION

Time::Profiler is designed to be called inside scopes (or functions) which
are needed to be measured. It provides automatic, manual or cumulative
scope names.

=head1 OUTPUT

The example in the SYNOPSIS will print this output:

    begin main
    begin t1
    begin t2
    begin t2
    begin t2

    SINGLE PROFILE SCOPES
        1 time  =      8.001 sec. main::
        1 time  =      5.000 sec. main::t1
        3 times =      3.000 sec. main::t2

    TREE PROFILE SCOPES
        1 time  =      8.001 sec. main::
        1 time  =      5.000 sec. |    main::t1
        2 times =      2.000 sec. |    |    main::t2
        1 time  =      1.000 sec. |    main::t2

=head1 AUTOMATIC SCOPE NAMES

Time::Profiler will traverse the stack and will construct automatic name if
scope name is left empty or '*':

    t1();
    t2();

    print $pr->report();

    sub t1
    {
      my $_ps = $pr->begin_scope(); # same as below
      t2();
      sleep( 3 );
    }

    sub t2
    {
      my $_ps = $pr->begin_scope( '*' ); # same as above
      sleep( 2 );
    }

Output will be:

    SINGLE PROFILE SCOPES
        1 time  =      5.000 sec. main::t1
        2 times =      4.000 sec. main::t2

    TREE PROFILE SCOPES
                                  main::
        1 time  =      5.000 sec. |    main::t1
        1 time  =      2.000 sec. |    |    main::t2
        1 time  =      2.000 sec. |    main::t2

=head1 MANUAL SCOPE NAMES

Manual names can force fixed scope names. All names without '/' are considered
SINGLE scopes. All names with '/' are TREE scope names. SINGLE and TREE scopes
are reported separately:

    my $_ps = $pr->begin_scope( 'ALL' ); # SINGLE scope

    t1();
    t2();
    
    $_ps->stop;
    print $pr->report();

    sub t1
    {
      # T1 here
      t2();
      sleep( 3 );
    }

    sub t2
    {
      my $_ps = $pr->begin_scope( 'ROOT/T1/T2' ); # TREE scope
      sleep( 2 );
    }

This will force main:: scope name to be 'ROOT' and only nested t2() name 
'ROOT/T1/T2'. Output will be:

    SINGLE PROFILE SCOPES
        1 time  =      5.000 sec. ROOT

    TREE PROFILE SCOPES
        1 time  =      5.000 sec. ROOT
                                  |    T1
        1 time  =      2.000 sec. |    |    T2

So t1() has no profile stats but t2() scope name (path) is measured inside
the 'ROOT' scope.

=head1 CUMULATIVE SCOPE NAMES

TREE scopes can be cumulative. Cumulative names begin with '+' and allow 
measurement aggregation for same type functions.

For example database module may have read_data() and 
write_data() function, which read or write data from/to different tables
(in this example table names are 'CLIENTS' and 'ADDRESSES'):

  sub read_data
  {
    my $table_name = shift;
    my $_ps = $pr->begin_scope( "+DB/READ_DATA/$table_name" );
    ...
  }

  sub write_data
  {
    my $table_name = shift;
    my $_ps = $pr->begin_scope( "+DB/WRITE_DATA/$table_name" );
    ...
  }

Possible output:

    TREE PROFILE SCOPES
        1 time  =     14.000 sec. DB
        1 time  =      8.000 sec. |   READ_DATA
        2 time  =      4.000 sec. |   |   CLIENTS
        2 time  =      4.000 sec. |   |   ADDRESSES
        1 time  =      6.000 sec. |   WRITE_DATA
        1 time  =      3.000 sec. |   |   CLIENTS
        1 time  =      3.000 sec. |   |   ADDRESSES


This will measure several things:

=over 4

=item all calls to read_data() for specific $table_name (DB/READ_DATA/$table_name)

=item all calls to write_data() for specific $table_name (DB/WRITE_DATA/$table_name)

=item will accumulate all read stats for tables (DB/READ_DATA)

=item will accumulate all write stats for tables (DB/WRITE_DATA)

=item will accumulate all database stats for all operations for all tables (DB)

=back  

Other case could require measuring of all DB access for specific table 
(i.e. kind of "DB/*/$table_name"). To achieve this and do not lose the previous
prifile stats, requires multiple scope names:

  sub read_data
  {
    my $table_name = shift;
    my $_ps = $pr->begin_scope( "+DB/READ_DATA/$table_name", "+DB_TABLES/$table_name" );
    ...
  }

This will measure time stats by database access (DB) per table and per operation:

Possible output:

    TREE PROFILE SCOPES
        1 time  =     14.000 sec. DB
        1 time  =      8.000 sec. |   READ_DATA
        2 time  =      4.000 sec. |   |   CLIENTS
        2 time  =      4.000 sec. |   |   ADDRESSES
        1 time  =      6.000 sec. |   WRITE_DATA
        1 time  =      3.000 sec. |   |   CLIENTS
        1 time  =      3.000 sec. |   |   ADDRESSES
        6 time  =     14.000 sec. DB_TABLES
        3 time  =      7.000 sec. |   CLIENTS
        3 time  =      7.000 sec. |   ADDRESSES

=head1 MIXED NAMES

Scopes may have multiple names including mixed types names:

  sub read_data
  {
    my $table_name = shift;
    my $_ps = $pr->begin_scope( "*", "+TT/T2", "ALL_FUNCS" );
    ...
  }

This will produce automatic scope name ("*"), 
cumulative ("+DB/READ_DATA/$table_name") and 
manual static one ("ALL_FUNCS").

In this case stats will be mixed in the same profiler output:

    SINGLE PROFILE SCOPES
        1 time  =      5.000 sec. ROOT
        1 time  =      2.000 sec. main::t2
        1 time  =      2.000 sec. TT/
        1 time  =      2.000 sec. ALL_FUNCS
        1 time  =      2.000 sec. TT/T2/

    TREE PROFILE SCOPES
        1 time  =      5.000 sec. ROOT
        1 time  =      2.000 sec. TT
        1 time  =      2.000 sec. |    T2
        1 time  =      2.000 sec. ALL_FUNCS
                                  main::
                                  |    main::t1
        1 time  =      2.000 sec. |    |    main::t2

=head1 PITFALLS

Avoid cumulative names for recursive or nested functions, otherwise some stats 
may seem wrong:

    t1();
    t2();

    print $pr->report();

    sub t1
    {
      my $_ps = $pr->begin_scope( '+ALL_FUNCS/T1' );
      
      t2();
      sleep( 3 );
    }

    sub t2
    {
      my $_ps = $pr->begin_scope( '+ALL_FUNCS/T2' );
      sleep( 2 );
    }

Output will be:

    SINGLE PROFILE SCOPES
        3 times =      9.000 sec. ALL_FUNCS/
        1 time  =      5.000 sec. ALL_FUNCS/T1/
        2 times =      4.000 sec. ALL_FUNCS/T2/

    TREE PROFILE SCOPES
        3 times =      9.000 sec. ALL_FUNCS
        1 time  =      5.000 sec. |    T1
        2 times =      4.000 sec. |    T2

Total program execution time is actually 7 sec. but we see that ALL_FUNCS says
9 sec. This is because t2() time is measured twice: once as separate function
call and second time as nested function.

=head1 DEPENDENCIES

  Time::HR
  Data::Dumper

=head1 GITHUB REPOSITORY

  https://github.com/cade-vs/perl-time-profiler
  
  git clone git://github.com/cade-vs/perl-time-profiler.git

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg

=cut

##############################################################################
1;
##############################################################################

