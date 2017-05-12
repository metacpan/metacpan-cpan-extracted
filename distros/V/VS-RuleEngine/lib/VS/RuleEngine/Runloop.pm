package VS::RuleEngine::Runloop;

use strict;
use warnings;

use Carp qw(croak);
use List::Util qw(first);
use Scalar::Util qw(refaddr blessed);

use VS::RuleEngine::Constants;

my %Engine;
my %Runloop;
my %Initialized;

sub new {
    my ($pkg) = @_;
    my $self = bless \do { my $v; }, $pkg;
    $$self = refaddr $self;

    $Engine{$$self} = [];
    $Runloop{$$self} = [];
    $Initialized{$$self} = 0;

    return $self;
}

sub DESTROY {
    my $self = shift;
    delete $Engine{$$self};
    delete $Initialized{$$self};
    delete $Runloop{$$self};
}

sub add_engine {
    my ($self, $engine, $global) = @_;
    
    croak "Engine is undefined" if !defined $engine;
    croak "Engine is not a VS::RuleEngine::Engine instance" if !(blessed $engine && $engine->isa("VS::RuleEngine::Engine"));
    
    my $engines = $Engine{$$self};
    if (!first { $_->[0] == $engine } @$engines) {
        push @$engines, [$engine, $global];
    }
    else {
        croak "Engine already exists";
    }    
}

sub init {
    my ($self) = @_;
    
    return if $Initialized{$$self};
    
    for my $engine (@{$Engine{$$self}}) {
        my $runloop = _mk_runloop($engine->[0], $engine->[1]);
        $self->_register_runloop($runloop);
    }
}

sub _mk_runloop {
    my $engine = shift;
    my $global = shift;
    
    my @rules = @{$engine->_rule_order};

    my %action_map  = map {
        my $actions = $engine->_get_rule_actions($_);
        $_ => [@{$actions}];
    } @rules;
    
	my %rules       = map {
	    my $rule = $engine->_get_rule($_);
	    my $rule_obj = $rule->instantiate($engine);
	    $_ => $rule_obj;
    } @rules;
    
    my %actions     = map {
        my $action = $engine->_get_action($_);
        my $action_obj = $action->instantiate($engine);
        $_ => $action_obj;
    } $engine->actions;
    
	my @pre_hooks	= map { $_->instantiate($engine); } map { $engine->_get_hook($_) } @{$engine->_pre_hooks};
	my @post_hooks	= map { $_->instantiate($engine); } map { $engine->_get_hook($_) } @{$engine->_post_hooks};

	my $inputs		= $engine->_input_handler;
	my @outputs		= map { $_->instantiate($engine); } map { $engine->_get_output($_) } sort $engine->outputs;

	$global = $global || VS::RuleEngine::Data->new();
	    
	$inputs->set_global($global);

	my $runloop = sub {
	    $inputs->_clear();
	    
		my $local = VS::RuleEngine::Data->new();
		
		$inputs->set_local($local);

		my $skip = 0;
		
		# Process all pre hooks
		for my $hook (@pre_hooks) {
			my $result = $hook->invoke($inputs, $global, $local);
			$skip = 1 if $result == KV_SKIP;
			return KV_ABORT if $result == KV_ABORT;
		}
		
		# Run rules until we find a matching rule
		if (!$skip) {
		    my $match;
		
		    PROCESS_RULES: for (@rules) {
		        my $rule = $rules{$_};
			    my $result = $rule->evaluate($inputs, $global, $local);
			    $skip = 1, last PROCESS_RULES if $result == KV_SKIP;
			    $match = $_, last PROCESS_RULES if $result == KV_MATCH;
		    }
        
            # Run all actions
            if (!$skip && $match) {
                $local->set('VS::RuleEngine/matchingRule' => $match);
                my $actions = $action_map{$match};
                for (@$actions) {
                    my $action = $actions{$_};
                    $action->perform($inputs, $global, $local);
                }
            }
        }
        
        # All outputs are always called if somethings decides not to skip
        if (!$skip) {
		    PROCESS_OUTPUT: for my $output (@outputs) {
			    $output->process($inputs, $global, $local);
		    }
		}
		
		# Process all post hooks
		for my $hook (@post_hooks) {
			my $result = $hook->invoke($inputs, $global, $local);
			return KV_ABORT if $result == KV_ABORT;
		}
		
		return KV_CONTINUE;
	};
	
	return $runloop;
}

sub _register_runloop {
    my ($self, $runloop) = @_;
    
    my $runloops = $Runloop{$$self};
    if (!first { $_ == $runloop } @$runloops) {
        push @$runloops, $runloop;
    }
    else {
        croak "Runloop already registered";
    }
}

sub _unregister_runloop {
    my ($self, $runloop) = @_;
    
    my $runloops = $Runloop{$$self};
    my @runloops = grep { $_ != $runloop } @$runloops;
    $Runloop{$$self} = \@runloops;
    
}

sub step {
    my $self = shift;
    
    my $runloops = $Runloop{$$self};
    
    if (@$runloops) {
        for my $runloop (@$runloops) {
            my $status = $runloop->();
            if ($status == KV_ABORT) {
                $self->_unregister_runloop($runloop);
            }
        }
    }
    
    return scalar @$runloops;
}

sub run {
    my $self = shift;
    
    $self->init();
    
    RUNLOOP: while(1) {
        last RUNLOOP if $self->step() == 0;
    }    
}

1;
__END__

=head1 NAME

VS::RuleEngine::Runloop - Runs engine(s)

=head1 SYNOPSIS

  use VS::RuleEngine::Runloop;
  
  my $engine1 = MyApp::Engine->get_engine();
  my $engine2 = MyApp::Engine->get_another_engine();
  
  my $runloop = VS::RuleEngine::Runloop->new();
  $runloop->add_engine($engine1);
  $runloop->add_engine($engine2);

  # Run the two engines until there's no more processing
  # to be done in either of them
  $runloop->run();
  
=head1 DESCRIPTION

This class converts engine descriptions (C<VS::RuleEngine::Engine>-instances) into something 
runnable and executes them.

If multiple engines are defined in a single runloop execution will continue until no
engines have anything ore to process. Engines that report they are done processing are 
removed from the runloop.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new

Creates a new runloop instance.

=back

=head2 INSTANCE METHODS

=over 4

=item add_engine ( ENGINE [, GLOBALS] )

Adds an engine to the runloop. An optional VS::RuleEngine::Data instance can be passed 
as global data for the engine. If omitted a empty VS::RuleEngine::Data instance will be 
created and used as global.

=item init

Initializes the runloop. Must be called before C<step> in order for 
the runloop to work. It called automaticly by C<run>.

=item step

Performs one iteration in the runloop. Returns the number of engines 
that are still in the runloop. When there is no more work to be done it returns 0.

=item run

Runs the engine until there is no more work to perform.

=back

=cut


