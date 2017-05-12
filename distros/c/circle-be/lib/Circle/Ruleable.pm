#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2014 -- leonerd@leonerd.org.uk

package Circle::Ruleable;

use base qw( Circle::Commandable );

use strict;
use warnings;

sub init_rulestore
{
   my $self = shift;
   my %args = @_;

   $self->{rulestore} = Circle::Rule::Store->new( %args );
}

sub run_rulechain
{
   my $self = shift;
   my ( $chainname, $event ) = @_;

   return if eval { $self->{rulestore}->run( $chainname, $event ); 1 };

   my $err = $@; chomp $err;
   $self->responderr( "Exception during processing of rulechain '$chainname': $err" );
}

sub command_rules
   : Command_description("Display or manipulate action rules")
{
   # The body doesn't matter as it never gets run
}

sub command_rules_list
   : Command_description("List the action rules")
   : Command_subof('rules')
   : Command_default()
   : Command_arg('chain?')
{
   my $self = shift;
   my ( $chain, $cinv ) = @_;

   my $rulestore = $self->{rulestore};

   my @chains = $rulestore->chains;

   if( defined $chain ) {
      grep { $chain eq $_ } @chains or 
         return $cinv->responderr( "No such rule chain '$chain'" );
   }

   foreach my $chain ( sort @chains ) {
      $cinv->respond( "Chain '$chain':" );
      my @rules = $rulestore->get_chain( $chain )->deparse_rules();
      $cinv->respond( "$_: $rules[$_]" ) for 0 .. $#rules;
   }

   return;
}

sub command_rules_add
   : Command_description("Add a new rule")
   : Command_subof('rules')
   : Command_arg('chain')
   : Command_arg('spec', eatall => 1)
{
   my $self = shift;
   my ( $chain, $spec, $cinv ) = @_;

   my $rulestore = $self->{rulestore};

   $rulestore->get_chain( $chain )->append_rule( $spec );

   $cinv->respond( "Added to chain $chain" );
}

sub command_rules_insert
   : Command_description("Insert a rule before another rule")
   : Command_subof('rules')
   : Command_arg('chain')
   : Command_arg('index')
   : Command_arg('spec', eatall => 1)
{
   my $self = shift;
   my ( $chain, $index, $spec, $cinv ) = @_;

   $index =~ m/^\d+$/ or
      return $cinv->responderr( "Bad index: $index" );

   my $rulestore = $self->{rulestore};

   $rulestore->get_chain( $chain )->insert_rule( $index, $spec );

   $cinv->respond( "Inserted in $chain before rule $index" );
}

sub command_rules_replace
   : Command_description("Replace an existing rule with a new one")
   : Command_subof('rules')
   : Command_arg('chain')
   : Command_arg('index')
   : Command_arg('spec', eatall => 1)
{
   my $self = shift;
   my ( $chain, $index, $spec, $cinv ) = @_;

   # We'll do this by inserting our new rule before the one we want to
   # replace. If it works, delete the old one, which will now be one further
   # down.

   my $rulestore = $self->{rulestore};
   my $rulechain = $rulestore->get_chain( $chain );

   $rulechain->insert_rule( $index, $spec );
   $rulechain->delete_rule( $index + 1 );

   $cinv->respond( "Replaced $chain rule $index" );
}

sub command_rules_delete
   : Command_description("Delete a rule")
   : Command_subof('rules')
   : Command_arg('chain')
   : Command_arg('index')
{
   my $self = shift;
   my ( $chain, $index, $cinv ) = @_;

   $index =~ m/^\d+$/ or
      return $cinv->responderr( "Bad index: $index" );

   my $rulestore = $self->{rulestore};

   $rulestore->get_chain( $chain )->delete_rule( $index );

   $cinv->respond( "Deleted $chain rule $index" );
}

sub command_rules_describe
   : Command_description("Describe rule conditions or actions")
   : Command_subof('rules')
   : Command_arg('name?')
   : Command_opt('conds=+',   desc => "List conditions")
   : Command_opt('actions=+', desc => "List actions")
{
   my $self = shift;
   my ( $name, $opts, $cinv ) = @_;

   my $rulestore = $self->{rulestore};

   my @names;
   
   if( defined $name ) {
      @names = ( $name );
   }
   else {
      # List both if neither or both options specified
      push @names, sort $rulestore->list_conds   if !$opts->{actions} or $opts->{conds};
      push @names, sort $rulestore->list_actions if !$opts->{conds}   or $opts->{actions};
   }

   for my $name ( @names ) {
      if( my $attrs = eval { $rulestore->describe_cond( $name ) } ) {
         my $description = $attrs->{desc} || "[has no description]";
         $cinv->respond( "Condition '$name': $description" );
         $cinv->respond( "  $name($attrs->{format})" ) if defined $attrs->{format};
      }
      elsif( $attrs = eval { $rulestore->describe_action( $name ) } ) {
         my $description = $attrs->{desc} || "[has no description]";
         $cinv->respond( "Action '$name': $description" );
         $cinv->respond( "  $name($attrs->{format})" ) if defined $attrs->{format};
      }
      else {
         $cinv->responderr( "No such condition or action '$name'" );
      }
   }

   return;
}

use Class::Method::Modifiers qw( install_modifier );
sub APPLY_Ruleable
{
   my $caller = caller;

   install_modifier $caller, after => load_configuration => sub {
      my $self = shift;
      my ( $ynode ) = @_;

      return unless my $rules_ynode = $ynode->{rules};
      my $rulestore = $self->{rulestore};

      foreach my $chain ( keys %$rules_ynode ) {
         my $chain_ynode = $rules_ynode->{$chain};
         my $chain = $rulestore->new_chain( $chain ); # or fetch the existing one
         $chain->clear;
         $chain->append_rule( $_ ) for @$chain_ynode;
      }
   };

   install_modifier $caller, after => store_configuration => sub {
      my $self = shift;
      my ( $ynode ) = @_;

      my $rulestore = $self->{rulestore};
      my $rules_ynode = $ynode->{rules} ||= YAML::Node->new({});

      foreach my $chain ( $rulestore->chains ) {
         my $chain_ynode = $rules_ynode->{$chain} = [
            $rulestore->get_chain( $chain )->deparse_rules(),
         ];
      }

      # Delete any of the old ones
      $rulestore->get_chain( $_ ) or delete $rules_ynode->{$_} for keys %$rules_ynode;
   };
}

0x55AA;
