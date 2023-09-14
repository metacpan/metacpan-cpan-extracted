package Venus::Test;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind';

with 'Venus::Role::Buildable';

use Test::More ();

use Exporter 'import';

our @EXPORT = 'test';

# ATTRIBUTES

attr 'file';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    file => $data,
  };
}

sub build_self {
  my ($self, $data) = @_;

  return $self if !$self->file;

  for my $name (qw(name abstract tagline synopsis description)) {
    $self->error({throw => "error_on_$name"}) if !$self->data->count({
      name => $name,
      list => undef,
    });
  }

  return $self;
}

# FUNCTIONS

sub test {
  Venus::Test->new($_[0]);
}

# METHODS

sub collect {
  my ($self, $name, @args) = @_;

  my $method = "collect_data_for_$name";

  return $self->$method(@args);
}

sub collect_data_for_abstract {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'abstract');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_attribute {
  my ($self, $name) = @_;

  my ($find) = $self->data->find('attribute', $name);

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_attributes {
  my ($self, $name) = @_;

  my ($find) = $self->data->find(undef, 'attributes');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_authors {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'authors');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_description {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'description');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_encoding {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'encoding');

  my $data = $find ? $find->{data} : [];

  @{$data} = (map {map uc, split /\r?\n+/} @{$data});

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_error {
  my ($self, $name) = @_;

  my ($find) = $self->data->find('error', $name);

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_example {
  my ($self, $number, $name) = @_;

  my ($find) = $self->data->find("example-$number", $name);

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_feature {
  my ($self, $name) = @_;

  my ($find) = $self->data->find('feature', $name);

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_function {
  my ($self, $name) = @_;

  my ($find) = $self->data->find('function', $name);

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_includes {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'includes');

  my $data = $find ? $find->{data} : [];

  @{$data} = grep !/^#/, grep /\w/, map {split/\n/} @{$data};

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_inherits {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'inherits');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_integrates {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'integrates');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_layout {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'layout');

  my $data = $find ? $find->{data} : [
    'encoding',
    'name',
    'abstract',
    'version',
    'synopsis',
    'description',
    'attributes: attribute',
    'inherits',
    'integrates',
    'libraries',
    'functions: function',
    'methods: method',
    'messages: message',
    'features: feature',
    'errors: error',
    'operators: operator',
    'partials',
    'authors',
    'license',
    'project',
  ];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_libraries {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'libraries');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_license {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'license');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_message {
  my ($self, $name) = @_;

  my ($find) = $self->data->find('message', $name);

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_metadata {
  my ($self, $name) = @_;

  my ($find) = $self->data->find('metadata', $name);

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_method {
  my ($self, $name) = @_;

  my ($find) = $self->data->find('method', $name);

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_name {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'name');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_operator {
  my ($self, $name) = @_;

  my ($find) = $self->data->find('operator', $name);

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_partials {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'partials');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_project {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'project');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_signature {
  my ($self, $name) = @_;

  my ($find) = $self->data->find('signature', $name);

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_synopsis {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'synopsis');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_tagline {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'tagline');

  my $data = $find ? $find->{data} : [];

  return wantarray ? (@{$data}) : $data;
}

sub collect_data_for_version {
  my ($self) = @_;

  my ($find) = $self->data->find(undef, 'version');

  my $data = $find ? $find->{data} : [];

  require Venus::Space;

  if (!@{$data} && (my ($name) = $self->collect('name'))) {
    @{$data} = (Venus::Space->new($name)->version) || ();
  }

  return wantarray ? (@{$data}) : $data;
}

sub diag {
  my ($self, @args) = @_;

  return $self->more('diag', $self->explain(@args));
}

sub data {
  my ($self) = @_;

  require Venus::Data;

  $self->{data} ||= Venus::Data->new($self->file);

  return $self->{data};
}

sub done {
  my ($self) = @_;

  return $self->more('done_testing');
}

sub eval {
  my ($self, $perl) = @_;

  local $@;

  my @result = CORE::eval(join("\n\n", "no warnings q(redefine);", $perl));

  my $dollarat = $@;

  die $dollarat if $dollarat;

  return wantarray ? (@result) : $result[0];
}

sub execute {
  my ($self, $name, @args) = @_;

  my $method = "execute_test_for_$name";

  return $self->$method(@args);
}

sub execute_test_for_abstract {
  my ($self, $code) = @_;

  my $data = $self->collect('abstract');

  my $result = $self->perform('abstract', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=abstract');

  return $result;
}

sub execute_test_for_attribute {
  my ($self, $name, $code) = @_;

  my $data = $self->collect('attribute', $name);

  my $result = $self->perform('attribute', $name, $data);

  $result = $code->($data) if $code;

  $self->pass($result, "=attribute $name");

  return $result;
}

sub execute_test_for_attributes {
  my ($self, $code) = @_;

  my $data = $self->collect('attributes');

  my $result = $self->perform('attributes', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=attributes');

  my ($package) = $self->collect('name');

  for my $line (@{$data}) {
    next if !$line;

    my ($name, $is, $pre, $isa, $def) = map { split /,\s*/ } split /:\s*/,
      $line, 2;

    $self->pass($package->can($name), "$package has $name");
    $self->pass((($is eq 'ro' || $is eq 'rw')
        && ($pre eq 'opt' || $pre eq 'req')
        && $isa), $line);
  }

  return $result;
}

sub execute_test_for_authors {
  my ($self, $code) = @_;

  my $data = $self->collect('authors');

  my $result = $self->perform('authors', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=authors');

  return $result;
}

sub execute_test_for_description {
  my ($self, $code) = @_;

  my $data = $self->collect('description');

  my $result = $self->perform('description', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=description');

  return $result;
}

sub execute_test_for_encoding {
  my ($self, $code) = @_;

  my $data = $self->collect('encoding');

  my $result = $self->perform('encoding', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=encoding');

  return $result;
}

sub execute_test_for_error {
  my ($self, $name, $code) = @_;

  my $data = $self->collect('error', $name);

  my $result = $self->perform('error', $name, $data);

  $result = $code->($data) if $code;

  $self->pass($result, "=error $name");

  return $result;
}

sub execute_test_for_example {
  my ($self, $number, $name, $code) = @_;

  my $data = $self->collect('example', $number, $name);

  my $text = join "\n\n", @{$data};

  my @includes;

  if ($text =~ /.*#\s*given:\s*synopsis/m) {
    my $line = $&;
    if ($line !~ /#.*#\s*given:\s*synopsis/) {
      push @includes, $self->collect('synopsis');
    }
  }

  for my $given ($text =~ /.*#\s*given:\s*example-((?:\d+)\s+(?:[\-\w]+))/gm) {
    my $line = $&;
    if ($line !~ /#.*#\s*given:\s*example-(?:\d+)\s+(?:[\-\w]+)/) {
      my ($number, $name) = split /\s+/, $given, 2;
      push @includes, $self->collect('example', $number, $name);
    }
  }

  $text =~ s/.*#\s*given:\s*.*\n\n*//g;
  $text = join "\n\n", @includes, $text;

  my $result = $self->perform('example', $number, $name, $data);

  $self->pass($result, "=example-$number $name");

  $result = $code->($self->try('eval', $text)) if $code;

  $self->pass($result, "=example-$number $name returns ok") if $code;

  return $result;
}

sub execute_test_for_feature {
  my ($self, $name, $code) = @_;

  my $data = $self->collect('feature', $name);

  my $result = $self->perform('feature', $name, $data);

  $result = $code->($data) if $code;

  $self->pass($result, "=feature $name");

  return $result;
}

sub execute_test_for_function {
  my ($self, $name, $code) = @_;

  my $data = $self->collect('function', $name);

  my $result = $self->perform('function', $name, $data);

  $result = $code->($data) if $code;

  $self->pass($result, "=function $name");

  return $result;
}

sub execute_test_for_includes {
  my ($self, $code) = @_;

  my $data = $self->collect('includes');

  my $result = $self->perform('includes', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=includes');

  return $result;
}

sub execute_test_for_inherits {
  my ($self, $code) = @_;

  my $data = $self->collect('inherits');

  my $result = $self->perform('inherits', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=inherits');

  return $result;
}

sub execute_test_for_integrates {
  my ($self, $code) = @_;

  my $data = $self->collect('integrates');

  my $result = $self->perform('integrates', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=integrates');

  return $result;
}

sub execute_test_for_layout {
  my ($self, $code) = @_;

  my $data = $self->collect('layout');

  my $result = $self->perform('layout', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=layout');

  return $result;
}

sub execute_test_for_libraries {
  my ($self, $code) = @_;

  my $data = $self->collect('libraries');

  my $result = $self->perform('libraries', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=libraries');

  return $result;
}

sub execute_test_for_license {
  my ($self, $code) = @_;

  my $data = $self->collect('license');

  my $result = $self->perform('license', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=license');

  return $result;
}

sub execute_test_for_message {
  my ($self, $name, $code) = @_;

  my $data = $self->collect('message', $name);

  my $result = $self->perform('message', $name, $data);

  $result = $code->($data) if $code;

  $self->pass($result, "=message $name");

  return $result;
}

sub execute_test_for_metadata {
  my ($self, $name, $code) = @_;

  my $data = $self->collect('metadata', $name);

  my $result = $self->perform('metadata', $name, $data);

  $result = $code->($data) if $code;

  $self->pass($result, "=metadata $name");

  return $result;
}

sub execute_test_for_method {
  my ($self, $name, $code) = @_;

  my $data = $self->collect('method', $name);

  my $result = $self->perform('method', $name, $data);

  $result = $code->($data) if $code;

  $self->pass($result, "=method $name");

  return $result;
}

sub execute_test_for_name {
  my ($self, $code) = @_;

  my $data = $self->collect('name');

  my $result = $self->perform('name', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=name');

  return $result;
}

sub execute_test_for_operator {
  my ($self, $name, $code) = @_;

  my $data = $self->collect('operator', $name);

  my $result = $self->perform('operator', $name, $data);

  $result = $code->($data) if $code;

  $self->pass($result, "=operator $name");

  return $result;
}

sub execute_test_for_partials {
  my ($self, $code) = @_;

  my $data = $self->collect('partials');

  my $result = $self->perform('partials', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=partials');

  return $result;
}

sub execute_test_for_project {
  my ($self, $code) = @_;

  my $data = $self->collect('project');

  my $result = $self->perform('project', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=project');

  return $result;
}

sub execute_test_for_signature {
  my ($self, $name, $code) = @_;

  my $data = $self->collect('signature', $name);

  my $result = $self->perform('signature', $name, $data);

  $result = $code->($data) if $code;

  $self->pass($result, "=signature $name");

  return $result;
}

sub execute_test_for_synopsis {
  my ($self, $code) = @_;

  my $data = $self->collect('synopsis');

  my $text = join "\n\n", @{$data};

  my @includes;

  for my $given ($text =~ /.*#\s*given:\s*example-((?:\d+)\s+(?:[\-\w]+))/gm) {
    my $line = $&;
    if ($line !~ /#.*#\s*given:\s*example-(?:\d+)\s+(?:[\-\w]+)/) {
      my ($number, $name) = split /\s+/, $given, 2;
      push @includes, $self->collect('example', $number, $name);
    }
  }

  $text =~ s/.*#\s*given:\s*.*\n\n*//g;
  $text = join "\n\n", @includes, $text;

  my $result = $self->perform('synopsis', $data);

  $self->pass($result, "=synopsis");

  $result = $code->($self->try('eval', $text)) if $code;

  $self->pass($result, "=synopsis returns ok") if $code;

  return $result;
}

sub execute_test_for_tagline {
  my ($self, $code) = @_;

  my $data = $self->collect('tagline');

  my $result = $self->perform('tagline', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=tagline');

  return $result;
}

sub execute_test_for_version {
  my ($self, $code) = @_;

  my $data = $self->collect('version');

  my $result = $self->perform('version', $data);

  $result = $code->($data) if $code;

  $self->pass($result, '=version');

  return $result;
}

sub explain {
  my ($self, @args) = @_;

  return join ' ', map {s/^\s+|\s+$//gr} map {$self->more('explain', $_)} @args;
}

sub fail {
  my ($self, $data, $desc) = @_;

  return $self->more('ok', ($data ? false : true), $desc) || $self->diag($data);
}

sub for {
  my ($self, $type, @args) = @_;

  my $name = join(
    ' ', map {ref($_) ? () : $_} $type, @args
  );

  $self->more('subtest', $name, sub {
    $self->execute($type, @args);
  });

  return $self;
}

sub like {
  my ($self, $this, $that, $desc) = @_;

  $that = qr/$that/ if ref $that ne 'Regexp';

  return $self->more('like', $this, $that, $desc);
}

sub more {
  my ($self, $name, @args) = @_;

  require Test::More;

  my $level = 1;

  local $Test::Builder::Level = $Test::Builder::Level + $level;

  for (my $i = 0; my @caller = caller($i); $i++) {
    $level += $i; last if $caller[1] =~ qr{@{[quotemeta($self->file)]}$};
  }

  return Test::More->can($name)->(@args);
}

sub okay {
  my ($self, $data, $desc) = @_;

  return $self->more('ok', ($data ? true : false), $desc);
}

sub okay_can {
  my ($self, $data, @args) = @_;

  return $self->more('can_ok', $data, @args);
}

sub okay_isa {
  my ($self, $data, $name) = @_;

  return $self->more('isa_ok', $data, $name);
}

sub pass {
  my ($self, $data, $desc) = @_;

  return $self->more('ok', ($data ? true : false), $desc) || $self->diag($data);
}

sub perform {
  my ($self, $name, @args) = @_;

  my $method = "perform_test_for_$name";

  return $self->$method(@args);
}

sub perform_test_for_abstract {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=abstract content');

  return $result;
}

sub perform_test_for_attribute {
  my ($self, $name, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, "=attribute $name content");

  return $result;
}

sub perform_test_for_attributes {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=attributes content');

  return $result;
}

sub perform_test_for_authors {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=authors content');

  return $result;
}

sub perform_test_for_description {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=description content');

  return $result;
}

sub perform_test_for_encoding {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=encoding content');

  return $result;
}

sub perform_test_for_error {
  my ($self, $name, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, "=error $name content");

  return $result;
}

sub perform_test_for_example {
  my ($self, $number, $name, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, "=example-$number $name content");

  return $result;
}

sub perform_test_for_feature {
  my ($self, $name, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, "=feature $name content");

  return $result;
}

sub perform_test_for_function {
  my ($self, $name, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, "=function $name content");

  return $result;
}

sub perform_test_for_includes {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=includes content');

  return $result;
}

sub perform_test_for_inherits {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=inherits content');

  return $result;
}

sub perform_test_for_integrates {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=integrates content');

  return $result;
}

sub perform_test_for_layout {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=layout content');

  return $result;
}

sub perform_test_for_libraries {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=libraries content');

  return $result;
}

sub perform_test_for_license {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=license content');

  return $result;
}

sub perform_test_for_message {
  my ($self, $name, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, "=message $name content");

  return $result;
}

sub perform_test_for_metadata {
  my ($self, $name, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, "=metadata $name content");

  return $result;
}

sub perform_test_for_method {
  my ($self, $name, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, "=method $name content");

  return $result;
}

sub perform_test_for_name {
  my ($self, $data) = @_;

  my $text = join "\n", @{$data};

  my $result = length($text) ? true : false;

  $self->pass($result, '=name content');

  $self->pass(scalar(eval("require $text")), $self->explain('require', $text));

  return $result;
}

sub perform_test_for_operator {
  my ($self, $name, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, "=operator $name content");

  return $result;
}

sub perform_test_for_partials {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=partials content');

  return $result;
}

sub perform_test_for_project {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=project content');

  return $result;
}

sub perform_test_for_signature {
  my ($self, $name, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, "=signature $name content");

  return $result;
}

sub perform_test_for_synopsis {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=synopsis content');

  return $result;
}

sub perform_test_for_tagline {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=tagline content');

  return $result;
}

sub perform_test_for_version {
  my ($self, $data) = @_;

  my $result = length(join "\n", @{$data}) ? true : false;

  $self->pass($result, '=version content');

  return $result;
}

sub present {
  my ($self, $name, @args) = @_;

  my $method = "present_data_for_$name";

  return $self->$method(@args);
}

sub present_data_for_abstract {
  my ($self) = @_;

  my @data = $self->collect('abstract');

  return @data ? ($self->present_data_for_head1('abstract', @data)) : ();
}

sub present_data_for_attribute {
  my ($self, $name) = @_;

  return $self->present_data_for_attribute_type2($name);
}

sub present_data_for_attribute_type1 {
  my ($self, $name, $is, $pre, $isa, $def) = @_;

  my @output;

  $is = $is eq 'ro' ? 'read-only' : 'read-write';
  $pre = $pre eq 'req' ? 'required' : 'optional';

  push @output, "  $name($isa)\n";
  push @output, "This attribute is $is, accepts C<($isa)> values, ". (
    $def ? "is $pre, and defaults to $def." : "and is $pre."
  );

  return ($self->present_data_for_head2($name, @output));
}

sub present_data_for_attribute_type2 {
  my ($self, $name) = @_;

  my @output;

  my ($metadata) = $self->collect('metadata', $name);
  my ($signature) = $self->collect('signature', $name);

  push @output, ($signature, '') if $signature;

  my @data = $self->collect('attribute', $name);

  return () if !@data;

  push @output, join "\n\n", @data;

  if ($metadata) {
    local $@;
    if ($metadata = eval $metadata) {
      if (my $since = $metadata->{since}) {
        push @output, "", "I<Since C<$since>>";
      }
    }
  }

  my @results = $self->data->search({name => $name});

  for my $i (1..(int grep {($$_{list} || '') =~ /^example-\d+/} @results)) {
    push @output, join "\n\n", $self->present('example', $i, $name);
  }

  pop @output if $output[-1] eq '';

  return ($self->present_data_for_head2($name, @output));
}

sub present_data_for_attributes {
  my ($self, @args) = @_;

  my $method = $self->data->count({list => undef, name => 'attributes'})
    ? 'attributes_type1'
    : 'attributes_type2';

  return $self->present($method, @args);
}

sub present_data_for_attributes_type1 {
  my ($self) = @_;

  my @output;

  my @data = $self->collect('attributes');

  return () if !@data;

  for my $line (split /\r?\n/, join "\n", @data) {
    push @output, $self->present('attribute_type1', (
      map {split /,\s*/} split /:\s*/, $line, 2
    ));
  }

  return () if !@output;

  if (@output) {
    unshift @output,
      $self->present_data_for_head1('attributes',
      'This package has the following attributes:');
  }

  return join "\n", @output;
}

sub present_data_for_attributes_type2 {
  my ($self) = @_;

  my @output;

  for my $list ($self->data->search({list => 'attribute'})) {
    push @output, $self->present('attribute_type2', $list->{name});
  }

  if (@output) {
    unshift @output,
      $self->present_data_for_head1('attributes',
      'This package has the following attributes:');
  }

  return join "\n", @output;
}

sub present_data_for_authors {
  my ($self) = @_;

  my @data = $self->collect('authors');

  return @data ? ($self->present_data_for_head1('authors', join "\n\n", @data)) : ();
}

sub present_data_for_description {
  my ($self) = @_;

  my @data = $self->collect('description');

  return @data ? ($self->present_data_for_head1('description', join "\n\n", @data)) : ();
}

sub present_data_for_encoding {
  my ($self) = @_;

  my ($name) = $self->collect('encoding');

  return () if !$name;

  return join("\n", "", "=encoding \U$name", "", "=cut");
}

sub present_data_for_error {
  my ($self, $name) = @_;

  my @output;

  my @data = $self->collect('error', $name);

  return () if !@data;

  my @results = $self->data->search({name => $name});

  for my $i (1..(int grep {($$_{list} || '') =~ /^example-\d+/} @results)) {
    push @output, "B<example $i>", $self->collect('example', $i, $name);
  }

  return (
    $self->present_data_for_over($self->present_data_for_item(
      "error: C<$name>",
      join "\n\n", @data, @output
    ))
  );
}

sub present_data_for_errors {
  my ($self) = @_;

  my @output;

  my $type = 'error';

  for my $name (
    sort map $$_{name},
      $self->data->search({list => $type})
  )
  {
    push @output, $self->present($type, $name);
  }

  if (@output) {
    unshift @output,
      $self->present_data_for_head1('errors',
      'This package may raise the following errors:');
  }

  return join "\n", @output;
}

sub present_data_for_example {
  my ($self, $number, $name) = @_;

  my @data = $self->collect('example', $number, $name);

  return @data
    ? (
    $self->present_data_for_over($self->present_data_for_item(
      "$name example $number", join "\n\n", @data)))
    : ();
}

sub present_data_for_feature {
  my ($self, $name) = @_;

  my @output;

  my ($signature) = $self->collect('signature', $name);

  push @output, ($signature, '') if $signature;

  my @data = $self->collect('feature', $name);

  return () if !@data;

  my @results = $self->data->search({name => $name});

  for my $i (1..(int grep {($$_{list} || '') =~ /^example-\d+/} @results)) {
    push @output, "B<example $i>", $self->collect('example', $i, $name);
  }

  return (
    $self->present_data_for_over($self->present_data_for_item(
      $name, join "\n\n", @data, @output))
  );
}

sub present_data_for_features {
  my ($self) = @_;

  my @output;

  my $type = 'feature';

  for my $name (
    sort map $$_{name},
      $self->data->search({list => $type})
  )
  {
    push @output, $self->present($type, $name);
  }

  if (@output) {
    unshift @output,
      $self->present_data_for_head1('features',
      'This package provides the following features:');
  }

  return join "\n", @output;
}

sub present_data_for_function {
  my ($self, $name) = @_;

  my @output;

  my ($metadata) = $self->collect('metadata', $name);
  my ($signature) = $self->collect('signature', $name);

  push @output, ($signature, '') if $signature;

  my @data = $self->collect('function', $name);

  return () if !@data;

  push @output, join "\n\n", @data;

  if ($metadata) {
    local $@;
    if ($metadata = eval $metadata) {
      if (my $since = $metadata->{since}) {
        push @output, "", "I<Since C<$since>>";
      }
    }
  }

  my @results = $self->data->search({name => $name});

  for my $i (1..(int grep {($$_{list} || '') =~ /^example-\d+/} @results)) {
    push @output, $self->present('example', $i, $name);
  }

  pop @output if $output[-1] eq '';

  return ($self->present_data_for_head2($name, @output));
}

sub present_data_for_functions {
  my ($self) = @_;

  my @output;

  my $type = 'function';

  for my $name (
    sort map /:\s*(\w+)$/,
    grep /^$type/,
    split /\r?\n/,
    join "\n\n", $self->collect('includes')
  )
  {
    push @output, $self->present($type, $name);
  }

  if (@output) {
    unshift @output,
      $self->present_data_for_head1('functions',
      'This package provides the following functions:');
  }

  return join "\n", @output;
}

sub present_data_for_head1 {
  my ($self, $name, @data) = @_;

  return join("\n", "", "=head1 \U$name", "", grep(defined, @data), "", "=cut");
}

sub present_data_for_head2 {
  my ($self, $name, @data) = @_;

  return join("\n", "", "=head2 \L$name", "", grep(defined, @data), "", "=cut");
}

sub present_data_for_includes {
  my ($self) = @_;

  return ();
}

sub present_data_for_inherits {
  my ($self) = @_;

  my @output = map +($self->present_data_for_link($_), ""), grep defined,
    split /\r?\n/, join "\n\n", $self->collect('inherits');

  return () if !@output;

  pop @output;

  return $self->present_data_for_head1('inherits',
    "This package inherits behaviors from:",
    "",
    @output,
  );
}

sub present_data_for_integrates {
  my ($self) = @_;

  my @output = map +($self->present_data_for_link($_), ""), grep defined,
    split /\r?\n/, join "\n\n", $self->collect('integrates');

  return () if !@output;

  pop @output;

  return $self->present_data_for_head1('integrates',
    "This package integrates behaviors from:",
    "",
    @output,
  );
}

sub present_data_for_item {
  my ($self, $name, $data) = @_;

  return ("=item $name\n", "$data\n");
}

sub present_data_for_layout {
  my ($self) = @_;

  return ();
}

sub present_data_for_libraries {
  my ($self) = @_;

  my @output = map +($self->present_data_for_link($_), ""), grep defined,
    split /\r?\n/, join "\n\n", $self->collect('libraries');

  return '' if !@output;

  pop @output;

  return $self->present_data_for_head1('libraries',
    "This package uses type constraints from:",
    "",
    @output,
  );
}

sub present_data_for_license {
  my ($self) = @_;

  my @data = $self->collect('license');

  return @data
    ? ($self->present_data_for_head1('license', join "\n\n", @data))
    : ();
}

sub present_data_for_link {
  my ($self, @data) = @_;

  return ("L<@{[join('|', @data)]}>");
}

sub present_data_for_message {
  my ($self, $name) = @_;

  my @output;

  my ($signature) = $self->collect('signature', $name);

  push @output, ($signature, '') if $signature;

  my @data = $self->collect('message', $name);

  return () if !@data;

  my @results = $self->data->search({name => $name});

  for my $i (1..(int grep {($$_{list} || '') =~ /^example-\d+/} @results)) {
    push @output, "B<example $i>", join "\n\n",
      $self->collect('example', $i, $name);
  }

  return (
    $self->present_data_for_over($self->present_data_for_item(
      $name, join "\n\n", @data, @output))
  );
}

sub present_data_for_messages {
  my ($self) = @_;

  my @output;

  my $type = 'message';

  for my $name (
    sort map /:\s*(\w+)$/,
    grep /^$type/,
    split /\r?\n/,
    join "\n\n", $self->collect('includes')
  )
  {
    push @output, $self->present($type, $name);
  }

  if (@output) {
    unshift @output,
      $self->present_data_for_head1('messages',
      'This package provides the following messages:');
  }

  return join "\n", @output;
}

sub present_data_for_metadata {
  my ($self) = @_;

  return ();
}

sub present_data_for_method {
  my ($self, $name) = @_;

  my @output;

  my ($metadata) = $self->collect('metadata', $name);
  my ($signature) = $self->collect('signature', $name);

  push @output, ($signature, '') if $signature;

  my @data = $self->collect('method', $name);

  return () if !@data;

  push @output, join "\n\n", @data;

  if ($metadata) {
    local $@;
    if ($metadata = eval $metadata) {
      if (my $since = $metadata->{since}) {
        push @output, "", "I<Since C<$since>>";
      }
    }
  }

  my @results = $self->data->search({name => $name});

  for my $i (1..(int grep {($$_{list} || '') =~ /^example-\d+/} @results)) {
    push @output, $self->present('example', $i, $name);
  }

  pop @output if $output[-1] eq '';

  return ($self->present_data_for_head2($name, @output));
}

sub present_data_for_methods {
  my ($self) = @_;

  my @output;

  my $type = 'method';

  for my $name (
    sort map /:\s*(\w+)$/,
    grep /^$type/,
    split /\r?\n/,
    join "\n\n", $self->collect('includes')
  )
  {
    push @output, $self->present($type, $name);
  }

  if (@output) {
    unshift @output,
      $self->present_data_for_head1('methods',
      'This package provides the following methods:');
  }

  return join "\n", @output;
}

sub present_data_for_name {
  my ($self) = @_;

  my $name = join ' - ', map $self->collect($_), 'name', 'tagline';

  return $name ? ($self->present_data_for_head1('name', $name)) : ();
}

sub present_data_for_operator {
  my ($self, $name) = @_;

  my @output;

  my @data = $self->collect('operator', $name);

  return () if !@data;

  my @results = $self->data->search({name => $name});

  for my $i (1..(int grep {($$_{list} || '') =~ /^example-\d+/} @results)) {
    push @output, "B<example $i>", join "\n\n",
      $self->collect('example', $i, $name);
  }

  return (
    $self->present_data_for_over($self->present_data_for_item(
      "operation: C<$name>",
      join "\n\n", @data, @output
    ))
  );
}

sub present_data_for_operators {
  my ($self) = @_;

  my @output;

  my $type = 'operator';

  for my $name (
    sort map $$_{name},
      $self->data->search({list => $type})
  )
  {
    push @output, $self->present($type, $name);
  }

  if (@output) {
    unshift @output,
      $self->present_data_for_head1('operators',
      'This package overloads the following operators:');
  }

  return join "\n", @output;
}

sub present_data_for_over {
  my ($self, @data) = @_;

  return join("\n", "", "=over 4", "", grep(defined, @data), "=back");
}

sub present_data_for_partial {
  my ($self, $data) = @_;

  my ($file, $method, @args) = @{$data};

  $method = 'present' if lc($method) eq 'pdml';

  my $test = $self->new($file);

  my @output;

  $self->pass((-f $file && (@output = ($test->$method(@args)))),
    "$file: $method: @args");

  return join "\n", @output;
}

sub present_data_for_partials {
  my ($self) = @_;

  my @output;

  push @output, $self->present('partial', $_)
    for map [split /\:\s*/], grep /\w/, grep !/^#/, split /\r?\n/, join "\n\n",
      $self->collect('partials');

  return join "\n", @output;
}

sub present_data_for_project {
  my ($self) = @_;

  my @data = $self->collect('project');

  return @data ? ($self->present_data_for_head1('project', join "\n\n", @data)) : ();
}

sub present_data_for_signature {
  my ($self) = @_;

  return ();
}

sub present_data_for_synopsis {
  my ($self) = @_;

  my @data = $self->collect('synopsis');

  return @data
    ? ($self->present_data_for_head1('synopsis', join "\n\n", @data))
    : ();
}

sub present_data_for_tagline {
  my ($self) = @_;

  my @data = $self->collect('tagline');

  return @data
    ? ($self->present_data_for_head1('tagline', join "\n\n", @data))
    : ();
}

sub present_data_for_version {
  my ($self) = @_;

  my @data = $self->collect('version');

  return @data
    ? ($self->present_data_for_head1('version', join "\n\n", @data))
    : ();
}

sub render {
  my ($self, $file) = @_;

  require Venus::Path;

  my $path = Venus::Path->new($file);

  $path->parent->mkdirs;

  my @layout = $self->collect('layout');

  my @output;

  for my $item (@layout) {
    push @output, grep {length} $self->present(split /:\s*/, $item);
  }

  $path->write(join "\n", @output);

  return $path;
}

sub same {
  my ($self, $this, $that, $desc) = @_;

  return $self->more('is_deeply', $this, $that, $desc);
}

sub skip {
  my ($self, $desc, @args) = @_;

  my ($bool) = @args ? @args : (true);

  $bool = (ref $bool eq 'CODE') ? $self->$bool : $bool;

  $self->more('plan', 'skip_all', $desc) if $bool;

  return $bool;
}

# ERRORS

sub error_on_abstract {
  my ($self, $data) = @_;

  my $message = 'Test file "{{file}}" missing abstract section';

  my $stash = {
    file => $self->file,
  };

  my $result = {
    name => 'on.abstract',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_description {
  my ($self, $data) = @_;

  my $message = 'Test file "{{file}}" missing description section';

  my $stash = {
    file => $self->file,
  };

  my $result = {
    name => 'on.description',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_name {
  my ($self, $data) = @_;

  my $message = 'Test file "{{file}}" missing name section';

  my $stash = {
    file => $self->file,
  };

  my $result = {
    name => 'on.name',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_synopsis {
  my ($self, $data) = @_;

  my $message = 'Test file "{{file}}" missing synopsis section';

  my $stash = {
    file => $self->file,
  };

  my $result = {
    name => 'on.synopsis',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_tagline {
  my ($self, $data) = @_;

  my $message = 'Test file "{{file}}" missing tagline section';

  my $stash = {
    file => $self->file,
  };

  my $result = {
    name => 'on.tagline',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

1;



=head1 NAME

Venus::Test - Test Class

=cut

=head1 ABSTRACT

Test Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Test;

  my $test = Venus::Test->new('t/Venus_Test.t');

  # $test->for('name');

  # $test->for('tagline');

  # $test->for('abstract');

  # $test->for('synopsis');

  # $test->done;

=cut

=head1 DESCRIPTION

This package aims to provide a standard for documenting L<Venus> derived
software projects, a framework writing tests, test automation, and
documentation generation.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 file

  file(string $data) (string)

The file attribute is read-write, accepts C<(string)> values, and is required.

I<Since C<3.55>>

=over 4

=item file example 1

  # given: synopsis

  package main;

  my $set_file = $test->file("t/Venus_Test.t");

  # "t/Venus_Test.t"

=back

=over 4

=item file example 2

  # given: synopsis

  # given: example-1 file

  package main;

  my $get_file = $test->file;

  # "t/Venus_Test.t"

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

=cut

=head1 FUNCTIONS

This package provides the following functions:

=cut

=head2 test

  test(string $file) (Venus::Test)

The test function is exported automatically and returns a L<Venus::Test> object
for the test file given.

I<Since C<0.09>>

=over 4

=item test example 1

  package main;

  use Venus::Test;

  my $test = test 't/Venus_Test.t';

  # bless(..., "Venus::Test")

=back

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 collect

  collect(string $name, any @args) (any)

The collect method dispatches to the C<collect_data_for_${name}> method
indictated by the first argument and returns the result. Returns an arrayref in
scalar context, and a list in list context.

I<Since C<3.55>>

=over 4

=item collect example 1

  # given: synopsis

  package main;

  my ($collect) = $test->collect('name');

  # "Venus::Test"

=back

=over 4

=item collect example 2

  # given: synopsis

  package main;

  my $collect = $test->collect('name');

  # ["Venus::Test"]

=back

=cut

=head2 collect_data_for_abstract

  collect_data_for_abstract() (arrayref)

The collect_data_for_abstract method uses L</data> to fetch data for the C<abstract>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_abstract example 1

  # =abstract
  #
  # Example Test Documentation
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_abstract = $test->collect_data_for_abstract;

  # ["Example Test Documentation"]

=back

=over 4

=item collect_data_for_abstract example 2

  # =abstract
  #
  # Example Test Documentation
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_abstract) = $test->collect_data_for_abstract;

  # "Example Test Documentation"

=back

=cut

=head2 collect_data_for_attribute

  collect_data_for_attribute(string $name) (arrayref)

The collect_data_for_attribute method uses L</data> to fetch data for the
C<attribute $name> section and returns the data. Returns an arrayref in scalar
context, and a list in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_attribute example 1

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_attribute = $test->collect_data_for_attribute('name');

  # ["The name attribute is read-write, optional, and holds a string."]

=back

=over 4

=item collect_data_for_attribute example 2

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_attribute) = $test->collect_data_for_attribute('name');

  # "The name attribute is read-write, optional, and holds a string."

=back

=cut

=head2 collect_data_for_authors

  collect_data_for_authors() (arrayref)

The collect_data_for_authors method uses L</data> to fetch data for the
C<authors> section and returns the data. Returns an arrayref in scalar context,
and a list in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_authors example 1

  # =authors
  #
  # Awncorp, C<awncorp@cpan.org>
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_authors = $test->collect_data_for_authors;

  # ["Awncorp, C<awncorp@cpan.org>"]

=back

=over 4

=item collect_data_for_authors example 2

  # =authors
  #
  # Awncorp, C<awncorp@cpan.org>
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_authors) = $test->collect_data_for_authors;

  # "Awncorp, C<awncorp@cpan.org>"

=back

=cut

=head2 collect_data_for_description

  collect_data_for_description() (arrayref)

The collect_data_for_description method uses L</data> to fetch data for the C<description>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_description example 1

  # =description
  #
  # This package provides an example class.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_description = $test->collect_data_for_description;

  # ["This package provides an example class."]

=back

=over 4

=item collect_data_for_description example 2

  # =description
  #
  # This package provides an example class.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_description) = $test->collect_data_for_description;

  # "This package provides an example class."

=back

=cut

=head2 collect_data_for_encoding

  collect_data_for_encoding() (arrayref)

The collect_data_for_encoding method uses L</data> to fetch data for the C<encoding>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_encoding example 1

  # =encoding
  #
  # utf8
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_encoding = $test->collect_data_for_encoding;

  # ["UTF8"]

=back

=over 4

=item collect_data_for_encoding example 2

  # =encoding
  #
  # utf8
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_encoding) = $test->collect_data_for_encoding;

  # "UTF8"

=back

=cut

=head2 collect_data_for_error

  collect_data_for_error(string $name) (arrayref)

The collect_data_for_error method uses L</data> to fetch data for the C<error
$name> section and returns the data. Returns an arrayref in scalar context, and
a list in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_error example 1

  # =error error_on_unknown
  #
  # This package may raise an error_on_unknown error.
  #
  # =cut
  #
  # =example-1 error_on_unknown
  #
  #   # given: synopsis
  #
  #   my $error = $example->catch('error', {
  #     with => 'error_on_unknown',
  #   });
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_error = $test->collect_data_for_error('error_on_unknown');

  # ["This package may raise an error_on_unknown error."]

=back

=over 4

=item collect_data_for_error example 2

  # =error error_on_unknown
  #
  # This package may raise an error_on_unknown error.
  #
  # =cut
  #
  # =example-1 error_on_unknown
  #
  #   # given: synopsis
  #
  #   my $error = $example->catch('error', {
  #     with => 'error_on_unknown',
  #   });
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_error) = $test->collect_data_for_error('error_on_unknown');

  # "This package may raise an error_on_unknown error."

=back

=cut

=head2 collect_data_for_example

  collect_data_for_example(number $numberm string $name) (arrayref)

The collect_data_for_example method uses L</data> to fetch data for the
C<example-$number $name> section and returns the data. Returns an arrayref in
scalar context, and a list in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_example example 1

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_example = $test->collect_data_for_example(1, 'name');

  # ['  # given: synopsis', '  my $name = $example->name;', '  # "..."']

=back

=over 4

=item collect_data_for_example example 2

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my @collect_data_for_example = $test->collect_data_for_example(1, 'name');

  # ('  # given: synopsis', '  my $name = $example->name;', '  # "..."')

=back

=cut

=head2 collect_data_for_feature

  collect_data_for_feature(string $name) (arrayref)

The collect_data_for_feature method uses L</data> to fetch data for the
C<feature $name> section and returns the data. Returns an arrayref in scalar
context, and a list in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_feature example 1

  # =feature noop
  #
  # This package is no particularly useful features.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_feature = $test->collect_data_for_feature('noop');

  # ["This package is no particularly useful features."]

=back

=over 4

=item collect_data_for_feature example 2

  # =feature noop
  #
  # This package is no particularly useful features.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_feature) = $test->collect_data_for_feature('noop');

  # "This package is no particularly useful features."

=back

=cut

=head2 collect_data_for_function

  collect_data_for_function(string $name) (arrayref)

The collect_data_for_function method uses L</data> to fetch data for the
C<function $name> section and returns the data. Returns an arrayref in scalar
context, and a list in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_function example 1

  # =function eg
  #
  # The eg function returns a new instance of Example.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $example = eg();
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_function = $test->collect_data_for_function('eg');

  # ["The eg function returns a new instance of Example."]

=back

=over 4

=item collect_data_for_function example 2

  # =function eg
  #
  # The eg function returns a new instance of Example.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $example = eg();
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_function) = $test->collect_data_for_function('eg');

  # "The eg function returns a new instance of Example."

=back

=cut

=head2 collect_data_for_includes

  collect_data_for_includes() (arrayref)

The collect_data_for_includes method uses L</data> to fetch data for the
C<includes> section and returns the data. Returns an arrayref in scalar
context, and a list in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_includes example 1

  # =includes
  #
  # function: eg
  #
  # method: prepare
  # method: execute
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_includes = $test->collect_data_for_includes;

  # ["function: eg", "method: prepare", "method: execute"]

=back

=over 4

=item collect_data_for_includes example 2

  # =includes
  #
  # function: eg
  #
  # method: prepare
  # method: execute
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my @collect_data_for_includes = $test->collect_data_for_includes;

  # ("function: eg", "method: prepare", "method: execute")

=back

=cut

=head2 collect_data_for_inherits

  collect_data_for_inherits() (arrayref)

The collect_data_for_inherits method uses L</data> to fetch data for the C<inherits>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_inherits example 1

  # =inherits
  #
  # Venus::Core::Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_inherits = $test->collect_data_for_inherits;

  # ["Venus::Core::Class"]

=back

=over 4

=item collect_data_for_inherits example 2

  # =inherits
  #
  # Venus::Core::Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_inherits) = $test->collect_data_for_inherits;

  # "Venus::Core::Class"

=back

=cut

=head2 collect_data_for_integrates

  collect_data_for_integrates() (arrayref)

The collect_data_for_integrates method uses L</data> to fetch data for the C<integrates>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_integrates example 1

  # =integrates
  #
  # Venus::Role::Catchable
  # Venus::Role::Throwable
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_integrates = $test->collect_data_for_integrates;

  # ["Venus::Role::Catchable\nVenus::Role::Throwable"]

=back

=over 4

=item collect_data_for_integrates example 2

  # =integrates
  #
  # Venus::Role::Catchable
  # Venus::Role::Throwable
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_integrates) = $test->collect_data_for_integrates;

  # "Venus::Role::Catchable\nVenus::Role::Throwable"

=back

=cut

=head2 collect_data_for_layout

  collect_data_for_layout() (arrayref)

The collect_data_for_layout method uses L</data> to fetch data for the C<layout>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_layout example 1

  # =layout
  #
  # encoding
  # name
  # synopsis
  # description
  # attributes: attribute
  # authors
  # license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_layout = $test->collect_data_for_layout;

  # ["encoding\nname\nsynopsis\ndescription\nattributes: attribute\nauthors\nlicense"]

=back

=over 4

=item collect_data_for_layout example 2

  # =layout
  #
  # encoding
  # name
  # synopsis
  # description
  # attributes: attribute
  # authors
  # license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_layout) = $test->collect_data_for_layout;

  # "encoding\nname\nsynopsis\ndescription\nattributes: attribute\nauthors\nlicense"

=back

=cut

=head2 collect_data_for_libraries

  collect_data_for_libraries() (arrayref)

The collect_data_for_libraries method uses L</data> to fetch data for the C<libraries>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_libraries example 1

  # =libraries
  #
  # Venus::Check
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_libraries = $test->collect_data_for_libraries;

  # ["Venus::Check"]

=back

=over 4

=item collect_data_for_libraries example 2

  # =libraries
  #
  # Venus::Check
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_libraries) = $test->collect_data_for_libraries;

  # "Venus::Check"

=back

=cut

=head2 collect_data_for_license

  collect_data_for_license() (arrayref)

The collect_data_for_license method uses L</data> to fetch data for the C<license>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_license example 1

  # =license
  #
  # No license granted.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_license = $test->collect_data_for_license;

  # ["No license granted."]

=back

=over 4

=item collect_data_for_license example 2

  # =license
  #
  # No license granted.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_license) = $test->collect_data_for_license;

  # "No license granted."

=back

=cut

=head2 collect_data_for_message

  collect_data_for_message(string $name) (arrayref)

The collect_data_for_message method uses L</data> to fetch data for the
C<message $name> section and returns the data. Returns an arrayref in scalar
context, and a list in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_message example 1

  # =message accept
  #
  # The accept message represents acceptance.
  #
  # =cut
  #
  # =example-1 accept
  #
  #   # given: synopsis
  #
  #   my $accept = $example->accept;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_message = $test->collect_data_for_message('accept');

  # ["The accept message represents acceptance."]

=back

=over 4

=item collect_data_for_message example 2

  # =message accept
  #
  # The accept message represents acceptance.
  #
  # =cut
  #
  # =example-1 accept
  #
  #   # given: synopsis
  #
  #   my $accept = $example->accept;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_message) = $test->collect_data_for_message('accept');

  # "The accept message represents acceptance."

=back

=cut

=head2 collect_data_for_metadata

  collect_data_for_metadata(string $name) (arrayref)

The collect_data_for_metadata method uses L</data> to fetch data for the C<metadata $name>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_metadata example 1

  # =method prepare
  #
  # The prepare method prepares for execution.
  #
  # =cut
  #
  # =metadata prepare
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 prepare
  #
  #   # given: synopsis
  #
  #   my $prepare = $example->prepare;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_metadata = $test->collect_data_for_metadata('prepare');

  # ["{since => 1.2.3}"]

=back

=over 4

=item collect_data_for_metadata example 2

  # =method prepare
  #
  # The prepare method prepares for execution.
  #
  # =cut
  #
  # =metadata prepare
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 prepare
  #
  #   # given: synopsis
  #
  #   my $prepare = $example->prepare;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_metadata) = $test->collect_data_for_metadata('prepare');

  # "{since => 1.2.3}"

=back

=cut

=head2 collect_data_for_method

  collect_data_for_method(string $name) (arrayref)

The collect_data_for_method method uses L</data> to fetch data for the C<method $name>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_method example 1

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_method = $test->collect_data_for_method('execute');

  # ["The execute method executes the logic."]

=back

=over 4

=item collect_data_for_method example 2

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_method) = $test->collect_data_for_method('execute');

  # "The execute method executes the logic."

=back

=cut

=head2 collect_data_for_name

  collect_data_for_name() (arrayref)

The collect_data_for_name method uses L</data> to fetch data for the C<name>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_name example 1

  # =name

  # Example

  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_name = $test->collect_data_for_name;

  # ["Example"]

=back

=over 4

=item collect_data_for_name example 2

  # =name

  # Example

  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_name) = $test->collect_data_for_name;

  # "Example"

=back

=cut

=head2 collect_data_for_operator

  collect_data_for_operator(string $name) (arrayref)

The collect_data_for_operator method uses L</data> to fetch data for the C<operator $name>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_operator example 1

  # =operator ("")
  #
  # This package overloads the C<""> operator.
  #
  # =cut
  #
  # =example-1 ("")
  #
  #   # given: synopsis
  #
  #   my $string = "$example";
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_operator = $test->collect_data_for_operator('("")');

  # ['This package overloads the C<""> operator.']

=back

=over 4

=item collect_data_for_operator example 2

  # =operator ("")
  #
  # This package overloads the C<""> operator.
  #
  # =cut
  #
  # =example-1 ("")
  #
  #   # given: synopsis
  #
  #   my $string = "$example";
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_operator) = $test->collect_data_for_operator('("")');

  # 'This package overloads the C<""> operator.'

=back

=cut

=head2 collect_data_for_partials

  collect_data_for_partials() (arrayref)

The collect_data_for_partials method uses L</data> to fetch data for the C<partials>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_partials example 1

  # =partials
  #
  # t/path/to/other.t: present: authors
  # t/path/to/other.t: present: license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_partials = $test->collect_data_for_partials;

  # ["t/path/to/other.t: present: authors\nt/path/to/other.t: present: license"]

=back

=over 4

=item collect_data_for_partials example 2

  # =partials
  #
  # t/path/to/other.t: present: authors
  # t/path/to/other.t: present: license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_partials) = $test->collect_data_for_partials;

  # "t/path/to/other.t: present: authors\nt/path/to/other.t: present: license"

=back

=cut

=head2 collect_data_for_project

  collect_data_for_project() (arrayref)

The collect_data_for_project method uses L</data> to fetch data for the C<project>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_project example 1

  # =project
  #
  # https://github.com/awncorp/example
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_project = $test->collect_data_for_project;

  # ["https://github.com/awncorp/example"]

=back

=over 4

=item collect_data_for_project example 2

  # =project
  #
  # https://github.com/awncorp/example
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_project) = $test->collect_data_for_project;

  # "https://github.com/awncorp/example"

=back

=cut

=head2 collect_data_for_signature

  collect_data_for_signature(string $name) (arrayref)

The collect_data_for_signature method uses L</data> to fetch data for the C<signature $name>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_signature example 1

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =signature execute
  #
  #   execute() (boolean)
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_signature = $test->collect_data_for_signature('execute');

  # ["  execute() (boolean)"]

=back

=over 4

=item collect_data_for_signature example 2

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =signature execute
  #
  #   execute() (boolean)
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_signature) = $test->collect_data_for_signature('execute');

  # "  execute() (boolean)"

=back

=cut

=head2 collect_data_for_synopsis

  collect_data_for_synopsis() (arrayref)

The collect_data_for_synopsis method uses L</data> to fetch data for the C<synopsis>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_synopsis example 1

  # =synopsis
  #
  #   use Example;
  #
  #   my $example = Example->new;
  #
  #   # bless(..., "Example")
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_synopsis = $test->collect_data_for_synopsis;

  # ['  use Example;', '  my $example = Example->new;', '  # bless(..., "Example")']

=back

=over 4

=item collect_data_for_synopsis example 2

  # =synopsis
  #
  #   use Example;
  #
  #   my $example = Example->new;
  #
  #   # bless(..., "Example")
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my @collect_data_for_synopsis = $test->collect_data_for_synopsis;

  # ('  use Example;', '  my $example = Example->new;', '  # bless(..., "Example")')

=back

=cut

=head2 collect_data_for_tagline

  collect_data_for_tagline() (arrayref)

The collect_data_for_tagline method uses L</data> to fetch data for the C<tagline>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_tagline example 1

  # =tagline
  #
  # Example Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_tagline = $test->collect_data_for_tagline;

  # ["Example Class"]

=back

=over 4

=item collect_data_for_tagline example 2

  # =tagline
  #
  # Example Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_tagline) = $test->collect_data_for_tagline;

  # "Example Class"

=back

=cut

=head2 collect_data_for_version

  collect_data_for_version() (arrayref)

The collect_data_for_version method uses L</data> to fetch data for the C<version>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

I<Since C<3.55>>

=over 4

=item collect_data_for_version example 1

  # =version
  #
  # 1.2.3
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_version = $test->collect_data_for_version;

  # ["1.2.3"]

=back

=over 4

=item collect_data_for_version example 2

  # =version
  #
  # 1.2.3
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_version) = $test->collect_data_for_version;

  # "1.2.3"

=back

=cut

=head2 data

  data() (Venus::Data)

The data method returns a L<Venus::Data> object using L</file> for parsing the
test specification.

I<Since C<3.55>>

=over 4

=item data example 1

  # given: synopsis

  package main;

  my $data = $test->data;

  # bless(..., "Venus::Data")

=back

=cut

=head2 done

  done() (any)

The done method dispatches to the L<Test::More/done_testing> operation and
returns the result.

I<Since C<3.55>>

=over 4

=item done example 1

  # given: synopsis

  package main;

  my $done = $test->done;

  # true

=back

=cut

=head2 execute

  execute(string $name, any @args) (boolean)

The execute method dispatches to the C<execute_data_for_${name}> method
indictated by the first argument and returns the result. Returns an arrayref in
scalar context, and a list in list context.

I<Since C<3.55>>

=over 4

=item execute example 1

  # given: synopsis

  package main;

  my $execute = $test->execute('name');

  # true

=back

=over 4

=item execute example 2

  # given: synopsis

  package main;

  my $execute = $test->execute('name', sub {
    my ($data) = @_;

    my $result = $data->[0] eq 'Venus::Test' ? true : false;

    $self->pass($result, 'name set as Venus::Test');

    return $result;
  });

  # true

=back

=cut

=head2 execute_test_for_abstract

  execute_test_for_abstract() (arrayref)

The execute_test_for_abstract method tests a documentation block for the C<abstract> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_abstract example 1

  # =abstract
  #
  # Example Test Documentation
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_abstract = $test->execute_test_for_abstract;

  # true

=back

=cut

=head2 execute_test_for_attribute

  execute_test_for_attribute(string $name) (arrayref)

The execute_test_for_attribute method tests a documentation block for the C<attribute $name> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_attribute example 1

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_attribute = $test->execute_test_for_attribute('name');

  # true

=back

=cut

=head2 execute_test_for_authors

  execute_test_for_authors() (arrayref)

The execute_test_for_authors method tests a documentation block for the C<authors> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_authors example 1

  # =authors
  #
  # Awncorp, C<awncorp@cpan.org>
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_authors = $test->execute_test_for_authors;

  # true

=back

=cut

=head2 execute_test_for_description

  execute_test_for_description() (arrayref)

The execute_test_for_description method tests a documentation block for the C<description> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_description example 1

  # =description
  #
  # This package provides an example class.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_description = $test->execute_test_for_description;

  # true

=back

=cut

=head2 execute_test_for_encoding

  execute_test_for_encoding() (arrayref)

The execute_test_for_encoding method tests a documentation block for the C<encoding> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_encoding example 1

  # =encoding
  #
  # utf8
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_encoding = $test->execute_test_for_encoding;

  # true

=back

=cut

=head2 execute_test_for_error

  execute_test_for_error(string $name) (arrayref)

The execute_test_for_error method tests a documentation block for the C<error $name> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_error example 1

  # =error error_on_unknown
  #
  # This package may raise an error_on_unknown error.
  #
  # =cut
  #
  # =example-1 error_on_unknown
  #
  #   # given: synopsis
  #
  #   my $error = $example->catch('error', {
  #     with => 'error_on_unknown',
  #   });
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_error = $test->execute_test_for_error('error_on_unknown');

  # true

=back

=cut

=head2 execute_test_for_example

  execute_test_for_example(number $numberm string $name) (arrayref)

The execute_test_for_example method tests a documentation block for the C<example-$number $name> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_example example 1

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_example = $test->execute_test_for_example(1, 'name');

  # true

=back

=cut

=head2 execute_test_for_feature

  execute_test_for_feature(string $name) (arrayref)

The execute_test_for_feature method tests a documentation block for the C<feature $name> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_feature example 1

  # =feature noop
  #
  # This package is no particularly useful features.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_feature = $test->execute_test_for_feature('noop');

  # true

=back

=cut

=head2 execute_test_for_function

  execute_test_for_function(string $name) (arrayref)

The execute_test_for_function method tests a documentation block for the C<function $name> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_function example 1

  # =function eg
  #
  # The eg function returns a new instance of Example.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $example = eg();
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_function = $test->execute_test_for_function('eg');

  # true

=back

=cut

=head2 execute_test_for_includes

  execute_test_for_includes() (arrayref)

The execute_test_for_includes method tests a documentation block for the C<includes> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_includes example 1

  # =includes
  #
  # function: eg
  #
  # method: prepare
  # method: execute
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_includes = $test->execute_test_for_includes;

  # true

=back

=cut

=head2 execute_test_for_inherits

  execute_test_for_inherits() (arrayref)

The execute_test_for_inherits method tests a documentation block for the C<inherits> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_inherits example 1

  # =inherits
  #
  # Venus::Core::Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_inherits = $test->execute_test_for_inherits;

  # true

=back

=cut

=head2 execute_test_for_integrates

  execute_test_for_integrates() (arrayref)

The execute_test_for_integrates method tests a documentation block for the C<integrates> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_integrates example 1

  # =integrates
  #
  # Venus::Role::Catchable
  # Venus::Role::Throwable
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_integrates = $test->execute_test_for_integrates;

  # true

=back

=cut

=head2 execute_test_for_layout

  execute_test_for_layout() (arrayref)

The execute_test_for_layout method tests a documentation block for the C<layout> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_layout example 1

  # =layout
  #
  # encoding
  # name
  # synopsis
  # description
  # attributes: attribute
  # authors
  # license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_layout = $test->execute_test_for_layout;

  # true

=back

=cut

=head2 execute_test_for_libraries

  execute_test_for_libraries() (arrayref)

The execute_test_for_libraries method tests a documentation block for the C<libraries> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_libraries example 1

  # =libraries
  #
  # Venus::Check
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_libraries = $test->execute_test_for_libraries;

  # true

=back

=cut

=head2 execute_test_for_license

  execute_test_for_license() (arrayref)

The execute_test_for_license method tests a documentation block for the C<license> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_license example 1

  # =license
  #
  # No license granted.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_license = $test->execute_test_for_license;

  # true

=back

=cut

=head2 execute_test_for_message

  execute_test_for_message(string $name) (arrayref)

The execute_test_for_message method tests a documentation block for the C<message $name> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_message example 1

  # =message accept
  #
  # The accept message represents acceptance.
  #
  # =cut
  #
  # =example-1 accept
  #
  #   # given: synopsis
  #
  #   my $accept = $example->accept;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_message = $test->execute_test_for_message('accept');

  # true

=back

=cut

=head2 execute_test_for_metadata

  execute_test_for_metadata(string $name) (arrayref)

The execute_test_for_metadata method tests a documentation block for the C<metadata $name> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_metadata example 1

  # =method prepare
  #
  # The prepare method prepares for execution.
  #
  # =cut
  #
  # =metadata prepare
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 prepare
  #
  #   # given: synopsis
  #
  #   my $prepare = $example->prepare;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_metadata = $test->execute_test_for_metadata('prepare');

  # true

=back

=cut

=head2 execute_test_for_method

  execute_test_for_method(string $name) (arrayref)

The execute_test_for_method method tests a documentation block for the C<method $name> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_method example 1

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_method = $test->execute_test_for_method('execute');

  # true

=back

=cut

=head2 execute_test_for_name

  execute_test_for_name() (arrayref)

The execute_test_for_name method tests a documentation block for the C<name> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_name example 1

  # =name

  # Example

  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_name = $test->execute_test_for_name;

  # true

=back

=cut

=head2 execute_test_for_operator

  execute_test_for_operator(string $name) (arrayref)

The execute_test_for_operator method tests a documentation block for the C<operator $name> section and returns the result.

I<Since C<3.55>>

=over 4

=item execute_test_for_operator example 1

  # =operator ("")
  #
  # This package overloads the C<""> operator.
  #
  # =cut
  #
  # =example-1 ("")
  #
  #   # given: synopsis
  #
  #   my $string = "$example";
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_operator = $test->execute_test_for_operator('("")');

  # true

=back

=cut

=head2 explain

  explain(any @args) (any)

The explain method dispatches to the L<Test::More/explain> operation and
returns the result.

I<Since C<3.55>>

=over 4

=item explain example 1

  # given: synopsis

  package main;

  my $explain = $test->explain(123.456);

  # "123.456"

=back

=cut

=head2 fail

  fail(any $data, string $description) (any)

The fail method dispatches to the L<Test::More/ok> operation expecting the
first argument to be falsy and returns the result.

I<Since C<3.55>>

=over 4

=item fail example 1

  # given: synopsis

  package main;

  my $fail = $test->fail(0, 'example-1 fail passed');

  # true

=back

=cut

=head2 for

  for(any @args) (Venus::Test)

The for method dispatches to the L</execute> method using the arguments
provided within a L<subtest|Test::More/subtest> and returns the invocant.

I<Since C<3.55>>

=over 4

=item for example 1

  # given: synopsis

  package main;

  my $for = $test->for('name');

  # bless(..., "Venus::Test")

=back

=over 4

=item for example 2

  # given: synopsis

  package main;

  my $for = $test->for('synopsis');

  # bless(..., "Venus::Test")

=back

=over 4

=item for example 3

  # given: synopsis

  package main;

  my $for = $test->for('synopsis', sub{
    my ($tryable) = @_;
    return $tryable->result;
  });

  # bless(..., "Venus::Test")

=back

=over 4

=item for example 4

  # given: synopsis

  package main;

  my $for = $test->for('example', 1, 'test', sub {
    my ($tryable) = @_;
    return $tryable->result;
  });

  # bless(..., "Venus::Test")

=back

=cut

=head2 like

  like(string $data, string | Venus::Regexp $match, string $description) (any)

The like method dispatches to the L<Test::More/like> operation and returns the
result.

I<Since C<3.55>>

=over 4

=item like example 1

  # given: synopsis

  package main;

  my $like = $test->like('hello world', 'world', 'example-1 like passed');

  # true

=back

=over 4

=item like example 2

  # given: synopsis

  package main;

  my $like = $test->like('hello world', qr/world/, 'example-1 like passed');

  # true

=back

=cut

=head2 more

  more(any @args) (Venus::Test)

The more method dispatches to the L<Test::More> method specified by the first
argument and returns its result.

I<Since C<3.55>>

=over 4

=item more example 1

  # given: synopsis

  package main;

  my $more = $test->more('ok', true);

  # true

=back

=cut

=head2 okay

  okay(any $data, string $description) (any)

The okay method dispatches to the L<Test::More/ok> operation and returns the
result.

I<Since C<3.55>>

=over 4

=item okay example 1

  # given: synopsis

  package main;

  my $okay = $test->okay(1, 'example-1 okay passed');

  # true

=back

=over 4

=item okay example 2

  # given: synopsis

  package main;

  my $okay = $test->okay(!0, 'example-1 okay passed');

  # true

=back

=cut

=head2 okay_can

  okay_can(string $name, string @args) (any)

The okay_can method dispatches to the L<Test::More/can_ok> operation and
returns the result.

I<Since C<3.55>>

=over 4

=item okay_can example 1

  # given: synopsis

  package main;

  my $okay_can = $test->okay_can('Venus::Test', 'diag');

  # true

=back

=cut

=head2 okay_isa

  okay_isa(string $name, string $base) (any)

The okay_isa method dispatches to the L<Test::More/isa_ok> operation and
returns the result.

I<Since C<3.55>>

=over 4

=item okay_isa example 1

  # given: synopsis

  package main;

  my $okay_isa = $test->okay_isa('Venus::Test', 'Venus::Kind');

  # true

=back

=cut

=head2 pass

  pass(any $data, string $description) (any)

The pass method dispatches to the L<Test::More/ok> operation expecting the
first argument to be truthy and returns the result.

I<Since C<3.55>>

=over 4

=item pass example 1

  # given: synopsis

  package main;

  my $fail = $test->pass(1, 'example-1 pass passed');

  # true

=back

=cut

=head2 perform

  perform(string $name, any @args) (boolean)

The perform method dispatches to the C<perform_data_for_${name}> method
indictated by the first argument and returns the result. Returns an arrayref in
scalar context, and a list in list context.

I<Since C<3.55>>

=over 4

=item perform example 1

  # given: synopsis

  package main;

  my $data = $test->collect('name');

  my $perform = $test->perform('name', $data);

  # true

=back

=cut

=head2 perform_test_for_abstract

  perform_test_for_abstract(arrayref $data) (boolean)

The perform_data_for_abstract method performs an overridable test for the C<abstract> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_abstract example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_abstract {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=abstract content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_abstract;

  my $perform_test_for_abstract = $test->perform_test_for_abstract(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_attribute

  perform_test_for_attribute(string $name, arrayref $data) (boolean)

The perform_data_for_attribute method performs an overridable test for the C<attribute $name> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_attribute example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_attribute {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=attribute $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_attribute('name');

  my $perform_test_for_attribute = $test->perform_test_for_attribute(
    'name', $data,
  );

  # true

=back

=cut

=head2 perform_test_for_authors

  perform_test_for_authors(arrayref $data) (boolean)

The perform_data_for_authors method performs an overridable test for the C<authors> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_authors example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_authors {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=authors content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_authors;

  my $perform_test_for_authors = $test->perform_test_for_authors(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_description

  perform_test_for_description(arrayref $data) (boolean)

The perform_data_for_description method performs an overridable test for the C<description> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_description example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_description {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=description content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_description;

  my $perform_test_for_description = $test->perform_test_for_description(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_encoding

  perform_test_for_encoding(arrayref $data) (boolean)

The perform_data_for_encoding method performs an overridable test for the C<encoding> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_encoding example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_encoding {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=encoding content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_encoding;

  my $perform_test_for_encoding = $test->perform_test_for_encoding(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_error

  perform_test_for_error(arrayref $data) (boolean)

The perform_data_for_error method performs an overridable test for the C<error $name> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_error example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_error {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=error $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_error('error_on_unknown');

  my $perform_test_for_error = $test->perform_test_for_error(
    'error_on_unknown', $data,
  );

  # true

=back

=cut

=head2 perform_test_for_example

  perform_test_for_example(arrayref $data) (boolean)

The perform_data_for_example method performs an overridable test for the C<example-$number $name> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_example example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_example {
    my ($self, $number, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=example-$number $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_example(1, 'execute');

  my $perform_test_for_example = $test->perform_test_for_example(
    1, 'execute', $data,
  );

  # true

=back

=cut

=head2 perform_test_for_feature

  perform_test_for_feature(arrayref $data) (boolean)

The perform_data_for_feature method performs an overridable test for the C<feature $name> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_feature example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_feature {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=feature $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_feature('noop');

  my $perform_test_for_feature = $test->perform_test_for_feature(
    'noop', $data,
  );

  # true

=back

=cut

=head2 perform_test_for_function

  perform_test_for_function(arrayref $data) (boolean)

The perform_data_for_function method performs an overridable test for the C<function $name> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_function example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_function {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=function $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_function('eg');

  my $perform_test_for_function = $test->perform_test_for_function(
    'eg', $data,
  );

  # true

=back

=cut

=head2 perform_test_for_includes

  perform_test_for_includes(arrayref $data) (boolean)

The perform_data_for_includes method performs an overridable test for the C<includes> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_includes example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_includes {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=includes content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_includes;

  my $perform_test_for_includes = $test->perform_test_for_includes(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_inherits

  perform_test_for_inherits(arrayref $data) (boolean)

The perform_data_for_inherits method performs an overridable test for the C<inherits> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_inherits example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_inherits {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=inherits content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_inherits;

  my $perform_test_for_inherits = $test->perform_test_for_inherits(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_integrates

  perform_test_for_integrates(arrayref $data) (boolean)

The perform_data_for_integrates method performs an overridable test for the C<integrates> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_integrates example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_integrates {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=integrates content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_integrates;

  my $perform_test_for_integrates = $test->perform_test_for_integrates(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_layout

  perform_test_for_layout(arrayref $data) (boolean)

The perform_data_for_layout method performs an overridable test for the C<layout> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_layout example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_layout {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=layout content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_layout;

  my $perform_test_for_layout = $test->perform_test_for_layout(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_libraries

  perform_test_for_libraries(arrayref $data) (boolean)

The perform_data_for_libraries method performs an overridable test for the C<libraries> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_libraries example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_libraries {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=libraries content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_libraries;

  my $perform_test_for_libraries = $test->perform_test_for_libraries(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_license

  perform_test_for_license(arrayref $data) (boolean)

The perform_data_for_license method performs an overridable test for the C<license> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_license example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_license {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=license content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_license;

  my $perform_test_for_license = $test->perform_test_for_license(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_message

  perform_test_for_message(arrayref $data) (boolean)

The perform_data_for_message method performs an overridable test for the C<message $name> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_message example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_message {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=message $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_message('accept');

  my $perform_test_for_message = $test->perform_test_for_message(
    'accept', $data,
  );

  # true

=back

=cut

=head2 perform_test_for_metadata

  perform_test_for_metadata(arrayref $data) (boolean)

The perform_data_for_metadata method performs an overridable test for the C<metadata $name> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_metadata example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_metadata {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=metadata $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_metadata('execute');

  my $perform_test_for_metadata = $test->perform_test_for_metadata(
    'execute', $data,
  );

  # true

=back

=cut

=head2 perform_test_for_method

  perform_test_for_method(arrayref $data) (boolean)

The perform_data_for_method method performs an overridable test for the C<method $name> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_method example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_method {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=method $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_method('execute');

  my $perform_test_for_method = $test->perform_test_for_method(
    'execute', $data,
  );

  # true

=back

=cut

=head2 perform_test_for_name

  perform_test_for_name(arrayref $data) (boolean)

The perform_data_for_name method performs an overridable test for the C<name> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_name example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_name {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_name;

  my $perform_test_for_name = $test->perform_test_for_name(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_operator

  perform_test_for_operator(arrayref $data) (boolean)

The perform_data_for_operator method performs an overridable test for the C<operator $name> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_operator example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_operator {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=operator $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_operator('("")');

  my $perform_test_for_operator = $test->perform_test_for_operator(
    '("")', $data,
  );

  # true

=back

=cut

=head2 perform_test_for_partials

  perform_test_for_partials(arrayref $data) (boolean)

The perform_data_for_partials method performs an overridable test for the C<partials> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_partials example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_partials {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=partials content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_partials;

  my $perform_test_for_partials = $test->perform_test_for_partials(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_project

  perform_test_for_project(arrayref $data) (boolean)

The perform_data_for_project method performs an overridable test for the C<project> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_project example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_project {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=project content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_project;

  my $perform_test_for_project = $test->perform_test_for_project(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_signature

  perform_test_for_signature(arrayref $data) (boolean)

The perform_data_for_signature method performs an overridable test for the C<signature $name> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_signature example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_signature {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=signature $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_signature('execute');

  my $perform_test_for_signature = $test->perform_test_for_signature(
    'execute', $data,
  );

  # true

=back

=cut

=head2 perform_test_for_synopsis

  perform_test_for_synopsis(arrayref $data) (boolean)

The perform_data_for_synopsis method performs an overridable test for the C<synopsis> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_synopsis example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_synopsis {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=synopsis content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_synopsis;

  my $perform_test_for_synopsis = $test->perform_test_for_synopsis(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_tagline

  perform_test_for_tagline(arrayref $data) (boolean)

The perform_data_for_tagline method performs an overridable test for the C<tagline> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_tagline example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_tagline {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=tagline content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_tagline;

  my $perform_test_for_tagline = $test->perform_test_for_tagline(
    $data,
  );

  # true

=back

=cut

=head2 perform_test_for_version

  perform_test_for_version(arrayref $data) (boolean)

The perform_data_for_version method performs an overridable test for the C<version> section and returns truthy or falsy.

I<Since C<3.55>>

=over 4

=item perform_test_for_version example 1

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_version {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=version content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_version;

  my $perform_test_for_version = $test->perform_test_for_version(
    $data,
  );

  # true

=back

=cut

=head2 present

  present(string $name, any @args) (string)

The present method dispatches to the C<present_data_for_${name}> method
indictated by the first argument and returns the result. Returns an arrayref in
scalar context, and a list in list context.

I<Since C<3.55>>

=over 4

=item present example 1

  # given: synopsis

  package main;

  my $present = $test->present('name');

  # =head1 NAME
  #
  # Venus::Test - Test Class
  #
  # =cut

=back

=cut

=head2 present_data_for_abstract

  present_data_for_abstract() (arrayref)

The present_data_for_abstract method builds a documentation block for the C<abstract> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_abstract example 1

  # =abstract
  #
  # Example Test Documentation
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_abstract = $test->present_data_for_abstract;

  # =head1 ABSTRACT
  #
  # Example Test Documentation
  #
  # =cut

=back

=cut

=head2 present_data_for_attribute

  present_data_for_attribute(string $name) (arrayref)

The present_data_for_attribute method builds a documentation block for the C<attribute $name> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_attribute example 1

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_attribute = $test->present_data_for_attribute('name');

  # =head2 name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =over 4
  #
  # =item name example 1
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =back
  #
  # =cut

=back

=cut

=head2 present_data_for_authors

  present_data_for_authors() (arrayref)

The present_data_for_authors method builds a documentation block for the C<authors> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_authors example 1

  # =authors
  #
  # Awncorp, C<awncorp@cpan.org>
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_authors = $test->present_data_for_authors;

  # =head1 AUTHORS
  #
  # Awncorp, C<awncorp@cpan.org>
  #
  # =cut

=back

=cut

=head2 present_data_for_description

  present_data_for_description() (arrayref)

The present_data_for_description method builds a documentation block for the C<description> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_description example 1

  # =description
  #
  # This package provides an example class.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_description = $test->present_data_for_description;

  # =head1 DESCRIPTION
  #
  # This package provides an example class.
  #
  # =cut

=back

=cut

=head2 present_data_for_encoding

  present_data_for_encoding() (arrayref)

The present_data_for_encoding method builds a documentation block for the C<encoding> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_encoding example 1

  # =encoding
  #
  # utf8
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_encoding = $test->present_data_for_encoding;

  # =encoding UTF8
  #
  # =cut

=back

=cut

=head2 present_data_for_error

  present_data_for_error(string $name) (arrayref)

The present_data_for_error method builds a documentation block for the C<error $name> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_error example 1

  # =error error_on_unknown
  #
  # This package may raise an error_on_unknown error.
  #
  # =cut
  #
  # =example-1 error_on_unknown
  #
  #   # given: synopsis
  #
  #   my $error = $example->catch('error', {
  #     with => 'error_on_unknown',
  #   });
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_error = $test->present_data_for_error('error_on_unknown');

  # =over 4
  #
  # =item error: C<error_on_unknown>
  #
  # This package may raise an error_on_unknown error.
  #
  # B<example 1>
  #
  #   # given: synopsis
  #
  #   my $error = $example->catch('error', {
  #     with => 'error_on_unknown',
  #   });
  #
  #   # "..."
  #
  # =back

=back

=cut

=head2 present_data_for_example

  present_data_for_example(number $numberm string $name) (arrayref)

The present_data_for_example method builds a documentation block for the C<example-$number $name> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_example example 1

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_example = $test->present_data_for_example(1, 'name');

  # =over 4
  #
  # =item name example 1
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =back

=back

=cut

=head2 present_data_for_feature

  present_data_for_feature(string $name) (arrayref)

The present_data_for_feature method builds a documentation block for the C<feature $name> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_feature example 1

  # =feature noop
  #
  # This package is no particularly useful features.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_feature = $test->present_data_for_feature('noop');

  # =over 4
  #
  # =item noop
  #
  # This package is no particularly useful features.
  #
  # =back

=back

=cut

=head2 present_data_for_function

  present_data_for_function(string $name) (arrayref)

The present_data_for_function method builds a documentation block for the C<function $name> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_function example 1

  # =function eg
  #
  # The eg function returns a new instance of Example.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $example = eg();
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_function = $test->present_data_for_function('eg');

  # =head2 eg
  #
  # The eg function returns a new instance of Example.
  #
  # =cut

=back

=cut

=head2 present_data_for_includes

  present_data_for_includes() (arrayref)

The present_data_for_includes method builds a documentation block for the C<includes> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_includes example 1

  # =includes
  #
  # function: eg
  #
  # method: prepare
  # method: execute
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_includes = $test->present_data_for_includes;

  # undef

=back

=cut

=head2 present_data_for_inherits

  present_data_for_inherits() (arrayref)

The present_data_for_inherits method builds a documentation block for the C<inherits> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_inherits example 1

  # =inherits
  #
  # Venus::Core::Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_inherits = $test->present_data_for_inherits;

  # =head1 INHERITS
  #
  # This package inherits behaviors from:
  #
  # L<Venus::Core::Class>
  #
  # =cut

=back

=cut

=head2 present_data_for_integrates

  present_data_for_integrates() (arrayref)

The present_data_for_integrates method builds a documentation block for the C<integrates> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_integrates example 1

  # =integrates
  #
  # Venus::Role::Catchable
  # Venus::Role::Throwable
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_integrates = $test->present_data_for_integrates;

  # =head1 INTEGRATES
  #
  # This package integrates behaviors from:
  #
  # L<Venus::Role::Catchable>
  #
  # L<Venus::Role::Throwable>
  #
  # =cut

=back

=cut

=head2 present_data_for_layout

  present_data_for_layout() (arrayref)

The present_data_for_layout method builds a documentation block for the C<layout> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_layout example 1

  # =layout
  #
  # encoding
  # name
  # synopsis
  # description
  # attributes: attribute
  # authors
  # license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_layout = $test->present_data_for_layout;

  # undef

=back

=cut

=head2 present_data_for_libraries

  present_data_for_libraries() (arrayref)

The present_data_for_libraries method builds a documentation block for the C<libraries> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_libraries example 1

  # =libraries
  #
  # Venus::Check
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_libraries = $test->present_data_for_libraries;

  # =head1 LIBRARIES
  #
  # This package uses type constraints from:
  #
  # L<Venus::Check>
  #
  # =cut

=back

=cut

=head2 present_data_for_license

  present_data_for_license() (arrayref)

The present_data_for_license method builds a documentation block for the C<license> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_license example 1

  # =license
  #
  # No license granted.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_license = $test->present_data_for_license;

  # =head1 LICENSE
  #
  # No license granted.
  #
  # =cut

=back

=cut

=head2 present_data_for_message

  present_data_for_message(string $name) (arrayref)

The present_data_for_message method builds a documentation block for the C<message $name> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_message example 1

  # =message accept
  #
  # The accept message represents acceptance.
  #
  # =cut
  #
  # =example-1 accept
  #
  #   # given: synopsis
  #
  #   my $accept = $example->accept;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_message = $test->present_data_for_message('accept');

  # =over 4
  #
  # =item accept
  #
  # The accept message represents acceptance.
  #
  # B<example 1>
  #
  #   # given: synopsis
  #
  #   my $accept = $example->accept;
  #
  #   # "..."
  #
  # =back

=back

=cut

=head2 present_data_for_metadata

  present_data_for_metadata(string $name) (arrayref)

The present_data_for_metadata method builds a documentation block for the C<metadata $name> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_metadata example 1

  # =method prepare
  #
  # The prepare method prepares for execution.
  #
  # =cut
  #
  # =metadata prepare
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 prepare
  #
  #   # given: synopsis
  #
  #   my $prepare = $example->prepare;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_metadata = $test->present_data_for_metadata('prepare');

  # undef

=back

=cut

=head2 present_data_for_method

  present_data_for_method(string $name) (arrayref)

The present_data_for_method method builds a documentation block for the C<method $name> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_method example 1

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_method = $test->present_data_for_method('execute');

  # =head2 execute
  #
  #   execute() (boolean)
  #
  # The execute method executes the logic.
  #
  # I<Since C<1.2.3>>
  #
  # =over 4
  #
  # =item execute example 1
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =back
  #
  # =cut

=back

=cut

=head2 present_data_for_name

  present_data_for_name() (arrayref)

The present_data_for_name method builds a documentation block for the C<name> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_name example 1

  # =name

  # Example

  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_name = $test->present_data_for_name;

  # =head1 NAME
  #
  # Example - Example Class
  #
  # =cut

=back

=cut

=head2 present_data_for_operator

  present_data_for_operator(string $name) (arrayref)

The present_data_for_operator method builds a documentation block for the C<operator $name> section and returns it as a string.

I<Since C<3.55>>

=over 4

=item present_data_for_operator example 1

  # =operator ("")
  #
  # This package overloads the C<""> operator.
  #
  # =cut
  #
  # =example-1 ("")
  #
  #   # given: synopsis
  #
  #   my $string = "$example";
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_operator = $test->present_data_for_operator('("")');

  # =over 4
  #
  # =item operation: C<("")>
  #
  # This package overloads the C<""> operator.
  #
  # B<example 1>
  #
  #   # given: synopsis
  #
  #   my $string = "$example";
  #
  #   # "..."
  #
  # =back

=back

=cut

=head2 render

  render(string $file) (Venus::Path)

The render method reads the test specification and generates L<perlpod>
documentation and returns a L<Venus::Path> object for the filename provided.

I<Since C<3.55>>

=over 4

=item render example 1

  # given: synopsis

  package main;

  my $path = $test->render('t/path/pod/test');

  # bless(..., "Venus::Path")

=back

=cut

=head2 same

  same(any $data1, any $data2, string $description) (any)

The same method dispatches to the L<Test::More/is_deeply> operation and returns
the result.

I<Since C<3.55>>

=over 4

=item same example 1

  # given: synopsis

  package main;

  my $same = $test->same({1..4}, {1..4}, 'example-1 same passed');

  # true

=back

=cut

=head2 skip

  skip(string $description, boolean | coderef $value) (any)

The skip method dispatches to the L<Test::More/skip> operation with the
C<plan_all> option and returns the result.

I<Since C<3.55>>

=over 4

=item skip example 1

  # given: synopsis

  package main;

  my $skip = $test->skip('Unsupported', !0);

  # true

=back

=over 4

=item skip example 2

  # given: synopsis

  package main;

  my $skip = $test->skip('Unsupported', sub{!0});

  # true

=back

=cut

=head1 FEATURES

This package provides the following features:

=cut

=over 4

=item spec

  # [required]

  =name
  =abstract
  =tagline
  =synopsis
  =description

  # [optional]

  =includes
  =libraries
  =inherits
  =integrates

  # [optional; repeatable]

  =attribute $name
  =signature $name
  =example-$number $name # [repeatable]

  # [optional; repeatable]

  =function $name
  =signature $name
  =example-$number $name # [repeatable]

  # [optional; repeatable]

  =message $name
  =signature $name
  =example-$number $name # [repeatable]

  # [optional; repeatable]

  =method $name
  =signature $name
  =example-$number $name # [repeatable]

  # [optional; repeatable]

  =routine $name
  =signature $name
  =example-$number $name # [repeatable]

  # [optional; repeatable]

  =feature $name
  =example $name

  # [optional; repeatable]

  =error $name
  =example $name

  # [optional; repeatable]

  =operator $name
  =example $name

  # [optional]

  =partials
  =authors
  =license
  =project

The specification is designed to accommodate typical package declarations. It
is used by the parser to provide the content used in test automation and
document generation. B<Note:> When code blocks are evaluated, the
I<"redefined"> warnings are now automatically disabled.

=back

=over 4

=item spec-abstract

  =abstract

  Example Test Documentation

  =cut

  $test->for('abstract');

The C<abstract> block should contain a subtitle describing the package. This is
tested for existence.

=back

=over 4

=item spec-attribute

  =attribute name

  The name attribute is read-write, optional, and holds a string.

  =example-1 name

    # given: synopsis

    my $name = $example->name;

    # "..."

  =cut

  $test->for('attribute', 'name');

  $test->for('example', 1, 'name', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

Describing an attribute requires at least three blocks, i.e. C<attribute
$name>, C<signature $name>, and C<example-$number $name>. The C<attribute>
block should contain a description of the attribute and its purpose. The
C<signature> block should contain a routine signature in the form of
C<$signature : $return_type>, where C<$signature> is a valid typed signature
and C<$return_type> is any valid L<Venus::Check> expression. The
C<example-$number> block is a repeatable block, and at least one block must
exist when documenting an attribute. The C<example-$number> block should
contain valid Perl code and return a value. The block may contain a "magic"
comment in the form of C<given: synopsis> or C<given: example-$number $name>
which if present will include the given code example(s) with the evaluation of
the current block. Each attribute is tested and must be recognized to exist.

=back

=over 4

=item spec-authors

  =authors

  Awncorp, C<awncorp@cpan.org>

  =cut

  $test->for('authors');

The C<authors> block should contain text describing the authors of the package.

=back

=over 4

=item spec-description

  =description

  This package provides an example class.

  =cut

  $test->for('description');

The C<description> block should contain a description of the package and it's
behaviors.

=back

=over 4

=item spec-encoding

  =encoding

  utf8

  =cut

  $test->for('encoding');

The C<encoding> block should contain the appropriate L<encoding|perlpod/encoding-encodingname>.

=back

=over 4

=item spec-error

  =error error_on_unknown

  This package may raise an error_on_unknown error.

  =example-1 error_on_unknown

    # given: synopsis

    my $error = $example->error;

    # "..."

  =cut

  $test->for('error', 'error_on_unknown');

  $test->for('example', 1, 'error_on_unknown', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<error $name> block should contain a description of the error the package
may raise, and can include an C<example-$number $name> block to ensure the
error is raised and caught.

=back

=over 4

=item spec-example

  =example-1 name

    # given: synopsis

    my $name = $example->name;

    # "..."

  =cut

  $test->for('example', 1, 'name', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<example-$number $name> block should contain valid Perl code and return a
value. The block may contain a "magic" comment in the form of C<given:
synopsis> or C<given: example-$number $name> which if present will include the
given code example(s) with the evaluation of the current block.

=back

=over 4

=item spec-feature

  =feature noop

  This package is no particularly useful features.

  =example-1 noop

    # given: synopsis

    my $feature = $example->feature;

    # "..."

  =cut

  $test->for('feature');

  $test->for('example', 1, 'noop', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<feature $name> block should contain a description of the feature(s) the
package enables, and can include an C<example-$number $name> block to ensure
the feature described works as expected.

=back

=over 4

=item spec-function

  =function eg

  The eg function returns a new instance of Example.

  =example-1 eg

    # given: synopsis

    my $example = eg();

    # "..."

  =cut

  $test->for('function', 'eg');

  $test->for('example', 1, 'eg', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

Describing a function requires at least three blocks, i.e. C<function $name>,
C<signature $name>, and C<example-$number $name>. The C<function> block should
contain a description of the function and its purpose. The C<signature> block
should contain a routine signature in the form of C<$signature : $return_type>,
where C<$signature> is a valid typed signature and C<$return_type> is any valid
L<Venus::Check> expression. The C<example-$number> block is a repeatable block,
and at least one block must exist when documenting an attribute. The
C<example-$number> block should contain valid Perl code and return a value. The
block may contain a "magic" comment in the form of C<given: synopsis> or
C<given: example-$number $name> which if present will include the given code
example(s) with the evaluation of the current block. Each attribute is tested
and must be recognized to exist.

=back

=over 4

=item spec-includes

  =includes

  function: eg

  method: prepare
  method: execute

  =cut

  $test->for('includes');

The C<includes> block should contain a list of C<function>, C<method>, and/or
C<routine> names in the format of C<$type: $name>. Empty (or commented out)
lines are ignored. Each function, method, and/or routine is tested to be
documented properly, i.e. has the requisite counterparts (e.g. signature and at
least one example block). Also, the package must recognize that each exists.

=back

=over 4

=item spec-inherits

  =inherits

  Venus::Core::Class

  =cut

  $test->for('inherits');

The C<inherits> block should contain a list of parent packages. These packages
are tested for loadability.

=back

=over 4

=item spec-integrates

  =integrates

  Venus::Role::Catchable
  Venus::Role::Throwable

  =cut

  $test->for('integrates');

The C<integrates> block should contain a list of packages that are involved in
the behavior of the main package. These packages are not automatically tested.

=back

=over 4

=item spec-layout

  =layout

  encoding
  name
  synopsis
  description
  attributes: attribute
  authors
  license

  =cut

  $test->for('layout');

The C<layout> block should contain a list blocks to render using L</render>, in
the order they should be rendered.

=back

=over 4

=item spec-libraries

  =libraries

  Venus::Check

  =cut

  $test->for('libraries');

The C<libraries> block should contain a list of packages, each describing how
particular type names used within function and method signatures will be
validated. These packages are tested for loadability.

=back

=over 4

=item spec-license

  =license

  No license granted.

  =cut

  $test->for('license');

The C<license> block should contain a link and/or description of the license
governing the package.

=back

=over 4

=item spec-message

  =message accept

  The accept message represents acceptance.

  =example-1 accept

    # given: synopsis

    my $accept = $example->accept;

    # "..."

  =cut

  $test->for('message', 'accept');

  $test->for('example', 1, 'accept', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

Describing a message requires at least three blocks, i.e. C<message $name>,
C<signature $name>, and C<example-$number $name>. The C<message> block should
contain a description of the message and its purpose. The C<signature> block
should contain a routine signature in the form of C<$signature : $return_type>,
where C<$signature> is a valid typed signature and C<$return_type> is any valid
L<Venus::Check> expression. The C<example-$number> block is a repeatable block,
and at least one block must exist when documenting an attribute. The
C<example-$number> block should contain valid Perl code and return a value. The
block may contain a "magic" comment in the form of C<given: synopsis> or
C<given: example-$number $name> which if present will include the given code
example(s) with the evaluation of the current block. Each attribute is tested
and must be recognized to exist.

=back

=over 4

=item spec-metadata

  =metadata prepare

  {since => "1.2.3"}

  =cut

  $test->for('metadata', 'prepare');

The C<metadata $name> block should contain a stringified hashref containing Perl data
structures used in the rendering of the package's documentation.

=back

=over 4

=item spec-method

  =method prepare

  The prepare method prepares for execution.

  =example-1 prepare

    # given: synopsis

    my $prepare = $example->prepare;

    # "..."

  =cut

  $test->for('method', 'prepare');

  $test->for('example', 1, 'prepare', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

Describing a method requires at least three blocks, i.e. C<method $name>,
C<signature $name>, and C<example-$number $name>. The C<method> block should
contain a description of the method and its purpose. The C<signature> block
should contain a routine signature in the form of C<$signature : $return_type>,
where C<$signature> is a valid typed signature and C<$return_type> is any valid
L<Venus::Check> expression. The C<example-$number> block is a repeatable block,
and at least one block must exist when documenting an attribute. The
C<example-$number> block should contain valid Perl code and return a value. The
block may contain a "magic" comment in the form of C<given: synopsis> or
C<given: example-$number $name> which if present will include the given code
example(s) with the evaluation of the current block. Each attribute is tested
and must be recognized to exist.

=back

=over 4

=item spec-name

  =name

  Example

  =cut

  $test->for('name');

The C<name> block should contain the package name. This is tested for
loadability.

=back

=over 4

=item spec-operator

  =operator ("")

  This package overloads the C<""> operator.

  =example-1 ("")

    # given: synopsis

    my $string = "$example";

    # "..."

  =cut

  $test->for('operator', '("")');

  $test->for('example', 1, '("")', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<operator $name> block should contain a description of the overloaded
operation the package performs, and can include an C<example-$number $name>
block to ensure the operation is functioning properly.

=back

=over 4

=item spec-partials

  =partials

  t/path/to/other.t: present: authors
  t/path/to/other.t: present: license

  =cut

  $test->for('partials');

The C<partials> block should contain references to other marked-up test files
in the form of C<$file: $method: $section>, which will call the C<$method> on a
L<Venus::Test> instance for the C<$file> and include the results in-place as
part of the rendering of the current file.

=back

=over 4

=item spec-project

  =project

  https://github.com/awncorp/example

  =cut

  $test->for('project');

The C<project> block should contain a description and/or links for the
package's project.

=back

=over 4

=item spec-signature

  =signature prepare

    prepare() (boolean)

  =cut

  $test->for('signature', 'prepare');

The C<signature $name> block should contain a routine signature in the form of
C<$signature : $return_type>, where C<$signature> is a valid typed signature
and C<$return_type> is any valid L<Venus::Check> expression.

=back

=over 4

=item spec-synopsis

  =synopsis

    use Example;

    my $example = Example->new;

    # bless(..., "Example")

  =cut

  $test->for('synopsis', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<synopsis> block should contain the normative usage of the package. This
is tested for existence. This block should be written in a way that allows it
to be evaled successfully and should return a value.

=back

=over 4

=item spec-tagline

  =tagline

  Example Class

  =cut

  $test->for('tagline');

The C<tagline> block should contain a 2-5 word description of the package,
which will be prepended to the name as a full description of the package.

=back

=over 4

=item spec-version

  =version

  1.2.3

  =cut

  $test->for('version');

The C<version> block should contain a valid version number for the package.

=back

=over 4

=item test-for

  # ...

  $test->for('name');

This framework provides a set of automated subtests based on the package
specification, but not everything can be automated so it also provides you with
powerful hooks into the framework for manual testing.

  # ...

  $test->for('synopsis', sub {
    my ($tryable) = @_;

    my $result = $tryable->result;

    # must return truthy to continue
    $result;
  });

The code examples documented can be automatically evaluated (evaled) and
returned using a callback you provide for further testing. Because the code
examples are returned as L<Venus::Try> objects this makes capturing and testing
exceptions simple, for example:

  # ...

  $test->for('synopsis', sub {
    my ($tryable) = @_;

    # catch exception thrown by the synopsis
    $tryable->catch('Path::Find::Error', sub {
      return $_[0];
    });

    # test the exception
    my $result = $tryable->result;
    ok $result->isa('Path::Find::Error'), 'exception caught';

    # must return truthy to continue
    $result;
  });

Additionally, another manual testing hook (with some automation) is the
C<example> method. This hook evaluates (evals) a given example and returns the
result as a L<Venus::Try> object. The first argument is the example ID (or
number), for example:

  # ...

  $test->for('example', 1, 'children', sub {
    my ($tryable) = @_;

    my $result = $tryable->result;

    # must return truthy to continue
    $result;
  });

Finally, the lesser-used but useful manual testing hook is the C<feature>
method. This hook evaluates (evals) a documented feature and returns the result
as a L<Venus::Try> object, for example:

  # ...

  $test->for('feature', 'export-path-make', sub {
    my ($tryable) = @_;

    ok my $result = $tryable->result, 'result ok';

    # must return truthy to continue
    $result;
  });

The test automation and documentation generation enabled through this framework
makes it easy to maintain source/test/documentation parity. This also increases
reusability and reduces the need for complicated state and test setup.

=back

=head1 ERRORS

This package may raise the following errors:

=cut

=over 4

=item error: C<error_on_abstract>

This package may raise an error_on_abstract exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_abstract',
  };

  my $error = $test->catch('error', $input);

  # my $name = $error->name;

  # "on_abstract"

  # my $message = $error->render;

  # "Test file \"t/Venus_Test.t\" missing abstract section"

  # my $file = $error->stash('file');

  # "t/Venus_Test.t"

=back

=over 4

=item error: C<error_on_description>

This package may raise an error_on_description exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_description',
  };

  my $error = $test->catch('error', $input);

  # my $name = $error->name;

  # "on_description"

  # my $message = $error->render;

  # "Test file \"t/Venus_Test.t\" missing description section"

  # my $file = $error->stash('file');

  # "t/Venus_Test.t"

=back

=over 4

=item error: C<error_on_name>

This package may raise an error_on_name exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_name',
  };

  my $error = $test->catch('error', $input);

  # my $name = $error->name;

  # "on_name"

  # my $message = $error->render;

  # "Test file \"t/Venus_Test.t\" missing name section"

  # my $file = $error->stash('file');

  # "t/Venus_Test.t"

=back

=over 4

=item error: C<error_on_synopsis>

This package may raise an error_on_synopsis exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_synopsis',
  };

  my $error = $test->catch('error', $input);

  # my $name = $error->name;

  # "on_synopsis"

  # my $message = $error->render;

  # "Test file \"t/Venus_Test.t\" missing synopsis section"

  # my $file = $error->stash('file');

  # "t/Venus_Test.t"

=back

=over 4

=item error: C<error_on_tagline>

This package may raise an error_on_tagline exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_tagline',
  };

  my $error = $test->catch('error', $input);

  # my $name = $error->name;

  # "on_tagline"

  # my $message = $error->render;

  # "Test file \"t/Venus_Test.t\" missing tagline section"

  # my $file = $error->stash('file');

  # "t/Venus_Test.t"

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut