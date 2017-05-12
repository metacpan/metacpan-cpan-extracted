package VS::RuleEngine::InputHandler;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(refaddr blessed);

my %Global;
my %Local;
my %InputCache;

sub new {
    my ($pkg, %inputs) = @_;
    my $self = bless \%inputs, $pkg;

    $InputCache{refaddr $self} = {};
    $Global{refaddr $self} = undef;
    $Local{refaddr $self} = undef;
    
    return $self;
}

sub _clear {
    my $self = shift;
    
    my $caller = caller;
    croak "You are not allowed to clear the input" if $caller ne "VS::RuleEngine::Runloop";
    
    $InputCache{refaddr $self} = {};
}

sub set_global {
    my ($self, $global) = @_;
    croak "Not a VS::RuleEngine::Data instance" unless blessed $global && $global->isa("VS::RuleEngine::Data");
    $Global{refaddr $self} = $global;
}

sub set_local {
    my ($self, $local) = @_;
    croak "Not a VS::RuleEngine::Data instance" unless blessed $local && $local->isa("VS::RuleEngine::Data");
    $Local{refaddr $self} = $local;
}

sub DESTROY {
    my $self = shift;
    
    delete $InputCache{refaddr $self};
    delete $Global{refaddr $self};
    delete $Local{refaddr $self};
}

sub get {
    my $self = shift;
    my $input = shift;
    
    my $addr = refaddr $self;
    my $cache = $InputCache{$addr};
    if (exists $cache->{$input}) {
        return $cache->{$input};
    }
    
    croak "I don't know anything about '${input}'" if !exists $self->{$input};
    
    my $input_obj = $self->{$input};
    my $value = $input_obj->value($self, $Global{$addr}, $Local{$addr});
    $cache->{$input} = $value;
    
    return $value;
}

1;
__END__

=head1 NAME

VS::RuleEngine::InputHandler - Handles input retrieval

=head1 SYNOPSIS

  package MyApp::Rule;
  
  use base qw(VS::RuleEngine::Rule);
  
  # ... constructors etc ...
  
  sub evaluate {
      # Retrieve the current input handler for the executing engine
      my ($input) = @_[KV_INPUT];
      
      # Retrieve the current value from the input 'some_input' 
      if ($input->get("some_input") > 10) {
          return KV_MATCH;
      }
      
      return KV_NO_MATCH;
  }
  
=head1 DESCRIPTION

This class handles input retrieval for an engine. It should not be instanciated by users.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( INPUTS )

Creates a new input manager for the given I<INPUTS>. I<INPUTS> must be a list of key/value pairs.

=back

=head2 INSTANCE METHODS

=over 4

=item get ( INPUT [, ARGS])

Retrieves the value from the input whose name is I<INPUT>. If the input does not exist an exception is 
thrown. Passes any extra arguments to the inputs value function as KV_ARGS.

=item set_local ( LOCAL )

Sets the local data for the manager.

=item set_global ( GLOBAL )

Sets the global data for the manager.

=back

=cut
