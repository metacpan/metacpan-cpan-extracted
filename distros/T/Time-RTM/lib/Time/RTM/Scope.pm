##############################################################################
#
#  Time::RTM::Scope
#  2024 (c) Vladi Belperchinov-Shabanski "Cade" <cade@noxrun.com>
#
#  This is internal module, see Time::RTM for external API
#
#  DISTRIBUTED UNDER GPLv2
#
##############################################################################
package Time::RTM::Scope;
use strict;
use Time::HiRes;
use Carp;

our $VERSION = '1.14';

##############################################################################

sub new
{
  my $class = shift;
  my $rtm   = shift; # controller bject
  my @keys  = @_;
  
  carp( "second argument is expected to be Time::RTM" ) unless ref( $rtm ) eq 'Time::RTM';

  push @keys, '*' if @keys == 0;
  
  $class = ref( $class ) || $class;
  my $self = {
               'RTM'  => $rtm,
               'KEYS' => \@keys,
             };
  bless $self, $class;
  
  $self->restart();
  
  return $self;
}

sub restart
{
  my $self = shift;
  
  $self->{ 'START' } = Time::HiRes::time();
}

# TODO: pause() cont()
sub split_str
{
  my $self = shift;
  
  return "n/a/n" unless $self->{ 'START' };
  return $self->{ 'START' } . "/" . Time::HiRes::time() . "/" . (Time::HiRes::time() - $self->{ 'START' });
}

sub split
{
  my $self = shift;
  
  return undef unless $self->{ 'START' };
  return Time::HiRes::time() - $self->{ 'START' };
}

sub stop
{
  my $self = shift;

  carp( "scope timer is not started, use start() first" ) if $self->{ 'START' } == 0;

  my $st = $self->{ 'START' };
  my $dt = Time::HiRes::time() - $st;
  
  my $rtm = $self->__rtm();
  
  my $keys = $self->{ 'KEYS' };

  for my $key ( @$keys )
    {
    $key = $self->auto_key() if $key =~ /^\*?$/;
    $rtm->__add_dt( $key, $st, $dt );
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
    next if $subname =~ /^Time::RTM::/; # skip self
    next if $subname eq '(eval)' and $se;
    $se = 0;
    push @key, "$subname";
    }

  push @key, 'main::';
    
  my $key = join '/', reverse @key;
  
  return $key;
}

### INTERNAL #################################################################

sub __rtm
{
  my $self = shift;
  
  return $self->{ 'RTM' };
}

##############################################################################

=pod

=head1 NAME

Time::RTM::Scope is used internally by Time::RTM. 
See Time::RTM manual.

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@noxrun.com> <cade@cpan.org>

  http://cade.noxrun.com

=cut

##############################################################################
1;
##############################################################################
