package VS::RuleEngine::Action::SetGlobal;

use strict;
use warnings;

use Carp qw(croak);

use VS::RuleEngine::Constants;

use base qw(VS::RuleEngine::Action);

sub new {
    my ($pkg, %args) = @_;
    my $self = bless \%args, $pkg;
    return $self;
}

sub perform {
    my ($self, $global) = @_[KV_SELF, KV_GLOBAL];
        
    while (my ($k, $v) = each %$self) {
        $global->set($k => $v);
    }
}

1;


=head1 NAME

VS::RuleEngine::Action::SetGlobal - Generic action to set key/value pairs in the global object

=head1 SYNOPSIS

  use VS::RuleEngine::Declare;
  
  my $engine = engine {
      # input_1 and input_2 will be set to the global object (KV_GLOBAL)
      # every time this action is invoked
      action 'set_properties' => instanceof "VS::RuleEngine::Action::SetGlobal" => with_args {
          'input_1' => 5,
          'input_2' => -5,
      }
  }
  
=head1 DESCRIPTION

This is a generic action that sets key/value pairs to the global object. Any 
existing value for a given key will be overwritten.
    
=head1 USAGE

=head2 Rule arguments

This rule expects a hash as its argument, which is what C<< with_args >> provides, 
where the key is the name of the key to set and the value is its value.

=begin PRIVATE

=over 4

=item new

L<VS::RuleEngine::Action/new>

=item perform

L<VS::RuleEngine::Action/perform>

=back

=end PRIVATE

=head1 SEE ALSO

L<VS::RuleEngine::Action::SetLocal>

=cut
