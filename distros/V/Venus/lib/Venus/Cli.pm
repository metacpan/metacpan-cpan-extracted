package Venus::Cli;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Stashable';

require POSIX;

# ATTRIBUTES

attr 'data';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    data => $data,
  };
}

sub build_self {
  my ($self, $data) = @_;

  $self->{data} ||= [@ARGV];

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

sub arg {
  my ($self, $name) = @_;

  return undef if !$name;

  my @values;

  my $data = $self->get('arg', $name) or return undef;
  my $_default = $data->{default};
  my $_help = $data->{help};
  my $_label = $data->{label};
  my $_name = $data->{name};
  my $_prompt = $data->{prompt};
  my $_range = $data->{range};
  my $_required = $data->{required};
  my $_type = $data->{type};

  require Venus::Array;
  require Venus::Unpack;

  # value
  @values = @{Venus::Array->new($self->parser->unused)->range($_range // 0)};

  # prompt
  if ($_prompt && (!@values || !defined $values[0])) {
    @values = (do{_print join ': ', $_label || $_name, $_prompt; _prompt}); _print;
  }

  # default
  if (defined $_default
    && (!@values || !defined $values[0] || $values[0] eq '')
    && exists $data->{default})
  {
    @values = ($_default);
  }

  my %type_map = (
    boolean => 'number',
    float => 'float',
    number => 'number',
    string => 'string',
    yesno => 'yesno',
  );

  # type
  if ($_type) {
    my ($caught, @values) = Venus::Unpack->new(args => [@values])->all->catch(
      'validate', $type_map{$_type}
    );
    $self->throw('error_on_arg_validation', $caught->message, $_name, $_type)->error
      if $caught;
  }

  # return boolean values
  @values = map +(lc($_type) eq 'boolean' ? ($_ ? true : false) : $_), @values
    if $_type;

  # returns
  return wantarray ? (@values) : [@values];
}

sub cmd {
  my ($self, $name) = @_;

  return undef if !$name;

  my $data = $self->get('cmd', $name) or return undef;

  my $value = $self->try('arg')->maybe->result($data->{arg});

  return (($value // '') eq $name) ? true : false;
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

sub get {
  my ($self, $key, $name) = @_;

  return undef if !$key;

  my $method = "get_${key}";

  return $self->$method($name);
}

sub get_arg {
  my ($self, $name) = @_;

  return $self->store('arg', $name);
}

sub get_arg_default {
  my ($self, $name) = @_;

  return $self->store('arg', $name, 'default');
}

sub get_arg_help {
  my ($self, $name) = @_;

  return $self->store('arg', $name, 'help');
}

sub get_arg_label {
  my ($self, $name) = @_;

  return $self->store('arg', $name, 'label');
}

sub get_arg_name {
  my ($self, $name) = @_;

  return $self->store('arg', $name, 'name');
}

sub get_arg_prompt {
  my ($self, $name) = @_;

  return $self->store('arg', $name, 'prompt');
}

sub get_arg_range {
  my ($self, $name) = @_;

  return $self->store('arg', $name, 'range');
}

sub get_arg_required {
  my ($self, $name) = @_;

  return $self->store('arg', $name, 'required');
}

sub get_arg_type {
  my ($self, $name) = @_;

  return $self->store('arg', $name, 'type');
}

sub get_cmd {
  my ($self, $name) = @_;

  return $self->store('cmd', $name);
}

sub get_cmd_arg {
  my ($self, $name) = @_;

  return $self->store('cmd', $name, 'arg');
}

sub get_cmd_help {
  my ($self, $name) = @_;

  return $self->store('cmd', $name, 'help');
}

sub get_cmd_label {
  my ($self, $name) = @_;

  return $self->store('cmd', $name, 'label');
}

sub get_cmd_name {
  my ($self, $name) = @_;

  return $self->store('cmd', $name, 'name');
}

sub get_opt {
  my ($self, $name) = @_;

  return $self->store('opt', $name);
}

sub get_opt_alias {
  my ($self, $name) = @_;

  return $self->store('opt', $name, 'alias');
}

sub get_opt_default {
  my ($self, $name) = @_;

  return $self->store('opt', $name, 'default');
}

sub get_opt_help {
  my ($self, $name) = @_;

  return $self->store('opt', $name, 'help');
}

sub get_opt_label {
  my ($self, $name) = @_;

  return $self->store('opt', $name, 'label');
}

sub get_opt_multi {
  my ($self, $name) = @_;

  return $self->store('opt', $name, 'multi') ? true : false;
}

sub get_opt_name {
  my ($self, $name) = @_;

  return $self->store('opt', $name, 'name');
}

sub get_opt_prompt {
  my ($self, $name) = @_;

  return $self->store('opt', $name, 'prompt');
}

sub get_opt_required {
  my ($self, $name) = @_;

  return $self->store('opt', $name, 'required');
}

sub get_opt_type {
  my ($self, $name) = @_;

  return $self->store('opt', $name, 'type');
}

sub get_str {
  my ($self, $name) = @_;

  return $self->store('str', $name, 'value');
}

sub get_str_arg {
  my ($self, $name) = @_;

  return $self->store('str', $name, 'arg');
}

sub get_str_author {
  my ($self, $name) = @_;

  return $self->store('str', $name, 'author');
}

sub get_str_description {
  my ($self, $name) = @_;

  return $self->store('str', $name, 'description');
}

sub get_str_footer {
  my ($self, $name) = @_;

  return $self->store('str', $name, 'footer');
}

sub get_str_header {
  my ($self, $name) = @_;

  return $self->store('str', $name, 'header');
}

sub get_str_name {
  my ($self, $name) = @_;

  return $self->store('str', $name, 'name');
}

sub get_str_opt {
  my ($self, $name) = @_;

  return $self->store('str', $name, 'opt');
}

sub get_str_opts {
  my ($self, $name) = @_;

  return $self->store('str', $name, 'opts');
}

sub get_str_version {
  my ($self, $name) = @_;

  return $self->store('str', $name, 'version');
}

sub help {
  my ($self) = @_;

  my @output = ($self->help_usage);

  # description
  if (my $description = $self->help_description) {
    push @output, $description;
  }

  # header
  if (my $header = $self->help_header) {
    push @output, $header;
  }

  # arguments
  if (my $arguments = $self->help_arguments) {
    push @output, $arguments;
  }

  # options
  if (my $options = $self->help_options) {
    push @output, $options;
  }

  # commands
  if (my $commands = $self->help_commands) {
    push @output, $commands;
  }

  # footer
  if (my $footer = $self->help_footer) {
    push @output, $footer;
  }

  return join("\n\n", @output);
}

sub help_arg {
  my ($self, $name) = @_;

  my @result;

  my $data = $self->get('arg', $name) or return ();

  my $_help = $data->{help};
  my $_name = $data->{name};
  my $_range = $data->{range};
  my $_required = $data->{required};
  my $_type = $data->{type};
  my $_multi = $_range && $_range =~ /:/;

  my $note = $_name;

  if ($_multi) {
    $note = "$note, ...";
  }

  push @result, [
    '', $note
  ];

  if ($_help) {
    push @result, [
      _wrap_text(4, 80, [split / /, $_help])
    ];
  }

  if ($_required) {
    push @result, [
      '', '', '(required)'
    ];
  }
  else {
    push @result, [
      '', '', '(optional)'
    ];
  }

  if ($_type) {
    push @result, [
      '', '', "($_type)"
    ];
  }

  return join("\n", map join('  ', @{$_}), @result);
}

sub help_args {
  my ($self) = @_;

  my @result;

  my $order = $self->store('arg_order') || {};

  for my $index (sort keys %{$order}) {
    push @result, $self->help_arg($order->{$index});
  }

  return join("\n\n", @result);
}

sub help_arguments {
  my ($self) = @_;

  my $arguments = $self->help_args or return ();

  return join "\n\n", "Arguments:", $arguments;
}

sub help_author {
  my ($self) = @_;

  return $self->str('author') || ();
}

sub help_cmd {
  my ($self, $name) = @_;

  my @result;

  my $data = $self->get('cmd', $name) or return ();

  my $_help = $data->{help};
  my $_name = $data->{name};

  my $arg = $self->get('arg', $data->{arg})  || {};

  my $_range = $arg->{range};
  my $_required = $arg->{required};
  my $_type = $arg->{type};
  my $_multi = $_range && $_range =~ /:/;

  my $note = $_name;

  if ($_multi) {
    $note = "$note, ...";
  }

  push @result, [
    '', $note
  ];

  if ($_help) {
    push @result, [
      _wrap_text(4, 80, [split / /, $_help])
    ];
  }

  if ($arg->{name}) {
    push @result, [
      '', '', sprintf("(%s)", $arg->{name})
    ];
  }

  return join("\n", map join('  ', @{$_}), @result);
}

sub help_cmds {
  my ($self) = @_;

  my @result;

  my $order = $self->store('cmd_order') || {};

  for my $index (sort keys %{$order}) {
    push @result, $self->help_cmd($order->{$index});
  }

  return join("\n\n", @result);
}

sub help_commands {
  my ($self) = @_;

  my $commands = $self->help_cmds or return ();

  return join "\n\n", "Commands:", $commands;
}

sub help_description {
  my ($self) = @_;

  my $description = $self->str('description') or return ();

  return join "\n", map _wrap_text(0, 80, [split / /, $_]), split /\n/, $description;
}

sub help_footer {
  my ($self) = @_;

  my $footer = $self->str('footer') or return ();

  return join "\n", map _wrap_text(0, 80, [split / /, $_]), split /\n/, $footer;
}

sub help_header {
  my ($self) = @_;

  my $header = $self->str('header') or return ();

  return join "\n", map _wrap_text(0, 80, [split / /, $_]), split /\n/, $header;
}

sub help_name {
  my ($self) = @_;

  return $self->str('name') || 'application';
}

sub help_opt {
  my ($self, $name) = @_;

  my @result;

  my $data = $self->get('opt', $name) or return ();

  my $_alias = $data->{alias};
  my $_help = $data->{help};
  my $_multi = $data->{multi};
  my $_name = $data->{name};
  my $_required = $data->{required};
  my $_type = $data->{type};

  my $note = "--$_name";

  my %type_map = (
    boolean => undef,
    float => 'float',
    number => 'number',
    string => 'string',
    yesno => 'yesno',
  );

  $note = "$note=<$_name>" if $_type && $type_map{$_type};

  if ($_alias) {
    $note = join(', ',
      (map "-$_", (ref $_alias eq 'ARRAY' ? sort @{$_alias} : $_alias)), $note);
  }

  if ($_multi) {
    $note = "$note, ...";
  }

  push @result, [
    '', $note
  ];

  if ($_help) {
    push @result, [
      _wrap_text(4, 80, [split / /, $_help])
    ];
  }

  if ($_required) {
    push @result, [
      '', '', '(required)'
    ];
  }
  else {
    push @result, [
      '', '', '(optional)'
    ];
  }

  if ($_type) {
    push @result, [
      '', '', "($_type)"
    ];
  }

  return join("\n", map join('  ', @{$_}), @result);
}

sub help_options {
  my ($self) = @_;

  my $options = $self->help_opts or return ();

  return join "\n\n", "Options:", $options;
}

sub help_opts {
  my ($self) = @_;

  my @result;

  my $order = $self->store('opt_order') || {};

  for my $index (sort keys %{$order}) {
    push @result, $self->help_opt($order->{$index});
  }

  return join("\n\n", @result);
}

sub help_usage {
  my ($self) = @_;

  my @result;

  my $name = $self->help_name;

  if (my $has_args = $self->get('arg')) {
    my $has_multi = keys(%{$has_args}) > 1 ? 1 : 0;
    my $has_required = 0;

    for my $data (values(%{$has_args})) {
      my $_range = $data->{range};
      my $_required = $data->{required};
      my $_multi = $_range && $_range =~ /:/;

      $has_multi = 1 if $_multi;
      $has_required = 1 if $_required;
    }

    my $token = '<argument>';

    $token = "$token, ..." if $has_multi;
    $token = "[$token]" if !$has_required;

    push @result, $token;
  }

  if (my $has_opts = $self->get('opt')) {
    my $has_multi = keys(%{$has_opts}) > 1 ? 1 : 0;
    my $has_required = 0;

    for my $data (values(%{$has_opts})) {
      my $_range = $data->{range};
      my $_required = $data->{required};
      my $_multi = $_range && $_range =~ /:/;

      $has_multi = 1 if $_multi;
      $has_required = 1 if $_required;
    }

    my $token = '<option>';

    $token = "$token, ..." if $has_multi;
    $token = "[$token]" if !$has_required;

    push @result, $token;
  }

  return join ' ', 'Usage:', $self->help_name, @result;
}

sub help_version {
  my ($self) = @_;

  return $self->str('version') || ();
}

sub okay {
  my ($self, $method, @args) = @_;

  return $self->exit(0, $method, @args);
}

sub opt {
  my ($self, $name) = @_;

  return undef if !$name;

  my @values;

  my $data = $self->get('opt', $name) or return undef;
  my $_default = $data->{default};
  my $_help = $data->{help};
  my $_label = $data->{label};
  my $_multi = $data->{multi};
  my $_name = $data->{name};
  my $_prompt = $data->{prompt};
  my $_required = $data->{required};
  my $_type = $data->{type};

  require Venus::Array;
  require Venus::Unpack;

  my $parsed = $self->parser->get($name);

  # value
  @values = ref $parsed eq 'ARRAY' ? @{$parsed} : $parsed;

  # prompt
  if ($_prompt && (!@values || !defined $values[0])) {
    @values = (do{_print join ': ', $_label || $_name, $_prompt; _prompt}); _print;
  }

  # default
  if (defined $_default
    && (!@values || !defined $values[0] || $values[0] eq '')
    && exists $data->{default})
  {
    @values = ($_default);
  }

  my %type_map = (
    boolean => 'number',
    float => 'float',
    number => 'number',
    string => 'string',
    yesno => 'yesno',
  );

  # type
  if ($_type) {
    my ($caught, @values) = Venus::Unpack->new(args => [@values])->all->catch(
      'validate', $type_map{$_type}
    );
    $self->throw('error_on_opt_validation', $caught->message, $_name, $_type)->error
      if $caught;
  }

  # return boolean values
  @values = map +(lc($_type) eq 'boolean' ? ($_ ? true : false) : $_), @values
    if $_type;

  # returns
  return wantarray ? (@values) : [@values];
}

sub parsed {
  my ($self) = @_;

  my $data = {};

  my $args = $self->store('arg') || {};

  for my $key (keys %{$args}) {
    my @values = $self->arg($key);
    $data->{$key} = @values > 1 ? [@values] : $values[0];
  }

  my $opts = $self->store('opt') || {};

  for my $key (keys %{$opts}) {
    my @values = $self->opt($key);
    $data->{$key} = @values > 1 ? [@values] : $values[0];
  }

  return $data;
}

sub parser {
  my ($self) = @_;

  require Venus::Opts;

  return Venus::Opts->new(value => $self->data, specs => $self->spec);
}

sub set {
  my ($self, $key, $name, $data) = @_;

  return undef if !$key;

  my $method = "set_${key}";

  return $self->$method($name, $data);
}

sub set_arg {
  my ($self, $name, $data) = @_;

  $self->set_arg_name($name, $name);

  do{my $method = "set_arg_$_"; $self->$method($name, $data->{$_})}
    for keys %{$data};

  my $store = $self->store;

  $store->{arg_order} ||= {};

  my $index = keys %{$store->{arg_order}} || 0;

  $store->{arg_order}->{$index} = $name;

  return $self;
}

sub set_arg_default {
  my ($self, $name, @args) = @_;

  return $self->store('arg', $name, 'default', @args);
}

sub set_arg_help {
  my ($self, $name, @args) = @_;

  return $self->store('arg', $name, 'help', @args);
}

sub set_arg_label {
  my ($self, $name, @args) = @_;

  return $self->store('arg', $name, 'label', @args);
}

sub set_arg_name {
  my ($self, $name, @args) = @_;

  return $self->store('arg', $name, 'name', @args);
}

sub set_arg_prompt {
  my ($self, $name, @args) = @_;

  return $self->store('arg', $name, 'prompt', @args);
}

sub set_arg_range {
  my ($self, $name, @args) = @_;

  return $self->store('arg', $name, 'range', @args);
}

sub set_arg_required {
  my ($self, $name, @args) = @_;

  return $self->store('arg', $name, 'required', @args);
}

sub set_arg_type {
  my ($self, $name, @args) = @_;

  my %type_map = (
    boolean => 'boolean',
    flag => 'boolean',
    float => 'float',
    number => 'number',
    string => 'string',
    yesno => 'yesno',
  );

  return $self->store('arg', $name, 'type', map +($type_map{$_} || 'boolean'),
    @args);
}

sub set_cmd {
  my ($self, $name, $data) = @_;

  $self->set_cmd_name($name, $name);

  $self->store('cmd', $name, $_, $data->{$_}) for keys %{$data};

  my $store = $self->store;

  $store->{cmd_order} ||= {};

  my $index = keys %{$store->{cmd_order}} || 0;

  $store->{cmd_order}->{$index} = $name;

  return $self;
}

sub set_cmd_arg {
  my ($self, $name, @args) = @_;

  return $self->store('cmd', $name, 'arg', @args);
}

sub set_cmd_help {
  my ($self, $name, @args) = @_;

  return $self->store('cmd', $name, 'help', @args);
}

sub set_cmd_label {
  my ($self, $name, @args) = @_;

  return $self->store('cmd', $name, 'label', @args);
}

sub set_cmd_name {
  my ($self, $name, @args) = @_;

  return $self->store('cmd', $name, 'name', @args);
}

sub set_opt {
  my ($self, $name, $data) = @_;

  $self->set_opt_name($name, $name);

  do{my $method = "set_opt_$_"; $self->$method($name, $data->{$_})}
    for keys %{$data};

  my $store = $self->store;

  $store->{opt_order} ||= {};

  my $index = keys %{$store->{opt_order}} || 0;

  $store->{opt_order}->{$index} = $name;

  return $self;
}

sub set_opt_alias {
  my ($self, $name, @args) = @_;

  return $self->store('opt', $name, 'alias', @args);
}

sub set_opt_default {
  my ($self, $name, @args) = @_;

  return $self->store('opt', $name, 'default', @args);
}

sub set_opt_help {
  my ($self, $name, @args) = @_;

  return $self->store('opt', $name, 'help', @args);
}

sub set_opt_label {
  my ($self, $name, @args) = @_;

  return $self->store('opt', $name, 'label', @args);
}

sub set_opt_multi {
  my ($self, $name, @args) = @_;

  return $self->store('opt', $name, 'multi', @args ? true : false);
}

sub set_opt_name {
  my ($self, $name, @args) = @_;

  return $self->store('opt', $name, 'name', @args);
}

sub set_opt_prompt {
  my ($self, $name, @args) = @_;

  return $self->store('opt', $name, 'prompt', @args);
}

sub set_opt_required {
  my ($self, $name, @args) = @_;

  return $self->store('opt', $name, 'required', @args);
}

sub set_opt_type {
  my ($self, $name, @args) = @_;

  my %type_map = (
    boolean => 'boolean',
    flag => 'boolean',
    float => 'float',
    number => 'number',
    string => 'string',
    yesno => 'yesno',
  );

  return $self->store('opt', $name, 'type', map +($type_map{$_} || 'boolean'),
    @args);
}

sub set_str {
  my ($self, $name, $data) = @_;

  $self->store('str', $name, 'value', $data);

  return $self;
}

sub set_str_arg {
  my ($self, $name, @args) = @_;

  return $self->store('str', $name, 'arg', @args);
}

sub set_str_author {
  my ($self, $name, @args) = @_;

  return $self->store('str', $name, 'author', @args);
}

sub set_str_description {
  my ($self, $name, @args) = @_;

  return $self->store('str', $name, 'description', @args);
}

sub set_str_footer {
  my ($self, $name, @args) = @_;

  return $self->store('str', $name, 'footer', @args);
}

sub set_str_header {
  my ($self, $name, @args) = @_;

  return $self->store('str', $name, 'header', @args);
}

sub set_str_name {
  my ($self, $name, @args) = @_;

  return $self->store('str', $name, 'name', @args);
}

sub set_str_opt {
  my ($self, $name, @args) = @_;

  return $self->store('str', $name, 'opt', @args);
}

sub set_str_opts {
  my ($self, $name, @args) = @_;

  return $self->store('str', $name, 'opts', @args);
}

sub set_str_version {
  my ($self, $name, @args) = @_;

  return $self->store('str', $name, 'version', @args);
}

sub spec {
  my ($self) = @_;

  my $result = [];

  my $order = $self->store('opt_order') || {};

  for my $index (sort keys %{$order}) {
    my $item = $self->store('opt', $order->{$index}) or next;
    my $_alias = $item->{alias};
    my $_multi = $item->{multi};
    my $_name = $item->{name};
    my $_type = $item->{type};

    my $note = "$_name";

    if ($_alias) {
      $note = join('|', $note,
        (ref $_alias eq 'ARRAY' ? sort @{$_alias} : $_alias));
    }

    my %type_map = (
      boolean => undef,
      float => 'f',
      number => 'i',
      string => 's',
      yesno => 's',
    );

    $note = join '=', $note, ($type_map{$_type} || ()) if $_type;
    $note = "$note\@" if $_multi;

    push @{$result}, $note;
  }

  return $result;
}

sub store {
  my ($self, $key, $name, @args) = @_;

  my $config = $self->stash->{config} ||= {};

  return $config if !$key;

  return $config->{$key} if !$name;

  return ((exists $config->{$key})
      && (exists $config->{$key}->{$name}))
    ? $config->{$key}->{$name}
    : undef
    if !@args;

  my ($prop, @data) = @args;

  return ((exists $config->{$key})
      && (exists $config->{$key}->{$name})
      && (exists $config->{$key}->{$name}->{$prop}))
    ? $config->{$key}->{$name}->{$prop}
    : undef
    if !@data;

  $config->{$key} ||= {};

  $config->{$key}->{$name} ||= {};

  $config->{$key}->{$name}->{$prop} = $data[0];

  return $self;
}

sub str {
  my ($self, $name) = @_;

  return undef if !$name;

  return $self->get_str($name);
}

# ROUTINES

sub _wrap_text {
  my ($indent, $length, $parts) = @_;

  my @results;
  my $size = 0;
  my $index = 0;

  for my $part (@{$results[$index]}) {
    $size += length($part) + 1 + $indent;
  }
  for my $part (@{$parts}) {
    if (($size + length($part) + 1 + $indent) > $length) {
      $index += 1;
      $size = length($part);
      $results[$index] = [];
    }
    else {
      $size += length($part) + 1;
    }
    push @{$results[$index]}, $part;
  }

  return join "\n",
    map {($indent ? (" " x $indent) : '') . join " ", @{$_}} @results;
}

# ERRORS

sub error_on_arg_validation {
  my ($self, $error, $name, $type) = @_;

  return {
    name => 'on.arg.validation',
    message => (join ': ', 'Invalid argument', $name, $error),
    stash => {
      name => $name,
      type => $type,
    },
  };
}

sub error_on_opt_validation {
  my ($self, $error, $name, $type) = @_;

  return {
    name => 'on.opt.validation',
    message => (join ': ', 'Invalid option', $name, $error),
    stash => {
      name => $name,
      type => $type,
    },
  };
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

  my $cli = Venus::Cli->new(['--help']);

  $cli->set('opt', 'help', {
    help => 'Show help information',
  });

  # $cli->opt('help');

  # [1]

  # $cli->data;

  # {help => 1}

=cut

=head1 DESCRIPTION

This package provides a superclass and methods for creating simple yet robust
command-line interfaces.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 data

  data(ArrayRef $data) (ArrayRef)

The data attribute holds an arrayref of command-line arguments and defaults to
C<@ARGV>.

I<Since C<2.55>>

=over 4

=item data example 1

  # given: synopsis

  package main;

  my $data = $cli->data([]);

  # []

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Stashable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 arg

  arg(Str $name) (Any)

The arg method returns the value passed to the CLI that corresponds to the
registered argument using the name provided.

I<Since C<2.55>>

=over 4

=item arg example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', '--help']);

  my $name = $cli->arg('name');

  # undef

=back

=over 4

=item arg example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', '--help']);

  $cli->set('arg', 'name', {
    range => '0',
  });

  my $name = $cli->arg('name');

  # ["example"]

=back

=over 4

=item arg example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', '--help']);

  $cli->set('arg', 'name', {
    range => '0',
  });

  my ($name) = $cli->arg('name');

  # "example"

=back

=over 4

=item arg example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['--help']);

  $cli->set('arg', 'name', {
    prompt => 'Enter a name',
    range => '0',
  });

  my ($name) = $cli->arg('name');

  # prompts for name, e.g.

  # > name: Enter a name
  # > example

  # "example"

=back

=over 4

=item arg example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['--help']);

  $cli->set('arg', 'name', {
    default => 'example',
    range => '0',
  });

  my ($name) = $cli->arg('name');

  # "example"

=back

=over 4

=item arg example 6

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', '--help']);

  $cli->set('arg', 'name', {
    type => 'string',
    range => '0',
  });

  my ($name) = $cli->arg('name');

  # "example"

=back

=over 4

=item arg example 7

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['--help']);

  $cli->set('arg', 'name', {
    type => 'string',
    range => '0',
  });

  my ($name) = $cli->arg('name');

  # Exception! (isa Venus::Cli::Error) (see error_on_arg_validation)

  # Invalid argument: name: received (undef), expected (string)

=back

=cut

=head2 cmd

  cmd(Str $name) (Any)

The cmd method returns truthy or falsy if the value passed to the CLI that
corresponds to the argument registered and associated with the registered
command using the name provided.

I<Since C<2.55>>

=over 4

=item cmd example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', 'execute']);

  my $name = $cli->cmd('name');

  # undef

=back

=over 4

=item cmd example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', 'execute']);

  $cli->set('arg', 'action', {
    range => '1',
  });

  $cli->set('cmd', 'execute', {
    arg => 'action',
  });

  my $is_execute = $cli->cmd('execute');

  # 1

=back

=over 4

=item cmd example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', 'execute']);

  $cli->set('arg', 'action', {
    range => '1',
  });

  $cli->set('cmd', 'execute', {
    arg => 'action',
  });

  my ($is_execute) = $cli->cmd('execute');

  # 1

=back

=over 4

=item cmd example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example']);

  $cli->set('arg', 'action', {
    prompt => 'Enter the desired action',
    range => '1',
  });

  $cli->set('cmd', 'execute', {
    arg => 'action',
  });

  my ($is_execute) = $cli->cmd('execute');

  # prompts for action, e.g.

  # > name: Enter the desired action
  # > execute

  # 1

=back

=over 4

=item cmd example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example']);

  $cli->set('arg', 'action', {
    default => 'execute',
    range => '1',
  });

  $cli->set('cmd', 'execute', {
    arg => 'action',
  });

  my ($is_execute) = $cli->cmd('execute');

  # 1

=back

=over 4

=item cmd example 6

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', 'execute']);

  $cli->set('arg', 'action', {
    type => 'string',
    range => '1',
  });

  $cli->set('cmd', 'execute', {
    arg => 'action',
  });

  my ($is_execute) = $cli->cmd('execute');

  # 1

=back

=over 4

=item cmd example 7

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example']);

  $cli->set('arg', 'action', {
    type => 'string',
    range => '1',
  });

  $cli->set('cmd', 'execute', {
    arg => 'action',
  });

  my ($is_execute) = $cli->cmd('execute');

  # 0

=back

=cut

=head2 exit

  exit(Int $code, Str|CodeRef $code, Any @args) (Any)

The exit method exits the program using the exit code provided. The exit code
defaults to C<0>. Optionally, you can dispatch before exiting by providing a
method name or coderef, and arguments.

I<Since C<2.55>>

=over 4

=item exit example 1

  # given: synopsis

  package main;

  my $exit = $cli->exit;

  # ()

=back

=over 4

=item exit example 2

  # given: synopsis

  package main;

  my $exit = $cli->exit(0);

  # ()

=back

=over 4

=item exit example 3

  # given: synopsis

  package main;

  my $exit = $cli->exit(1);

  # ()

=back

=over 4

=item exit example 4

  # given: synopsis

  package main;

  my $exit = $cli->exit(1, 'stash', 'executed', 1);

  # ()

=back

=cut

=head2 fail

  fail(Str|CodeRef $code, Any @args) (Any)

The fail method exits the program with the exit code C<1>. Optionally, you can
dispatch before exiting by providing a method name or coderef, and arguments.

I<Since C<2.55>>

=over 4

=item fail example 1

  # given: synopsis

  package main;

  my $fail = $cli->fail;

  # ()

=back

=over 4

=item fail example 2

  # given: synopsis

  package main;

  my $fail = $cli->fail('stash', 'executed', 1);

  # ()

=back

=cut

=head2 get

  get(Str $type, Str $name) (Any)

The get method returns C<arg>, C<opt>, C<cmd>, or C<str> configuration values
from the configuration database.

I<Since C<2.55>>

=over 4

=item get example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $get = $cli->get;

  # undef

=back

=over 4

=item get example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $get = $cli->get('opt', 'help');

  # undef

=back

=over 4

=item get example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  $cli->set('opt', 'help', {
    alias => 'h',
  });

  my $get = $cli->get('opt', 'help');

  # {name => 'help', alias => 'h'}

=back

=over 4

=item get example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  $cli->set('opt', 'help', {
    alias => 'h',
  });

  my $get = $cli->get('opt');

  # {help => {name => 'help', alias => 'h'}}

=back

=cut

=head2 help

  help() (Str)

The help method returns a string representing I<"usage"> information based on
the configuration of the CLI.

I<Since C<2.55>>

=over 4

=item help example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $help = $cli->help;

  # "Usage: application"

=back

=over 4

=item help example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  $cli->set('str', 'name', 'program');

  my $help = $cli->help;

  # "Usage: program"

=back

=over 4

=item help example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  $cli->set('str', 'name', 'program');

  $cli->set('arg', 'command', {
    help => 'Command to execute',
  });

  my $help = $cli->help;

  # "Usage: program [<argument>]
  #
  # Arguments:
  #
  #   command
  #     Command to execute
  #     (optional)"

=back

=over 4

=item help example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  $cli->set('str', 'name', 'program');

  $cli->set('arg', 'command', {
    help => 'Command to execute',
    required => 1
  });

  my $help = $cli->help;

  # "Usage: program <argument>
  #
  # Arguments:
  #
  #   command
  #     Command to execute
  #     (required)"

=back

=over 4

=item help example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  $cli->set('str', 'name', 'program');

  $cli->set('arg', 'command', {
    help => 'Command to execute',
    type => 'string',
    required => 1,
  });

  my $help = $cli->help;

  # "Usage: program <argument>
  #
  # Arguments:
  #
  #   command
  #     Command to execute
  #     (required)
  #     (string)"

=back

=over 4

=item help example 6

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  $cli->set('str', 'name', 'program');

  $cli->set('arg', 'command', {
    help => 'Command to execute',
    required => 1,
  });

  $cli->set('cmd', 'create', {
    help => 'Create new resource',
    arg => 'command',
  });

  my $help = $cli->help;

  # "Usage: program <argument>
  #
  # Arguments:
  #
  #   command
  #     Command to execute
  #     (required)
  #
  # Commands:
  #
  #   create
  #     Create new resource
  #     (ccommand)"

=back

=over 4

=item help example 7

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  $cli->set('str', 'name', 'program');

  $cli->set('arg', 'command', {
    help => 'Command to execute',
    required => 1,
  });

  $cli->set('opt', 'help', {
    help => 'Show help information',
    alias => ['?', 'h'],
  });

  $cli->set('cmd', 'create', {
    help => 'Create new resource',
    arg => 'command',
  });

  my $help = $cli->help;

  # "Usage: program <argument> [<option>]
  #
  # Arguments:
  #
  #   command
  #     Command to execute
  #     (required)
  #
  # Options:
  #
  #   -?, -h, --help
  #     Show help information
  #     (optional)
  #
  # Commands:
  #
  #   create
  #     Create new resource
  #     (command)"

=back

=over 4

=item help example 8

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  $cli->set('str', 'name', 'program');

  $cli->set('arg', 'files', {
    help => 'File paths',
    required => 1,
    range => '0:',
  });

  $cli->set('opt', 'verbose', {
    help => 'Show details during processing',
    alias => ['v'],
  });

  my $help = $cli->help;

  # "Usage: program <argument>, ... [<option>]
  #
  # Arguments:
  #
  #   files, ...
  #     File paths
  #     (required)
  #
  # Options:
  #
  #   -v, --verbose
  #     Show details during processing
  #     (optional)"

=back

=cut

=head2 okay

  okay(Str|CodeRef $code, Any @args) (Any)

The okay method exits the program with the exit code C<0>. Optionally, you can
dispatch before exiting by providing a method name or coderef, and arguments.

I<Since C<2.55>>

=over 4

=item okay example 1

  # given: synopsis

  package main;

  my $okay = $cli->okay;

  # ()

=back

=over 4

=item okay example 2

  # given: synopsis

  package main;

  my $okay = $cli->okay('stash', 'executed', 1);

  # ()

=back

=cut

=head2 opt

  opt(Str $name) (Any)

The opt method returns the value passed to the CLI that corresponds to the
registered option using the name provided.

I<Since C<2.55>>

=over 4

=item opt example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', '--help']);

  my $name = $cli->opt('help');

  # undef

=back

=over 4

=item opt example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', '--help']);

  $cli->set('opt', 'help', {});

  my $name = $cli->opt('help');

  # [1]

=back

=over 4

=item opt example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', '--help']);

  $cli->set('opt', 'help', {});

  my ($name) = $cli->opt('help');

  # 1

=back

=over 4

=item opt example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new([]);

  $cli->set('opt', 'name', {
    prompt => 'Enter a name',
    type => 'string',
    multi => 0,
  });

  my ($name) = $cli->opt('name');

  # prompts for name, e.g.

  # > name: Enter a name
  # > example

  # "example"

=back

=over 4

=item opt example 5

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['--name', 'example']);

  $cli->set('opt', 'name', {
    prompt => 'Enter a name',
    type => 'string',
    multi => 0,
  });

  my ($name) = $cli->opt('name');

  # Does not prompt

  # "example"

=back

=over 4

=item opt example 6

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', '--name', 'example', '--name', 'example']);

  $cli->set('opt', 'name', {
    type => 'string',
    multi => 1,
  });

  my (@name) = $cli->opt('name');

  # ("example", "example")

=back

=over 4

=item opt example 7

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', '--name', 'example']);

  $cli->set('opt', 'name', {
    type => 'number',
    multi => 1,
  });

  my ($name) = $cli->opt('name');

  # Exception! (isa Venus::Cli::Error) (see error_on_opt_validation)

  # Invalid option: name: received (undef), expected (number)

=back

=cut

=head2 parsed

  parsed() (HashRef)

The parsed method returns the values provided to the CLI for all registered
arguments and options as a hashref.

I<Since C<2.55>>

=over 4

=item parsed example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(['example', '--help']);

  $cli->set('arg', 'name', {
    range => '0',
  });

  $cli->set('opt', 'help', {
    alias => 'h',
  });

  my $parsed = $cli->parsed;

  # {name => "example", help => 1}

=back

=cut

=head2 parser

  parser() (Opts)

The parser method returns a L<Venus::Opts> object using the L</spec> returned
based on the CLI configuration.

I<Since C<2.55>>

=over 4

=item parser example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  $cli->set('opt', 'help', {
    help => 'Show help information',
    alias => 'h',
  });

  my $parser = $cli->parser;

  # bless({...}, 'Venus::Opts')

=back

=cut

=head2 set

  set(Str $type, Str $name, Str|HashRef $data) (Any)

The set method stores configuration values for C<arg>, C<opt>, C<cmd>, or
C<str> data in the configuration database, and returns the invocant.

The following are configurable C<arg> properties:

=over 4

=item *

The C<default> property specifies the "default" value to be used if none is
provided.

=item *

The C<help> property specifies the help text to output in usage instructions.

=item *

The C<label> property specifies the label text to output in usage instructions.

=item *

The C<name> property specifies the name of the argument.

=item *

The C<prompt> property specifies the text to be used in a prompt for input if
no value is provided.

=item *

The C<range> property specifies the zero-indexed position where the CLI
arguments can be found, using range notation.

=item *

The C<required> property specifies whether the argument is required and throws
an exception is missing when fetched.

=item *

The C<type> property specifies the data type of the argument. Valid types are
C<number> parsed as a L<Getopt::Long> integer, C<string> parsed as a
L<Getopt::Long> string, C<float> parsed as a L<Getopt::Long> float, C<boolean>
parsed as a L<Getopt::Long> flag, or C<yesno> parsed as a L<Getopt::Long>
string. Otherwise, the type will default to C<boolean>.

=back

The following are configurable C<cmd> properties:

=over 4

=item *

The C<arg> property specifies the CLI argument where the command can be found.

=item *

The C<help> property specifies the help text to output in usage instructions.

=item *

The C<label> property specifies the label text to output in usage instructions.

=item *

The C<name> property specifies the name of the command.

=back

The following are configurable C<opt> properties:

=over 4

=item *

The C<alias> property specifies the alternate identifiers that can be provided.

=item *

The C<default> property specifies the "default" value to be used if none is
provided.

=item *

The C<help> property specifies the help text to output in usage instructions.

=item *

The C<label> property specifies the label text to output in usage instructions.

=item *

The C<multi> property denotes whether the CLI will accept multiple occurrences
of the option.

=item *

The C<name> property specifies the name of the option.

=item *

The C<prompt> property specifies the text to be used in a prompt for input if
no value is provided.

=item *

The C<required> property specifies whether the option is required and throws an
exception is missing when fetched.

=item *

The C<type> property specifies the data type of the option. Valid types are
C<number> parsed as a L<Getopt::Long> integer, C<string> parsed as a
L<Getopt::Long> string, C<float> parsed as a L<Getopt::Long> float, C<boolean>
parsed as a L<Getopt::Long> flag, or C<yesno> parsed as a L<Getopt::Long>
string. Otherwise, the type will default to C<boolean>.

=back

I<Since C<2.55>>

=over 4

=item set example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $set = $cli->set;

  # undef

=back

=over 4

=item set example 2

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $set = $cli->set('opt', 'help');

  # bless({...}, 'Venus::Cli')

=back

=over 4

=item set example 3

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $set = $cli->set('opt', 'help', {
    alias => 'h',
  });

  # bless({...}, 'Venus::Cli')

=back

=over 4

=item set example 4

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $set = $cli->set('opt', 'help', {
    alias => ['?', 'h'],
  });

  # bless({...}, 'Venus::Cli')

=back

=cut

=head2 str

  str(Str $name) (Any)

The str method gets or sets configuration strings used in CLI help text based
on the arguments provided. The L</help> method uses C<"name">,
C<"description">, C<"header">, and C<"footer"> strings.

I<Since C<2.55>>

=over 4

=item str example 1

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  $cli->set('str', 'name', 'program');

  my $str = $cli->str('name');

  # "program"

=back

=cut

=head1 ERRORS

This package may raise the following errors:

=cut

=over 4

=item error: C<error_on_arg_validation>

This package may raise an error_on_arg_validation exception.

B<example 1>

  # given: synopsis;

  my @args = ("...", "example", "string");

  my $error = $cli->throw('error_on_arg_validation', @args)->catch('error');

  # my $name = $error->name;

  # "on_arg_validation"

  # my $message = $error->message;

  # "Invalid argument: example: ..."

  # my $name = $error->stash('name');

  # "example"

  # my $type = $error->stash('type');

  # "string"

=back

=over 4

=item error: C<error_on_opt_validation>

This package may raise an error_on_opt_validation exception.

B<example 1>

  # given: synopsis;

  my @args = ("...", "example", "string");

  my $error = $cli->throw('error_on_opt_validation', @args)->catch('error');

  # my $name = $error->name;

  # "on_opt_validation"

  # my $message = $error->message;

  # "Invalid option: example: ..."

  # my $name = $error->stash('name');

  # "example"

  # my $type = $error->stash('type');

  # "string"

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut