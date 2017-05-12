#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::Rule::Chain;

use strict;
use warnings;

use Circle::Rule::Resultset;

sub new
{
   my $class = shift;
   my ( $store ) = @_;

   my $self = bless {
      store => $store,
      rules => [],
   }, $class;

   return $self;
}

sub parse_rule
{
   my $self = shift;
   my ( $spec ) = @_;

   my $store = $self->{store};

   my @conds;

   while( length $spec and $spec !~ m/^:/ ) {
      push @conds, $store->parse_cond( $spec );

      $spec =~ s/^\s+//; # trim ws
   }

   $spec =~ s/^:\s*// or die "Expected ':' to separate condition and action\n";

   my @actions;

   while( length $spec ) {
      push @actions, $store->parse_action( $spec );

      $spec =~ s/^\s+//; # trim ws
   }

   @actions or die "Expected at least one action\n";

   return [ \@conds, \@actions ];
}

sub append_rule
{
   my $self = shift;
   my ( $spec ) = @_;

   push @{ $self->{rules} }, $self->parse_rule( $spec );
}

sub insert_rule
{
   my $self = shift;
   my ( $index, $spec ) = @_;

   # TODO: Consider what happens if index is OOB

   splice @{ $self->{rules} }, $index, 0, $self->parse_rule( $spec );
}

sub delete_rule
{
   my $self = shift;
   my ( $index ) = @_;

   $index < @{ $self->{rules} } or die "No rule at index $index\n";

   splice @{ $self->{rules} }, $index, 1, ();
}

sub clear
{
   my $self = shift;

   @{ $self->{rules} } = ();
}

sub deparse_rules
{
   my $self = shift;

   my $store = $self->{store};

   my @ret;

   foreach my $rule ( @{ $self->{rules} } ) {
      my ( $conds, $actions ) = @$rule;
      push @ret, join( " ", map { $store->deparse_cond( $_ ) } @$conds ) .
                 ": " .
                 join( " ", map { $store->deparse_action( $_ ) } @$actions );
   }

   return @ret;
}

sub run
{
   my $self = shift;
   my ( $event ) = @_;

   my $store = $self->{store};

   RULE: foreach my $rule ( @{ $self->{rules} } ) {
      my ( $conds, $actions ) = @$rule;

      my $results = Circle::Rule::Resultset->new();

      foreach my $cond ( @$conds ) {
         $store->eval_cond( $cond, $event, $results )
            or next RULE;
      }

      # We've got this far - run the actions

      foreach my $action ( @$actions ) {
         # TODO: Consider eval{} wrapping
         $store->eval_action( $action, $event, $results );
      }

      # All rules are independent - for now at least
   }
}

0x55AA;
