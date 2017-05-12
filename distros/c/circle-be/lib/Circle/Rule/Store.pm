#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::Rule::Store;

use strict;
use warnings;

use Carp;

use Circle::Rule::Chain;
use Circle::Rule::Resultset;

use Text::Balanced qw( extract_bracketed );

use Attribute::Storage qw( get_subattrs );

#############################################
### Attribute handlers for command_* subs ###
#############################################

sub Rule_description :ATTR(CODE)
{
   my $class = shift;
   my ( $text ) = @_;

   return $text;
}

sub Rule_format :ATTR(CODE)
{
   my $class = shift;
   my ( $format ) = @_;

   return $format;
}

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = bless {
      cond   => {},
      action => {},

      parent => $args{parent},

      chains => {},
   }, $class;

   $self->register_cond( not => $self );
   $self->register_cond( any => $self );
   $self->register_cond( all => $self );

   return $self;
}

sub register_cond
{
   my $self = shift;
   my ( $name, $obj ) = @_;

   croak "Already have a condition function called $name" if exists $self->{cond}->{$name};

   foreach my $method ( "parse_cond_$name", "deparse_cond_$name", "eval_cond_$name" ) {
      eval { $obj->can( $method ) } or 
         croak "Expected that $obj can $method";
   }

   $self->{cond}->{$name} = { obj => $obj };
}

sub list_conds
{
   my $self = shift;
   return ( keys %{ $self->{cond} } ),
          ( $self->{parent} ? $self->{parent}->list_conds : () );
}

sub get_cond
{
   my $self = shift;
   my ( $name ) = @_;

   return $self->{cond}->{$name} if $self->{cond}->{$name};
   return $self->{parent}->get_cond( $name ) if $self->{parent};

   die "No such condition '$name'\n";
}

sub parse_cond
{
   my $self = shift;
   # my ( $spec ) = @_ but we'll use $_[0] for alias

   $_[0] =~ s/^(\w+)\s*// or die "Expected a condition name\n";
   my $condname = $1;

   my $cond = $self->get_cond( $condname );

   my $condspec;
   if( $_[0] =~ m/^\(/ ) {
      $condspec = extract_bracketed( $_[0], q{("')} );
      defined $condspec or die "Bad argument spec '$condspec' for condition $condname\n";
      s/^\(\s*//, s/\s*\)$// for $condspec;
   }

   my $method = "parse_cond_$condname";

   my @condargs = eval { $cond->{obj}->$method( $condspec ) };
   if( $@ ) {
      my $err = $@; chomp $err;
      die "$err while parsing condition spec '$condspec' for $condname\n";
   }

   return [ $condname, @condargs ];
}

sub deparse_cond
{
   my $self = shift;
   my ( $condref ) = @_;

   my ( $name, @args ) = @$condref;

   my $cond = $self->get_cond( $name );

   my $method = "deparse_cond_$name";
   my $argspec = $cond->{obj}->$method( @args );

   return defined $argspec ? "$name($argspec)" : $name;
}

sub eval_cond
{
   my $self = shift;
   my ( $condref, $event, $results ) = @_;

   my ( $name, @args ) = @$condref;

   my $cond = $self->get_cond( $name );

   my $method = "eval_cond_$name";
   return $cond->{obj}->$method( $event, $results, @args );
}

sub describe_cond
{
   my $self = shift;
   my ( $name ) = @_;

   my $cond = $self->get_cond( $name );

   my $attrs = get_subattrs( $cond->{obj}->can( "parse_cond_$name" ) );
   
   return { 
      desc   => $attrs->{Rule_description},
      format => $attrs->{Rule_format},
   };
}

sub register_action
{
   my $self = shift;
   my ( $name, $obj ) = @_;

   croak "Already have a action function called $name" if exists $self->{action}->{$name};

   foreach my $method ( "parse_action_$name", "deparse_action_$name", "eval_action_$name" ) {
      eval { $obj->can( $method ) } or 
         croak "Expected that $obj can $method";
   }

   $self->{action}->{$name} = { obj => $obj };
}

sub list_actions
{
   my $self = shift;
   return ( keys %{ $self->{action} } ),
          ( $self->{parent} ? $self->{parent}->list_actions : () );
}

sub get_action
{
   my $self = shift;
   my ( $name ) = @_;

   return $self->{action}->{$name} if $self->{action}->{$name};
   return $self->{parent}->get_action( $name ) if $self->{parent};

   die "No such action '$name'\n";
}

sub parse_action
{
   my $self = shift;
   # my ( $spec ) = @_ but we'll use $_[0] for alias

   $_[0] =~ s/^(\w+)\s*// or die "Expected an action name, found '$_[0]'\n";
   my $actionname = $1;

   my $action = $self->get_action( $actionname );

   my $actionspec;
   if( $_[0] =~ m/^\(/ ) {
      $actionspec = extract_bracketed( $_[0], q{("')} );
      defined $actionspec or die "Bad argument spec '$actionspec' for action $actionname\n";
      s/^\(\s*//, s/\s*\)$// for $actionspec;
   }

   my $method = "parse_action_$actionname";

   my @actionargs = eval { $action->{obj}->$method( $actionspec ) };
   if( $@ ) {
      my $err = $@; chomp $err;
      die "$err while parsing condition spec '$actionspec' for $actionname\n";
   }

   return [ $actionname, @actionargs ];
}

sub deparse_action
{
   my $self = shift;
   my ( $actionref ) = @_;

   my ( $name, @args ) = @$actionref;

   my $action = $self->get_action( $name );

   my $method = "deparse_action_$name";
   my $argspec = $action->{obj}->$method( @args );

   return defined $argspec ? "$name($argspec)" : $name;
}

sub eval_action
{
   my $self = shift;
   my ( $actionref, $event, $results ) = @_;

   my ( $name, @args ) = @$actionref;

   my $action = $self->get_action( $name );

   my $method = "eval_action_$name";
   return $action->{obj}->$method( $event, $results, @args );
}

sub describe_action
{
   my $self = shift;
   my ( $name ) = @_;

   my $action = $self->get_action( $name );

   my $attrs = get_subattrs( $action->{obj}->can( "parse_action_$name" ) );
   
   return { 
      desc   => $attrs->{Rule_description},
      format => $attrs->{Rule_format},
   };
}

sub new_chain
{
   my $self = shift;
   my ( $name ) = @_;

   $self->{chains}->{$name} ||= Circle::Rule::Chain->new( $self );
}

sub chains
{
   my $self = shift;
   return keys %{ $self->{chains} };
}

sub get_chain
{
   my $self = shift;
   my ( $chainname ) = @_;

   return $self->{chains}->{$chainname} || die "No such rulechain called $chainname\n";
}

sub run
{
   my $self = shift;
   my ( $chainname, $event ) = @_;

   my $chain = $self->{chains}->{$chainname} or die "No such rulechain called $chainname\n";

   $chain->run( $event );
}

# Internal rules for boolean logic

sub parse_cond_not
   : Rule_description("Invert the sense of a sub-condition")
   : Rule_format('condition')
{
   my $self = shift;
   my ( $spec ) = @_;

   return $self->parse_cond( $spec );
}

sub deparse_cond_not
{
   my $self = shift;
   my ( $cond ) = @_;

   return $self->deparse_cond( $cond );
}

sub eval_cond_not
{
   my $self = shift;
   my ( $event, $results, $cond ) = @_;

   # Construct a new result set which we throw away
   return not $self->eval_cond( $cond, $event, Circle::Rule::Resultset->new() );
}

sub parse_cond_any
   : Rule_description("Check if any sub-condition is true")
   : Rule_format('condition ...')
{
   my $self = shift;
   my ( $spec ) = @_;

   my @conds;
   while( length $spec ) {
      push @conds, $self->parse_cond( $spec );

      $spec =~ s/\s+//; # trim ws
   }

   @conds or die "Expected at least one condition\n";

   return @conds;
}

sub deparse_cond_any
{
   my $self = shift;
   my ( @conds ) = @_;

   return join( " ", map { $self->deparse_cond( $_ ) } @conds );
}

sub eval_cond_any
{
   my $self = shift;
   my ( $event, $results, @conds ) = @_;

   foreach my $cond ( @conds ) {
      return 1 if $self->eval_cond( $cond, $event, $results );
   }

   return 0;
}

sub parse_cond_all
   : Rule_description("Check if all sub-conditions are true")
   : Rule_format('condition ...')
{
   my $self = shift;
   my ( $spec ) = @_;

   my @conds;
   while( length $spec ) {
      push @conds, $self->parse_cond( $spec );

      $spec =~ s/\s+//; # trim ws
   }

   @conds or die "Expected at least one condition\n";

   return @conds;
}

sub deparse_cond_all
{
   my $self = shift;
   my ( @conds ) = @_;

   return join( " ", map { $self->deparse_cond( $_ ) } @conds );
}

sub eval_cond_all
{
   my $self = shift;
   my ( $event, $results, @conds ) = @_;

   # Construct sub-results because we don't want any results to apply if a
   # later failure causes us to fail after an earlier cond was successful and
   # stored results
   my $subresults = Circle::Rule::Resultset->new();

   foreach my $cond ( @conds ) {
      return 0 unless $self->eval_cond( $cond, $event, $subresults );
   }

   $results->merge_from( $subresults );
   return 1;
}

0x55AA;
