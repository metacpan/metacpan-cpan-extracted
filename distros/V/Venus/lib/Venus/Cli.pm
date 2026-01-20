package Venus::Cli;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

use POSIX ();

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Printable';

# ATTRIBUTES

attr 'name';
attr 'version';
attr 'summary';
attr 'description';
attr 'header';
attr 'footer';
attr 'arguments';
attr 'options';
attr 'choices';
attr 'routes';
attr 'data';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    name => $data,
  };
}

sub build_data {
  my ($self, $data) = @_;

  $data->{data} ||= [];
  $data->{arguments} ||= {};
  $data->{options} ||= {};
  $data->{choices} ||= {};
  $data->{routes} ||= {};

  return $data;
}

sub build_self {
  my ($self, $data) = @_;

  my $arguments = $self->arguments;

  $self->argument($_, $arguments->{$_}) for keys %{$arguments};

  my $choices = $self->choices;

  $self->choice($_, $choices->{$_}) for keys %{$choices};

  my $options = $self->options;

  $self->option($_, $options->{$_}) for keys %{$options};

  my $routes = $self->routes;

  $self->route($_, $routes->{$_}) for keys %{$routes};

  $self->reorder;

  return $self;
}

# HOOKS

sub _exit {
  POSIX::_exit(shift);
}

sub _print {
  do {local $| = 1; CORE::print(@_, "\n")}
}

sub _prompt {
  do {local $\ = ''; local $_ = <STDIN>; chomp; $_}
}

# METHODS

sub args {
  my ($self) = @_;

  my $parsed_arguments = $self->parsed_arguments;

  $self->parse if !$parsed_arguments || !@{$parsed_arguments};

  $parsed_arguments = $self->parsed_arguments;

  require Venus::Args;

  return Venus::Args->new(value => $parsed_arguments);
}

sub argument {
  my ($self, $name, @data) = @_;

  return undef if !$name;

  return $self->arguments->{$name} if !@data;

  return delete $self->arguments->{$name} if !defined $data[0];

  my $defaults = {
    name => $name,
    label => undef,
    help => undef,
    default => undef,
    multiples => 0,
    prompt => undef,
    range => undef,
    required => false,
    type => 'string',
    index => int(keys(%{$self->arguments})),
    wants => undef,
  };

  require Venus;

  my $overrides = Venus::merge_take({}, @data);

  $overrides->{wants} //= $overrides->{type} || 'string' if !exists $overrides->{wants};

  my $data = Venus::merge_take($self->arguments->{$name} || $defaults, $overrides);

  $data->{help} ||= "Expects a $data->{type} value";

  return $self->arguments->{$data->{name} ? $data->{name} : $name} = $data;
}

sub argument_choice {
  my ($self, $name) = @_;

  my $output = [];

  return $output if !$name;

  my $choices = {map +($$_{name}, $_), $self->argument_choices($name)};

  for my $value ($self->argument_value($name)) {
    if (exists $choices->{$value}) {
      push @{$output}, $value;
    }
    else {
      $output = [];
      last;
    }
  }

  return wantarray ? @{$output} : $output;
}

sub argument_choices {
  my ($self, $name) = @_;

  my $output = [];

  $output = [grep +($$_{argument} eq $name), $self->choice_list] if $name;

  return wantarray ? @{$output} : $output;
}

sub argument_count {
  my ($self) = @_;

  return int(scalar(keys(%{$self->arguments})));
}

sub argument_default {
  my ($self, $name) = @_;

  return '' if !$name;

  my $argument = $self->argument($name);

  return '' if !defined $argument;

  my $default = $argument->{default};

  return $default;
}

sub argument_errors {
  my ($self, $name) = @_;

  return [] if !$name;

  my $result = $self->argument_validate($name);

  $result = [$result] if ref $result ne 'ARRAY';

  @{$result} = grep defined, map $_->issue, @{$result};

  return wantarray ? (@{$result}) : $result;
}

sub argument_help {
  my ($self, $name) = @_;

  return '' if !$name;

  my $argument = $self->argument($name);

  return '' if !$argument;

  my $help = $argument->{help};

  return $help;
}

sub argument_label {
  my ($self, $name) = @_;

  return '' if !$name;

  my $argument = $self->argument($name);

  return '' if !$argument;

  my $label = $argument->{label};

  return $label;
}

sub argument_list {
  my ($self) = @_;

  my $output = [];

  my $arguments = $self->arguments;

  $output = [map $arguments->{$_}, $self->argument_names];

  return wantarray ? @{$output} : $output;
}

sub argument_multiples {
  my ($self, $name) = @_;

  return false if !$name;

  my $argument = $self->argument($name);

  return false if !$argument;

  my $multiples = $argument->{multiples};

  return $multiples ? true : false;
}

sub argument_name {
  my ($self, $name) = @_;

  return '' if !$name;

  my $argument = $self->argument($name);

  return '' if !$argument;

  $name = $argument->{name};

  return $name;
}

sub argument_names {
  my ($self) = @_;

  my $arguments = $self->arguments;

  my @names = sort {
    (exists $arguments->{$a}->{index} ? $arguments->{$a}->{index} : $a)
      <=> (exists $arguments->{$b}->{index} ? $arguments->{$b}->{index} : $b)
  } keys %{$arguments};

  return wantarray ? (@names) : [@names];
}

sub argument_prompt {
  my ($self, $name) = @_;

  return '' if !$name;

  my $argument = $self->argument($name);

  return '' if !$argument;

  my $prompt = $argument->{prompt};

  return $prompt;
}

sub argument_range {
  my ($self, $name) = @_;

  return '' if !$name;

  my $argument = $self->argument($name);

  return '' if !$argument;

  my $range = $argument->{range};

  return $range;
}

sub argument_required {
  my ($self, $name) = @_;

  return false if !$name;

  my $argument = $self->argument($name);

  return false if !$argument;

  my $required = $argument->{required};

  return $required ? true : false;
}

sub argument_type {
  my ($self, $name) = @_;

  return '' if !$name;

  my $argument = $self->argument($name);

  return '' if !$argument;

  my $type = $argument->{type};

  return $type;
}

sub argument_validate {
  my ($self, $name) = @_;

  return [] if !$name;

  my $argument = $self->argument($name);

  return [] if !$argument;

  require Venus::Validate;

  my $validate = Venus::Validate->new(input => [$self->argument_value($name)]);

  my $required = $argument->{required} ? 'required' : 'optional';

  my $value = $validate->each($required);

  my $type = 'string';

  $type = 'boolean' if $argument->{type} eq 'boolean';
  $type = 'float' if $argument->{type} eq 'float';
  $type = 'number' if $argument->{type} eq 'number';
  $type = 'any' if $argument->{type} eq 'string';
  $type = 'yesno' if $argument->{type} eq 'yesno';

  for my $value (@{$value}) {
    next if $required eq 'optional' && !defined $value->input->[0];
    $value->type($type);
  }

  my $multiples = $argument->{multiples};

  return $multiples ? (wantarray ? (@{$value}) : $value) : $value->[0];
}

sub argument_value {
  my ($self, $name) = @_;

  return undef if !$name;

  my $argument = $self->argument($name);

  return undef if !$argument;

  my $parsed_arguments = $self->parsed_arguments;

  my $range = $argument->{range};

  require Venus::Array;

  my $value = Venus::Array->new($parsed_arguments)->range($range);

  @{$value} = (grep defined, @{$value});

  my $default = $argument->{default};

  $value = defined $default
    ? ref $default eq 'ARRAY'
      ? $default
      : [$default // ()]
    : [$self->argument_value_prompt($name) // ()] if !@{$value};

  my $type = 'string';

  $type = 'boolean' if $argument->{type} eq 'boolean';
  $type = 'float' if $argument->{type} eq 'float';
  $type = 'number' if $argument->{type} eq 'number';
  $type = 'string' if $argument->{type} eq 'string';
  $type = 'yesno' if $argument->{type} eq 'yesno';

  require Scalar::Util;

  if ($type eq 'number') {
    @{$value} = map +(Scalar::Util::looks_like_number($_) ? (0+$_) : $_), @{$value};
  }

  if ($type eq 'boolean') {
    @{$value} = map +(Scalar::Util::looks_like_number($_) ? !!$_ ? true : false
      : $_ =~ /true/i ? true : false), @{$value};
  }

  my $multiples = $argument->{multiples};

  return $multiples ? (wantarray ? (@{$value}) : $value) : $value->[0];
}

sub argument_value_prompt {
  my ($self, $name) = @_;

  return undef if !$name;

  my $argument = $self->argument($name);

  return undef if !$argument;

  my $prompt = $argument->{prompt};

  return undef if !$prompt;

  _print($prompt);

  my $captured = _prompt;

  return $captured eq '' ? undef : $captured;
}

sub argument_wants {
  my ($self, $name) = @_;

  return '' if !$name;

  my $argument = $self->argument($name);

  return '' if !$argument;

  my $wants = $argument->{wants};

  return $wants;
}

sub assigned_arguments {
  my ($self) = @_;

  my $values = {};

  for my $name ($self->argument_names) {
    $values->{$name} = $self->argument_value($name);
  }

  return $values;
}

sub assigned_options {
  my ($self) = @_;

  my $values = {};

  for my $name ($self->option_names) {
    $values->{$name} = $self->option_value($name);
  }

  return $values;
}

sub boolean {
  my ($self, $next, @args) = @_;

  my $data = {type => 'boolean'};

  $data = {%{pop(@args)}, %{$data}} if ref $args[$#args] eq 'HASH';

  return $data if !$next;

  return $self->$next(undef, $data) if !@args;

  push @args, $data;

  return $self->$next(@args);
}

sub choice {
  my ($self, $name, @data) = @_;

  return undef if !$name;

  return $self->choices->{$name} if !@data;

  return delete $self->choices->{$name} if !defined $data[0];

  my $defaults = {
    name => $name,
    label => undef,
    help => undef,
    argument => undef,
    index => int(keys(%{$self->choices})),
    wants => undef,
  };

  require Venus;

  my $overrides = Venus::merge_take({}, @data);

  $overrides->{wants} //= $overrides->{type} || 'string' if !exists $overrides->{wants};

  my $data = Venus::merge_take($self->choices->{$name} || $defaults, $overrides);

  my $link = $self->argument($data->{argument}) if $data->{argument};

  $data->{help} ||= "Expects a $link->{type} value" if $link;

  return $self->choices->{$name} = $data;
}

sub choice_argument {
  my ($self, $name) = @_;

  return '' if !$name;

  my $choice = $self->choice($name);

  return '' if !$choice;

  my $argument = $choice->{argument};

  return $self->argument($argument);
}

sub choice_count {
  my ($self) = @_;

  return int(scalar(keys(%{$self->choices})));
}

sub choice_default {
  my ($self, $name) = @_;

  return '' if !$name;

  my $choice = $self->choice($name);

  return '' if !$choice;

  my $argument = $choice->{argument};

  return $self->argument_default($argument);
}

sub choice_errors {
  my ($self, $name) = @_;

  return [] if !$name;

  my $choice = $self->choice($name);

  return [] if !$choice;

  my $argument = $choice->{argument};

  return $self->argument_errors($argument);
}

sub choice_help {
  my ($self, $name) = @_;

  return '' if !$name;

  my $choice = $self->choice($name);

  return '' if !$choice;

  my $help = $choice->{help};

  return $help;
}

sub choice_label {
  my ($self, $name) = @_;

  return '' if !$name;

  my $choice = $self->choice($name);

  return '' if !$choice;

  my $label = $choice->{label};

  return $label;
}

sub choice_list {
  my ($self) = @_;

  my $output = [];

  my $choices = $self->choices;

  $output = [map $choices->{$_}, $self->choice_names];

  return wantarray ? @{$output} : $output;
}

sub choice_multiples {
  my ($self, $name) = @_;

  return false if !$name;

  my $choice = $self->choice($name);

  return false if !$choice;

  my $argument = $choice->{argument};

  return $self->argument_multiples($argument);
}

sub choice_name {
  my ($self, $name) = @_;

  return '' if !$name;

  my $choice = $self->choice($name);

  return '' if !$choice;

  $name = $choice->{name};

  return $name;
}

sub choice_names {
  my ($self) = @_;

  my $choices = $self->choices;

  my @names = sort {
    (exists $choices->{$a}->{index} ? $choices->{$a}->{index} : $a)
      <=> (exists $choices->{$b}->{index} ? $choices->{$b}->{index} : $b)
  } keys %{$choices};

  return wantarray ? (@names) : [@names];
}

sub choice_prompt {
  my ($self, $name) = @_;

  return '' if !$name;

  my $choice = $self->choice($name);

  return '' if !$choice;

  my $argument = $choice->{argument};

  return $self->argument_prompt($argument);
}

sub choice_range {
  my ($self, $name) = @_;

  return '' if !$name;

  my $choice = $self->choice($name);

  return '' if !$choice;

  my $argument = $choice->{argument};

  return $self->argument_range($argument);
}

sub choice_required {
  my ($self, $name) = @_;

  return false if !$name;

  my $choice = $self->choice($name);

  return false if !$choice;

  my $argument = $choice->{argument};

  return $self->argument_required($argument);
}

sub choice_type {
  my ($self, $name) = @_;

  return '' if !$name;

  my $choice = $self->choice($name);

  return '' if !$choice;

  my $argument = $choice->{argument};

  return $self->argument_type($argument);
}

sub choice_validate {
  my ($self, $name) = @_;

  return [] if !$name;

  my $choice = $self->choice($name);

  return [] if !$choice;

  my $argument = $choice->{argument};

  return $self->argument_validate($argument);
}

sub choice_value {
  my ($self, $name) = @_;

  return undef if !$name;

  my $choice = $self->choice($name);

  return undef if !$choice;

  my $argument = $choice->{argument};

  return $self->argument_value($argument);
}

sub choice_wants {
  my ($self, $name) = @_;

  return '' if !$name;

  my $choice = $self->choice($name);

  return '' if !$choice;

  my $argument = $choice->{argument};

  return $self->argument_wants($argument);
}

sub command {
  my ($self, $argument_name, $choice_name, $handler) = @_;

  return undef if !$argument_name;
  return undef if !$choice_name;
  return undef if !$handler;

  require Venus;

  my $choice_parts = ref $choice_name eq 'ARRAY'
    ? $choice_name
    : [split /\s+/, $choice_name];

  my $route_name = join ' ', @{$choice_parts};

  my $range = ':' . ($#{$choice_parts});

  $self->argument($argument_name, {range => $range, multiples => $#{$choice_parts} > 0 ? 1 : 0})
    if !$self->argument($argument_name);

  $self->choice($route_name, {argument => $argument_name})
    if !$self->choice($route_name);

  $self->route($route_name, {
    argument => $argument_name,
    choice => $route_name,
    handler => $handler,
    range => $range,
  });

  return $self->route($route_name);
}

sub dispatch {
  my ($self, @args) = @_;

  $self->parse(@args) if @args;

  my $parsed_arguments = $self->parsed_arguments;

  return undef if !$parsed_arguments || !@{$parsed_arguments};

  my $matched_route = undef;
  my $matched_length = -1;

  for my $route ($self->route_list) {
    my $choice = $route->{choice};

    next if !$choice;

    my @choice_parts = split /\s+/, $choice;
    my $choice_length = scalar @choice_parts;

    next if $choice_length > scalar @{$parsed_arguments};

    my $matches = 1;

    for my $i (0..$#choice_parts) {
      if ($parsed_arguments->[$i] ne $choice_parts[$i]) {
        $matches = 0;
        last;
      }
    }

    if ($matches && $choice_length > $matched_length) {
      $matched_route = $route;
      $matched_length = $choice_length;
    }
  }

  return undef if !$matched_route;

  my $handler = $matched_route->{handler};

  return undef if !$handler;

  if (ref $handler ) {
    if (ref $handler eq 'CODE') {
      return $handler->($self, $self->assigned_arguments, $self->assigned_options);
    }
    else {
      return undef;
    }
  }

  require Venus::Space;

  my $space = Venus::Space->new($handler);

  if ($handler !~ /\W/ && $self->can($handler)) {
    return $self->$handler($self->assigned_arguments, $self->assigned_options);
  }

  if ($space->lookslike_a_package && $space->tryload) {
    my $remaining_args = [@{$parsed_arguments}[$matched_length..$#{$parsed_arguments}]];

    my $remaining_data = [grep {$_ ne '--'} @{$self->data}];

    splice @{$remaining_data}, 0, $matched_length
      if @{$remaining_data} >= $matched_length;

    my $instance = $space->package->new;

    if ($instance->isa('Venus::Task')) {
      return $instance->handle(@{$remaining_data});
    }
    elsif ($instance->isa('Venus::Cli')) {
      return $instance->dispatch(@{$remaining_data});
    }
    else {
      return $instance;
    }
  }

  return undef;
}

sub exit {
  my ($self, $code, $method, @args) = @_;

  $self->$method(@args) if $method;

  $code ||= 0;

  _exit($code);
}

sub fail {
  my ($self, $method, @args) = @_;

  return $self->exit(1, $method, @args);
}

sub float {
  my ($self, $next, @args) = @_;

  my $data = {type => 'float'};

  $data = {%{pop(@args)}, %{$data}} if ref $args[$#args] eq 'HASH';

  return $data if !$next;

  return $self->$next(undef, $data) if !@args;

  push @args, $data;

  return $self->$next(@args);
}

sub has_input {
  my ($self) = @_;

  return !$self->no_input ? true : false;
}

sub has_input_arguments {
  my ($self) = @_;

  return !$self->no_input_arguments ? true : false;
}

sub has_input_options {
  my ($self) = @_;

  return !$self->no_input_options ? true : false;
}

sub has_output {
  my ($self) = @_;

  return !$self->no_output ? true : false;
}

sub has_output_debug_events {
  my ($self) = @_;

  return !$self->no_output_debug_events ? true : false;
}

sub has_output_error_events {
  my ($self) = @_;

  return !$self->no_output_error_events ? true : false;
}

sub has_output_fatal_events {
  my ($self) = @_;

  return !$self->no_output_fatal_events ? true : false;
}

sub has_output_info_events {
  my ($self) = @_;

  return !$self->no_output_info_events ? true : false;
}

sub has_output_trace_events {
  my ($self) = @_;

  return !$self->no_output_trace_events ? true : false;
}

sub has_output_warn_events {
  my ($self) = @_;

  return !$self->no_output_warn_events ? true : false;
}

sub help {
  my ($self) = @_;

  $self->log_info($self->usage);

  return $self;
}

sub input {
  my ($self) = @_;

  my ($arguments, $options) = ({}, {});

  for my $name ($self->argument_names) {
    $arguments->{$self->arguments->{$name}->{name}} = $self->argument_value($name);
  }

  for my $name ($self->option_names) {
    $options->{$self->options->{$name}->{name}} = $self->option_value($name);
  }

  return wantarray ? ($arguments, $options) : $arguments;
}

sub input_arguments {
  my ($self) = @_;

  return $self->{input_arguments} if $self->{input_arguments} && keys %{$self->{input_arguments}};

  my ($arguments, $options) = $self->input;

  return $self->{input_arguments} = $arguments;
}

sub input_arguments_defined {
  my ($self) = @_;

  my $arguments = $self->input_arguments;

  %{$arguments} = (
    map +(
        ref $arguments->{$_} eq 'ARRAY'
      ? !@{$arguments->{$_}}
          ? ()
          : ($_, $arguments->{$_})
      : ($_, $arguments->{$_})
    ),
    grep defined $arguments->{$_},
    keys %{$arguments},
  );

  return $arguments;
}

sub input_arguments_defined_count {
  my ($self) = @_;

  my $arguments = $self->input_arguments_defined;

  return 0 + (keys %{$arguments});
}

sub input_arguments_defined_list {
  my ($self) = @_;

  my $arguments = $self->input_arguments_defined;

  my $keys = [keys %{$arguments}];

  return wantarray ? (@{$keys}) : $keys;
}

sub input_argument_count {
  my ($self) = @_;

  my $arguments = $self->input_arguments;

  return 0 + (keys %{$arguments});
}

sub input_argument_list {
  my ($self) = @_;

  my $arguments = $self->input_arguments;

  my $keys = [keys %{$arguments}];

  return wantarray ? (@{$keys}) : $keys;
}

sub input_options {
  my ($self) = @_;

  return $self->{input_options} if $self->{input_options} && keys %{$self->{input_options}};

  my ($arguments, $options) = $self->input;

  return $self->{input_options} ||= $options;
}

sub input_options_defined {
  my ($self) = @_;

  my $options = $self->input_options;

  %{$options} = (
    map +(
        ref $options->{$_} eq 'ARRAY'
      ? !@{$options->{$_}}
          ? ()
          : ($_, $options->{$_})
      : ($_, $options->{$_})
    ),
    grep defined $options->{$_},
    keys %{$options},
  );

  return $options;
}

sub input_options_defined_count {
  my ($self) = @_;

  my $options = $self->input_options_defined;

  return 0 + (keys %{$options});
}

sub input_options_defined_list {
  my ($self) = @_;

  my $options = $self->input_options_defined;

  my $keys = [keys %{$options}];

  return wantarray ? (@{$keys}) : $keys;
}

sub input_option_count {
  my ($self) = @_;

  my $options = $self->input_options;

  return 0 + (keys %{$options});
}

sub input_option_list {
  my ($self) = @_;

  my $options = $self->input_options;

  my $keys = [keys %{$options}];

  return wantarray ? (@{$keys}) : $keys;
}

sub lines {
  my ($self, $text, $length, $indent) = @_;

  require Venus::String;

  my $string = Venus::String->new($text);

  return scalar $string->wrap($length, $indent);
}

sub log {
  my ($self) = @_;

  require Venus::Log;

  my $log = Venus::Log->new(handler => $self->log_handler, level => $self->log_level);

  return $log;
}

sub log_debug {
  my ($self, @args) = @_;

  my $log = $self->log;

  return $log->debug(@args);
}

sub log_error {
  my ($self, @args) = @_;

  my $log = $self->log;

  return $log->error(@args);
}

sub log_events {
  my ($self) = @_;

  my $logs = $self->{logs} ||= [];

  return $logs;
}

sub log_fatal {
  my ($self, @args) = @_;

  my $log = $self->log;

  return $log->fatal(@args);
}

sub log_flush {
  my ($self, $code) = @_;

  for my $event (@{$self->log_events}) {
    local $_ = $event;

    $self->$code($event) if $code;
  }

  @{$self->log_events} = ();

  return $self;
}

sub log_handler {
  my ($self, @args) = @_;

  my $log_events = $self->log_events;

  my $handler = sub {
    push @{$log_events}, [@_];
  };

  return $handler;
}

sub log_info {
  my ($self, @args) = @_;

  my $log = $self->log;

  return $log->info(@args);
}

sub log_level {

  return 'trace';
}

sub log_trace {
  my ($self, @args) = @_;

  my $log = $self->log;

  return $log->trace(@args);
}

sub log_warn {
  my ($self, @args) = @_;

  my $log = $self->log;

  return $log->warn(@args);
}

sub multiple {
  my ($self, $next, @args) = @_;

  my $data = {multiples => true};

  $data = {%{pop(@args)}, %{$data}} if ref $args[$#args] eq 'HASH';

  return $data if !$next;

  return $self->$next(undef, $data) if !@args;

  push @args, $data;

  return $self->$next(@args);
}

sub no_input {
  my ($self) = @_;

  my @data = $self->parsed;

  return (keys %{$data[0]}) || (@{$data[1]}) ? false : true;
}

sub no_input_arguments {
  my ($self) = @_;

  my @data = $self->parsed;

  return @{$data[1]} ? false : true;
}

sub no_input_options {
  my ($self) = @_;

  my @data = $self->parsed;

  return keys %{$data[0]} ? false : true;
}

sub no_output {
  my ($self) = @_;

  my @data = $self->output;

  return @data ? false : true;
}

sub no_output_debug_events {
  my ($self) = @_;

  my @data = $self->output('debug');

  return @data ? false : true;
}

sub no_output_error_events {
  my ($self) = @_;

  my @data = $self->output('error');

  return @data ? false : true;
}

sub no_output_fatal_events {
  my ($self) = @_;

  my @data = $self->output('fatal');

  return @data ? false : true;
}

sub no_output_info_events {
  my ($self) = @_;

  my @data = $self->output('info');

  return @data ? false : true;
}

sub no_output_trace_events {
  my ($self) = @_;

  my @data = $self->output('trace');

  return @data ? false : true;
}

sub no_output_warn_events {
  my ($self) = @_;

  my @data = $self->output('warn');

  return @data ? false : true;
}

sub number {
  my ($self, $next, @args) = @_;

  my $data = {type => 'number'};

  $data = {%{pop(@args)}, %{$data}} if ref $args[$#args] eq 'HASH';

  return $data if !$next;

  return $self->$next(undef, $data) if !@args;

  push @args, $data;

  return $self->$next(@args);
}

sub okay {
  my ($self, $method, @args) = @_;

  return $self->exit(0, $method, @args);
}

sub option {
  my ($self, $name, @data) = @_;

  return undef if !$name;

  return $self->options->{$name} if !@data;

  return delete $self->options->{$name} if !defined $data[0];

  my $defaults = {
    name => $name,
    label => undef,
    help => undef,
    default => undef,
    aliases => undef,
    multiples => 0,
    prompt => undef,
    range => undef,
    required => false,
    type => 'string',
    index => int(keys(%{$self->options})),
    wants => undef,
  };

  require Venus;

  my $overrides = Venus::merge_take({}, @data);

  $overrides->{aliases} //= [Venus::list($overrides->{alias})] if exists $overrides->{alias};

  $overrides->{wants} //= $overrides->{type} || 'string' if !exists $overrides->{wants};

  my $data = Venus::merge_take($self->options->{$name} || $defaults, $overrides);

  $data->{aliases} = [$data->{aliases} // ()] if !ref $data->{aliases};

  $data->{help} ||= "Expects a $data->{type} value";

  return $self->options->{$data->{name} ? $data->{name} : $name} = $data;
}

sub option_aliases {
  my ($self, $name) = @_;

  return [] if !$name;

  my $option = $self->option($name);

  return [] if !$option;

  my $aliases = $option->{aliases};

  return $aliases;
}

sub option_count {
  my ($self) = @_;

  return int(scalar(keys(%{$self->options})));
}

sub option_default {
  my ($self, $name) = @_;

  return '' if !$name;

  my $option = $self->option($name);

  return '' if !$option;

  my $default = $option->{default};

  return $default;
}

sub option_errors {
  my ($self, $name) = @_;

  return [] if !$name;

  my $result = $self->option_validate($name);

  $result = [$result] if ref $result ne 'ARRAY';

  $result = [grep defined, map $_->issue, @{$result}];

  return wantarray ? (@{$result}) : $result;
}

sub option_help {
  my ($self, $name) = @_;

  return '' if !$name;

  my $option = $self->option($name);

  return '' if !$option;

  my $help = $option->{help};

  return $help;
}

sub option_label {
  my ($self, $name) = @_;

  return '' if !$name;

  my $option = $self->option($name);

  return '' if !$option;

  my $label = $option->{label};

  return $label;
}

sub option_list {
  my ($self) = @_;

  my $output = [];

  my $options = $self->options;

  $output = [map $options->{$_}, $self->option_names];

  return wantarray ? @{$output} : $output;
}

sub option_multiples {
  my ($self, $name) = @_;

  return false if !$name;

  my $option = $self->option($name);

  return false if !$option;

  my $multiples = $option->{multiples};

  return $multiples ? true : false;
}

sub option_name {
  my ($self, $name) = @_;

  return '' if !$name;

  my $option = $self->option($name);

  return '' if !$option;

  $name = $option->{name};

  return $name;
}

sub option_names {
  my ($self) = @_;

  my $options = $self->options;

  my @names = sort {
    (exists $options->{$a}->{index} ? $options->{$a}->{index} : $a)
      <=> (exists $options->{$b}->{index} ? $options->{$b}->{index} : $b)
  } keys %{$options};

  return wantarray ? (@names) : [@names];
}

sub option_prompt {
  my ($self, $name) = @_;

  return '' if !$name;

  my $option = $self->option($name);

  return '' if !$option;

  my $prompt = $option->{prompt};

  return $prompt;
}

sub option_range {
  my ($self, $name) = @_;

  return '' if !$name;

  my $option = $self->option($name);

  return '' if !$option;

  my $range = $option->{range};

  return $range;
}

sub option_required {
  my ($self, $name) = @_;

  return false if !$name;

  my $option = $self->option($name);

  return false if !$option;

  my $required = $option->{required};

  return $required ? true : false;
}

sub option_type {
  my ($self, $name) = @_;

  return '' if !$name;

  my $option = $self->option($name);

  return '' if !$option;

  my $type = $option->{type};

  return $type;
}

sub option_validate {
  my ($self, $name) = @_;

  return [] if !$name;

  my $option = $self->option($name);

  return [] if !$option;

  require Venus::Validate;

  my $validate = Venus::Validate->new(input => [$self->option_value($name)]);

  my $required = $option->{required} ? 'required' : 'optional';

  my $value = $validate->each($required);

  my $type = 'string';

  $type = 'boolean' if $option->{type} eq 'boolean';
  $type = 'float' if $option->{type} eq 'float';
  $type = 'number' if $option->{type} eq 'number';
  $type = 'any' if $option->{type} eq 'string';
  $type = 'yesno' if $option->{type} eq 'yesno';

  for my $value (@{$value}) {
    next if $required eq 'optional' && !defined $value->input->[0];
    $value->type($type);
  }

  my $multiples = $option->{multiples};

  return $multiples ? (wantarray ? (@{$value}) : $value) : $value->[0];
}

sub option_value {
  my ($self, $name) = @_;

  return undef if !$name;

  my $option = $self->option($name);

  return undef if !$option;

  my $parsed_options = $self->parsed_options;

  my $default = $option->{default};

  my $value = exists $parsed_options->{$name}
    ? ref $parsed_options->{$name} eq 'ARRAY'
      ? $parsed_options->{$name}
      : [$parsed_options->{$name} // ()]
    : $default ? ref $default eq 'ARRAY' ? $default
      : [$default // ()]
    : [$self->option_value_prompt($name) // ()];

  my $type = 'string';

  $type = 'boolean' if $option->{type} eq 'boolean';
  $type = 'float' if $option->{type} eq 'float';
  $type = 'number' if $option->{type} eq 'number';
  $type = 'string' if $option->{type} eq 'string';
  $type = 'yesno' if $option->{type} eq 'yesno';

  require Scalar::Util;

  if ($type eq 'number') {
    @{$value} = map +(Scalar::Util::looks_like_number($_) ? (0+$_) : $_), @{$value};
  }

  if ($type eq 'boolean') {
    @{$value} = map +(Scalar::Util::looks_like_number($_) ? !!$_ ? true : false
      : $_ =~ /true/i ? true : false), @{$value};
  }

  my $multiples = $option->{multiples};

  return $multiples ? (wantarray ? (@{$value}) : $value) : $value->[0];
}

sub option_value_prompt {
  my ($self, $name) = @_;

  return undef if !$name;

  my $option = $self->option($name);

  return undef if !$option;

  my $prompt = $option->{prompt};

  return undef if !$prompt;

  _print($prompt);

  my $captured = _prompt;

  return $captured eq '' ? undef : $captured;
}

sub option_wants {
  my ($self, $name) = @_;

  return '' if !$name;

  my $option = $self->option($name);

  return '' if !$option;

  my $wants = $option->{wants};

  return $wants;
}

sub optional {
  my ($self, $next, @args) = @_;

  my $data = {required => false};

  $data = {%{pop(@args)}, %{$data}} if ref $args[$#args] eq 'HASH';

  return $data if !$next;

  return $self->$next(undef, $data) if !@args;

  push @args, $data;

  return $self->$next(@args);
}

sub opts {
  my ($self) = @_;

  my $parsed_options = $self->parsed_options;

  $self->parse if !$parsed_options || !keys %{$parsed_options};

  $parsed_options = $self->parsed_options;

  require Venus::Opts;

  return Venus::Opts->new(value => [], parsed => $parsed_options);
}

sub output {
  my ($self, $level) = @_;

  my $output = [];

  my $log_events = $self->log_events;

  push @{$output}, map {$$_[1]} ($level ? (grep {$$_[0] eq $level} @{$log_events}) : (@{$log_events}));

  return wantarray ? (@{$output}) : (@{$output})[-1];
}

sub output_debug_events {
  my ($self) = @_;

  my $output = [$self->output('debug')];

  return wantarray ? (@{$output}) : $output;
}

sub output_error_events {
  my ($self) = @_;

  my $output = [$self->output('error')];

  return wantarray ? (@{$output}) : $output;
}

sub output_fatal_events {
  my ($self) = @_;

  my $output = [$self->output('fatal')];

  return wantarray ? (@{$output}) : $output;
}

sub output_info_events {
  my ($self) = @_;

  my $output = [$self->output('info')];

  return wantarray ? (@{$output}) : $output;
}

sub output_trace_events {
  my ($self) = @_;

  my $output = [$self->output('trace')];

  return wantarray ? (@{$output}) : $output;
}

sub output_warn_events {
  my ($self) = @_;

  my $output = [$self->output('warn')];

  return wantarray ? (@{$output}) : $output;
}

sub parse {
  my ($self, @args) = @_;

  require Venus;
  require Getopt::Long;
  require Text::ParseWords;

  my $data = [@args ? @args : @ARGV];

  $self->data($data);

  my $arguments = [map $_, @{$data}];

  Getopt::Long::Configure(qw(default bundling no_auto_abbrev no_ignore_case));

  local $SIG{__WARN__} = sub {};

  my $options = {};

  my $returned = Getopt::Long::GetOptionsFromArray($arguments, $options, $self->parse_specification);

  $self->parsed_arguments($arguments);
  $self->parsed_options($options);

  return $self;
}

sub parse_specification {
  my ($self) = @_;

  my $spec = [];

  for my $option ($self->option_list) {
    my $spec_string = $option->{name};

    if ($option->{aliases}) {
      $spec_string = join '|', $spec_string, @{$option->{aliases}};
    }

    my $type
      = $option->{type} eq 'boolean' ? ''
      : $option->{type} eq 'float' ? 'f'
      : $option->{type} eq 'number' ? 'i'
      : $option->{type} eq 'yesno' ? 's'
      : $option->{type} eq 'string' ? 's'
      : '';

    $spec_string .= $type ? "=$type" : '';

    $spec_string .= $option->{multiples} ? '@' : '';

    push @{$spec}, $spec_string;
  }

  return wantarray ? (@{$spec}) : $spec;
}

sub parsed {
  my ($self) = @_;

  return wantarray ? ($self->parsed_options, $self->parsed_arguments) : $self->parsed_options;
}

sub parsed_arguments {
  my ($self, @args) = @_;

  $self->{parsed_arguments} = $args[0] if @args;

  $self->parse if !$self->{parsed_arguments};

  return $self->{parsed_arguments};
}

sub parsed_options {
  my ($self, @args) = @_;

  $self->{parsed_options} = $args[0] if @args;

  $self->parse if !$self->{parsed_options};

  return $self->{parsed_options};
}

sub pass {
  my ($self, $method, @args) = @_;

  return $self->exit(0, $method, @args);
}

sub reorder {
  my ($self) = @_;

  $self->reorder_arguments;
  $self->reorder_choices;
  $self->reorder_options;
  $self->reorder_routes;

  return $self;
}

sub reorder_arguments {
  my ($self) = @_;

  my $arguments = $self->arguments;

  my $index = 0;

  $self->argument($_, {%{$arguments->{$_}}, index => $index++}) for $self->argument_names;

  return $self;
}

sub reorder_choices {
  my ($self) = @_;

  my $choices = $self->choices;

  my $index = 0;

  $self->choice($_, {%{$choices->{$_}}, index => $index++}) for $self->choice_names;

  return $self;
}

sub reorder_options {
  my ($self) = @_;

  my $options = $self->options;

  my $index = 0;

  $self->option($_, {%{$options->{$_}}, index => $index++}) for $self->option_names;

  return $self;
}

sub reorder_routes {
  my ($self) = @_;

  my $routes = $self->routes;

  my $index = 0;

  $self->route($_, {%{$routes->{$_}}, index => $index++}) for $self->route_names;

  return $self;
}

sub route {
  my ($self, $name, @data) = @_;

  return undef if !$name;

  return $self->routes->{$name} if !@data;

  return delete $self->routes->{$name} if !defined $data[0];

  my $defaults = {
    name => $name,
    label => undef,
    help => undef,
    argument => undef,
    choice => undef,
    handler => undef,
    range => undef,
    index => int(keys(%{$self->routes})),
  };

  require Venus;

  my $overrides = Venus::merge_take({}, @data);

  my $data = Venus::merge_take($self->routes->{$name} || $defaults, $overrides);

  return $self->routes->{$name} = $data;
}

sub route_argument {
  my ($self, $name) = @_;

  return '' if !$name;

  my $route = $self->route($name);

  return '' if !$route;

  my $argument = $route->{argument};

  return $self->argument($argument);
}

sub route_choice {
  my ($self, $name) = @_;

  return '' if !$name;

  my $route = $self->route($name);

  return '' if !$route;

  my $choice = $route->{choice};

  return $self->choice($choice);
}

sub route_count {
  my ($self) = @_;

  return int(scalar(keys(%{$self->routes})));
}

sub route_handler {
  my ($self, $name) = @_;

  return undef if !$name;

  my $route = $self->route($name);

  return undef if !$route;

  my $handler = $route->{handler};

  return $handler;
}

sub route_help {
  my ($self, $name) = @_;

  return '' if !$name;

  my $route = $self->route($name);

  return '' if !$route;

  my $help = $route->{help};

  return $help;
}

sub route_label {
  my ($self, $name) = @_;

  return '' if !$name;

  my $route = $self->route($name);

  return '' if !$route;

  my $label = $route->{label};

  return $label;
}

sub route_list {
  my ($self) = @_;

  my $output = [];

  my $routes = $self->routes;

  $output = [map $routes->{$_}, $self->route_names];

  return wantarray ? @{$output} : $output;
}

sub route_name {
  my ($self, $name) = @_;

  return '' if !$name;

  my $route = $self->route($name);

  return '' if !$route;

  $name = $route->{name};

  return $name;
}

sub route_names {
  my ($self) = @_;

  my $routes = $self->routes;

  my @names = sort {
    (exists $routes->{$a}->{index} ? $routes->{$a}->{index} : $a)
      <=> (exists $routes->{$b}->{index} ? $routes->{$b}->{index} : $b)
  } keys %{$routes};

  return wantarray ? (@names) : [@names];
}

sub route_range {
  my ($self, $name) = @_;

  return '' if !$name;

  my $route = $self->route($name);

  return '' if !$route;

  my $range = $route->{range};

  return $range;
}

sub required {
  my ($self, $next, @args) = @_;

  my $data = {required => true};

  $data = {%{pop(@args)}, %{$data}} if ref $args[$#args] eq 'HASH';

  return $data if !$next;

  return $self->$next(undef, $data) if !@args;

  push @args, $data;

  return $self->$next(@args);
}

sub reset {
  my ($self) = @_;

  $self->data([]);
  $self->arguments({});
  $self->options({});
  $self->choices({});
  $self->routes({});
  $self->parsed_arguments([]);
  $self->parsed_options({});

  $self->{logs} = [];

  delete $self->{input_arguments};
  delete $self->{input_options};

  return $self;
}

sub single {
  my ($self, $next, @args) = @_;

  my $data = {multiples => false};

  $data = {%{pop(@args)}, %{$data}} if ref $args[$#args] eq 'HASH';

  return $data if !$next;

  return $self->$next(undef, $data) if !@args;

  push @args, $data;

  return $self->$next(@args);
}

sub spec {
  my ($self, $data) = @_;

  return $self if !$data || ref $data ne 'HASH';

  $self->name($data->{name}) if exists $data->{name};
  $self->version($data->{version}) if exists $data->{version};
  $self->summary($data->{summary}) if exists $data->{summary};
  $self->description($data->{description}) if exists $data->{description};
  $self->header($data->{header}) if exists $data->{header};
  $self->footer($data->{footer}) if exists $data->{footer};

  if ($data->{arguments} && ref $data->{arguments} eq 'ARRAY') {
    for my $item (@{$data->{arguments}}) {
      next if !$item || ref $item ne 'HASH';
      my $name = $item->{name};
      next if !$name;
      $self->argument($name, $item);
    }
  }

  if ($data->{options} && ref $data->{options} eq 'ARRAY') {
    for my $item (@{$data->{options}}) {
      next if !$item || ref $item ne 'HASH';
      my $name = $item->{name};
      next if !$name;
      $self->option($name, $item);
    }
  }

  if ($data->{choices} && ref $data->{choices} eq 'ARRAY') {
    for my $item (@{$data->{choices}}) {
      next if !$item || ref $item ne 'HASH';
      my $name = $item->{name};
      next if !$name;
      $self->choice($name, $item);
    }
  }

  if ($data->{routes} && ref $data->{routes} eq 'ARRAY') {
    for my $item (@{$data->{routes}}) {
      next if !$item || ref $item ne 'HASH';
      my $name = $item->{name};
      next if !$name;
      $self->route($name, $item);
    }
  }

  if ($data->{commands} && ref $data->{commands} eq 'ARRAY') {
    for my $item (@{$data->{commands}}) {
      next if !$item || ref $item ne 'ARRAY';
      my @parts = @{$item};
      next if @parts < 3;
      my $argument = shift @parts;
      my $handler = pop @parts;
      my $choice = [map {split /\s+/} map {ref $_ ? @{$_} : $_} @parts];
      $self->command($argument, $choice, $handler);
    }
  }

  $self->reorder;

  return $self;
}

sub string {
  my ($self, $next, @args) = @_;

  my $data = {type => 'string'};

  $data = {%{pop(@args)}, %{$data}} if ref $args[$#args] eq 'HASH';

  return $data if !$next;

  return $self->$next(undef, $data) if !@args;

  push @args, $data;

  return $self->$next(@args);
}

sub usage {
  my ($self) = @_;

  my @value;

  my @output;

  @value = grep length, $self->usage_gist;

  push @output, join " ", @value if @value;

  @value = grep length, $self->usage_line;

  push @output, join " ", @value if @value;

  @value = grep length, $self->usage_description;

  push @output, $self->lines(join " ", @value) if @value;

  @value = grep length, $self->usage_header;

  push @output, $self->lines(join " ", @value) if @value;

  @value = grep length, $self->usage_arguments;

  push @output, join " ", @value if @value;

  @value = grep length, $self->usage_options;

  push @output, join " ", @value if @value;

  @value = grep length, $self->usage_choices;

  push @output, join " ", @value if @value;

  @value = grep length, $self->usage_footer;

  push @output, $self->lines(join " ", @value) if @value;

  return join "\n\n", @output;
}

sub usage_argument_default {
  my ($self, $name) = @_;

  my $output = '';

  my $default = $self->argument_default($name);

  return $output if !defined $default || !length $default;

  $output = 'Default: ' . join ', ',
    ref $default ? @{$default} : $default;

  return $output;
}

sub usage_argument_help {
  my ($self, $name) = @_;

  my $output = '';

  my $help = $self->argument_help($name);

  return $output if !$help;

  return $help;
}

sub usage_argument_label {
  my ($self, $name) = @_;

  my $output = '';

  my $arg = $self->argument($name);

  return $output if !$arg;

  return $arg->{label} if $arg->{label};

  if ($arg->{required}) {
    if ($arg->{multiples}) {
      $output = "<$arg->{name}> ...";
    }
    else {
      $output = "<$arg->{name}>";
    }
  }
  else {
    if ($arg->{multiples}) {
      $output = "[<$arg->{name}> ...]";
    }
    else {
      $output = "[<$arg->{name}>]";
    }
  }

  return $output;
}

sub usage_argument_required {
  my ($self, $name) = @_;

  my $required = $self->argument_required($name);

  return $required ? '(required)' : '(optional)';
}

sub usage_argument_token {
  my ($self, $name) = @_;

  my $output = '';

  my $arg = $self->argument($name);

  return $output if !$arg;

  if ($arg->{required}) {
    if ($arg->{multiples}) {
      $output = "<$arg->{name}> ...";
    }
    else {
      $output = "<$arg->{name}>";
    }
  }
  else {
    if ($arg->{multiples}) {
      $output = "[<$arg->{name}> ...]";
    }
    else {
      $output = "[<$arg->{name}>]";
    }
  }

  return $output;
}

sub usage_arguments {
  my ($self) = @_;

  my @value;

  if ($self->argument_count > 0) {
    push @value, "Arguments:";
    for my $name ($self->argument_names) {
      push @value, grep length,
        $self->lines($self->usage_argument_label($name), 80, 2);
      push @value, grep length,
        $self->lines($self->usage_argument_help($name), 80, 4);
      push @value, grep length,
        $self->lines($self->usage_argument_required($name), 80, 4);
      push @value, grep length,
        $self->lines($self->usage_argument_default($name), 80, 4);
    }
  }

  return join "\n", @value;
}

sub usage_choice_help {
  my ($self, $name) = @_;

  return $self->choice_help($name);
}

sub usage_choice_label {
  my ($self, $name) = @_;

  my $cmd = $self->choice($name);

  return '' if !$cmd;

  return $cmd->{label} || $cmd->{name} || '';
}

sub usage_choice_required {
  my ($self, $name) = @_;

  my $output = '';

  my $cmd = $self->choice($name);

  return $output if !$cmd;

  return $self->usage_argument_label($cmd->{argument});
}

sub usage_choices {
  my ($self) = @_;

  my @value;

  if ($self->choice_count > 0) {
    my %cmd_groups;
    for my $name ($self->choice_names) {
      push @{$cmd_groups{$self->choice($name)->{argument}}}, $name;
    }
    for my $group (grep $cmd_groups{$_}, $self->argument_names) {
      my @group = "Choices for " . ($self->usage_argument_label($group)) . ":";
      for my $name (@{$cmd_groups{$group}}) {
        push @group, grep length,
          $self->lines($self->usage_choice_label($name), 80, 2);
        push @group, grep length,
          $self->lines($self->usage_choice_help($name), 80, 4);
        push @group, grep length,
          $self->lines($self->usage_choice_required($name), 80, 4);
      }
      push @value, join "\n", @group;
    }
  }

  return join "\n\n", @value;
}

sub usage_description {
  my ($self) = @_;

  my $description = $self->description // '';

  return $description;
}

sub usage_footer {
  my ($self) = @_;

  my $footer = $self->footer // '';

  return $footer;
}

sub usage_gist {
  my ($self) = @_;

  my $name = $self->usage_name;

  my $version = $self->usage_version;

  my $summary = $self->usage_summary;

  return '' if !$name;

  return "$name - $summary" if $summary && !$version;

  return "$name version $version" if !$summary && $version;

  return "$name version $version - $summary" if $summary && $version;

  return '';
}

sub usage_header {
  my ($self) = @_;

  my $header = $self->header // '';

  return $header;
}

sub usage_line {
  my ($self) = @_;

  my @lines;

  my $width = 80;

  my @name = $self->usage_name;

  return '' if !@name;

  my $line = my $usage = join ' ', 'Usage:', @name;

  my $indent = length($usage) + 1;

  for my $name ($self->argument_names) {
    my $part = $self->usage_argument_token($name);
    if (length($line) + length($part) + 1 > $width) {
      push @lines, $line;
      $line = (" " x $indent) . $part;
    }
    else {
      $line .= " $part";
    }
  }

  for my $name ($self->option_names) {
    my $part = $self->usage_option_token($name);
    if (length($line) + length($part) + 1 > $width) {
      push @lines, $line;
      $line = (" " x $indent) . $part;
    }
    else {
      $line .= " $part";
    }
  }

  return join "\n", @lines, $line;
}

sub usage_name {
  my ($self) = @_;

  my $name = $self->name // '';

  return $name;
}

sub usage_option_default {
  my ($self, $name) = @_;

  my $output = '';

  my $default = $self->option_default($name);

  return $output if !defined $default || !length $default;

  $output = 'Default: ' . join ', ',
    ref $default ? @{$default} : $default;

  return $output;
}

sub usage_option_help {
  my ($self, $name) = @_;

  return $self->option_help($name);
}

sub usage_option_label {
  my ($self, $name) = @_;

  my $output = '';

  my $opt = $self->option($name);

  return $output if !$opt;

  return $opt->{label} if $opt->{label};

  $output = join ', ', map length($_) > 1 ? "--$_" : "-$_", grep length,
    ref $opt->{aliases} ? @{$opt->{aliases}} : $opt->{aliases};

  if ($opt->{required}) {
    if ($opt->{multiples}) {
      if ($opt->{wants} && ($opt->{wants} ne 'boolean')) {
        $output = join ', ', ($output ? $output : ()), "--$opt->{name}=<$opt->{wants}> ...";
      }
      else {
        $output = join ', ', ($output ? $output : ()), "--$opt->{name} ...";
      }
    }
    else {
      if ($opt->{wants} && ($opt->{wants} ne 'boolean')) {
        $output = join ', ', ($output ? $output : ()), "--$opt->{name}=<$opt->{wants}>";
      }
      else {
        $output = join ', ', ($output ? $output : ()), "--$opt->{name}";
      }
    }
  }
  else {
    if ($opt->{multiples}) {
      if ($opt->{wants} && ($opt->{wants} ne 'boolean')) {
        $output = sprintf '[%s]',
          join ', ', ($output ? $output : ()), "--$opt->{name}=<$opt->{wants}> ...";
      }
      else {
        $output = sprintf '[%s]',
          join ', ', ($output ? $output : ()), "--$opt->{name} ...";
      }
    }
    else {
      if ($opt->{wants} && ($opt->{wants} ne 'boolean')) {
        $output = sprintf '[%s]',
          join ', ', ($output ? $output : ()), "--$opt->{name}=<$opt->{wants}>";
      }
      else {
        $output = sprintf '[%s]',
          join ', ', ($output ? $output : ()), "--$opt->{name}";
      }
    }
  }

  return $output;
}

sub usage_option_required {
  my ($self, $name) = @_;

  my $required = $self->option_required($name);

  return $required ? '(required)' : '(optional)';
}

sub usage_option_token {
  my ($self, $name) = @_;

  my $output = '';

  my $opt = $self->option($name);

  return $output if !$opt;

  if ($opt->{required}) {
    if ($opt->{multiples}) {
      $output = "--$opt->{name} ...";
    }
    else {
      $output = "--$opt->{name}";
    }
  }
  else {
    if ($opt->{multiples}) {
      $output = "[--$opt->{name} ...]";
    }
    else {
      $output = "[--$opt->{name}]";
    }
  }

  return $output;
}

sub usage_options {
  my ($self) = @_;

  my @value;

  if ($self->option_count > 0) {
    push @value, "Options:";
    for my $name ($self->option_names) {
      push @value, grep length,
        $self->lines($self->usage_option_label($name), 80, 2);
      push @value, grep length,
        $self->lines($self->usage_option_help($name), 80, 4);
      push @value, grep length,
        $self->lines($self->usage_option_required($name), 80, 4);
      push @value, grep length,
        $self->lines($self->usage_option_default($name), 80, 4);
    }
  }

  return join "\n", @value;
}

sub usage_summary {
  my ($self) = @_;

  my $summary = $self->summary;

  return $summary;
}

sub usage_version {
  my ($self) = @_;

  my $version = $self->version;

  return $version;
}

sub vars {
  my ($self) = @_;

  require Venus::Vars;

  return Venus::Vars->new;
}

sub yesno {
  my ($self, $next, @args) = @_;

  my $data = {type => 'yesno'};

  $data = {%{pop(@args)}, %{$data}} if ref $args[$#args] eq 'HASH';

  return $data if !$next;

  return $self->$next(undef, $data) if !@args;

  push @args, $data;

  return $self->$next(@args);
}

1;



=head1 NAME

Venus::Cli - Cli Class

=cut

=head1 ABSTRACT

Cli Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  # $cli->usage;

  # ...

  # $cli->parsed;

  # {help => 1}

=cut

=head1 DESCRIPTION

This package provides a superclass and methods for creating simple yet robust
command-line interfaces.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 name

  name(string $name) (string)

The name attribute is read-write, accepts C<(string)> values, and is optional.

I<Since C<4.15>>

=over 4

=item name example 1

  # given: synopsis

  package main;

  my $name = $cli->name("mycli");

  # "mycli"

=back

=over 4

=item name example 2

  # given: synopsis

  # given: example-1 name

  package main;

  $name = $cli->name;

  # "mycli"

=back

=cut

=head2 version

  version(string $version) (string)

The version attribute is read-write, accepts C<(string)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item version example 1

  # given: synopsis

  package main;

  my $version = $cli->version("0.0.1");

  # "0.0.1"

=back

=over 4

=item version example 2

  # given: synopsis

  # given: example-1 version

  package main;

  $version = $cli->version;

  # "0.0.1"

=back

=cut

=head2 summary

  summary(string $summary) (string)

The summary attribute is read-write, accepts C<(string)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item summary example 1

  # given: synopsis

  package main;

  my $summary = $cli->summary("Example summary");

  # "Example summary"

=back

=over 4

=item summary example 2

  # given: synopsis

  # given: example-1 summary

  package main;

  $summary = $cli->summary;

  # "Example summary"

=back

=cut

=head2 description

  description(string $description) (string)

The description attribute is read-write, accepts C<(string)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item description example 1

  # given: synopsis

  package main;

  my $description = $cli->description("Example description");

  # "Example description"

=back

=over 4

=item description example 2

  # given: synopsis

  # given: example-1 description

  package main;

  $description = $cli->description;

  # "Example description"

=back

=cut

=head2 header

  header(string $header) (string)

The header attribute is read-write, accepts C<(string)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item header example 1

  # given: synopsis

  package main;

  my $header = $cli->header("Example header");

  # "Example header"

=back

=over 4

=item header example 2

  # given: synopsis

  # given: example-1 header

  package main;

  $header = $cli->header;

  # "Example header"

=back

=cut

=head2 footer

  footer(string $footer) (string)

The footer attribute is read-write, accepts C<(string)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item footer example 1

  # given: synopsis

  package main;

  my $footer = $cli->footer("Example footer");

  # "Example footer"

=back

=over 4

=item footer example 2

  # given: synopsis

  # given: example-1 footer

  package main;

  $footer = $cli->footer;

  # "Example footer"

=back

=cut

=head2 arguments

  arguments(hashref $arguments) (hashref)

The arguments attribute is read-write, accepts C<(hashref)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item arguments example 1

  # given: synopsis

  package main;

  my $arguments = $cli->arguments({});

  # {}

=back

=over 4

=item arguments example 2

  # given: synopsis

  # given: example-1 arguments

  package main;

  $arguments = $cli->arguments;

  # {}

=back

=cut

=head2 options

  options(hashref $options) (hashref)

The options attribute is read-write, accepts C<(hashref)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item options example 1

  # given: synopsis

  package main;

  my $options = $cli->options({});

  # {}

=back

=over 4

=item options example 2

  # given: synopsis

  # given: example-1 options

  package main;

  $options = $cli->options;

  # {}

=back

=cut

=head2 choices

  choices(hashref $choices) (hashref)

The choices attribute is read-write, accepts C<(hashref)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item choices example 1

  # given: synopsis

  package main;

  my $choices = $cli->choices({});

  # {}

=back

=over 4

=item choices example 2

  # given: synopsis

  # given: example-1 choices

  package main;

  $choices = $cli->choices;

  # {}

=back

=cut

=head2 data

  data(hashref $data) (hashref)

The data attribute is read-write, accepts C<(hashref)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item data example 1

  # given: synopsis

  package main;

  my $data = $cli->data({});

  # {}

=back

=over 4

=item data example 2

  # given: synopsis

  # given: example-1 data

  package main;

  $data = $cli->data;

  # {}

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Printable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 args

  args() (Venus::Args)

The args method returns the list of parsed command-line arguments as a
L<Venus::Args> object.

I<Since C<4.15>>

=over 4

=item args example 1

  # given: synopsis

  package main;

  my $args = $cli->args;

  # bless(..., "Venus::Args")

=back

=over 4

=item args example 2

  # given: synopsis

  package main;

  $cli->parse('hello', 'world');

  my $args = $cli->args;

  # bless(..., "Venus::Args")

  # $args->get(0);

  # $args->get(1);

=back

=cut

=head2 argument

  argument(string $name, hashref $data) (maybe[hashref])

The argument method registers and returns the configuration for the argument
specified. The method takes a name (argument name) and a hashref of
configuration values. The possible configuration values are as follows:

=over 4

=item *

The C<name> key holds the name of the argument.

=item *

The C<label> key holds the name of the argument as it should be displayed in
the CLI help text.

=item *

The C<help> key holds the help text specific to this argument.

=item *

The C<default> key holds the default value that should used if no value for
this argument is provided to the CLI.

=item *

The C<multiples> key denotes whether this argument can be used more than once,
to collect multiple values, and holds a C<1> if multiples are allowed and a C<0>
otherwise.

=item *

The C<prompt> key holds the question or statement that should be presented to
the user of the CLI if no value has been provided for this argument and no
default value has been set.

=item *

The C<range> key holds a two-value arrayref where the first value is the
starting index and the second value is the ending index. These values are used
to select values from the parsed arguments array as the value(s) for this
argument. This value is ignored if the C<multiples> key is set to C<0>.

=item *

The C<required> key denotes whether this argument is required or not, and holds
a C<1> if required and a C<0> otherwise.

=item *

The C<type> key holds the data type of the argument expected. Valid values are
"number", "string", "float", "boolean", or "yesno". B<Note:> Valid boolean
values are C<1>, C<0>, C<"true">, and C<"false">.

=back

I<Since C<4.15>>

=over 4

=item argument example 1

  # given: synopsis

  package main;

  my $argument = $cli->argument('name', {
    label => 'Name',
    help => 'The name of the user',
    default => 'Unknown',
    required => 1,
    type => 'string'
  });

  # {
  #   name => 'name',
  #   label => 'Name',
  #   help => 'The name of the user',
  #   default => 'Unknown',
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=back

=cut

=head2 argument_choice

  argument_choice(string $name) (arrayref)

The argument_choice method returns the parsed argument value only if it
corresponds to a registered choice associated with the named argument. If the
value (or any of the values) doesn't map to a choice, this method will return
an empty arrayref. Returns a list in list context.

I<Since C<4.15>>

=over 4

=item argument_choice example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_choice = $cli->argument_choice;

  # []

=back

=over 4

=item argument_choice example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'string',
  });

  $cli->parse('stdin');

  my $argument_choice = $cli->argument_choice('input');

  # []

=back

=over 4

=item argument_choice example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->choice('stdout', {
    argument => 'input',
  });

  $cli->parse('stdin');

  my $argument_choice = $cli->argument_choice('input');

  # ['stdin']

=back

=over 4

=item argument_choice example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->choice('stdout', {
    argument => 'input',
  });

  $cli->parse('stdin', 'stdout');

  my $argument_choice = $cli->argument_choice('input');

  # ['stdin', 'stdout']

=back

=cut

=head2 argument_choices

  argument_choices(string $name) (arrayref)

The argument_choices method returns all registered choices associated with
the argument named. Returns a list in list context.

I<Since C<4.15>>

=over 4

=item argument_choices example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_choices = $cli->argument_choices;

  # []

=back

=over 4

=item argument_choices example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  my $argument_choices = $cli->argument_choices('input');

  # []

=back

=over 4

=item argument_choices example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $argument_choices = $cli->argument_choices('input');

  # [{
  #   name => 'stdin',
  #   label => undef,
  #   help => 'Expects a string value',
  #   argument => 'input',
  #   index => 0,
  #   wants => 'string',
  # }]

=back

=cut

=head2 argument_count

  argument_count() (number)

The argument_count method returns the count of registered arguments.

I<Since C<4.15>>

=over 4

=item argument_count example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_count = $cli->argument_count;

  # 0

=back

=over 4

=item argument_count example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->argument('output', {
    type => 'string',
  });

  my $argument_count = $cli->argument_count;

  # 2

=back

=cut

=head2 argument_default

  argument_default(string $name) (string)

The argument_default method returns the C<default> configuration value for the
named argument.

I<Since C<4.15>>

=over 4

=item argument_default example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_default = $cli->argument_default;

  # ""

=back

=over 4

=item argument_default example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    default => 'stdin',
  });

  my $argument_default = $cli->argument_default('input');

  # "stdin"

=back

=cut

=head2 argument_errors

  argument_errors(string $name) (within[arrayref, Venus::Validate])

The argument_errors method returns a list of L<"issues"|Venus::Validate/issue>,
if any, for each value returned by L</argument_value> for the named argument.
Returns a list in list context.

I<Since C<4.15>>

=over 4

=item argument_errors example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_errors = $cli->argument_errors;

  # []

=back

=over 4

=item argument_errors example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'string',
  });

  $cli->parse('hello');

  my $argument_errors = $cli->argument_errors('input');

  # []

=back

=over 4

=item argument_errors example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'number',
  });

  $cli->parse('hello');

  my $argument_errors = $cli->argument_errors('input');

  # [['type', ['number']]]

=back

=cut

=head2 argument_help

  argument_help(string $name) (string)

The argument_help method returns the C<help> configuration value for the named
argument.

I<Since C<4.15>>

=over 4

=item argument_help example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_help = $cli->argument_help;

  # ""

=back

=over 4

=item argument_help example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    help => 'Example help text',
  });

  my $argument_help = $cli->argument_help('input');

  # "Example help text"

=back

=cut

=head2 argument_label

  argument_label(string $name) (string)

The argument_label method returns the C<label> configuration value for the
named argument.

I<Since C<4.15>>

=over 4

=item argument_label example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_label = $cli->argument_label;

  # ""

=back

=over 4

=item argument_label example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    label => 'Input',
  });

  my $argument_label = $cli->argument_label('input');

  # "Input"

=back

=cut

=head2 argument_list

  argument_list(string $name) (within[arrayref, hashref])

The argument_list method returns a list of registered argument configurations.
Returns a list in list context.

I<Since C<4.15>>

=over 4

=item argument_list example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_list = $cli->argument_list;

  # []

=back

=over 4

=item argument_list example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  my $argument_list = $cli->argument_list;

  # [{
  #   name => 'input',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => false,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }]

=back

=cut

=head2 argument_multiples

  argument_multiples(string $name) (boolean)

The argument_multiples method returns the C<multiples> configuration value for
the named argument.

I<Since C<4.15>>

=over 4

=item argument_multiples example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_multiples = $cli->argument_multiples;

  # false

=back

=over 4

=item argument_multiples example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
  });

  my $argument_multiples = $cli->argument_multiples('input');

  # true

=back

=cut

=head2 argument_name

  argument_name(string $name) (string)

The argument_name method returns the C<name> configuration value for the named
argument.

I<Since C<4.15>>

=over 4

=item argument_name example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_name = $cli->argument_name;

  # ""

=back

=over 4

=item argument_name example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    name => 'INPUT',
  });

  my $argument_name = $cli->argument_name('input');

  # ""

=back

=over 4

=item argument_name example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    name => 'INPUT',
  });

  my $argument_name = $cli->argument_name('INPUT');

  # "INPUT"

=back

=cut

=head2 argument_names

  argument_names(string $name) (within[arrayref, string])

The argument_names method returns the names (keys) of registered arguments in
the order declared. Returns a list in list context.

I<Since C<4.15>>

=over 4

=item argument_names example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_names = $cli->argument_names;

  # []

=back

=over 4

=item argument_names example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->argument('output', {
    type => 'string',
  });

  my $argument_names = $cli->argument_names;

  # ['input', 'output']

=back

=over 4

=item argument_names example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('output', {
    type => 'string',
  });

  $cli->argument('input', {
    type => 'string',
  });

  my $argument_names = $cli->argument_names;

  # ['output', 'input']

=back

=cut

=head2 argument_prompt

  argument_prompt(string $name) (string)

The argument_prompt method returns the C<prompt> configuration value for the
named argument.

I<Since C<4.15>>

=over 4

=item argument_prompt example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_prompt = $cli->argument_prompt;

  # ""

=back

=over 4

=item argument_prompt example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    prompt => 'Example prompt',
  });

  my $argument_prompt = $cli->argument_prompt('input');

  # "Example prompt"

=back

=cut

=head2 argument_range

  argument_range(string $name) (string)

The argument_range method returns the C<range> configuration value for the
named argument.

I<Since C<4.15>>

=over 4

=item argument_range example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_range = $cli->argument_range;

  # ""

=back

=over 4

=item argument_range example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
  });

  my $argument_range = $cli->argument_range('input');

  # "0"

=back

=over 4

=item argument_range example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0:5',
  });

  my $argument_range = $cli->argument_range('input');

  # "0:5"

=back

=cut

=head2 argument_required

  argument_required(string $name) (boolean)

The argument_required method returns the C<required> configuration value for
the named argument.

I<Since C<4.15>>

=over 4

=item argument_required example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_required = $cli->argument_required;

  # false

=back

=over 4

=item argument_required example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
  });

  my $argument_required = $cli->argument_required('input');

  # true

=back

=cut

=head2 argument_type

  argument_type(string $name) (string)

The argument_type method returns the C<type> configuration value for the named
argument. Valid values are as follows:

=over 4

=item *

C<number>

=item *

C<string>

=item *

C<float>

=item *

C<boolean> - B<Note:> Valid boolean values are C<1>, C<0>, C<"true">, and C<"false">.

=item *

C<yesno>

=back

I<Since C<4.15>>

=over 4

=item argument_type example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_type = $cli->argument_type;

  # ""

=back

=over 4

=item argument_type example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'boolean',
  });

  my $argument_type = $cli->argument_type('input');

  # "boolean"

=back

=cut

=head2 argument_validate

  argument_validate(string $name) (Venus::Validate | within[arrayref, Venus::Validate])

The argument_validate method returns a L<Venus::Validate> object for each value
returned by L</argument_value> for the named argument. Returns a list in list
context.

I<Since C<4.15>>

=over 4

=item argument_validate example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_validate = $cli->argument_validate;

  # []

=back

=over 4

=item argument_validate example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0',
    type => 'string',
  });

  my $argument_validate = $cli->argument_validate('input');

  # [bless(..., "Venus::Validate")]

=back

=over 4

=item argument_validate example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => false,
    range => '0',
    type => 'string',
  });

  my $argument_validate = $cli->argument_validate('input');

  # bless(..., "Venus::Validate")

=back

=over 4

=item argument_validate example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->parse('hello', 'world');

  my $argument_validate = $cli->argument_validate('input');

  # [bless(..., "Venus::Validate"), bless(..., "Venus::Validate")]

=back

=cut

=head2 argument_value

  argument_value(string $name) (any)

The argument_value method returns the parsed argument value for the named
argument.

I<Since C<4.15>>

=over 4

=item argument_value example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_value = $cli->argument_value;

  # undef

=back

=over 4

=item argument_value example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => false,
    range => '0:',
    type => 'string',
  });

  $cli->parse('hello', 'world');

  my $argument_value = $cli->argument_value('input');

  # "hello"

=back

=over 4

=item argument_value example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->parse('hello', 'world');

  my $argument_value = $cli->argument_value('input');

  # ["hello", "world"]

=back

=cut

=head2 argument_wants

  argument_wants(string $name) (string)

The argument_wants method returns the C<wants> configuration value for the
named argument.

I<Since C<4.15>>

=over 4

=item argument_wants example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_wants = $cli->argument_wants;

  # ""

=back

=over 4

=item argument_wants example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    wants => 'string',
  });

  my $argument_wants = $cli->argument_wants('input');

  # "string"

=back

=cut

=head2 assigned_arguments

  assigned_arguments() (hashref)

The assigned_arguments method gets the values for the registered arguments.

I<Since C<4.15>>

=over 4

=item assigned_arguments example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $assigned_arguments = $cli->assigned_arguments;

  # {extra => 'hello'}

=back

=over 4

=item assigned_arguments example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $assigned_arguments = $cli->assigned_arguments;

  # {extra => ['hello', 'world']}

=back

=cut

=head2 assigned_options

  assigned_options() (hashref)

The assigned_options method gets the values for the registered options.

I<Since C<4.15>>

=over 4

=item assigned_options example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $assigned_options = $cli->assigned_options;

  # {input => 'stdin', output => 'stdout'}

=back

=over 4

=item assigned_options example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    type => 'string',
  });

  $cli->option('output', {
    multiples => true,
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $assigned_options = $cli->assigned_options;

  # {input => ['stdin'], output => ['stdout']}

=back

=cut

=head2 boolean

  boolean(string $method, any @args) (any)

The boolean method is a configuration dispatcher and shorthand for C<{'type',
'boolean'}>. It returns the data or dispatches to the next configuration
dispatcher based on the name provided and merges the configurations produced.

I<Since C<4.15>>

=over 4

=item boolean example 1

  # given: synopsis

  package main;

  my $boolean = $cli->boolean;

  # {type => 'boolean'}

=back

=over 4

=item boolean example 2

  # given: synopsis

  package main;

  my $boolean = $cli->boolean(undef, {required => true});

  # {type => 'boolean', required => true}

=back

=over 4

=item boolean example 3

  # given: synopsis

  package main;

  my $boolean = $cli->boolean('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a boolean value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'boolean',
  #   index => 0,
  #   wants => 'boolean',
  # }

=back

=cut

=head2 choice

  choice(string $name, hashref $data) (maybe[hashref])

The choice method registers and returns the configuration for the choice
specified. The method takes a name (choice name) and a hashref of
configuration values. The possible configuration values are as follows:

=over 4

=item *

The C<name> key holds the name of the argument.

=item *

The C<label> key holds the name of the argument as it should be displayed in
the CLI help text.

=item *

The C<help> key holds the help text specific to this argument.

=item *

The C<argument> key holds the name  of the argument that this choice is a
value for.

=item *

The C<wants> key holdd the text to be used as a value placeholder in the CLI
help text.

=back

I<Since C<4.15>>

=over 4

=item choice example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'string',
  });

  my $choice = $cli->choice('stdin', {
    argument => 'input',
  });

  # {
  #   name => 'stdin',
  #   label => undef,
  #   help => undef,
  #   argument => 'input',
  #   index => 0,
  #   wants => 'string',
  # }

=back

=cut

=head2 choice_argument

  choice_argument(string $name) (hashref)

The choice_argument method returns the argument configuration corresponding
with the C<argument> value of the named choice.

I<Since C<4.15>>

=over 4

=item choice_argument example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_argument = $cli->choice_argument('stdin');

  # {
  #   name => 'input',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 0,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=back

=cut

=head2 choice_count

  choice_count() (number)

The choice_count method returns the count of registered choices.

I<Since C<4.15>>

=over 4

=item choice_count example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_count = $cli->choice_count;

  # 0

=back

=over 4

=item choice_count example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0:',
    type => 'string',
  });

  $cli->choice('file', {
    argument => 'input',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_count = $cli->choice_count;

  # 2

=back

=cut

=head2 choice_default

  choice_default(string $name) (string)

The choice_default method returns the C<default> configuration value for the
argument corresponding to the named choice.

I<Since C<4.15>>

=over 4

=item choice_default example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    default => 'file',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_default = $cli->choice_default('stdin');

  # "file"

=back

=cut

=head2 choice_errors

  choice_errors(string $name) (within[arrayref, Venus::Validate])

The choice_errors method returns a list of L<"issues"|Venus::Validate/issue>,
if any, for each value returned by L</choice_value> for the named choice.
Returns a list in list context.

I<Since C<4.15>>

=over 4

=item choice_errors example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_errors = $cli->choice_errors;

  # []

=back

=over 4

=item choice_errors example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->parse('hello');

  my $choice_errors = $cli->choice_errors('stdin');

  # []

=back

=over 4

=item choice_errors example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'number',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->parse('hello');

  my $choice_errors = $cli->choice_errors('stdin');

  # [['type', ['number']]]

=back

=cut

=head2 choice_help

  choice_help(string $name) (string)

The choice_help method returns the C<help> configuration value the named
choice.

I<Since C<4.15>>

=over 4

=item choice_help example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_help = $cli->choice_help;

  # ""

=back

=over 4

=item choice_help example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
    help => 'Example help',
  });

  my $choice_help = $cli->choice_help('stdin');

  # "Example help"

=back

=cut

=head2 choice_label

  choice_label(string $name) (string)

The choice_label method returns the C<label> configuration value for the named
choice.

I<Since C<4.15>>

=over 4

=item choice_label example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_label = $cli->choice_label;

  # ""

=back

=over 4

=item choice_label example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
    label => 'Standard input',
  });

  my $choice_label = $cli->choice_label('stdin');

  # "Standard input"

=back

=cut

=head2 choice_list

  choice_list(string $name) (within[arrayref, hashref])

The choice_list method returns a list of registered choice configurations.
Returns a list in list context.

I<Since C<4.15>>

=over 4

=item choice_list example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_list = $cli->choice_list;

  # []

=back

=over 4

=item choice_list example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_list = $cli->choice_list;

  # [{
  #   name => 'stdin',
  #   label => undef,
  #   help => 'Expects a string value',
  #   argument => 'input',
  #   index => 0,
  #   wants => 'string',
  # }]

=back

=cut

=head2 choice_multiples

  choice_multiples(string $name) (boolean)

The choice_multiples method returns the C<multiples> configuration value for
the argument corresponding to the named choice.

I<Since C<4.15>>

=over 4

=item choice_multiples example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_multiples = $cli->choice_multiples;

  # false

=back

=over 4

=item choice_multiples example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_multiples = $cli->choice_multiples('stdin');

  # true

=back

=cut

=head2 choice_name

  choice_name(string $name) (string)

The choice_name method returns the C<name> configuration value for the named
choice.

I<Since C<4.15>>

=over 4

=item choice_name example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_name = $cli->choice_name;

  # ""

=back

=over 4

=item choice_name example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    name => 'STDIN',
    argument => 'input',
  });

  my $choice_name = $cli->choice_name('stdin');

  # "STDIN"

=back

=cut

=head2 choice_names

  choice_names(string $name) (within[arrayref, string])

The choice_names method returns the names (keys) of registered choices in
the order declared. Returns a list in list context.

I<Since C<4.15>>

=over 4

=item choice_names example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_names = $cli->choice_names;

  # []

=back

=over 4

=item choice_names example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('file', {
    argument => 'input',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_names = $cli->choice_names;

  # ['file', 'stdin']

=back

=over 4

=item choice_names example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->choice('file', {
    argument => 'input',
  });

  my $choice_names = $cli->choice_names;

  # ['stdin', 'file']

=back

=cut

=head2 choice_prompt

  choice_prompt(string $name) (string)

The choice_prompt method returns the C<prompt> configuration value for the
argument corresponding to the named choice.

I<Since C<4.15>>

=over 4

=item choice_prompt example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_prompt = $cli->choice_prompt;

  # ""

=back

=over 4

=item choice_prompt example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    prompt => 'Example prompt',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_prompt = $cli->choice_prompt('stdin');

  # "Example prompt"

=back

=cut

=head2 choice_range

  choice_range(string $name) (string)

The choice_range method returns the C<range> configuration value for the
argument corresponding to the named choice.

I<Since C<4.15>>

=over 4

=item choice_range example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_range = $cli->choice_range;

  # ""

=back

=over 4

=item choice_range example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0:',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_range = $cli->choice_range('stdin');

  # "0:"

=back

=cut

=head2 choice_required

  choice_required(string $name) (boolean)

The choice_required method returns the C<required> configuration value for the
argument corresponding to the named choice.

I<Since C<4.15>>

=over 4

=item choice_required example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_required = $cli->choice_required;

  # false

=back

=over 4

=item choice_required example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_required = $cli->choice_required('stdin');

  # true

=back

=cut

=head2 choice_type

  choice_type(string $name) (string)

The choice_type method returns the C<type> configuration value for the
argument corresponding to the named choice.

I<Since C<4.15>>

=over 4

=item choice_type example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_type = $cli->choice_type;

  # ""

=back

=over 4

=item choice_type example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_type = $cli->choice_type('stdin');

  # "string"

=back

=cut

=head2 choice_validate

  choice_validate(string $name) (within[arrayref, Venus::Validate])

The choice_validate method returns a L<Venus::Validate> object for each value
returned by L</choice_value> for the named choice. Returns a list in list
context.

I<Since C<4.15>>

=over 4

=item choice_validate example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_validate = $cli->choice_validate;

  # []

=back

=over 4

=item choice_validate example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_validate = $cli->choice_validate('stdin');

  # [bless(..., "Venus::Validate")]

=back

=over 4

=item choice_validate example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => false,
    range => '0',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_validate = $cli->choice_validate('stdin');

  # bless(..., "Venus::Validate")

=back

=over 4

=item choice_validate example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->parse('hello', 'world');

  my $choice_validate = $cli->choice_validate('stdin');

  # [bless(..., "Venus::Validate"), bless(..., "Venus::Validate")]

=back

=cut

=head2 choice_value

  choice_value(string $name) (any)

The choice_value method returns the parsed choice value for the named
choice.

I<Since C<4.15>>

=over 4

=item choice_value example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_value = $cli->choice_value;

  # undef

=back

=over 4

=item choice_value example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => false,
    range => '0:',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->parse('hello', 'world');

  my $choice_value = $cli->choice_value('stdin');

  # "hello"

=back

=over 4

=item choice_value example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->parse('hello', 'world');

  my $choice_value = $cli->choice_value('stdin');

  # ["hello", "world"]

=back

=cut

=head2 choice_wants

  choice_wants(string $name) (string)

The choice_wants method returns the C<wants> configuration value for the
argument corresponding to the named choice.

I<Since C<4.15>>

=over 4

=item choice_wants example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_wants = $cli->choice_wants;

  # ""

=back

=over 4

=item choice_wants example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    wants => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_wants = $cli->choice_wants('stdin');

  # "string"

=back

=cut

=head2 command

  command(string $argument, string | arrayref $choice, string | coderef $handler) (maybe[hashref])

The command method creates and associates an argument, choice, and route. It
takes an argument name, a choice name (string or arrayref of parts), and a
handler (method name or coderef). The method returns the route configuration
for the command.

I<Since C<4.15>>

=over 4

=item command example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $command = $cli->command('command', ['user', 'create'], 'handle_user_create');

  # {
  #   name => 'user create',
  #   label => undef,
  #   help => undef,
  #   argument => 'command',
  #   choice => 'user create',
  #   handler => 'handle_user_create',
  #   range => ':1',
  #   index => 0,
  # }

=back

=over 4

=item command example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $command = $cli->command('command', 'user create', 'handle_user_create');

  # {
  #   name => 'user create',
  #   label => undef,
  #   help => undef,
  #   argument => 'command',
  #   choice => 'user create',
  #   handler => 'handle_user_create',
  #   range => ':1',
  #   index => 0,
  # }

=back

=over 4

=item command example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $command = $cli->command('command', ['user'], 'handle_user');

  # {
  #   name => 'user',
  #   label => undef,
  #   help => undef,
  #   argument => 'command',
  #   choice => 'user',
  #   handler => 'handle_user',
  #   range => ':0',
  #   index => 0,
  # }

=back

=over 4

=item command example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['user', 'create'], 'handle_user_create');
  $cli->command('command', ['user', 'delete'], 'handle_user_delete');

  my $argument = $cli->argument('command');

  # {
  #   name => 'command',
  #   ...
  #   range => ':1',
  # }

=back

=cut

=head2 dispatch

  dispatch(any @args) (any)

The dispatch method parses CLI arguments, matches them against registered
routes, and invokes the appropriate handler. If the handler is a coderef, it is
called with the CLI instance, L</assigned_arguments>, and L</assigned_options>.
If the handler is a local method name, it is called with </assigned_arguments>,
and L</assigned_options>. If the handler is a package name, the package is
loaded and instantiated. If the package is a L<Venus::Task>, its
L<Venus::Task/handle> method is called. If the package is a L<Venus::Cli>, its
L</dispatch> method is called. When dispatching to a package, only the relevant
portion of the command line arguments (after the matched command) is passed.

I<Since C<4.15>>

=over 4

=item dispatch example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $dispatch = $cli->dispatch;

  # undef

=back

=over 4

=item dispatch example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['user', 'create'], 'handle_user_create');

  my $dispatch = $cli->dispatch('user', 'create');

  # undef (no handler method exists)

=back

=over 4

=item dispatch example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $handler_called = 0;
  my $handler_args;

  $cli->command('command', ['user', 'create'], sub {
    my ($self, $args, $opts) = @_;
    $handler_called = 1;
    $handler_args = [$args, $opts];
    return 'handler result';
  });

  my $dispatch = $cli->dispatch('user', 'create');

  # "handler result"

=back

=over 4

=item dispatch example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['user', 'create'], sub {'user_create'});
  $cli->command('command', ['user', 'delete'], sub {'user_delete'});
  $cli->command('command', ['user'], sub {'user'});

  my $dispatch = $cli->dispatch('user', 'create');

  # "user_create"

=back

=over 4

=item dispatch example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['user', 'create'], sub {'user_create'});
  $cli->command('command', ['user', 'delete'], sub {'user_delete'});
  $cli->command('command', ['user'], sub {'user'});

  my $dispatch = $cli->dispatch('user');

  # "user"

=back

=over 4

=item dispatch example 6

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['user', 'create'], sub {'user_create'});
  $cli->command('command', ['user', 'delete'], sub {'user_delete'});
  $cli->command('command', ['user'], sub {'user'});

  my $dispatch = $cli->dispatch('user', 'delete');

  # "user_delete"

=back

=over 4

=item dispatch example 7

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('verbose', {
    type => 'boolean',
    alias => 'v',
  });

  $cli->command('command', ['user', 'create'], sub {
    my ($self, $args, $opts) = @_;
    return $opts->{verbose} ? 'verbose' : 'quiet';
  });

  my $dispatch = $cli->dispatch('user', 'create', '--verbose');

  # "verbose"

=back

=over 4

=item dispatch example 8

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['unknown'], sub {'unknown'});

  my $dispatch = $cli->dispatch('other');

  # undef (no matching route)

=back

=cut

=head2 exit

  exit(number $expr, string | coderef $code, any @args) (any)

The exit method terminates the program with a specified exit code. If no exit
code is provided, it defaults to C<0>, indicating a successful exit. This
method can be used to end the program explicitly, either after a specific task
is completed or when an error occurs that requires halting execution. This
method can dispatch to another method or callback before exiting.

I<Since C<4.15>>

=over 4

=item exit example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->exit;

  # 0

=back

=over 4

=item exit example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->exit(1);

  # 1

=back

=over 4

=item exit example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->exit(5, sub{
    $cli->{dispatched} = 1;
  });

  # 5

=back

=cut

=head2 fail

  fail(string | coderef $code, any @args) (any)

The fail method terminates the program with a the exit code C<1>, indicating a
failure on exit. This method can be used to end the program explicitly, either
after a specific task is completed or when an error occurs that requires
halting execution. This method can dispatch to another method or callback
before exiting.

I<Since C<4.15>>

=over 4

=item fail example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->fail;

  # 1

=back

=over 4

=item fail example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->fail(sub{
    $cli->{dispatched} = 1;
  });

  # 1

=back

=cut

=head2 float

  float(string $method, any @args) (any)

The float method is a configuration dispatcher and shorthand for C<{'type',
'float'}>. It returns the data or dispatches to the next configuration
dispatcher based on the name provided and merges the configurations produced.

I<Since C<4.15>>

=over 4

=item float example 1

  # given: synopsis

  package main;

  my $float = $cli->float;

  # {type => 'float'}

=back

=over 4

=item float example 2

  # given: synopsis

  package main;

  my $float = $cli->float(undef, {required => true});

  # {type => 'float', required => true}

=back

=over 4

=item float example 3

  # given: synopsis

  package main;

  my $float = $cli->float('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a float value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'float',
  #   index => 0,
  #   wants => 'float',
  # }

=back

=cut

=head2 has_input

  has_input() (boolean)

The has_input method returns true if input arguments and/or options are found,
and otherwise returns false.

I<Since C<4.15>>

=over 4

=item has_input example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $has_input = $cli->has_input;

  # false

=back

=over 4

=item has_input example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin');

  my $has_input = $cli->has_input;

  # true

=back

=cut

=head2 has_input_arguments

  has_input_arguments() (boolean)

The has_input_arguments method returns true if input arguments are found, and
otherwise returns false.

I<Since C<4.15>>

=over 4

=item has_input_arguments example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $has_input_arguments = $cli->has_input_arguments;

  # false

=back

=over 4

=item has_input_arguments example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('example');

  my $has_input_arguments = $cli->has_input_arguments;

  # true

=back

=cut

=head2 has_input_options

  has_input_options() (boolean)

The has_input_options method returns true if input options are found, and
otherwise returns false.

I<Since C<4.15>>

=over 4

=item has_input_options example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $has_input_options = $cli->has_input_options;

  # false

=back

=over 4

=item has_input_options example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdout');

  my $has_input_options = $cli->has_input_options;

  # true

=back

=cut

=head2 has_output

  has_output() (boolean)

The has_output method returns true if output events are found, and otherwise
returns false.

I<Since C<4.15>>

=over 4

=item has_output example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $has_output = $cli->has_output;

  # false

=back

=over 4

=item has_output example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output = $cli->has_output;

  # true

=back

=cut

=head2 has_output_debug_events

  has_output_debug_events() (boolean)

The has_output_debug_events method returns true if debug output events are
found, and otherwise returns false.

I<Since C<4.15>>

=over 4

=item has_output_debug_events example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_debug_events = $cli->has_output_debug_events;

  # false

=back

=over 4

=item has_output_debug_events example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_debug('example output');

  my $has_output_debug_events = $cli->has_output_debug_events;

  # true

=back

=cut

=head2 has_output_error_events

  has_output_error_events() (boolean)

The has_output_error_events method returns true if error output events are
found, and otherwise returns false.

I<Since C<4.15>>

=over 4

=item has_output_error_events example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_error_events = $cli->has_output_error_events;

  # false

=back

=over 4

=item has_output_error_events example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_error('example output');

  my $has_output_error_events = $cli->has_output_error_events;

  # true

=back

=cut

=head2 has_output_fatal_events

  has_output_fatal_events() (boolean)

The has_output_fatal_events method returns true if fatal output events are
found, and otherwise returns false.

I<Since C<4.15>>

=over 4

=item has_output_fatal_events example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_fatal_events = $cli->has_output_fatal_events;

  # false

=back

=over 4

=item has_output_fatal_events example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_fatal('example output');

  my $has_output_fatal_events = $cli->has_output_fatal_events;

  # true

=back

=cut

=head2 has_output_info_events

  has_output_info_events() (boolean)

The has_output_info_events method returns true if info output events are found,
and otherwise returns false.

I<Since C<4.15>>

=over 4

=item has_output_info_events example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_info_events = $cli->has_output_info_events;

  # true

=back

=over 4

=item has_output_info_events example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_error('example output');

  my $has_output_info_events = $cli->has_output_info_events;

  # false

=back

=cut

=head2 has_output_trace_events

  has_output_trace_events() (boolean)

The has_output_trace_events method returns true if trace output events are
found, and otherwise returns false.

I<Since C<4.15>>

=over 4

=item has_output_trace_events example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_trace_events = $cli->has_output_trace_events;

  # false

=back

=over 4

=item has_output_trace_events example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_trace('example output');

  my $has_output_trace_events = $cli->has_output_trace_events;

  # true

=back

=cut

=head2 has_output_warn_events

  has_output_warn_events() (boolean)

The has_output_warn_events method returns true if warn output events are found,
and otherwise returns false.

I<Since C<4.15>>

=over 4

=item has_output_warn_events example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_warn_events = $cli->has_output_warn_events;

  # false

=back

=over 4

=item has_output_warn_events example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_warn('example output');

  my $has_output_warn_events = $cli->has_output_warn_events;

  # true

=back

=cut

=head2 help

  help() (Venus::Cli)

The help method uses L</log_info> method to output CLI usage/help text.

I<Since C<4.15>>

=over 4

=item help example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $help = $cli->help;

  # bless(..., "Venus::Cli")

=back

=cut

=head2 input

  input() (hashref)

The input method returns input arguments in scalar context, and returns
arguments and options in list context. Arguments and options are returned as
hashrefs.

I<Since C<4.15>>

=over 4

=item input example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input = $cli->input;

  # {args => undef}

=back

=over 4

=item input example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input = $cli->input;

  # {args => ['arg1', 'arg2']}

=back

=cut

=head2 input_argument_count

  input_argument_count() (number)

The input_argument_count method returns the number of arguments provided to the
CLI.

I<Since C<4.15>>

=over 4

=item input_argument_count example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_argument_count = $cli->input_argument_count;

  # 1

=back

=over 4

=item input_argument_count example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input_argument_count = $cli->input_argument_count;

  # 1

=back

=cut

=head2 input_argument_list

  input_argument_list() (arrayref)

The input_argument_list method returns the list of argument names as an
arrayref in scalar context, and as a list in list context.

I<Since C<4.15>>

=over 4

=item input_argument_list example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_argument_list = $cli->input_argument_list;

  # ['args']

=back

=over 4

=item input_argument_list example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my @input_argument_list = $cli->input_argument_list;

  # ('args')

=back

=cut

=head2 input_arguments

  input_arguments() (hashref)

The input_arguments method returns the list of argument names and values as a
hashref.

I<Since C<4.15>>

=over 4

=item input_arguments example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_arguments = $cli->input_arguments;

  # {args => []}

=back

=over 4

=item input_arguments example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input_arguments = $cli->input_arguments;

  # {args => ['arg1', 'arg2']}

=back

=cut

=head2 input_arguments_defined

  input_arguments_defined() (hashref)

The input_arguments_defined method returns the list of argument names and
values as a hashref, excluding undefined and empty arrayref values.

I<Since C<4.15>>

=over 4

=item input_arguments_defined example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_arguments_defined = $cli->input_arguments_defined;

  # {}

=back

=over 4

=item input_arguments_defined example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input_arguments_defined = $cli->input_arguments_defined;

  # {args => ['arg1', 'arg2']}

=back

=cut

=head2 input_arguments_defined_count

  input_arguments_defined_count() (number)

The input_arguments_defined_count method returns the number of arguments found
using L</input_arguments_defined>.

I<Since C<4.15>>

=over 4

=item input_arguments_defined_count example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_arguments_defined_count = $cli->input_arguments_defined_count;

  # 0

=back

=over 4

=item input_arguments_defined_count example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input_arguments_defined_count = $cli->input_arguments_defined_count;

  # 1

=back

=cut

=head2 input_arguments_defined_list

  input_arguments_defined_list() (arrayref)

The input_arguments_defined_list method returns the list of argument names
found, using L</input_arguments_defined>, as an arrayref in scalar context, and
as a list in list context.

I<Since C<4.15>>

=over 4

=item input_arguments_defined_list example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_arguments_defined_list = $cli->input_arguments_defined_list;

  # []

=back

=over 4

=item input_arguments_defined_list example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input_arguments_defined_list = $cli->input_arguments_defined_list;

  # ['args']

=back

=cut

=head2 input_option_count

  input_option_count() (number)

The input_option_count method returns the number of options provided to the
CLI.

I<Since C<4.15>>

=over 4

=item input_option_count example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_option_count = $cli->input_option_count;

  # 2

=back

=over 4

=item input_option_count example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin');

  my $input_option_count = $cli->input_option_count;

  # 2

=back

=cut

=head2 input_option_list

  input_option_list() (arrayref)

The input_option_list method returns the list of option names as an arrayref in
scalar context, and as a list in list context.

I<Since C<4.15>>

=over 4

=item input_option_list example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_option_list = $cli->input_option_list;

  # ['input', 'output']

=back

=over 4

=item input_option_list example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $input_option_list = $cli->input_option_list;

  # ['input', 'output']

=back

=cut

=head2 input_options

  input_options() (hashref)

The input_options method returns the list of option names and values as a
hashref.

I<Since C<4.15>>

=over 4

=item input_options example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_options = $cli->input_options;

  # {input => undef, output => undef}

=back

=over 4

=item input_options example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $input_options = $cli->input_options;

  # {input => undef, output => undef}

=back

=cut

=head2 input_options_defined

  input_options_defined() (hashref)

The input_options_defined method returns the list of option names and values as
a hashref, excluding undefined and empty arrayref values.

I<Since C<4.15>>

=over 4

=item input_options_defined example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_options_defined = $cli->input_options_defined;

  # {}

=back

=over 4

=item input_options_defined example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $input_options_defined = $cli->input_options_defined;

  # {input => 'stdin', output => 'stdout'}

=back

=cut

=head2 input_options_defined_count

  input_options_defined_count() (number)

The input_options_defined_count method returns the number of options found
using L</input_options_defined>.

I<Since C<4.15>>

=over 4

=item input_options_defined_count example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_options_defined_count = $cli->input_options_defined_count;

  # 0

=back

=over 4

=item input_options_defined_count example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $input_options_defined_count = $cli->input_options_defined_count;

  # 2

=back

=cut

=head2 input_options_defined_list

  input_options_defined_list() (arrayref)

The input_options_defined_list method returns the list of option names found,
using L</input_options_defined>, as an arrayref in scalar context, and as a
list in list context.

I<Since C<4.15>>

=over 4

=item input_options_defined_list example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_options_defined_list = $cli->input_options_defined_list;

  # []

=back

=over 4

=item input_options_defined_list example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $input_options_defined_list = $cli->input_options_defined_list;

  # ['input', 'output']

=back

=over 4

=item input_options_defined_list example 3

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--output', 'stdout');

  my $input_options_defined_list = $cli->input_options_defined_list;

  # ['output']

=back

=cut

=head2 lines

  lines(string $text, number $length, number $indent) (string)

The lines method takes a string of text, a maximum character length for
each line, and an optional number of spaces to use for indentation
(defaulting to C<0>). It returns the text formatted as a string where each
line wraps at the specified length and is indented with the given number
of spaces. The default lenght is C<80>.

I<Since C<4.15>>

=over 4

=item lines example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $message = join(' ',
    'This is an example of a long line of text that needs',
    'to be wrapped and formatted.'
  );

  my $string = $cli->lines($message, 40, 2);

  # "  This is an example of a long line of
  #   text that needs to be wrapped and
  #   formatted."

=back

=cut

=head2 log

  log() (Venus::Log)

The log method returns a L<Venus::Log> object passing L</log_handler> and
L</log_level> to its constructor.

I<Since C<4.15>>

=over 4

=item log example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log = $cli->log;

  # bless(..., "Venus::Log")

=back

=cut

=head2 log_debug

  log_debug(any @args) (Venus::Log)

The log_debug method dispatches to the C<debug> method on the object returned
by L</log>.

I<Since C<4.15>>

=over 4

=item log_debug example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_debug = $cli->log_debug('Example debug');

  # bless(..., "Venus::Log")

=back

=cut

=head2 log_error

  log_error(any @args) (Venus::Log)

The log_error method dispatches to the C<error> method on the object returned
by L</log>.

I<Since C<4.15>>

=over 4

=item log_error example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_error = $cli->log_error('Example error');

  # bless(..., "Venus::Log")

=back

=cut

=head2 log_events

  log_events() (arrayref)

The log_events method returns the log messages collected by the default
L</log_handler>.

I<Since C<4.15>>

=over 4

=item log_events example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->log_debug('Example debug');

  $cli->log_error('Example error');

  my $log_events = $cli->log_events;

  # [['debug', 'Example debug'], ['debug', 'Example error']]

=back

=cut

=head2 log_fatal

  log_fatal(any @args) (Venus::Log)

The log_fatal method dispatches to the C<fatal> method on the object returned
by L</log>.

I<Since C<4.15>>

=over 4

=item log_fatal example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_fatal = $cli->log_fatal('Example fatal');

  # bless(..., "Venus::Log")

=back

=cut

=head2 log_flush

  log_flush(string | coderef $code) (Venus::Cli)

The log_flush method dispatches to the method or callback provided for each
L<"log event"|/log_event>, then purges all log events.

I<Since C<4.15>>

=over 4

=item log_flush example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->log_debug('Example debug 1');

  $cli->log_debug('Example debug 2');

  my $log_flush = $cli->log_flush(sub{
    push @{$cli->{flushed} ||= []}, $_;
  });

  # bless(..., "Venus::Cli")

=back

=over 4

=item log_flush example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->log_debug('Example debug 1');

  $cli->log_debug('Example debug 2');

  my $log_flush = $cli->log_flush(sub{
    my ($self, $event) = @_;
    push @{$cli->{flushed} ||= []}, $event;
  });

  # bless(..., "Venus::Cli")

=back

=cut

=head2 log_handler

  log_handler() (coderef)

The log_handler method is passed to the L<Venus::Log> constructor in L</log>
and by default handles log events by recording them to be
L<"flushed"|/log_flush> later.

I<Since C<4.15>>

=over 4

=item log_handler example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_handler = $cli->log_handler;

  # sub{...}

=back

=cut

=head2 log_info

  log_info(any @args) (Venus::Log)

The log_info method dispatches to the C<info> method on the object returned
by L</log>.

I<Since C<4.15>>

=over 4

=item log_info example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_info = $cli->log_info('Example info');

  # bless(..., "Venus::Log")

=back

=cut

=head2 log_level

  log_level() (string)

The log_level method is passed to the L<Venus::Log> constructor in L</log> and
by default specifies a log-level of C<debug>.

I<Since C<4.15>>

=over 4

=item log_level example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_level = $cli->log_level;

  # "trace"

=back

=cut

=head2 log_trace

  log_trace(any @args) (Venus::Log)

The log_trace method dispatches to the C<trace> method on the object returned
by L</log>.

I<Since C<4.15>>

=over 4

=item log_trace example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_trace = $cli->log_trace('Example trace');

  # bless(..., "Venus::Log")

=back

=cut

=head2 log_warn

  log_warn(any @args) (Venus::Log)

The log_warn method dispatches to the C<warn> method on the object returned
by L</log>.

I<Since C<4.15>>

=over 4

=item log_warn example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_warn = $cli->log_warn('Example warn');

  # bless(..., "Venus::Log")

=back

=cut

=head2 multiple

  multiple(string $method, any @args) (any)

The multiple method is a configuration dispatcher and shorthand for
C<{'multiples', true}>. It returns the data or dispatches to the next
configuration dispatcher based on the name provided and merges the
configurations produced.

I<Since C<4.15>>

=over 4

=item multiple example 1

  # given: synopsis

  package main;

  my $multiple = $cli->multiple;

  # {multiples => true}

=back

=over 4

=item multiple example 2

  # given: synopsis

  package main;

  my $multiple = $cli->multiple(undef, {required => true});

  # {multiples => true, required => true}

=back

=over 4

=item multiple example 3

  # given: synopsis

  package main;

  my $multiple = $cli->multiple('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 1,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=back

=cut

=head2 new

  new(any @args) (Venus::Cli)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new('mycli');

  # bless(..., "Venus::Cli")

  # $cli->name;

  # "mycli"

=back

=over 4

=item new example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  # bless(..., "Venus::Cli")

  # $cli->name;

  # "mycli"

=back

=cut

=head2 no_input

  no_input() (boolean)

The no_input method returns true if no arguments or options are provided to the
CLI, and false otherwise.

I<Since C<4.15>>

=over 4

=item no_input example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $no_input = $cli->no_input;

  # true

=back

=over 4

=item no_input example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $no_input = $cli->no_input;

  # false

=back

=cut

=head2 no_input_arguments

  no_input_arguments() (boolean)

The no_input_arguments method returns true if no arguments are provided to the
CLI, and false otherwise.

I<Since C<4.15>>

=over 4

=item no_input_arguments example 1

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $no_input_arguments = $cli->no_input_arguments;

  # true

=back

=over 4

=item no_input_arguments example 2

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2', '--output', 'stdout');

  my $no_input_arguments = $cli->no_input_arguments;

  # false

=back

=cut

=head2 no_input_options

  no_input_options() (boolean)

The no_input_options method returns true if no options are provided to the CLI,
and false otherwise.

I<Since C<4.15>>

=over 4

=item no_input_options example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $no_input_options = $cli->no_input_options;

  # true

=back

=over 4

=item no_input_options example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin');

  my $no_input_options = $cli->no_input_options;

  # false

=back

=cut

=head2 no_output

  no_output() (boolean)

The no_output method returns true if no output events are found, and false
otherwise.

I<Since C<4.15>>

=over 4

=item no_output example 1

  # given: synopsis

  package main;

  my $no_output = $cli->no_output;

  # true

=back

=over 4

=item no_output example 2

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output = $cli->no_output;

  # false

=back

=cut

=head2 no_output_debug_events

  no_output_debug_events() (boolean)

The no_output_debug_events method returns true if no debug output events are
found, and false otherwise.

I<Since C<4.15>>

=over 4

=item no_output_debug_events example 1

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_debug_events = $cli->no_output_debug_events;

  # true

=back

=over 4

=item no_output_debug_events example 2

  # given: synopsis

  package main;

  $cli->log_debug('example output');

  my $no_output_debug_events = $cli->no_output_debug_events;

  # false

=back

=cut

=head2 no_output_error_events

  no_output_error_events() (boolean)

The no_output_error_events method returns true if no error output events are
found, and false otherwise.

I<Since C<4.15>>

=over 4

=item no_output_error_events example 1

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_error_events = $cli->no_output_error_events;

  # true

=back

=over 4

=item no_output_error_events example 2

  # given: synopsis

  package main;

  $cli->log_error('example output');

  my $no_output_error_events = $cli->no_output_error_events;

  # false

=back

=cut

=head2 no_output_fatal_events

  no_output_fatal_events() (boolean)

The no_output_fatal_events method returns true if no fatal output events are
found, and false otherwise.

I<Since C<4.15>>

=over 4

=item no_output_fatal_events example 1

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_fatal_events = $cli->no_output_fatal_events;

  # true

=back

=over 4

=item no_output_fatal_events example 2

  # given: synopsis

  package main;

  $cli->log_fatal('example output');

  my $no_output_fatal_events = $cli->no_output_fatal_events;

  # false

=back

=cut

=head2 no_output_info_events

  no_output_info_events() (boolean)

The no_output_info_events method returns true if no info output events are
found, and false otherwise.

I<Since C<4.15>>

=over 4

=item no_output_info_events example 1

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_info_events = $cli->no_output_info_events;

  # false

=back

=over 4

=item no_output_info_events example 2

  # given: synopsis

  package main;

  $cli->log_error('example output');

  my $no_output_info_events = $cli->no_output_info_events;

  # true

=back

=cut

=head2 no_output_trace_events

  no_output_trace_events() (boolean)

The no_output_trace_events method returns true if no trace output events are
found, and false otherwise.

I<Since C<4.15>>

=over 4

=item no_output_trace_events example 1

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_trace_events = $cli->no_output_trace_events;

  # true

=back

=over 4

=item no_output_trace_events example 2

  # given: synopsis

  package main;

  $cli->log_trace('example output');

  my $no_output_trace_events = $cli->no_output_trace_events;

  # false

=back

=cut

=head2 no_output_warn_events

  no_output_warn_events() (boolean)

The no_output_warn_events method returns true if no warn output events are
found, and false otherwise.

I<Since C<4.15>>

=over 4

=item no_output_warn_events example 1

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_warn_events = $cli->no_output_warn_events;

  # true

=back

=over 4

=item no_output_warn_events example 2

  # given: synopsis

  package main;

  $cli->log_warn('example output');

  my $no_output_warn_events = $cli->no_output_warn_events;

  # false

=back

=cut

=head2 number

  number(string $method, any @args) (any)

The number method is a configuration dispatcher and shorthand for C<{'type',
'number'}>. It returns the data or dispatches to the next configuration
dispatcher based on the name provided and merges the configurations produced.

I<Since C<4.15>>

=over 4

=item number example 1

  # given: synopsis

  package main;

  my $number = $cli->number;

  # {type => 'number'}

=back

=over 4

=item number example 2

  # given: synopsis

  package main;

  my $number = $cli->number(undef, {required => true});

  # {type => 'number', required => true}

=back

=over 4

=item number example 3

  # given: synopsis

  package main;

  my $number = $cli->number('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a number value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'number',
  #   index => 0,
  #   wants => 'number',
  # }

=back

=cut

=head2 okay

  okay(string | coderef $code, any @args) (any)

The okay method terminates the program with a the exit code C<0>,
indicating a successful exit. This method can be used to end the program
explicitly, either after a specific task is completed or when an error
occurs that requires halting execution. This method can dispatch to
another method or callback before exiting.

I<Since C<4.15>>

=over 4

=item okay example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->okay;

  # 0

=back

=over 4

=item okay example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->okay(sub{
    $cli->{dispatched} = 1;
  });

  # 0

=back

=cut

=head2 option

  option(string $name, hashref $data) (maybe[hashref])

The option method registers and returns the configuration for the option
specified. The method takes a name (option name) and a hashref of
configuration values. The possible configuration values are as follows:

=over 4

=item *

The C<name> key holds the name of the option.

=item *

The C<label> key holds the name of the option as it should be displayed in
the CLI help text.

=item *

The C<help> key holds the help text specific to this option.

=item *

The C<default> key holds the default value that should used if no value for
this option is provided to the CLI.

=item *

The C<aliases> (or C<alias>) key holds the arrayref of aliases that can be
provided to the CLI to specify a value (or values) for this option.

=item *

The C<multiples> key denotes whether this option can be used more than once,
to collect multiple values, and holds a C<1> if multiples are allowed and a C<0>
otherwise.

=item *

The C<prompt> key holds the question or statement that should be presented to
the user of the CLI if no value has been provided for this option and no
default value has been set.

=item *

The C<range> key holds a two-value arrayref where the first value is the
starting index and the second value is the ending index. These values are used
to select values from the parsed arguments array as the value(s) for this
argument. This value is ignored if the C<multiples> key is set to C<0>.

=item *

The C<required> key denotes whether this option is required or not, and holds
a C<1> if required and a C<0> otherwise.

=item *

The C<type> key holds the data type of the option expected. Valid values are
"number", "string", "float", "boolean", or "yesno". B<Note:> Valid boolean
values are C<1>, C<0>, C<"true">, and C<"false">.

=item *

The C<wants> key holds the text to be used as a value being assigned to the
option in the usage text. This value defaults to the type specified, or
C<"string">.

=back

I<Since C<4.15>>

=over 4

=item option example 1

  # given: synopsis

  package main;

  my $option = $cli->option('name', {
    label => 'Name',
    help => 'The name of the user',
    default => 'Unknown',
    required => 1,
    type => 'string'
  });

  # {
  #   name => 'name',
  #   label => 'Name',
  #   help => 'The name of the user',
  #   default => 'Unknown',
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=back

=cut

=head2 option_aliases

  option_aliases(string $name) (arrayref)

The option_aliases method returns the C<aliases> configuration value for the
named option.

I<Since C<4.15>>

=over 4

=item option_aliases example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_aliases = $cli->option_aliases;

  # []

=back

=over 4

=item option_aliases example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    alias => 'i',
    type => 'string',
  });

  my $option_aliases = $cli->option_aliases('input');

  # ['i']

=back

=over 4

=item option_aliases example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    aliases => 'i',
    type => 'string',
  });

  my $option_aliases = $cli->option_aliases('input');

  # ['i']

=back

=over 4

=item option_aliases example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    aliases => ['i'],
    type => 'string',
  });

  my $option_aliases = $cli->option_aliases('input');

  # ['i']

=back

=cut

=head2 option_count

  option_count() (number)

The option_count method returns the count of registered options.

I<Since C<4.15>>

=over 4

=item option_count example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_count = $cli->option_count;

  # 0

=back

=over 4

=item option_count example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $option_count = $cli->option_count;

  # 2

=back

=cut

=head2 option_default

  option_default(string $name) (string)

The option_default method returns the C<default> configuration value for the
named option.

I<Since C<4.15>>

=over 4

=item option_default example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_default = $cli->option_default;

  # ""

=back

=over 4

=item option_default example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    default => 'stdin',
  });

  my $option_default = $cli->option_default('input');

  # "stdin"

=back

=cut

=head2 option_errors

  option_errors(string $name) (within[arrayref, Venus::Validate])

The option_errors method returns a list of L<"issues"|Venus::Validate/issue>,
if any, for each value returned by L</option_value> for the named option.
Returns a list in list context.

I<Since C<4.15>>

=over 4

=item option_errors example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_errors = $cli->option_errors;

  # []

=back

=over 4

=item option_errors example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->parse('--input hello');

  my $option_errors = $cli->option_errors('input');

  # []

=back

=over 4

=item option_errors example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    default => 'hello',
    type => 'number',
  });

  $cli->parse('--input hello');

  my $option_errors = $cli->option_errors('input');

  # [['type', ['number']]]

=back

=cut

=head2 option_help

  option_help(string $name) (string)

The option_help method returns the C<help> configuration value for the named
option.

I<Since C<4.15>>

=over 4

=item option_help example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_help = $cli->option_help;

  # ""

=back

=over 4

=item option_help example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    help => 'Example help text',
  });

  my $option_help = $cli->option_help('input');

  # "Example help text"

=back

=cut

=head2 option_label

  option_label(string $name) (string)

The option_label method returns the C<label> configuration value for the
named option.

I<Since C<4.15>>

=over 4

=item option_label example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_label = $cli->option_label;

  # ""

=back

=over 4

=item option_label example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    label => 'Input',
  });

  my $option_label = $cli->option_label('input');

  # "Input"

=back

=cut

=head2 option_list

  option_list(string $name) (within[arrayref, hashref])

The option_list method returns a list of registered option configurations.
Returns a list in list context.

I<Since C<4.15>>

=over 4

=item option_list example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_list = $cli->option_list;

  # []

=back

=over 4

=item option_list example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  my $option_list = $cli->option_list;

  # [{
  #   name => 'input',
  #   label => undef,
  #   help => 'Expects a string value',
  #   aliases => [],
  #   default => undef,
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => false,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }]

=back

=cut

=head2 option_multiples

  option_multiples(string $name) (boolean)

The option_multiples method returns the C<multiples> configuration value for
the named option.

I<Since C<4.15>>

=over 4

=item option_multiples example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_multiples = $cli->option_multiples;

  # false

=back

=over 4

=item option_multiples example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
  });

  my $option_multiples = $cli->option_multiples('input');

  # true

=back

=cut

=head2 option_name

  option_name(string $name) (string)

The option_name method returns the C<name> configuration value for the named
option.

I<Since C<4.15>>

=over 4

=item option_name example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_name = $cli->option_name;

  # ""

=back

=over 4

=item option_name example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    name => 'INPUT',
  });

  my $option_name = $cli->option_name('input');

  # ""

=back

=over 4

=item option_name example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    name => 'INPUT',
  });

  my $option_name = $cli->option_name('INPUT');

  # "INPUT"

=back

=cut

=head2 option_names

  option_names(string $name) (within[arrayref, string])

The option_names method returns the names (keys) of registered options in
the order declared. Returns a list in list context.

I<Since C<4.15>>

=over 4

=item option_names example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_names = $cli->option_names;

  # []

=back

=over 4

=item option_names example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $option_names = $cli->option_names;

  # ['input', 'output']

=back

=over 4

=item option_names example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('output', {
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  my $option_names = $cli->option_names;

  # ['output', 'input']

=back

=cut

=head2 option_prompt

  option_prompt(string $name) (string)

The option_prompt method returns the C<prompt> configuration value for the
named option.

I<Since C<4.15>>

=over 4

=item option_prompt example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_prompt = $cli->option_prompt;

  # ""

=back

=over 4

=item option_prompt example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    prompt => 'Example prompt',
  });

  my $option_prompt = $cli->option_prompt('input');

  # "Example prompt"

=back

=cut

=head2 option_range

  option_range(string $name) (string)

The option_range method returns the C<range> configuration value for the
named option.

I<Since C<4.15>>

=over 4

=item option_range example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_range = $cli->option_range;

  # ""

=back

=over 4

=item option_range example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    range => '0',
  });

  my $option_range = $cli->option_range('input');

  # "0"

=back

=over 4

=item option_range example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    range => '0:5',
  });

  my $option_range = $cli->option_range('input');

  # "0:5"

=back

=cut

=head2 option_required

  option_required(string $name) (boolean)

The option_required method returns the C<required> configuration value for
the named option.

I<Since C<4.15>>

=over 4

=item option_required example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_required = $cli->option_required;

  # false

=back

=over 4

=item option_required example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => true,
  });

  my $option_required = $cli->option_required('input');

  # true

=back

=cut

=head2 option_type

  option_type(string $name) (string)

The option_type method returns the C<type> configuration value for the named
option. Valid values are as follows:

=over 4

=item *

C<number>

=item *

C<string>

=item *

C<float>

=item *

C<boolean> - B<Note:> Valid boolean values are C<1>, C<0>, C<"true">, and C<"false">.

=item *

C<yesno>

=back

I<Since C<4.15>>

=over 4

=item option_type example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_type = $cli->option_type;

  # ""

=back

=over 4

=item option_type example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'boolean',
  });

  my $option_type = $cli->option_type('input');

  # "boolean"

=back

=cut

=head2 option_validate

  option_validate(string $name) (Venus::Validate | within[arrayref, Venus::Validate])

The option_validate method returns a L<Venus::Validate> object for each value
returned by L</option_value> for the named option. Returns a list in list
context.

I<Since C<4.15>>

=over 4

=item option_validate example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_validate = $cli->option_validate;

  # []

=back

=over 4

=item option_validate example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    type => 'string',
  });

  my $option_validate = $cli->option_validate('input');

  # [bless(..., "Venus::Validate")]

=back

=over 4

=item option_validate example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => false,
    type => 'string',
  });

  my $option_validate = $cli->option_validate('input');

  # bless(..., "Venus::Validate")

=back

=over 4

=item option_validate example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    type => 'string',
  });

  $cli->parse('--input', 'hello', '--input', 'world');

  my $option_validate = $cli->option_validate('input');

  # [bless(..., "Venus::Validate"), bless(..., "Venus::Validate")]

=back

=cut

=head2 option_value

  option_value(string $name) (any)

The option_value method returns the parsed option value for the named
option.

I<Since C<4.15>>

=over 4

=item option_value example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_value = $cli->option_value;

  # undef

=back

=over 4

=item option_value example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => false,
    type => 'string',
  });

  $cli->parse('--input', 'hello', '--input', 'world');

  my $option_value = $cli->option_value('input');

  # "world"

=back

=over 4

=item option_value example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    type => 'string',
  });

  $cli->parse('--input', 'hello', '--input', 'world');

  my $option_value = $cli->option_value('input');

  # ["hello", "world"]

=back

=cut

=head2 option_wants

  option_wants(string $name) (string)

The option_wants method returns the C<wants> configuration value for the
named option.

I<Since C<4.15>>

=over 4

=item option_wants example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_wants = $cli->option_wants;

  # ""

=back

=over 4

=item option_wants example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    wants => 'string',
  });

  my $option_wants = $cli->option_wants('input');

  # "string"

=back

=cut

=head2 optional

  optional(string $method, any @args) (any)

The optional method is a configuration dispatcher and shorthand for
C<{'required', false}>. It returns the data or dispatches to the next
configuration dispatcher based on the name provided and merges the
configurations produced.

I<Since C<4.15>>

=over 4

=item optional example 1

  # given: synopsis

  package main;

  my $optional = $cli->optional;

  # {required => false}

=back

=over 4

=item optional example 2

  # given: synopsis

  package main;

  my $optional = $cli->optional(undef, {type => 'boolean'});

  # {required => false, type => 'boolean'}

=back

=over 4

=item optional example 3

  # given: synopsis

  package main;

  my $optional = $cli->optional('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 0,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=back

=cut

=head2 opts

  opts() (Venus::Opts)

The opts method returns the list of parsed command-line options as a
L<Venus::Opts> object.

I<Since C<4.15>>

=over 4

=item opts example 1

  # given: synopsis

  package main;

  my $opts = $cli->opts;

  # bless(..., "Venus::Opts")

=back

=over 4

=item opts example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->parse('--input', 'hello world');

  my $opts = $cli->opts;

  # bless(..., "Venus::Opts")

  # $opts->input;

=back

=cut

=head2 output

  output(string $level) (any)

The output method returns the list of output events as an arrayref in scalar
context, and a list in list context. The method optionally takes a log-level
and if provided will only return output events for that log-level.

I<Since C<4.15>>

=over 4

=item output example 1

  # given: synopsis

  package main;

  my $output = $cli->output;

  # undef

=back

=over 4

=item output example 2

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output = $cli->output;

  # "example output"

=back

=over 4

=item output example 3

  # given: synopsis

  package main;

  $cli->log_info('example output 1');

  $cli->log_info('example output 2');

  my @output = $cli->output;

  # ('example output 1', 'example output 2')

=back

=cut

=head2 output_debug_events

  output_debug_events() (arrayref)

The output_debug_events method returns the list of debug output events as an
arrayref in scalar context, and a list in list context.

I<Since C<4.15>>

=over 4

=item output_debug_events example 1

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_debug_events = $cli->output_debug_events;

  # []

=back

=over 4

=item output_debug_events example 2

  # given: synopsis

  package main;

  $cli->log_debug('example output');

  my $output_debug_events = $cli->output_debug_events;

  # ['example output']

=back

=over 4

=item output_debug_events example 3

  # given: synopsis

  package main;

  $cli->log_debug('example output 1');

  $cli->log_debug('example output 2');

  my $output_debug_events = $cli->output_debug_events;

  # ['example output 1', 'example output 2']

=back

=over 4

=item output_debug_events example 4

  # given: synopsis

  package main;

  $cli->log_debug('example output 1');

  $cli->log_debug('example output 2');

  my @output_debug_events = $cli->output_debug_events;

  # ('example output 1', 'example output 2')

=back

=cut

=head2 output_error_events

  output_error_events() (arrayref)

The output_error_events method returns the list of error output events as an
arrayref in scalar context, and a list in list context.

I<Since C<4.15>>

=over 4

=item output_error_events example 1

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_error_events = $cli->output_error_events;

  # []

=back

=over 4

=item output_error_events example 2

  # given: synopsis

  package main;

  $cli->log_error('example output');

  my $output_error_events = $cli->output_error_events;

  # ['example output']

=back

=over 4

=item output_error_events example 3

  # given: synopsis

  package main;

  $cli->log_error('example output 1');

  $cli->log_error('example output 2');

  my $output_error_events = $cli->output_error_events;

  # ['example output 1', 'example output 2']

=back

=over 4

=item output_error_events example 4

  # given: synopsis

  package main;

  $cli->log_error('example output 1');

  $cli->log_error('example output 2');

  my @output_error_events = $cli->output_error_events;

  # ('example output 1', 'example output 2')

=back

=cut

=head2 output_fatal_events

  output_fatal_events() (arrayref)

The output_fatal_events method returns the list of fatal output events as an
arrayref in scalar context, and a list in list context.

I<Since C<4.15>>

=over 4

=item output_fatal_events example 1

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_fatal_events = $cli->output_fatal_events;

  # []

=back

=over 4

=item output_fatal_events example 2

  # given: synopsis

  package main;

  $cli->log_fatal('example output');

  my $output_fatal_events = $cli->output_fatal_events;

  # ['example output']

=back

=over 4

=item output_fatal_events example 3

  # given: synopsis

  package main;

  $cli->log_fatal('example output 1');

  $cli->log_fatal('example output 2');

  my $output_fatal_events = $cli->output_fatal_events;

  # ['example output 1', 'example output 2']

=back

=over 4

=item output_fatal_events example 4

  # given: synopsis

  package main;

  $cli->log_fatal('example output 1');

  $cli->log_fatal('example output 2');

  my @output_fatal_events = $cli->output_fatal_events;

  # ('example output 1', 'example output 2')

=back

=cut

=head2 output_info_events

  output_info_events() (arrayref)

The output_info_events method returns the list of info output events as an
arrayref in scalar context, and a list in list context.

I<Since C<4.15>>

=over 4

=item output_info_events example 1

  # given: synopsis

  package main;

  $cli->log_warn('example output');

  my $output_info_events = $cli->output_info_events;

  # []

=back

=over 4

=item output_info_events example 2

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_info_events = $cli->output_info_events;

  # ['example output']

=back

=over 4

=item output_info_events example 3

  # given: synopsis

  package main;

  $cli->log_info('example output 1');

  $cli->log_info('example output 2');

  my $output_info_events = $cli->output_info_events;

  # ['example output 1', 'example output 2']

=back

=over 4

=item output_info_events example 4

  # given: synopsis

  package main;

  $cli->log_info('example output 1');

  $cli->log_info('example output 2');

  my @output_info_events = $cli->output_info_events;

  # ('example output 1', 'example output 2')

=back

=cut

=head2 output_trace_events

  output_trace_events() (arrayref)

The output_trace_events method returns the list of trace output events as an
arrayref in scalar context, and a list in list context.

I<Since C<4.15>>

=over 4

=item output_trace_events example 1

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_trace_events = $cli->output_trace_events;

  # []

=back

=over 4

=item output_trace_events example 2

  # given: synopsis

  package main;

  $cli->log_trace('example output');

  my $output_trace_events = $cli->output_trace_events;

  # ['example output']

=back

=over 4

=item output_trace_events example 3

  # given: synopsis

  package main;

  $cli->log_trace('example output 1');

  $cli->log_trace('example output 2');

  my $output_trace_events = $cli->output_trace_events;

  # ['example output 1', 'example output 2']

=back

=over 4

=item output_trace_events example 4

  # given: synopsis

  package main;

  $cli->log_trace('example output 1');

  $cli->log_trace('example output 2');

  my @output_trace_events = $cli->output_trace_events;

  # ('example output 1', 'example output 2')

=back

=cut

=head2 output_warn_events

  output_warn_events() (arrayref)

The output_warn_events method returns the list of warn output events as an
arrayref in scalar context, and a list in list context.

I<Since C<4.15>>

=over 4

=item output_warn_events example 1

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_warn_events = $cli->output_warn_events;

  # []

=back

=over 4

=item output_warn_events example 2

  # given: synopsis

  package main;

  $cli->log_warn('example output');

  my $output_warn_events = $cli->output_warn_events;

  # ['example output']

=back

=over 4

=item output_warn_events example 3

  # given: synopsis

  package main;

  $cli->log_warn('example output 1');

  $cli->log_warn('example output 2');

  my $output_warn_events = $cli->output_warn_events;

  # ['example output 1', 'example output 2']

=back

=over 4

=item output_warn_events example 4

  # given: synopsis

  package main;

  $cli->log_warn('example output 1');

  $cli->log_warn('example output 2');

  my @output_warn_events = $cli->output_warn_events;

  # ('example output 1', 'example output 2')

=back

=cut

=head2 parse

  parse(any @args) (Venus::Cli)

The parse method accepts arbitrary input (typically strings or arrayrefs of
strings) and parses out the arguments and options made available via
L</parsed_arguments> and L</parsed_options> respectively. If no arguments are
provided C<@ARGV> is used as a default.

I<Since C<4.15>>

=over 4

=item parse example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $parse = $cli->parse;

  # bless(..., "Venus::Cli")

  # $cli->parsed_arguments

  # []

  # $result->parsed_options

  # {}

=back

=over 4

=item parse example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $parse = $cli->parse('hello', 'world');

  # bless(..., "Venus::Cli")

  # $cli->parsed_arguments

  # ['hello', 'world']

  # $result->parsed_options

  # {}

=back

=over 4

=item parse example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  my $parse = $cli->parse('--input', 'stdin', '--output', 'stdout', 'hello', 'world');

  # bless(..., "Venus::Cli")

  # $cli->parsed_arguments

  # ['hello', 'world']

  # $result->parsed_options

  # {input => 'stdin', output => 'stdout'}

=back

=cut

=head2 parsed

  parsed() (arrayref | hashref)

The parsed method is shorthand for calling the L</parsed_arguments> and/or
L</parsed_options> method directly. In scalar context this method returns
L</parsed_options>. In list context returns L</parsed_options> and
L</parsed_arguments> in that order.

I<Since C<4.15>>

=over 4

=item parsed example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $parsed = $cli->parsed;

  # {}

=back

=over 4

=item parsed example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->parse('hello world');

  my $parsed = $cli->parsed;

  # {}

=back

=over 4

=item parsed example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->parse('hello', 'world');

  my ($options, $arguments) = $cli->parsed;

  # ({}, ['hello', 'world'])

=back

=over 4

=item parsed example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  my $parse = $cli->parse('--input', 'stdin', '--output', 'stdout', 'hello world');

  my $parsed = $cli->parsed;

  # {input => 'stdin', output => 'stdout'}

=back

=over 4

=item parsed example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  my $parse = $cli->parse('--input', 'stdin', '--output', 'stdout', 'hello', 'world');

  my ($options, $arguments) = $cli->parsed;

  # ({input => 'stdin', output => 'stdout'}, ['hello', 'world'])

=back

=cut

=head2 parsed_arguments

  parsed_arguments(arrayref $data) (arrayref)

The parsed_arguments method gets or sets the set of parsed arguments. This
method calls L</parse> if no data has been set.

I<Since C<4.15>>

=over 4

=item parsed_arguments example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $parsed_arguments = $cli->parsed_arguments;

  # ['hello', 'world']

=back

=cut

=head2 parsed_options

  parsed_options(hashref $data) (hashref)

The parsed_options method method gets or sets the set of parsed options. This
method calls L</parse> if no data has been set.

I<Since C<4.15>>

=over 4

=item parsed_options example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $parsed_options = $cli->parsed_options;

  # {input => 'stdin', output => 'stdout'}

=back

=cut

=head2 pass

  pass(string | coderef $code, any @args) (any)

The pass method terminates the program with a the exit code C<0>, indicating a
successful exit. This method can be used to end the program explicitly, either
after a specific task is completed or when an error occurs that requires
halting execution. This method can dispatch to another method or callback
before exiting.

I<Since C<4.15>>

=over 4

=item pass example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->pass;

  # 0

=back

=over 4

=item pass example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->pass(sub{
    $cli->{dispatched} = 1;
  });

  # 0

=back

=cut

=head2 reorder

  reorder() (Venus::Cli)

The reorder method re-indexes the L<"arguments"|/argument_list>,
L<"choices"|/choice_list>, and L<"options"|/option_list>, based on the order
they were declared.

I<Since C<4.15>>

=over 4

=item reorder example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
    index => 1,
  });

  $cli->argument('output', {
    type => 'string',
    index => 3,
  });

  $cli->option('file', {
    type => 'string',
    index => 1,
  });

  $cli->option('directory', {
    type => 'string',
    index => 3,
  });

  $cli->choice('stdin', {
    argument => 'input',
    type => 'string',
    index => 1,
  });

  $cli->choice('stdout', {
    argument => 'output',
    type => 'string',
    index => 3,
  });

  my $reorder = $cli->reorder;

  # bless(..., "Venus::Cli")

=back

=cut

=head2 reorder_arguments

  reorder_arguments() (Venus::Cli)

The reorder_arguments method re-indexes the L<"arguments"|/argument_list> based
on the order they were declared.

I<Since C<4.15>>

=over 4

=item reorder_arguments example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
    index => 1,
  });

  $cli->argument('output', {
    type => 'string',
    index => 3,
  });

  my $reorder_arguments = $cli->reorder_arguments;

  # bless(..., "Venus::Cli")

=back

=cut

=head2 reorder_choices

  reorder_choices() (Venus::Cli)

The reorder_choices method re-indexes the L<"choices"|/choice_list> based on
the order they were declared.

I<Since C<4.15>>

=over 4

=item reorder_choices example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
    index => 1,
  });

  $cli->argument('output', {
    type => 'string',
    index => 3,
  });

  $cli->choice('stdin', {
    argument => 'input',
    type => 'string',
    index => 1,
  });

  $cli->choice('stdout', {
    argument => 'output',
    type => 'string',
    index => 3,
  });

  my $reorder_choices = $cli->reorder_choices;

  # bless(..., "Venus::Cli")

=back

=cut

=head2 reorder_options

  reorder_options() (Venus::Cli)

The reorder_options method re-indexes the L<"options"|/option_list> based on
the order they were declared.

I<Since C<4.15>>

=over 4

=item reorder_options example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('file', {
    type => 'string',
    index => 1,
  });

  $cli->option('directory', {
    type => 'string',
    index => 3,
  });

  my $reorder_options = $cli->reorder_options;

  # bless(..., "Venus::Cli")

=back

=cut

=head2 reorder_routes

  reorder_routes() (Venus::Cli)

The reorder_routes method reorders the registered routes based on their
indices. This method returns the invocant.

I<Since C<4.15>>

=over 4

=item reorder_routes example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
    index => 1,
  });

  $cli->route('user delete', {
    handler => 'handle_user_delete',
    index => 0,
  });

  my $reorder_routes = $cli->reorder_routes;

  # bless(..., "Venus::Cli")

=back

=cut

=head2 required

  required(string $method, any @args) (any)

The required method is a configuration dispatcher and shorthand for
C<{'required', true}>. It returns the data or dispatches to the next
configuration dispatcher based on the name provided and merges the
configurations produced.

I<Since C<4.15>>

=over 4

=item required example 1

  # given: synopsis

  package main;

  my $required = $cli->required;

  # {required => true}

=back

=over 4

=item required example 2

  # given: synopsis

  package main;

  my $required = $cli->required(undef, {type => 'boolean'});

  # {required => true, type => 'boolean'}

=back

=over 4

=item required example 3

  # given: synopsis

  package main;

  my $required = $cli->required('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=back

=cut

=head2 reset

  reset() (Venus::Cli)

The reset method clears the argument and option configurations, cached parsed
values, and returns the invocant.

I<Since C<4.15>>

=over 4

=item reset example 1

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $reset = $cli->reset;

  # bless(..., "Venus::Cli")

=back

=over 4

=item reset example 2

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $reset = $cli->reset;

  # bless(..., "Venus::Cli")

=back

=cut

=head2 route

  route(string $name, hashref $data) (maybe[hashref])

The route method registers and returns the configuration for the route
specified. The method takes a name (route name) and a hashref of configuration
values. The possible configuration values are as follows:

=over 4

=item *

The C<name> key holds the name of the route.

=item *

The C<label> key holds the name of the route as it should be displayed in the
CLI help text.

=item *

The C<help> key holds the help text specific to this route.

=item *

The C<argument> key holds the name of the argument that this route is
associated with.

=item *

The C<choice> key holds the name of the choice that this route is associated
with.

=item *

The C<handler> key holds the (local) method name, or L<Venus::Cli> derived
package, or coderef to execute when this route is matched.

=item *

The C<range> key holds the range specification for the argument.

=item *

The C<wants> key holds the text to be used as a value placeholder in the CLI
help text.

=back

I<Since C<4.15>>

=over 4

=item route example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route = $cli->route('user create');

  # undef

=back

=over 4

=item route example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route = $cli->route('user create', {
    handler => 'handle_user_create',
  });

  # {
  #   name => 'user create',
  #   label => undef,
  #   help => undef,
  #   argument => undef,
  #   choice => undef,
  #   handler => 'handle_user_create',
  #   range => undef,
  #   index => 0,
  # }

=back

=over 4

=item route example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  my $route = $cli->route('user create');

  # {
  #   name => 'user create',
  #   label => undef,
  #   help => undef,
  #   argument => undef,
  #   choice => undef,
  #   handler => 'handle_user_create',
  #   range => undef,
  #   index => 0,
  # }

=back

=over 4

=item route example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  my $route = $cli->route('user create', undef);

  # {
  #   name => 'user create',
  #   ...
  # }

=back

=cut

=head2 route_argument

  route_argument(string $name) (maybe[hashref])

The route_argument method returns the argument configuration for the named
route.

I<Since C<4.15>>

=over 4

=item route_argument example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_argument = $cli->route_argument;

  # ""

=back

=over 4

=item route_argument example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('command', {
    range => ':1',
  });

  $cli->route('user create', {
    argument => 'command',
    handler => 'handle_user_create',
  });

  my $route_argument = $cli->route_argument('user create');

  # {
  #   name => 'command',
  #   ...
  # }

=back

=cut

=head2 route_choice

  route_choice(string $name) (maybe[hashref])

The route_choice method returns the choice configuration for the named route.

I<Since C<4.15>>

=over 4

=item route_choice example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_choice = $cli->route_choice;

  # ""

=back

=over 4

=item route_choice example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('command', {
    range => ':1',
  });

  $cli->choice('user create', {
    argument => 'command',
  });

  $cli->route('user create', {
    argument => 'command',
    choice => 'user create',
    handler => 'handle_user_create',
  });

  my $route_choice = $cli->route_choice('user create');

  # {
  #   name => 'user create',
  #   ...
  # }

=back

=cut

=head2 route_count

  route_count() (number)

The route_count method returns the number of registered routes.

I<Since C<4.15>>

=over 4

=item route_count example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_count = $cli->route_count;

  # 0

=back

=over 4

=item route_count example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  $cli->route('user delete', {
    handler => 'handle_user_delete',
  });

  my $route_count = $cli->route_count;

  # 2

=back

=cut

=head2 route_handler

  route_handler(string $name) (maybe[string | coderef])

The route_handler method returns the handler for the named route.

I<Since C<4.15>>

=over 4

=item route_handler example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_handler = $cli->route_handler;

  # undef

=back

=over 4

=item route_handler example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  my $route_handler = $cli->route_handler('user create');

  # "handle_user_create"

=back

=over 4

=item route_handler example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $handler = sub { ... };

  $cli->route('user create', {
    handler => $handler,
  });

  my $route_handler = $cli->route_handler('user create');

  # sub { ... }

=back

=cut

=head2 route_help

  route_help(string $name) (string)

The route_help method returns the help text for the named route.

I<Since C<4.15>>

=over 4

=item route_help example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_help = $cli->route_help;

  # ""

=back

=over 4

=item route_help example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
    help => 'Create a new user',
  });

  my $route_help = $cli->route_help('user create');

  # "Create a new user"

=back

=cut

=head2 route_label

  route_label(string $name) (string)

The route_label method returns the label for the named route.

I<Since C<4.15>>

=over 4

=item route_label example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_label = $cli->route_label;

  # ""

=back

=over 4

=item route_label example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
    label => 'User Create',
  });

  my $route_label = $cli->route_label('user create');

  # "User Create"

=back

=cut

=head2 route_list

  route_list() (arrayref[hashref])

The route_list method returns a list of all registered route configurations in
insertion order.

I<Since C<4.15>>

=over 4

=item route_list example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_list = $cli->route_list;

  # []

=back

=over 4

=item route_list example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  $cli->route('user delete', {
    handler => 'handle_user_delete',
  });

  my $route_list = $cli->route_list;

  # [
  #   { name => 'user create', ... },
  #   { name => 'user delete', ... },
  # ]

=back

=cut

=head2 route_name

  route_name(string $name) (string)

The route_name method returns the name of the named route.

I<Since C<4.15>>

=over 4

=item route_name example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_name = $cli->route_name;

  # ""

=back

=over 4

=item route_name example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  my $route_name = $cli->route_name('user create');

  # "user create"

=back

=cut

=head2 route_names

  route_names() (arrayref[string])

The route_names method returns a list of all registered route names in
insertion order.

I<Since C<4.15>>

=over 4

=item route_names example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_names = $cli->route_names;

  # []

=back

=over 4

=item route_names example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  $cli->route('user delete', {
    handler => 'handle_user_delete',
  });

  my $route_names = $cli->route_names;

  # ["user create", "user delete"]

=back

=cut

=head2 route_range

  route_range(string $name) (string)

The route_range method returns the range for the named route.

I<Since C<4.15>>

=over 4

=item route_range example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_range = $cli->route_range;

  # ""

=back

=over 4

=item route_range example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
    range => ':1',
  });

  my $route_range = $cli->route_range('user create');

  # ":1"

=back

=cut

=head2 single

  single(string $method, any @args) (any)

The single method is a configuration dispatcher and shorthand for
C<{'multiples', false}>. It returns the data or dispatches to the next
configuration dispatcher based on the name provided and merges the
configurations produced.

I<Since C<4.15>>

=over 4

=item single example 1

  # given: synopsis

  package main;

  my $single = $cli->single;

  # {multiples => false}

=back

=over 4

=item single example 2

  # given: synopsis

  package main;

  my $single = $cli->single(undef, {type => 'boolean'});

  # {multiples => false, type => 'boolean'}

=back

=over 4

=item single example 3

  # given: synopsis

  package main;

  my $single = $cli->single('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 0,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=back

=cut

=head2 spec

  spec(hashref $data) (Venus::Cli)

The spec method configures the CLI instance from a hashref specification. It
accepts a hashref containing any of the following keys: C<name>, C<version>,
C<summary>, C<description>, C<header>, C<footer>, C<arguments>, C<options>,
C<choices>, C<routes>, and C<commands>. The method returns the invocant.

I<Since C<4.15>>

=over 4

=item spec example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec;

  # bless(..., "Venus::Cli")

=back

=over 4

=item spec example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec({
    name => 'mycli',
    version => '1.0.0',
    summary => 'My CLI application',
  });

  # bless(..., "Venus::Cli")

=back

=over 4

=item spec example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec({
    name => 'mycli',
    options => [
      {
        name => 'verbose',
        type => 'boolean',
        aliases => ['v'],
        help => 'Enable verbose output',
      },
      {
        name => 'config',
        type => 'string',
        aliases => ['c'],
        help => 'Path to config file',
      },
    ],
  });

  # bless(..., "Venus::Cli")

=back

=over 4

=item spec example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec({
    name => 'mycli',
    arguments => [
      {
        name => 'input',
        type => 'string',
        help => 'Input file path',
      },
    ],
  });

  # bless(..., "Venus::Cli")

=back

=over 4

=item spec example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec({
    name => 'mycli',
    commands => [
      ['command', 'user', 'create', 'handle_user_create'],
      ['command', 'user', 'delete', 'handle_user_delete'],
    ],
  });

  # bless(..., "Venus::Cli")

=back

=over 4

=item spec example 6

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec({
    name => 'mycli',
    version => '1.0.0',
    summary => 'User management CLI',
    description => 'A command-line tool for managing users',
    header => 'Welcome to mycli',
    footer => 'For more info, visit example.com',
    arguments => [
      {
        name => 'action',
        type => 'string',
        range => '0',
      },
    ],
    options => [
      {
        name => 'verbose',
        type => 'boolean',
        aliases => ['v'],
      },
    ],
    choices => [
      {
        name => 'create',
        argument => 'action',
        help => 'Create a new user',
      },
      {
        name => 'delete',
        argument => 'action',
        help => 'Delete a user',
      },
    ],
    routes => [
      {
        name => 'create',
        argument => 'action',
        choice => 'create',
        handler => 'handle_create',
      },
      {
        name => 'delete',
        argument => 'action',
        choice => 'delete',
        handler => 'handle_delete',
      },
    ],
  });

  # bless(..., "Venus::Cli")

=back

=cut

=head2 string

  string(string $method, any @args) (any)

The string method is a configuration dispatcher and shorthand for C<{'type',
'string'}>. It returns the data or dispatches to the next configuration
dispatcher based on the name provided and merges the configurations produced.

I<Since C<4.15>>

=over 4

=item string example 1

  # given: synopsis

  package main;

  my $string = $cli->string;

  # {type => 'string'}

=back

=over 4

=item string example 2

  # given: synopsis

  package main;

  my $string = $cli->string(undef, {required => true});

  # {type => 'string', required => true}

=back

=over 4

=item string example 3

  # given: synopsis

  package main;

  my $string = $cli->string('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=back

=cut

=head2 usage

  usage() (string)

The usage method provides the command-line usage information for the CLI. It
outputs details such as available choices, arguments, options, and a general
summary of how to use the CLI. This method is useful for users needing guidance
on the various arguments, options, and choices available, and how they work.

I<Since C<4.15>>

=over 4

=item usage example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage = $cli->usage;

  # "Usage: mycli"

=back

=over 4

=item usage example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
  );

  my $usage = $cli->usage;

  # "mycli - Example summary
  #
  # Usage: mycli"

=back

=over 4

=item usage example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  my $usage = $cli->usage;

  # "mycli version 0.0.1 - Example summary
  #
  # Usage: mycli"

=back

=over 4

=item usage example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    type => 'string',
  });

  $cli->argument('output', {
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli [<input>] [<output>]
  #
  # Arguments:
  #   [<input>]
  #     Expects a string value
  #     (optional)
  #   [<output>]
  #     Expects a string value
  #     (optional)

=back

=over 4

=item usage example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    required => true,
    type => 'string',
  });

  $cli->argument('output', {
    default => 'file',
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli <input> [<output>]
  #
  # Arguments:
  #   <input>
  #     Expects a string value
  #     (required)
  #   [<output>]
  #     Expects a string value
  #     (optional)
  #     Default: file

=back

=over 4

=item usage example 6

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    name => 'INPUT',
    type => 'string',
  });

  $cli->argument('output', {
    name => 'OUTPUT',
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli [<INPUT>] [<OUTPUT>]
  #
  # Arguments:
  #   [<INPUT>]
  #     Expects a string value
  #     (optional)
  #   [<OUTPUT>]
  #     Expects a string value
  #     (optional)

=back

=over 4

=item usage example 7

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    name => 'input',
    label => 'Input.',
    type => 'string',
  });

  $cli->argument('output', {
    name => 'output',
    label => 'Output.',
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli [<input>] [<output>]
  #
  # Arguments:
  #   Input.
  #     Expects a string value
  #     (optional)
  #   Output.
  #     Expects a string value
  #     (optional)

=back

=over 4

=item usage example 8

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    name => 'input',
    help => 'Provide the input device to use',
    type => 'string',
  });

  $cli->argument('output', {
    name => 'output',
    help => 'Provide the output device to use',
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli [<input>] [<output>]
  #
  # Arguments:
  #   [<input>]
  #     Provide the input device to use
  #     (optional)
  #   [<output>]
  #     Provide the output device to use
  #     (optional)

=back

=over 4

=item usage example 9

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    name => 'input',
    help => 'Provide the input device to use',
    type => 'string',
  });

  $cli->argument('output', {
    name => 'output',
    help => 'Provide the output device to use',
    multiples => true,
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli [<input>] [<output> ...]
  #
  # Arguments:
  #   [<input>]
  #     Provide the input device to use
  #     (optional)
  #   [<output> ...]
  #     Provide the output device to use
  #     (optional)

=back

=over 4

=item usage example 10

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('lines', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<lines> ...] [--input] [--output]
  #
  # Arguments:
  #   [<lines> ...]
  #     Expects a string value
  #     (optional)
  #
  # Options:
  #   [--input=<string>]
  #     Expects a string value
  #     (optional)
  #   [--output=<string>]
  #     Expects a string value
  #     (optional)

=back

=over 4

=item usage example 11

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->option('verbose', {
    type => 'boolean',
  });

  $cli->option('help', {
    alias => 'h',
    type => 'boolean',
  });

  $cli->argument('lines', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<lines> ...] [--input] [--output] [--verbose] [--help]
  #
  # Arguments:
  #   [<lines> ...]
  #     Expects a string value
  #     (optional)
  #
  # Options:
  #   [--input=<string>]
  #     Expects a string value
  #     (optional)
  #   [--output=<string>]
  #     Expects a string value
  #     (optional)
  #   [--verbose]
  #     Expects a boolean value
  #     (optional)
  #   [-h, --help]
  #     Expects a boolean value
  #     (optional)

=back

=over 4

=item usage example 12

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->option('input', {
    multiples => true,
    type => 'string',
  });

  $cli->option('output', {
    multiples => true,
    type => 'string',
  });

  $cli->option('verbose', {
    type => 'boolean',
  });

  $cli->option('help', {
    alias => 'h',
    type => 'boolean',
  });

  $cli->argument('lines', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<lines> ...] [--input ...] [--output ...] [--verbose] [--help]
  #
  # Arguments:
  #   [<lines> ...]
  #     Expects a string value
  #     (optional)
  #
  # Options:
  #   [--input=<string> ...]
  #     Expects a string value
  #     (optional)
  #   [--output=<string> ...]
  #     Expects a string value
  #     (optional)
  #   [--verbose]
  #     Expects a boolean value
  #     (optional)
  #   [-h, --help]
  #     Expects a boolean value
  #     (optional)

=back

=over 4

=item usage example 13

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->option('input', {
    alias => 'i',
    multiples => true,
    required => true,
    type => 'string',
    wants => 'input',
  });

  $cli->option('output', {
    alias => 'o',
    multiples => true,
    type => 'string',
    wants => 'output',
  });

  $cli->option('verbose', {
    aliases => ['v'],
    type => 'boolean',
  });

  $cli->option('help', {
    aliases => ['h'],
    type => 'boolean',
  });

  $cli->argument('lines', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<lines> ...] --input ... [--output ...] [--verbose] [--help]
  #
  # Arguments:
  #   [<lines> ...]
  #     Expects a string value
  #     (optional)
  #
  # Options:
  #   -i, --input=<input> ...
  #     Expects a string value
  #     (required)
  #   [-o, --output=<output> ...]
  #     Expects a string value
  #     (optional)
  #   [-v, --verbose]
  #     Expects a boolean value
  #     (optional)
  #   [-h, --help]
  #     Expects a boolean value
  #     (optional)

=back

=over 4

=item usage example 14

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->option('input', {
    alias => 'i',
    multiples => true,
    required => true,
    type => 'string',
    wants => 'input',
  });

  $cli->option('output', {
    alias => 'o',
    multiples => true,
    type => 'string',
    wants => 'output',
  });

  $cli->option('verbose', {
    aliases => ['v'],
    type => 'boolean',
  });

  $cli->option('help', {
    aliases => ['h'],
    type => 'boolean',
  });

  $cli->argument('lines', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->option('exit-code', {
    alias => 'ec',
    type => 'number',
    default => 0,
  });

  my $usage = $cli->usage;

  # Usage: mycli [<lines> ...] --input ... [--output ...] [--verbose] [--help]
  #              [--exit-code]
  #
  # Arguments:
  #   [<lines> ...]
  #     Expects a string value
  #     (optional)
  #
  # Options:
  #   -i, --input=<input> ...
  #     Expects a string value
  #     (required)
  #   [-o, --output=<output> ...]
  #     Expects a string value
  #     (optional)
  #   [-v, --verbose]
  #     Expects a boolean value
  #     (optional)
  #   [-h, --help]
  #     Expects a boolean value
  #     (optional)
  #   [--ec, --exit-code=<number>]
  #     Expects a number value
  #     (optional)
  #     Default: 0

=back

=over 4

=item usage example 15

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->argument('input', {
    type => 'string',
    default => 'stdin',
  });

  $cli->argument('output', {
    type => 'string',
    default => 'stdout',
  });

  $cli->option('verbose', {
    aliases => ['v'],
    type => 'boolean',
  });

  $cli->option('help', {
    aliases => ['h'],
    type => 'boolean',
  });

  $cli->option('exit-code', {
    alias => 'ec',
    type => 'number',
    default => 0,
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->choice('in-file', {
    argument => 'input',
  });

  $cli->choice('stdout', {
    argument => 'output',
  });

  $cli->choice('out-file', {
    argument => 'output',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<input>] [<output>] [--verbose] [--help] [--exit-code]
  #
  # Arguments:
  #   [<input>]
  #     Expects a string value
  #     (optional)
  #     Default: stdin
  #   [<output>]
  #     Expects a string value
  #     (optional)
  #     Default: stdout
  #
  # Options:
  #   [-v, --verbose]
  #     Expects a boolean value
  #     (optional)
  #   [-h, --help]
  #     Expects a boolean value
  #     (optional)
  #   [--ec, --exit-code=<number>]
  #     Expects a number value
  #     (optional)
  #     Default: 0
  #
  # Choices for [<input>]:
  #   stdin
  #     Expects a string value
  #     [<input>]
  #   in-file
  #     Expects a string value
  #     [<input>]
  #
  # Choices for [<output>]:
  #   stdout
  #     Expects a string value
  #     [<output>]
  #   out-file
  #     Expects a string value
  #     [<output>]

=back

=over 4

=item usage example 16

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->argument('choice', {
    help => 'See "choices" below',
    type => 'string',
    default => 'open',
  });

  $cli->choice('open', {
    argument => 'choice',
  });

  $cli->choice('close', {
    argument => 'choice',
  });

  $cli->choice('read', {
    argument => 'choice',
  });

  $cli->choice('write', {
    argument => 'choice',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<choice>]
  #
  # Arguments:
  #   [<choice>]
  #     See "choices" below
  #     (optional)
  #     Default: open
  #
  # Choices for [<choice>]:
  #   open
  #     Expects a string value
  #     [<choice>]
  #   close
  #     Expects a string value
  #     [<choice>]
  #   read
  #     Expects a string value
  #     [<choice>]
  #   write
  #     Expects a string value
  #     [<choice>]

=back

=over 4

=item usage example 17

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->argument('choice', {
    help => 'See "choices" below',
    type => 'string',
    required => true,
  });

  $cli->choice('open', {
    argument => 'choice',
  });

  $cli->choice('close', {
    argument => 'choice',
  });

  $cli->choice('read', {
    argument => 'choice',
  });

  $cli->choice('write', {
    argument => 'choice',
  });

  my $usage = $cli->usage;

  # Usage: mycli <choice>
  #
  # Arguments:
  #   <choice>
  #     See "choices" below
  #     (required)
  #
  # Choices for <choice>:
  #   open
  #     Expects a string value
  #     <choice>
  #   close
  #     Expects a string value
  #     <choice>
  #   read
  #     Expects a string value
  #     <choice>
  #   write
  #     Expects a string value
  #     <choice>

=back

=cut

=head2 usage_argument_default

  usage_argument_default(string $name) (string)

The usage_argument_default method renders the C<default> configuration value
for the named argument for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_argument_default example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_argument_default = $cli->usage_argument_default;

  # ""

=back

=over 4

=item usage_argument_default example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    default => 'stdin',
  });

  my $usage_argument_default = $cli->usage_argument_default('input');

  # "Default: stdin"

=back

=over 4

=item usage_argument_default example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    default => ['stdin', 'file'],
  });

  my $usage_argument_default = $cli->usage_argument_default('input');

  # "Default: stdin, file"

=back

=cut

=head2 usage_argument_help

  usage_argument_help(string $name) (string)

The usage_argument_help method renders the C<help> configuration value for the
named argument for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_argument_help example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_argument_help = $cli->usage_argument_help;

  # ""

=back

=over 4

=item usage_argument_help example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    help => 'Provide input.',
  });

  my $usage_argument_help = $cli->usage_argument_help('input');

  # "Provide input."

=back

=cut

=head2 usage_argument_label

  usage_argument_label(string $name) (string)

The usage_argument_label method renders the C<label> configuration value for
the named argument for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_argument_label example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_argument_label = $cli->usage_argument_label;

  # ""

=back

=over 4

=item usage_argument_label example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    label => 'Input.',
  });

  my $usage_argument_label = $cli->usage_argument_label('input');

  # "Input."

=back

=cut

=head2 usage_argument_required

  usage_argument_required(string $name) (string)

The usage_argument_required method renders the C<required> configuration value
for the named argument for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_argument_required example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_argument_required = $cli->usage_argument_required;

  # "(optional)"

=back

=over 4

=item usage_argument_required example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
  });

  my $usage_argument_required = $cli->usage_argument_required('input');

  # "(required)"

=back

=over 4

=item usage_argument_required example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => false,
  });

  my $usage_argument_required = $cli->usage_argument_required('input');

  # "(optional)"

=back

=cut

=head2 usage_argument_token

  usage_argument_token(string $name) (string)

The usage_argument_token method renders the C<token> configuration value for
the named argument for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_argument_token example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_argument_token = $cli->usage_argument_token;

  # ""

=back

=over 4

=item usage_argument_token example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    multiples => false,
    type => 'string',
  });

  my $usage_argument_token = $cli->usage_argument_token('input');

  # "<input>"

=back

=over 4

=item usage_argument_token example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    multiples => true,
    type => 'string',
  });

  my $usage_argument_token = $cli->usage_argument_token('input');

  # "<input> ..."

=back

=over 4

=item usage_argument_token example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => false,
    multiples => false,
    type => 'string',
  });

  my $usage_argument_token = $cli->usage_argument_token('input');

  # "[<input>]"

=back

=over 4

=item usage_argument_token example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => false,
    multiples => true,
    type => 'string',
  });

  my $usage_argument_token = $cli->usage_argument_token('input');

  # "[<input> ...]"

=back

=cut

=head2 usage_arguments

  usage_arguments() (string)

The usage_arguments method renders all registered arguments for use in the CLI
L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_arguments example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->argument('output', {
    type => 'string',
  });

  my $usage_arguments = $cli->usage_arguments;

  # Arguments:
  #   [<input>]
  #     Expects a string value
  #     (optional)
  #   [<output>]
  #     Expects a string value
  #     (optional)

=back

=over 4

=item usage_arguments example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    type => 'string',
  });

  $cli->argument('output', {
    required => true,
    type => 'string',
  });

  my $usage_arguments = $cli->usage_arguments;

  # Arguments:
  #   <input>
  #     Expects a string value
  #     (required)
  #   <output>
  #     Expects a string value
  #     (required)

=back

=cut

=head2 usage_choice_help

  usage_choice_help(string $name) (string)

The usage_choice_help method renders the C<help> configuration value for the
named choice for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_choice_help example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_choice_help = $cli->usage_choice_help;

  # ""

=back

=over 4

=item usage_choice_help example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    help => 'Example help',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $usage_choice_help = $cli->usage_choice_help('stdin');

  # "Expects a string value"

=back

=over 4

=item usage_choice_help example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    help => 'Example help',
  });

  $cli->choice('stdin', {
    argument => 'input',
    help => 'Example help',
  });

  my $usage_choice_help = $cli->usage_choice_help('stdin');

  # "Example help"

=back

=cut

=head2 usage_choice_label

  usage_choice_label(string $name) (string)

The usage_choice_label method renders the C<label> configuration value for the
named choice for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_choice_label example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_choice_label = $cli->usage_choice_label;

  # ""

=back

=over 4

=item usage_choice_label example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    label => 'Input.',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $usage_choice_label = $cli->usage_choice_label('stdin');

  # "stdin"

=back

=over 4

=item usage_choice_label example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    label => 'Input.',
    type => 'string',
  });

  $cli->choice('stdin', {
    label => 'Stdin',
    argument => 'input',
  });

  my $usage_choice_label = $cli->usage_choice_label('stdin');

  # "Stdin"

=back

=cut

=head2 usage_choice_required

  usage_choice_required(string $name) (string)

The usage_choice_required method renders the C<required> configuration value
for the named choice for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_choice_required example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_choice_required = $cli->usage_choice_required;

  # ""

=back

=over 4

=item usage_choice_required example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $usage_choice_required = $cli->usage_choice_required('stdin');

  # "<input>"

=back

=over 4

=item usage_choice_required example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => false,
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $usage_choice_required = $cli->usage_choice_required('stdin');

  # "[<input>]"

=back

=cut

=head2 usage_choices

  usage_choices() (string)

The usage_choices method renders all registered choices for use in the CLI
L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_choices example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->argument('output', {
    type => 'string',
  });

  $cli->choice('stdout', {
    argument => 'output',
  });

  my $usage_choices = $cli->usage_choices;

  # Choices for [<input>]:
  #   stdin
  #     Expects a string value
  #     [<input>]
  #
  # Choices for [<output>]:
  #   stdout
  #     Expects a string value
  #     [<output>]

=back

=over 4

=item usage_choices example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
  });

  $cli->choice('stdin', {
    argument => 'input',
    help => 'Use STDIN',
  });

  $cli->argument('output', {
    default => 'stdout',
  });

  $cli->choice('stdout', {
    argument => 'output',
    help => 'Use STDOUT',
  });

  my $usage_choices = $cli->usage_choices;

  # Choices for <input>:
  #   stdin
  #     Use STDIN
  #     <input>
  #
  # Choices for [<output>]:
  #   stdout
  #     Use STDOUT
  #     [<output>]

=back

=cut

=head2 usage_description

  usage_description() (string)

The usage_description method renders the description for use in the CLI
L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_description example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $description = $cli->description('Example description');

  my $usage_description = $cli->usage_description;

  # "Example description"

=back

=cut

=head2 usage_footer

  usage_footer() (string)

The usage_footer method renders the footer for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_footer example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $footer = $cli->footer('Example footer');

  my $usage_footer = $cli->usage_footer;

  # "Example footer"

=back

=cut

=head2 usage_gist

  usage_gist() (string)

The usage_gist method renders the CLI top-line describing the name, version,
and/or summary.

I<Since C<4.15>>

=over 4

=item usage_gist example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_gist = $cli->usage_gist;

  # ""

=back

=over 4

=item usage_gist example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->version('0.0.1');

  my $usage_gist = $cli->usage_gist;

  # "mycli version 0.0.1"

=back

=over 4

=item usage_gist example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->summary('Example summary');

  my $usage_gist = $cli->usage_gist;

  # "mycli - Example summary"

=back

=over 4

=item usage_gist example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->version('0.0.1');

  $cli->summary('Example summary');

  my $usage_gist = $cli->usage_gist;

  # "mycli version 0.0.1 - Example summary"

=back

=cut

=head2 usage_header

  usage_header() (string)

The usage_header method renders the header for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_header example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $header = $cli->header('Example header');

  my $usage_header = $cli->usage_header;

  # "Example header"

=back

=cut

=head2 usage_line

  usage_line() (string)

The usage_line method renders the CLI usage line for use in the CLI L</usage>
text.

I<Since C<4.15>>

=over 4

=item usage_line example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_line = $cli->usage_line;

  # "Usage: mycli"

=back

=over 4

=item usage_line example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  my $usage_line = $cli->usage_line;

  # "Usage: mycli [<input>]"

=back

=over 4

=item usage_line example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->argument('output', {
    type => 'string',
  });

  my $usage_line = $cli->usage_line;

  # "Usage: mycli [<input>] [<output>]"

=back

=over 4

=item usage_line example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    type => 'string',
  });

  $cli->argument('output', {
    required => true,
    type => 'string',
  });

  my $usage_line = $cli->usage_line;

  # "Usage: mycli <input> <output>"

=back

=over 4

=item usage_line example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    type => 'string',
  });

  $cli->argument('output', {
    multiples => true,
    required => false,
    type => 'string',
  });

  my $usage_line = $cli->usage_line;

  # "Usage: mycli <input> [<output> ...]"

=back

=cut

=head2 usage_name

  usage_name() (string)

The usage_name method renders the CLI name for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_name example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $usage_name = $cli->usage_name;

  # ""

=back

=over 4

=item usage_name example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_name = $cli->usage_name;

  # "mycli"

=back

=cut

=head2 usage_option_default

  usage_option_default(string $name) (string)

The usage_option_default method renders the C<default> configuration value for
the named option for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_option_default example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_option_default = $cli->usage_option_default;

  # ""

=back

=over 4

=item usage_option_default example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    default => 'stdin',
  });

  my $usage_option_default = $cli->usage_option_default('input');

  # "Default: stdin"

=back

=over 4

=item usage_option_default example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    default => ['stdin', 'file'],
  });

  my $usage_option_default = $cli->usage_option_default('input');

  # "Default: stdin, file"

=back

=cut

=head2 usage_option_help

  usage_option_help(string $name) (string)

The usage_option_help method renders the C<help> configuration value for the
named option for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_option_help example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_option_help = $cli->usage_option_help;

  # ""

=back

=over 4

=item usage_option_help example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    help => 'Example help',
  });

  my $usage_option_help = $cli->usage_option_help('input');

  # "Example help"

=back

=cut

=head2 usage_option_label

  usage_option_label(string $name) (string)

The usage_option_label method renders the C<label> configuration value for the
named option for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_option_label example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_option_label = $cli->usage_option_label;

  # ""

=back

=over 4

=item usage_option_label example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => true,
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "--input=<string>"

=back

=over 4

=item usage_option_label example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => true,
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "--input=<string> ..."

=back

=over 4

=item usage_option_label example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => true,
    type => 'number',
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "--input=<number> ..."

=back

=over 4

=item usage_option_label example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => true,
    type => 'number',
    wants => 'input',
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "--input=<input> ..."

=back

=over 4

=item usage_option_label example 6

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => false,
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "[--input=<string>]"

=back

=over 4

=item usage_option_label example 7

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => false,
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "[--input=<string> ...]"

=back

=over 4

=item usage_option_label example 8

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => false,
    type => 'number',
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "[--input=<number> ...]"

=back

=over 4

=item usage_option_label example 9

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => false,
    type => 'number',
    wants => 'input',
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "[--input=<input> ...]"

=back

=over 4

=item usage_option_label example 10

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => false,
    type => 'boolean',
    wants => undef,
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "[--input ...]"

=back

=cut

=head2 usage_option_required

  usage_option_required(string $name) (string)

The usage_option_required method renders the C<required> configuration value
for the named option for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_option_required example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_option_required = $cli->usage_option_required;

  # "(optional)"

=back

=over 4

=item usage_option_required example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => true,
  });

  my $usage_option_required = $cli->usage_option_required('input');

  # "(required)"

=back

=over 4

=item usage_option_required example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => false,
  });

  my $usage_option_required = $cli->usage_option_required('input');

  # "(optional)"

=back

=cut

=head2 usage_option_token

  usage_option_token(string $name) (string)

The usage_option_token method renders the C<token> configuration value for the
named option for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_option_token example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_option_token = $cli->usage_option_token;

  # ""

=back

=over 4

=item usage_option_token example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => true,
  });

  my $usage_option_token = $cli->usage_option_token('input');

  # "--input"

=back

=over 4

=item usage_option_token example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => true,
  });

  my $usage_option_token = $cli->usage_option_token('input');

  # "--input ..."

=back

=over 4

=item usage_option_token example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => false,
  });

  my $usage_option_token = $cli->usage_option_token('input');

  # "[--input]"

=back

=over 4

=item usage_option_token example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => false,
  });

  my $usage_option_token = $cli->usage_option_token('input');

  # "[--input ...]"

=back

=cut

=head2 usage_options

  usage_options() (string)

The usage_options method renders all registered options for use in the CLI
L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_options example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $usage_options = $cli->usage_options;

  # Options:
  #   [--input=<string>]
  #     Expects a string value
  #     (optional)
  #   [--output=<string>]
  #     Expects a string value
  #     (optional)

=back

=over 4

=item usage_options example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => true,
    type => 'string',
  });

  $cli->option('output', {
    required => true,
    type => 'string',
  });

  my $usage_options = $cli->usage_options;

  # Options:
  #   --input=<string>
  #     Expects a string value
  #     (required)
  #   --output=<string>
  #     Expects a string value
  #     (required)

=back

=cut

=head2 usage_summary

  usage_summary() (string)

The usage_summary method renders the summary for use in the CLI L</usage> text.

I<Since C<4.15>>

=over 4

=item usage_summary example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $summary = $cli->summary('Example summary');

  my $usage_summary = $cli->usage_summary;

  # "Example summary"

=back

=cut

=head2 usage_version

  usage_version() (string)

The usage_version method renders the description for use in the CLI L</usage>
text.

I<Since C<4.15>>

=over 4

=item usage_version example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $version = $cli->version('0.0.1');

  my $usage_version = $cli->usage_version;

  # "0.0.1"

=back

=cut

=head2 vars

  vars() (Venus::Vars)

The vars method returns the list of parsed command-line options as a
L<Venus::Vars> object.

I<Since C<4.15>>

=over 4

=item vars example 1

  # given: synopsis

  package main;

  my $vars = $cli->vars;

  # bless(..., "Venus::Vars")

=back

=cut

=head2 yesno

  yesno(string $method, any @args) (any)

The yesno method is a configuration dispatcher and shorthand for C<{'type',
'yesno'}>. It returns the data or dispatches to the next configuration
dispatcher based on the name provided and merges the configurations produced.

I<Since C<4.15>>

=over 4

=item yesno example 1

  # given: synopsis

  package main;

  my $yesno = $cli->yesno;

  # {type => 'yesno'}

=back

=over 4

=item yesno example 2

  # given: synopsis

  package main;

  my $yesno = $cli->yesno(undef, {required => true});

  # {type => 'yesno', required => true}

=back

=over 4

=item yesno example 3

  # given: synopsis

  package main;

  my $yesno = $cli->yesno('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a yesno value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'yesno',
  #   index => 0,
  #   wants => 'yesno',
  # }

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut