package VS::RuleEngine::Declare;

use strict;
use warnings;

use Carp;
use List::Util qw(first);
use Scalar::Util qw(blessed);

use VS::RuleEngine::Engine;

use VS::RuleEngine::Action::Perl;
use VS::RuleEngine::Hook::Perl;
use VS::RuleEngine::Input::Perl;
use VS::RuleEngine::Output::Perl;
use VS::RuleEngine::Rule::Perl;

use VS::RuleEngine::Util qw(is_existing_package);

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    action
    as
    defaults
    does
    engine 
    input 
    instanceof
    load_module
    output
    posthook
    prehook
    rule
    run
    when
    with_args
    with_defaults
);

our $current_engine;

sub engine(&) {
    my ($sub, $name) = @_;

    my $engine = VS::RuleEngine::Engine->new();

    local $current_engine = $engine;
    $sub->();
    
    if (defined $name) {
        VS::RuleEngine::Engine->register_engine($name => $engine);
    }
    
    return $engine;
}

sub as($) {
    return $_[0];
}

sub does(&) {
    my $cv = shift;
    my $does = bless [$cv], "_Does";
    return $does;
}

{
    my %Classes;
    sub load_module($) {
        my $class = shift;
        if (!exists $Classes{$class}) {
            eval "require $class;";
            croak $@ if $@;
            $Classes{$class} = 1;
        }
        
        1;        
    }
}

sub instanceof($) {
    my $class = shift;
    load_module($class) if !is_existing_package($class);
    my $instanceof = bless [$class], "_InstanceOf";
    return $instanceof;
}

sub with_args($) {
    my $args = shift;
    croak "Arguments must be a hash reference" if ref $args ne 'HASH';
    my $with_args = bless $args, "_WithArgs";
    return $with_args;
}

sub with_defaults($) {
    my $defaults = shift;
    croak "Arguments must be a single string or an array reference" if ref $defaults && ref $defaults ne 'ARRAY';
    $defaults = [$defaults] if ref $defaults ne 'ARRAY';
    
    my $with_defaults = bless [@$defaults], "_WithDefaults";
    return $with_defaults;
}

sub when(@) {
    for (@_) {
        croak "Rule '$_' does not exist" if !$current_engine->has_rule($_);
    }
    my $rules = bless [@_], "_When";
    return $rules;
}

sub run(@) {
    my @when = grep { blessed $_ && $_->isa('_When') } @_;
    my @actions = grep { !(blessed $_ && $_->isa('_When')) } @_;
    
    croak "Unkown input for 'run'" if @_ > @when + @actions;
    
    for (@actions) {
        croak "Action '$_' does not exist" if !$current_engine->has_action($_);
    }
    
    # Add all actions to each rule
    for my $rule (map { @$_ } @when) {
        for my $action (@actions) {
            $current_engine->add_rule_action($rule => $action);
        }
    }
}

sub _get_command {
    my $kind = shift;
    my $base_class = shift;
    my $does_class = shift;
    
    croak "Can't use keyword '${kind}' outside an engine declaration" if !$current_engine;
        
    my @isa = grep { blessed $_ && $_->isa('_InstanceOf') } @_;
    croak "Multiple 'instanceof' declared" if @isa > 1;
    
    my @args = grep { blessed $_ && $_->isa('_WithArgs') } @_;
    croak "Multiple 'with_args' declared" if @args > 1;

    my @defaults = grep { blessed $_ && $_->isa('_WithDefaults') } @_;
    croak "Multiple 'with_defaults' declared" if @defaults > 1;
    
    my @does = grep { blessed $_ && $_->isa('_Does') } @_;
    croak "Multiple 'does' declared" if @does > 1;
    
    my $instance = shift;
    my $cmd;
    my $defaults = [];
    
    if (@isa) {
        $defaults = [@{shift @defaults}] if @defaults;
        @args = @args ? %{shift @args} : ();
        $cmd = (shift @isa)->[0];
    }
    elsif (@does) {
        @args = (shift @does)->[0];
        $cmd = $does_class;
    }
    elsif ($instance && blessed $instance && $instance->isa($base_class)) {
        $cmd = $instance;
    }
    else {
        croak "Can't fingure out how to create ${kind} because we have neither 'instanceof', 'does' nor an instance";
    }
    
    return ($cmd, $defaults, @args);
}

sub action ($@) {
    my $name = shift;    
    my ($action, $defaults, @args) = _get_command("action", "VS::RuleEngine::Action", "VS::RuleEngine::Action::Perl", @_);    
    $current_engine->add_action($name => $action, $defaults, @args);
}

sub defaults ($$) {
    my $name = shift;
    my $defaults = shift;
    croak "Defaults is not a hash reference" if ref $defaults ne 'HASH';
    $current_engine->add_defaults($name => $defaults);
}

sub input ($@) {
    my $name = shift;
    my ($input, $defaults, @args) = _get_command("input", "VS::RuleEngine::Input", "VS::RuleEngine::Input::Perl", @_);    
    $current_engine->add_input($name => $input, $defaults, @args);
}

sub output ($@) {
    my $name = shift;
    my ($output, $defaults, @args) = _get_command("output", "VS::RuleEngine::Output", "VS::RuleEngine::Output::Perl", @_);    
    $current_engine->add_output($name => $output, $defaults, @args);
}

sub prehook ($@) {
    my $name = shift;    
    my ($hook, $defaults, @args) = _get_command("prehook", "VS::RuleEngine::Hook", "VS::RuleEngine::Hook::Perl", @_);    
    $current_engine->add_hook($name => $hook, $defaults, @args);
    $current_engine->add_pre_hook($name);
}

sub posthook ($@) {
    my $name = shift;    
    my ($hook, $defaults, @args) = _get_command("posthook", "VS::RuleEngine::Hook", "VS::RuleEngine::Hook::Perl", @_);    
    $current_engine->add_hook($name => $hook, $defaults, @args);
    $current_engine->add_post_hook($name);
}

sub rule ($@) {
    my $name = shift;    
    my ($rule, $defaults, @args) = _get_command("rule", "VS::RuleEngine::Rule", "VS::RuleEngine::Rule::Perl", @_);    
    $current_engine->add_rule($name => $rule, $defaults, @args);
}

1;
__END__

=head1 NAME

VS::RuleEngine::Declare - Declarative interface for VS::RuleEngine engines

=head1 SYNOPSIS

  use VS::RuleEngine::Constants;
  use VS::RuleEngine::Declare;
  
  my $input = MyApp::MyOtherInput->new();
  my $rule  = MyApp::ComplexRule->new();
  
  my $engine = engine {
      defaults "d1" => {
        some_arg => 1,
      };
      
      input "input1" => instanceof "MyApp::Input" => with_defaults "d1";
      input "input2" => $input;

      rule "rule1" => instanceof "MyApp::Rule" => with_args { input => "input1" };
      rule "rule2" => $rule;

      rule "rule3" => does {
          my ($input, $global, $local) = @_[KV_INPUT, KV_GLOBAL_DATA, KV_LOCAL_DATA];

          if ($input->get("input1") < 5 &&
              $input->get("input1") > 10) {
              return KV_MATCH;  
          }

          return KV_NO_MATCH;
      }; 

      action "action1" => does {
          my $result = complex_calculation();
          $_[KV_LOCAL]->set("result" => $result);
      };
            
      prehook "check_date" => does {
          return KV_CONTINUE;
      };
      
      run "action1" => when qw(rule1 rule2 rule3);
  };
  
  $engine->run();

=head1 INTERFACE

=head2 FUNCTIONS

=over 4

=item engine BLOCK

Creates a new engine.

=item action NAME [=> instanceof CLASS [ => with_defaults DEFAULTS ] [ => with_args ARGS]]

=item action NAME => INSTANCE

=item action NAME => does BLOCK

Creates a new action and registers it in the engine as I<NAME>. If an object is 
passed it must conform to C<VS::RuleEngine::Action>.

=item input NAME [=> instanceof CLASS [ => with_defaults DEFAULTS ] [ => with_args ARGS]]

=item input NAME => INSTANCE

=item input NAME => does BLOCK

Creates a new input and registers it in the engine as I<NAME>. If an object is 
passed it must conform to C<VS::RuleEngine::Input>.

=item output NAME [=> instanceof CLASS [ => with_defaults DEFAULTS ] [ => with_args ARGS]]

=item output NAME => INSTANCE

=item output NAME => does BLOCK

Creates a new output and registers it in the engine as I<NAME>. If an object is 
passed it must conform to C<VS::RuleEngine::Output>.

=item prehook NAME [=> instanceof CLASS [ => with_defaults DEFAULTS ] [ => with_args ARGS]]

=item prehook NAME => INSTANCE

=item prehook NAME => does BLOCK

Creates a new prehook and registers it in the engine as I<NAME>. If an object is 
passed it must conform to C<VS::RuleEngine::Hook>.

Prehooks are evaulated in the order they are declared.

=item posthook NAME [=> instanceof CLASS [ => with_defaults DEFAULTS ] [ => with_args ARGS]]

=item posthook NAME => INSTANCE

=item posthook NAME => does BLOCK

Creates a new posthook and registers it in the engine as I<NAME>. If an object is 
passed it must conform to C<VS::RuleEngine::Hook>.

Posthooks are evaulated in the order they are declared.

=item rule NAME [=> instanceof CLASS [ => with_defaults DEFAULTS ] [ => with_args ARGS]]

=item rule NAME => INSTANCE

=item rule NAME => does BLOCK

Creates a new rule and registers it in the engine as I<NAME>. If an object is 
passed it must conform to C<VS::RuleEngine::Rule>.

Rules are evaulated in the order they are declared unless an order has 
explicitly been defined using C<rule_order>. d

=item run ACTIONS => when RULES

Runs the list of I<ACTION> when the given I<RULES> matches.

=item with_args HASHREF

Creates a argument set for the entity.

=item with_defaults DEFAULT | DEFAULTS

Use the defaults defined by I<DEFAULT> or multiple defaults defined by the ARRAY referene I<DEFAULTS>.

=item as NAME

Checks that I<NAME> is a valid name and returns it if so. Otherwise throws an exception.

=item instanceof CLASS

Marks the declared entity to be an instance of the given I<CLASS>.

=item defaults NAME => ARGUMENTS

Creates a new arguent set with the given I<NAME> and arguments. I<ARGUMENTS> must be a hash reference. 

=item does BLOCK

Marks the declared entity to be implemented via a Perl subroutine.

=item load_module MODULE

Load the module I<MODULE>.

=back

=cut