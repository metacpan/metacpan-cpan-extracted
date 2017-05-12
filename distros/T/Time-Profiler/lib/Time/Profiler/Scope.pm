##############################################################################
#
#  Time::Profiler::Scope
#  Vladi Belperchinov-Shabanski "Cade" <cade@biscom.net> <cade@datamax.bg>
#
#  This is internal module, see Time::Profiler for external API
#
#  DISTRIBUTED UNDER GPLv2
#
##############################################################################
package Time::Profiler::Scope;
use strict;
use Time::HR;
use Carp;

##############################################################################

sub new
{
  my $class    = shift;
  my $profiler = shift;
  my @keys     = @_;
  
  carp( "second argument is expected to be Time::Profiler" ) unless ref( $profiler ) eq 'Time::Profiler';

  push @keys, '*' if @keys == 0;
  
  $class = ref( $class ) || $class;
  my $self = {
               'PROFILER' => $profiler,
               'KEYS'     => \@keys,
             };
  bless $self, $class;
  return $self;
}

sub start
{
  my $self = shift;
  
  $self->{ 'START' } = gethrtime();
}

sub stop
{
  my $self = shift;

  carp( "scope timer is not started, use start() first" ) if $self->{ 'START' } == 0;

  my $dt = gethrtime() - $self->{ 'START' };
  
  my $pr = $self->__pr();
  
  my $keys = $self->{ 'KEYS' };

  for my $key ( @$keys )
    {
    $key = $self->auto_key() if $key =~ /^\*?$/;
    $pr->__add_dt( $key, $dt );
    }

  delete $self->{ 'START' };
}

sub DESTROY
{
  my $self = shift;

  $self->stop() if $self->{ 'START' };
}

sub auto_key
{
  my $self = shift;

  my @key;
  my $i = 0;
  my $se = 1; # skip eval
  while ( my ( $pack, $file, $line, $subname, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash ) = caller($i++) )
    {
    next if $subname =~ /^Time::Profiler::/; # skip self
    next if $subname eq '(eval)' and $se;
    $se = 0;
    push @key, "$subname";
    }

  push @key, 'main::';
    
  my $key = join '/', reverse @key;
  
  return $key;
}

### INTERNAL #################################################################

sub __pr
{
  my $self = shift;
  
  return $self->{ 'PROFILER' }
}

##############################################################################

=pod

=head1 NAME

Time::Profiler::Scope is used internally by Time::Profiler. 
See Time::Profiler manual.

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg

=cut

##############################################################################
1;
##############################################################################
