package VS::RuleEngine::Engine;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);

use VS::RuleEngine::Constants;
use VS::RuleEngine::Data;
use VS::RuleEngine::Util qw(is_valid_package_name);
use VS::RuleEngine::Runloop;

use VS::RuleEngine::Engine::Actions;
use VS::RuleEngine::Engine::Defaults;
use VS::RuleEngine::Engine::Hooks;
use VS::RuleEngine::Engine::Inputs;
use VS::RuleEngine::Engine::Outputs;
use VS::RuleEngine::Engine::Rules;

use Object::Tiny qw(
	_actions
	_defaults
	_hooks
	_inputs
	_outputs
	_post_hooks
	_pre_hooks
	_rules
	_rule_actions
	_rule_order
);

sub new {
	my $pkg = shift;

	my $self = bless {
		_actions        => VS::RuleEngine::Data->new(),
		_defaults       => VS::RuleEngine::Data->new(),
		_hooks	        => VS::RuleEngine::Data->new(),
		_inputs		    => VS::RuleEngine::Data->new(),
		_outputs        => VS::RuleEngine::Data->new(),
		_post_hooks     => [],
		_pre_hooks      => [],
		_rules		    => VS::RuleEngine::Data->new(),
		_rule_actions   => VS::RuleEngine::Data->new(),
		_rule_order     => [],
	}, $pkg;
		
	return $self;
}

sub run {
	my $self = shift;
	my $global = shift;
	
    my $runloop = VS::RuleEngine::Runloop->new();

    $runloop->add_engine($self, $global);
    $runloop->run();
}

1;
__END__

=head1 NAME

VS::RuleEngine::Engine - Engine declaration

=head1 SYNOPSIS

  use VS::RuleEngine::Engine;
  
  my $engine = VS::RuleEngine::Engine->new();
  $engine->add_hook(hook1 => "MyApp::GetMoreData");
  $engine->add_rule(rule1 => "MyApp::Rule");
  $engine->add_action(action1 => "MyApp::Action");
  $engine->add_rule_action(rule1 => "action1");
  $engine->run();
  
=head1 DESCRIPTION

This class defines a VS::RuleEngine "engine". Altho it is possible using this class directly it 
is more readable using the declarative interface in L<VS::RuleEngine::Declare> or loading engines 
using an engine loader class (which is currently not available).

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new

Creates a new engine.

=back

=head2 INSTANCE METHODS

=over 4

=item run ( $work_callback )

Runs the engine.

=back

=head3 Defaults

=over 4

=item defaults

Returns the names of all default sets.

=item has_defaults ( NAME )

Checks if the engine has a default set named I<NAME>.

=item get_defaults ( NAME )

Returns a hash reference with the key/value pairs for the default named I<NAME>.

=item add_defaults ( NAME => DEFAULT )

Registers the hash reference I<DEFAULTS> as I<NAME>.

=back

=head3 Actions

=over 4

=item actions

Returns the names of all registered actions.

=item has_action ( NAME )

Checks if the engine has a registered action with the given I<NAME>.

=item add_action ( NAME => ACTION [, DEFAULTS, arguments ... ] )

Registers the I<ACTION> as I<NAME> in the engine with arguments provided by 
default argument sets referenced by name in the array reference I<DEFAULTS> and 
additional arguments.

=back

=head3 Hooks

=over 4

=item hooks

Returns the names of all registered hooks.

=item has_hook ( NAME )

Checks if the engine has a registered hook with the given I<NAME>.

=item add_hook ( NAME => HOOK [, DEFAULTS, arguments ... ] )

Registers the I<HOOK> as I<NAME> in the engine with arguments provided by 
default argument sets referenced by name in the array reference I<DEFAULTS> and 
additional arguments.

=item add_pre_hook ( NAME )

Adds the hook with the given I<NAME> to the list of hooks to run before each iteration.

=item add_post_hook ( NAME )

Adds the hook with the given I<NAME> to the list of hooks to run after each iteration.

=back

=head3 Inputs

=over 4

=item inputs

Returns the names of all registered inputs

=item has_input ( NAME )

Checks if the engine has a registered input with the given I<NAME>.

=item add_input ( NAME => INPUT [, DEFAULTS, arguments ... ] )

Registers the I<INPUT> as I<NAME> in the engine with arguments provided by 
default argument sets referenced by name in the array reference I<DEFAULTS> and 
additional arguments.

=back

=head3 Outputs

=over 4

=item outputs

Returns the names of all registered outputs

=item has_output ( NAME )

Checks if the engine has a registered output with the given I<NAME>.

=item add_output ( NAME => OUTPUT [, DEFAULTS, arguments ... ] )

Registers the I<OUTPUT> as I<NAME> in the engine with arguments provided by 
default argument sets referenced by name in the array reference I<DEFAULTS> and 
additional arguments.

=back

=head3 Rules

=over 4

=item rules

Returns the names of all registered rules

=item has_rule ( NAME )

Checks if the engine has a registered rule with the given I<NAME>.

=item add_rule ( NAME => OUTPUT [, DEFAULTS, arguments ... ] )

Registers the I<OUTPUT> as I<NAME> in the engine with arguments provided by 
default argument sets referenced by name in the array reference I<DEFAULTS> and 
additional arguments.

=item add_rule_action ( NAME => ACTION )

Connects the rule I<NAME> to the action I<ACTION>.

=item rule_order

Returns a list of names matching the rules in the order they'll be evaluated.

=item set_rule_order ( LIST )

Sets which order the rules should be evaluated. The list should be the names of the rules.

=back

=cut