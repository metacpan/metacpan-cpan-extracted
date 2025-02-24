package Venus::Check;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

use Venus::Type;

base 'Venus::Kind::Utility';

with 'Venus::Role::Buildable';

# ATTRIBUTES

attr 'on_eval';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    on_eval => ref $data eq 'ARRAY' ? $data : [$data],
  };
}

sub build_args {
  my ($self, $data) = @_;

  $data->{on_eval} = [] if !$data->{on_eval};

  return $data;
}

# METHODS

sub any {
  my ($self) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    return $source->pass($value, {
      from => 'any',
    });
  };

  return $self;
}

sub accept {
  my ($self, $name, @args) = @_;

  if (!$name) {
    return $self;
  }
  if ($self->can($name)) {
    return $self->$name(@args);
  }
  else {
    return $self->identity($name, @args);
  }
}

sub array {
  my ($self, @code) = @_;

  return $self->arrayref(@code);
}

sub arrayref {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'array')) {
      return $source->pass($value, {
        from => 'arrayref',
      });
    }
    else {
      return $source->fail($value, {
        from => 'arrayref',
        expected => 'arrayref',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub attributes {
  my ($self, @pairs) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'object')) {
      return $source->pass($value, {
        from => 'attributes',
      });
    }
    else {
      return $source->fail($value, {
        from => 'attributes',
        expected => 'object',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if (@pairs % 2) {
      return $source->fail($value, {
        from => 'attributes',
        args => [@pairs],
        with => 'error_on_pairs',
      });
    }
    my $result = true;
    for (my $i = 0; $i < @pairs;) {
      my ($key, $data) = (map $pairs[$_], $i++, $i++);
      if (!$value->can($key)) {
        $result = $source->fail($value, {
          from => 'attributes',
          name => $key,
          with => 'error_on_missing',
        });
        last;
      }
      my ($match, @args) = (ref $data) ? (@{$data}) : ($data);
      my $check = $source->branch($key)->accept($match, @args);
      if (!$check->eval($value->$key)) {
        $result = $source->fail($value, {
          branch => $check->{'$branch'},
          %{$check->{'$result'}},
          from => 'attributes',
        });
        last;
      }
    }
    if (!$result) {
      return $result;
    }
    else {
      return $source->pass($value, {
        from => 'attributes',
      });
    }
  };

  return $self;
}

sub bool {
  my ($self, @code) = @_;

  return $self->boolean(@code);
}

sub boolean {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'boolean')) {
      return $source->pass($value, {
        from => 'boolean',
      });
    }
    else {
      return $source->fail($value, {
        from => 'boolean',
        expected => 'boolean',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub branch {
  my ($self, @args) = @_;

  my $source = $self->new;

  $source->{'$branch'} = [
    ($self->{'$branch'} ? @{$self->{'$branch'}} : ()), @args
  ];

  return $source;
}

sub clear {
  my ($self) = @_;

  @{$self->on_eval} = ();

  delete $self->{'$branch'};
  delete $self->{'$result'};

  return $self;
}

sub code {
  my ($self, @code) = @_;

  return $self->coderef(@code);
}

sub coded {
  my ($self, $data, $name) = @_;

  require Venus::Type;

  return Venus::Type->new($data)->coded($name) ? true : false;
}

sub coderef {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'code')) {
      return $source->pass($value, {
        from => 'coderef',
      });
    }
    else {
      return $source->fail($value, {
        from => 'coderef',
        expected => 'coderef',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub consumes {
  my ($self, $role) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'object')) {
      return $source->pass($value, {
        from => 'consumes',
      });
    }
    else {
      return $source->fail($value, {
        from => 'consumes',
        expected => 'object',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if ($value->can('DOES') && $value->DOES($role)) {
      return $source->pass($value, {
        from => 'consumes',
      });
    }
    else {
      return $source->fail($value, {
        from => 'consumes',
        role => $role,
        with => 'error_on_consumes',
      });
    }
  };

  return $self;
}

sub defined {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if (CORE::defined($value)) {
      return $source->pass($value, {
        from => 'defined',
      });
    }
    else {
      return $source->fail($value, {
        from => 'defined',
        with => 'error_on_defined',
      });
    }
  }, @code;

  return $self;
}

sub either {
  my ($self, @data) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    my $returns;
    my @errors;
    my @results;
    for (my $i = 0; $i < @data; $i++) {
      my ($match, @args) = (ref $data[$i]) ? (@{$data[$i]}) : ($data[$i]);
      my $check = $source->branch->do('accept', $match, @args);
      if ($check->eval($value)) {
        $returns = $source->pass($value, {
          from => 'either',
          ($check->{'$branch'} ? (branch => $check->{'$branch'}) : ()),
          %{$check->{'$result'}},
        });
        push @results, $source->{'$result'};
        last;
      }
      else {
        $returns = $source->fail($value, {
          from => 'either',
          ($check->{'$branch'} ? (branch => $check->{'$branch'}) : ()),
          %{$check->{'$result'}},
        });
        push @results, $source->{'$result'};
        push @errors, $source->catch('result')->render;
      }
    }
    if ($returns) {
      return $returns;
    }
    else {
      return $self->fail($value, {
        from => 'either',
        with => 'error_on_either',
        results => [@results],
        errors => [@errors],
      });
    }
  };

  return $self;
}

sub enum {
  my ($self, @data) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if (CORE::defined($value)) {
      return $source->pass($value, {
        from => 'enum',
      });
    }
    else {
      return $source->fail($value, {
        from => 'enum',
        with => 'error_on_defined',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    my $result;
    for my $item (@data) {
      if ($value eq $item) {
        $result = $source->pass($value, {
          from => 'enum',
        });
        last;
      }
      else {
        $result = $source->fail($value, {
          from => 'enum',
          with => 'error_on_enum',
          enum => [@data],
        });
      }
    }
    return $result;
  };

  return $self;
}

sub eval {
  my ($self, $data) = @_;

  delete $self->{'$result'};

  my $result = false;

  for my $callback (@{$self->on_eval}) {
    local $_ = $data;
    $result = $self->$callback($data) ? true : false;
    last if !$result;
  }

  return $result;
}

sub evaled {
  my ($self) = @_;

  my $passed = $self->passed;
  my $failed = $self->failed;

  return !$passed && !$failed ? false : true;
}

sub evaler {
  my ($self, @args) = @_;

  return $self->defer('eval', @args);
}

sub fail {
  my ($self, $data, $meta) = @_;

  my $from = $meta->{from} || 'callback';
  my $with = $meta->{with};
  my $okay = false;

  $self->{'$result'} = {
    %$meta,
    data => $data,
    from => $from,
    okay => $okay,
    with => $with,
  };

  return $okay;
}

sub failed {
  my ($self) = @_;

  my $result = $self->{'$result'};

  return $result ? ($result->{okay} ? false : true) : false;
}

sub float {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'float')) {
      return $source->pass($value, {
        from => 'float',
      });
    }
    else {
      return $source->fail($value, {
        from => 'float',
        expected => 'float',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub hash {
  my ($self, @code) = @_;

  return $self->hashref(@code);
}

sub hashkeys {
  my ($self, @pairs) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if (CORE::defined($value)) {
      return $source->pass($value, {
        from => 'hashkeys',
      });
    }
    else {
      return $source->fail($value, {
        from => 'hashkeys',
        with => 'error_on_defined',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if (UNIVERSAL::isa($value, 'HASH')) {
      return $source->pass($value, {
        from => 'hashkeys',
      });
    }
    else {
      return $source->fail($value, {
        from => 'hashkeys',
        with => 'error_on_hashref',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if ((CORE::keys %{$value}) > 0) {
      return $source->pass($value, {
        from => 'hashkeys',
      });
    }
    else {
      return $source->fail($value, {
        from => 'hashkeys',
        with => 'error_on_hashref_empty',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if (@pairs % 2) {
      return $source->fail($value, {
        from => 'hashkeys',
        args => [@pairs],
        with => 'error_on_pairs',
      });
    }
    my $result = true;
    for (my $i = 0; $i < @pairs;) {
      my ($key, $data) = (map $pairs[$_], $i++, $i++);
      if (!exists $value->{$key}) {
        $result = $source->fail($value, {
          from => 'hashkeys',
          name => $key,
          with => 'error_on_missing',
        });
        last;
      }
      my ($match, @args) = (ref $data) ? (@{$data}) : ($data);
      my $check = $source->branch($key)->accept($match, @args);
      if (!$check->eval($value->{$key})) {
        $result = $source->fail($value, {
          branch => $check->{'$branch'},
          %{$check->{'$result'}},
          from => 'hashkeys',
        });
        last;
      }
    }
    if (!$result) {
      return $result;
    }
    else {
      return $source->pass($value, {
        from => 'hashkeys',
      });
    }
  };

  return $self;
}

sub hashref {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'hash')) {
      return $source->pass($value, {
        from => 'hashref',
      });
    }
    else {
      return $source->fail($value, {
        from => 'hashref',
        expected => 'hashref',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub includes {
  my ($self, @data) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    my $returns;
    my @errors;
    my @results;
    for (my $i = 0; $i < @data; $i++) {
      my ($match, @args) = (ref $data[$i]) ? (@{$data[$i]}) : ($data[$i]);
      my $check = $source->branch->do('accept', $match, @args);
      if ($check->eval($value)) {
        $returns = $source->pass($value, {
          from => 'either',
          ($check->{'$branch'} ? (branch => $check->{'$branch'}) : ()),
          %{$check->{'$result'}},
        });
        push @results, $source->{'$result'};
      }
      else {
        $returns = $source->fail($value, {
          from => 'either',
          ($check->{'$branch'} ? (branch => $check->{'$branch'}) : ()),
          %{$check->{'$result'}},
        });
        push @results, $source->{'$result'};
        push @errors, $source->catch('result')->render;
        last;
      }
    }
    if (@errors) {
      return $self->fail($value, {
        from => 'includes',
        with => 'error_on_includes',
        results => [@results],
        errors => [@errors],
      });
    }
    else {
      return $returns;
    }
  };

  return $self;
}

sub identity {
  my ($self, $name) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'object')) {
      return $source->pass($value, {
        from => 'identity',
      });
    }
    else {
      return $source->fail($value, {
        from => 'identity',
        expected => 'object',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if ($value->isa($name)) {
      return $source->pass($value, {
        from => 'identity',
      });
    }
    else {
      return $source->fail($value, {
        from => 'identity',
        with => 'error_on_identity',
        name => $name,
      });
    }
  };

  return $self;
}

sub inherits {
  my ($self, $name) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'object')) {
      return $source->pass($value, {
        from => 'inherits',
      });
    }
    else {
      return $source->fail($value, {
        from => 'inherits',
        expected => 'object',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if ($value->isa($name)) {
      return $source->pass($value, {
        from => 'inherits',
      });
    }
    else {
      return $source->fail($value, {
        from => 'inherits',
        with => 'error_on_inherits',
        name => $name,
      });
    }
  };

  return $self;
}

sub integrates {
  my ($self, $role) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'object')) {
      return $source->pass($value, {
        from => 'integrates',
      });
    }
    else {
      return $source->fail($value, {
        from => 'integrates',
        expected => 'object',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if ($value->can('DOES') && $value->DOES($role)) {
      return $source->pass($value, {
        from => 'integrates',
      });
    }
    else {
      return $source->fail($value, {
        from => 'integrates',
        role => $role,
        with => 'error_on_consumes',
      });
    }
  };

  return $self;
}

sub maybe {
  my ($self, $match, @args) = @_;

  $self->either('undef', ($match ? [$match, @args] : ()));

  return $self;
}

sub number {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'number')) {
      return $source->pass($value, {
        from => 'number',
      });
    }
    else {
      return $source->fail($value, {
        from => 'number',
        expected => 'number',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub object {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'object')) {
      return $source->pass($value, {
        from => 'object',
      });
    }
    else {
      return $source->fail($value, {
        from => 'object',
        expected => 'object',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub package {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'string')) {
      return $source->pass($value, {
        from => 'package',
      });
    }
    else {
      return $source->fail($value, {
        from => 'package',
        expected => 'string',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if ($value =~ /^[A-Z](?:(?:\w|::)*[a-zA-Z0-9])?$/) {
      return $source->pass($value, {
        from => 'package',
      });
    }
    else {
      return $source->fail($value, {
        from => 'package',
        with => 'error_on_package',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    require Venus::Space;
    if (Venus::Space->new($value)->loaded) {
      return $source->pass($value, {
        from => 'package',
      });
    }
    else {
      return $source->fail($value, {
        from => 'package',
        with => 'error_on_package_loaded',
      });
    }
  }, @code;

  return $self;
}

sub pass {
  my ($self, $data, $meta) = @_;

  my $from = $meta->{from} || 'callback';
  my $with = $meta->{with};
  my $okay = true;

  $self->{'$result'} = {
    %$meta,
    data => $data,
    from => $from,
    okay => $okay,
    with => $with,
  };

  return $okay;
}

sub passed {
  my ($self) = @_;

  my $result = $self->{'$result'};

  return $result ? ($result->{okay} ? true : false) : false;
}

sub reference {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if (CORE::defined($value)) {
      return $source->pass($value, {
        from => 'reference',
      });
    }
    else {
      return $source->fail($value, {
        from => 'reference',
        with => 'error_on_defined',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if (ref($value)) {
      return $source->pass($value, {
        from => 'reference',
      });
    }
    else {
      return $source->fail($value, {
        from => 'reference',
        with => 'error_on_reference',
      });
    }
  }, @code;

  return $self;
}

sub regexp {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'regexp')) {
      return $source->pass($value, {
        from => 'regexp',
      });
    }
    else {
      return $source->fail($value, {
        from => 'regexp',
        expected => 'regexp',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub result {
  my ($self, @data) = @_;

  my $eval = $self->eval(@data) if @data;

  my $result = $self->{'$result'};

  return undef if !defined $result;

  my $data = $result->{data};
  my $okay = $result->{okay} || $eval;
  my $with = $result->{with} || 'error_on_unknown';

  return $okay ? $data : $self->error({%{$result}, throw => $with});
}

sub routines {
  my ($self, @data) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'object')) {
      return $source->pass($value, {
        from => 'routines',
      });
    }
    else {
      return $source->fail($value, {
        from => 'routines',
        expected => 'object',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    my $result;
    for my $item (@data) {
      if ($value->can($item)) {
        $result = $source->pass($value, {
          from => 'routines',
        });
      }
      else {
        $result = $source->fail($value, {
          from => 'routines',
          name => $item,
          with => 'error_on_missing',
        });
        last;
      }
    }
    return $result;
  };

  return $self;
}

sub scalar {
  my ($self, @code) = @_;

  return $self->scalarref(@code);
}

sub scalarref {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'scalar')) {
      return $source->pass($value, {
        from => 'scalarref',
      });
    }
    else {
      return $source->fail($value, {
        from => 'scalarref',
        expected => 'scalarref',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub string {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'string')) {
      return $source->pass($value, {
        from => 'string',
      });
    }
    else {
      return $source->fail($value, {
        from => 'string',
        expected => 'string',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub tuple {
  my ($self, @data) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if (CORE::defined($value)) {
      return $source->pass($value, {
        from => 'tuple',
      });
    }
    else {
      return $source->fail($value, {
        from => 'tuple',
        with => 'error_on_defined',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if (UNIVERSAL::isa($value, 'ARRAY')) {
      return $source->pass($value, {
        from => 'tuple',
      });
    }
    else {
      return $source->fail($value, {
        from => 'tuple',
        with => 'error_on_arrayref',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if (@data == @{$value}) {
      return $source->pass($value, {
        from => 'tuple',
      });
    }
    else {
      return $source->fail($value, {
        from => 'tuple',
        with => 'error_on_arrayref_count',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    my $result = true;
    for (my $i = 0; $i < @data; $i++) {
      my ($match, @args) = (ref $data[$i]) ? (@{$data[$i]}) : ($data[$i]);
      my $check = $source->branch($i)->accept($match, @args);
      if (!$check->eval($value->[$i])) {
        $result = $source->fail($value, {
          branch => $check->{'$branch'},
          %{$check->{'$result'}},
          from => 'tuple',
        });
        last;
      }
    }
    if (!$result) {
      return $result;
    }
    else {
      return $self->pass($value, {
        from => 'tuple',
      });
    }
  };

  return $self;
}

sub type {
  my ($self, $value) = @_;

  my $aliases = {
    array => 'arrayref',
    code => 'coderef',
    hash => 'hashref',
    regexp => 'regexpref',
    scalar => 'scalarref',
    scalar => 'scalarref',
  };

  my $identity = lc(Venus::Type->new(value => $value)->identify);

  return $aliases->{$identity} || $identity;
}

sub undef {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'undef')) {
      return $source->pass($value, {
        from => 'undef',
      });
    }
    else {
      return $source->fail($value, {
        from => 'undef',
        expected => 'undef',
        received => $source->type($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub value {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if (CORE::defined($value)) {
      return $source->pass($value, {
        from => 'value',
      });
    }
    else {
      return $source->fail($value, {
        from => 'value',
        with => 'error_on_defined',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if (!CORE::ref($value)) {
      return $source->pass($value, {
        from => 'value',
      });
    }
    else {
      return $source->fail($value, {
        from => 'value',
        with => 'error_on_value',
      });
    }
  }, @code;

  return $self;
}

sub within {
  my ($self, $type, @next) = @_;

  if (!$type) {
    return $self;
  }

  my $where = $self->new;

  if (lc($type) eq 'hash' || lc($type) eq 'hashref') {
    push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if (CORE::defined($value)) {
      return $source->pass($value, {
        from => 'within',
      });
    }
    else {
      return $source->fail($value, {
        from => 'within',
        with => 'error_on_defined',
      });
    }
    }, sub {
      my ($source, $value) = @_;
      if (UNIVERSAL::isa($value, 'HASH')) {
        return $source->pass($value, {
          from => 'within',
        });
      }
      else {
        return $source->fail($value, {
          from => 'within',
          with => 'error_on_hashref',
        });
      }
    }, sub {
      my ($source, $value) = @_;
      if ((CORE::keys %{$value}) > 0) {
        return $source->pass($value, {
          from => 'within',
        });
      }
      else {
        return $source->fail($value, {
          from => 'within',
          with => 'error_on_hashref_empty',
        });
      }
    }, sub {
      my ($source, $value) = @_;
      my $result = true;
      for my $key (CORE::keys %{$value}) {
        my $check = $where->branch($key);
        $check->on_eval($where->on_eval);
        if (!$check->eval($value->{$key})) {
          $result = $source->fail($value, {
            branch => $check->{'$branch'},
            %{$check->{'$result'}},
            from => 'within',
          });
          last;
        }
      }
      if (!$result) {
        return $result;
      }
      else {
        return $self->pass($value, {
          from => 'within',
        });
      }
    };
  }
  elsif (lc($type) eq 'array' || lc($type) eq 'arrayref') {
    push @{$self->on_eval}, sub {
      my ($source, $value) = @_;
      if (CORE::defined($value)) {
        return $source->pass($value, {
          from => 'within',
        });
      }
      else {
        return $source->fail($value, {
          from => 'within',
          with => 'error_on_defined',
        });
      }
    }, sub {
      my ($source, $value) = @_;
      if (UNIVERSAL::isa($value, 'ARRAY')) {
        return $source->pass($value, {
          from => 'within',
        });
      }
      else {
        return $source->fail($value, {
          from => 'within',
          with => 'error_on_arrayref',
        });
      }
    }, sub {
      my ($source, $value) = @_;
      if (@{$value} > 0) {
        return $source->pass($value, {
          from => 'within',
        });
      }
      else {
        return $source->fail($value, {
          from => 'within',
          with => 'error_on_arrayref_count',
        });
      }
    }, sub {
      my ($source, $value) = @_;
      my $result = true;
      my $key = 0;
      for my $item (@{$value}) {
        my $check = $where->branch($key++);
        $check->on_eval($where->on_eval);
        if (!$check->eval($item)) {
          $result = $source->fail($value, {
            branch => $check->{'$branch'},
            %{$check->{'$result'}},
            from => 'within',
          });
          last;
        }
      }
      if (!$result) {
        return $result;
      }
      else {
        return $self->pass($value, {
          from => 'within',
        });
      }
    };
  }
  else {
    return $self->error({
      throw => 'error_on_within',
      type => $type,
      args => [@next]
    });
  }

  $where->accept(map +(ref($_) ? @$_ : $_), $next[0]) if @next;

  return $where;
}

sub yesno {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if (CORE::defined($value)) {
      return $source->pass($value, {
        from => 'yesno',
      });
    }
    else {
      return $source->fail($value, {
        from => 'yesno',
        with => 'error_on_defined',
      });
    }
  }, sub {
    my ($source, $value) = @_;
    if ($value =~ /^(?:1|y(?:es)?|0|n(?:o)?)$/i) {
      return $source->pass($value, {
        from => 'yesno',
      });
    }
    else {
      return $source->fail($value, {
        from => 'yesno',
        with => 'error_on_yesno',
      });
    }
  }, @code;

  return $self;
}

# ERRORS

sub error {
  my ($self, $data) = @_;

  delete $data->{okay};
  delete $data->{with};

  $data->{at} = $data->{'branch'}
    ? join('.', '', @{$data->{'branch'}}) || '.' : '.';

  return $self->SUPER::error($data);
}

sub error_on_arrayref {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is not an arrayref or arrayref derived',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.arrayref',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_arrayref_count {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'incorrect item count in arrayref or arrayref derived object',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.arrayref.count',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_coded {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'expected {{expected}}',
    'received {{received}}',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.coded',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_consumes {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'object does not consume the role "{{role}}"',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.consumes',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_defined {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is undefined',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.defined',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_either {
  my ($self, $data) = @_;

  my $message = join "\n\n",
    'Failed checking either-or condition:',
    @{$data->{errors}};

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.either',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_enum {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'received {{data}}',
    'valid options are {{options}}',
    'at {{at}}';

  my $stash = {
    %{$data},
    options => (join ', ', @{$data->{enum}}),
  };

  my $result = {
    name => 'on.enum',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_hashref {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is not a hashref or hashref derived',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.hashref',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_hashref_empty {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'no items found in hashref or hashref derived object',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.hashref.empty',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_includes {
  my ($self, $data) = @_;

  my $message = join "\n\n",
    'Failed checking union-includes condition:',
    @{$data->{errors}};

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.includes',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_identity {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'object is not a {{name}} or derived object',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.identity',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_inherits {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'object is not a {{name}} derived object',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.inherits',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_missing {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    '"{{name}}" is missing',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.missing',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_package {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    '"{{data}}" is not a valid package name',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.package',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_package_loaded {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    '"{{data}}" is not loaded',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.package.loaded',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_pairs {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'imblanced key/value pairs provided',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.pairs',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_reference {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is not a reference',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.reference',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_value {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is a reference',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.value',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_within {
  my ($self, $data) = @_;

  my $message = 'Invalid type "{{type}}" provided to the "within" method';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.within',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_unknown {
  my ($self, $data) = @_;

  my $message = 'Failed performing check for unknown reason';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.unknown',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}


sub error_on_yesno {
  my ($self, $data) = @_;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is not a recognized "yes" or "no" value',
    'at {{at}}';

  my $stash = {
    %{$data},
  };

  my $result = {
    name => 'on.yesno',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

1;



=head1 NAME

Venus::Check - Check Class

=cut

=head1 ABSTRACT

Check Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Check;

  my $check = Venus::Check->new;

  # $check->float;

  # my $result = $check->result(rand);

  # 0.1234567890

=cut

=head1 DESCRIPTION

This package provides a mechanism for performing runtime dynamic type checking
on data.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 on_eval

  on_eval(within[arrayref, coderef] $data) (within[arrayref, coderef])

The on_eval attribute is read-write, accepts C<(ArrayRef[CodeRef])> values, and
is optional.

I<Since C<3.55>>

=over 4

=item on_eval example 1

  # given: synopsis

  package main;

  my $set_on_eval = $check->on_eval([sub{1}]);

  # [sub{1}]

=back

=over 4

=item on_eval example 2

  # given: synopsis

  # given: example-1 on_eval

  package main;

  my $get_on_eval = $check->on_eval;

  # [sub{1}]

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 accept

  accept(string $name, string | within[arrayref, string] @args) (Venus::Check)

The accept method configures the object to accept the conditions or identity
provided and returns the invocant. This method dispatches to the method(s)
specified, or to the L</identity> method otherwise.

I<Since C<3.55>>

=over 4

=item accept example 1

  # given: synopsis

  package main;

  $check = $check->accept('string');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('okay');

  # true

=back

=over 4

=item accept example 2

  # given: synopsis

  package main;

  $check = $check->accept('string');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(12345);

  # false

=back

=over 4

=item accept example 3

  # given: synopsis

  package main;

  $check = $check->accept('string');

  # bless(..., 'Venus::Check')

  # my $result = $check->result('okay');

  # 'okay'

=back

=over 4

=item accept example 4

  # given: synopsis

  package main;

  $check = $check->accept('string');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(12345);

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 any

  any() (Venus::Check)

The any method configures the object to accept any value and returns the
invocant.

I<Since C<3.55>>

=over 4

=item any example 1

  # given: synopsis

  package main;

  $check = $check->any;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(1);

  # true

=back

=over 4

=item any example 2

  # given: synopsis

  package main;

  $check = $check->any;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(bless{});

  # true

=back

=cut

=head2 array

  array(coderef @code) (Venus::Check)

The array method configures the object to accept array references and returns
the invocant.

I<Since C<3.55>>

=over 4

=item array example 1

  # given: synopsis

  package main;

  $check = $check->array;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval([]);

  # true

=back

=over 4

=item array example 2

  # given: synopsis

  package main;

  $check = $check->array;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({});

  # false

=back

=over 4

=item array example 3

  # given: synopsis

  package main;

  $check = $check->array;

  # bless(..., 'Venus::Check')

  # my $result = $check->result([1..4]);

  # [1..4]

=back

=over 4

=item array example 4

  # given: synopsis

  package main;

  $check = $check->array;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({1..4});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 arrayref

  arrayref(coderef @code) (Venus::Check)

The arrayref method configures the object to accept array references and returns
the invocant.

I<Since C<3.55>>

=over 4

=item arrayref example 1

  # given: synopsis

  package main;

  $check = $check->arrayref;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval([]);

  # true

=back

=over 4

=item arrayref example 2

  # given: synopsis

  package main;

  $check = $check->arrayref;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({});

  # false

=back

=over 4

=item arrayref example 3

  # given: synopsis

  package main;

  $check = $check->arrayref;

  # bless(..., 'Venus::Check')

  # my $result = $check->result([1..4]);

  # [1..4]

=back

=over 4

=item arrayref example 4

  # given: synopsis

  package main;

  $check = $check->arrayref;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({1..4});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 attributes

  attributes(string | within[arrayref, string] @args) (Venus::Check)

The attributes method configures the object to accept objects containing
attributes whose values' match the attribute names and types specified, and
returns the invocant.

I<Since C<3.55>>

=over 4

=item attributes example 1

  # given: synopsis

  package Example;

  use Venus::Class 'attr';

  attr 'name';

  package main;

  $check = $check->attributes('name', 'string');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Example->new(name => 'test'));

  # true

=back

=over 4

=item attributes example 2

  # given: synopsis

  package Example;

  use Venus::Class 'attr';

  attr 'name';

  package main;

  $check = $check->attributes('name', 'string');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Example->new);

  # false

=back

=over 4

=item attributes example 3

  # given: synopsis

  package Example;

  use Venus::Class 'attr';

  attr 'name';

  package main;

  $check = $check->attributes('name', 'string');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Example->new(name => 'test'));

  # bless(..., 'Example')

=back

=over 4

=item attributes example 4

  # given: synopsis

  package Example;

  use Venus::Class 'attr';

  attr 'name';

  package main;

  $check = $check->attributes('name', 'string');

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=over 4

=item attributes example 5

  # given: synopsis

  package Example;

  use Venus::Class 'attr';

  attr 'name';

  package main;

  $check = $check->attributes('name', 'string', 'age');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Example->new);

  # Exception! (isa Venus::Check::Error) (see error_on_pairs)

=back

=over 4

=item attributes example 6

  # given: synopsis

  package Example;

  use Venus::Class;

  package main;

  $check = $check->attributes('name', 'string');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Example->new);

  # Exception! (isa Venus::Check::Error) (see error_on_missing)

=back

=over 4

=item attributes example 7

  # given: synopsis

  package Example;

  use Venus::Class 'attr';

  attr 'name';

  package main;

  $check = $check->attributes('name', 'string');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Example->new(name => rand));

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 bool

  bool(coderef @code) (Venus::Check)

The bool method configures the object to accept boolean values and returns the
invocant.

I<Since C<3.55>>

=over 4

=item bool example 1

  # given: synopsis

  package main;

  use Venus;

  $check = $check->bool;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(true);

  # true

=back

=over 4

=item bool example 2

  # given: synopsis

  package main;

  use Venus;

  $check = $check->bool;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(1);

  # false

=back

=over 4

=item bool example 3

  # given: synopsis

  package main;

  use Venus;

  $check = $check->bool;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(true);

  # true

=back

=over 4

=item bool example 4

  # given: synopsis

  package main;

  use Venus;

  $check = $check->bool;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(1);

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 boolean

  boolean(coderef @code) (Venus::Check)

The boolean method configures the object to accept boolean values and returns
the invocant.

I<Since C<3.55>>

=over 4

=item boolean example 1

  # given: synopsis

  package main;

  use Venus;

  $check = $check->boolean;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(true);

  # true

=back

=over 4

=item boolean example 2

  # given: synopsis

  package main;

  use Venus;

  $check = $check->boolean;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(1);

  # false

=back

=over 4

=item boolean example 3

  # given: synopsis

  package main;

  use Venus;

  $check = $check->boolean;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(true);

  # true

=back

=over 4

=item boolean example 4

  # given: synopsis

  package main;

  use Venus;

  $check = $check->boolean;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(1);

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 branch

  branch(string @args) (Venus::Check)

The branch method returns a new L<Venus::Check> object configured to evaluate a
branch of logic from its source.

I<Since C<3.55>>

=over 4

=item branch example 1

  # given: synopsis

  package main;

  my $branch = $check->branch('nested');

  # bless(..., 'Venus::Check')

=back

=cut

=head2 clear

  clear() (Venus::Check)

The clear method resets all registered conditions and returns the invocant.

I<Since C<3.55>>

=over 4

=item clear example 1

  # given: synopsis

  package main;

  $check->any;

  $check = $check->clear;

  # bless(..., 'Venus::Check')

=back

=cut

=head2 code

  code(coderef @code) (Venus::Check)

The code method configures the object to accept code references and returns
the invocant.

I<Since C<3.55>>

=over 4

=item code example 1

  # given: synopsis

  package main;

  $check = $check->code;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(sub{});

  # true

=back

=over 4

=item code example 2

  # given: synopsis

  package main;

  $check = $check->code;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({});

  # false

=back

=over 4

=item code example 3

  # given: synopsis

  package main;

  $check = $check->code;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(sub{});

  # sub{}

=back

=over 4

=item code example 4

  # given: synopsis

  package main;

  $check = $check->code;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 coded

  coded(any $data, string $name) (Venus::Check)

The coded method accepts a value and a type name returns the result of a
L<Venus::Type/coded> operation.

I<Since C<3.55>>

=over 4

=item coded example 1

  # given: synopsis

  package main;

  $check = $check->coded('hello', 'string');

  # true

=back

=over 4

=item coded example 2

  # given: synopsis

  package main;

  $check = $check->coded(12345, 'string');

  # false

=back

=cut

=head2 coderef

  coderef(coderef @code) (Venus::Check)

The coderef method configures the object to accept code references and returns
the invocant.

I<Since C<3.55>>

=over 4

=item coderef example 1

  # given: synopsis

  package main;

  $check = $check->coderef;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(sub{});

  # true

=back

=over 4

=item coderef example 2

  # given: synopsis

  package main;

  $check = $check->coderef;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({});

  # false

=back

=over 4

=item coderef example 3

  # given: synopsis

  package main;

  $check = $check->coderef;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(sub{});

  # sub{}

=back

=over 4

=item coderef example 4

  # given: synopsis

  package main;

  $check = $check->coderef;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 consumes

  consumes(string $role) (Venus::Check)

The consumes method configures the object to accept objects which consume the
role provided, and returns the invocant.

I<Since C<3.55>>

=over 4

=item consumes example 1

  # given: synopsis

  package Example;

  use Venus::Class 'base';

  base 'Venus::Kind';

  package main;

  $check = $check->consumes('Venus::Role::Throwable');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Example->new);

  # true

=back

=over 4

=item consumes example 2

  # given: synopsis

  package Example;

  use Venus::Class 'base';

  base 'Venus::Kind';

  package main;

  $check = $check->consumes('Venus::Role::Knowable');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Example->new);

  # false

=back

=over 4

=item consumes example 3

  # given: synopsis

  package Example;

  use Venus::Class 'base';

  base 'Venus::Kind';

  package main;

  $check = $check->consumes('Venus::Role::Throwable');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Example->new);

  # bless(..., 'Example')

=back

=over 4

=item consumes example 4

  # given: synopsis

  package main;

  $check = $check->consumes('Venus::Role::Knowable');

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=over 4

=item consumes example 5

  # given: synopsis

  package Example;

  use Venus::Class 'base';

  base 'Venus::Kind';

  package main;

  $check = $check->consumes('Venus::Role::Knowable');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Example->new);

  # Exception! (isa Venus::Check::Error) (see error_on_consumes)

=back

=cut

=head2 defined

  defined(coderef @code) (Venus::Check)

The defined method configures the object to accept any value that's not
undefined and returns the invocant.

I<Since C<3.55>>

=over 4

=item defined example 1

  # given: synopsis

  package main;

  $check = $check->defined;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('');

  # true

=back

=over 4

=item defined example 2

  # given: synopsis

  package main;

  $check = $check->defined;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(undef);

  # false

=back

=over 4

=item defined example 3

  # given: synopsis

  package main;

  $check = $check->defined;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('');

  # ''

=back

=over 4

=item defined example 4

  # given: synopsis

  package main;

  $check = $check->defined;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(undef);

  # Exception! (isa Venus::Check::Error) (see error_on_defined)

=back

=cut

=head2 either

  either(string | within[arrayref, string] @args) (Venus::Check)

The either method configures the object to accept "either" of the conditions
provided, which may be a string or arrayref representing a method call, and
returns the invocant.

I<Since C<3.55>>

=over 4

=item either example 1

  # given: synopsis

  package main;

  $check = $check->either('string', 'number');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('hello');

  # true

=back

=over 4

=item either example 2

  # given: synopsis

  package main;

  $check = $check->either('string', 'number');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(rand);

  # false

=back

=over 4

=item either example 3

  # given: synopsis

  package main;

  $check = $check->either('string', 'number');

  # bless(..., 'Venus::Check')

  # my $result = $check->result('hello');

  # 'hello'

=back

=over 4

=item either example 4

  # given: synopsis

  package main;

  $check = $check->either('string', 'number');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(rand);

  # Exception! (isa Venus::Check::Error) (see error_on_either)

=back

=cut

=head2 enum

  enum(string @args) (Venus::Check)

The enum method configures the object to accept any one of the provide options,
and returns the invocant.

I<Since C<3.55>>

=over 4

=item enum example 1

  # given: synopsis

  package main;

  $check = $check->enum('black', 'white', 'grey');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('black');

  # true

=back

=over 4

=item enum example 2

  # given: synopsis

  package main;

  $check = $check->enum('black', 'white', 'grey');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('purple');

  # false

=back

=over 4

=item enum example 3

  # given: synopsis

  package main;

  $check = $check->enum('black', 'white', 'grey');

  # bless(..., 'Venus::Check')

  # my $result = $check->result('black');

  # 'black'

=back

=over 4

=item enum example 4

  # given: synopsis

  package main;

  $check = $check->enum('black', 'white', 'grey');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(undef);

  # Exception! (isa Venus::Check::Error) (see error_on_defined)

=back

=over 4

=item enum example 5

  # given: synopsis

  package main;

  $check = $check->enum('black', 'white', 'grey');

  # bless(..., 'Venus::Check')

  # my $result = $check->result('purple');

  # Exception! (isa Venus::Check::Error) (see error_on_enum)

=back

=cut

=head2 eval

  eval(any $data) (any)

The eval method returns true or false if the data provided passes the
registered conditions.

I<Since C<3.55>>

=over 4

=item eval example 1

  # given: synopsis

  package main;

  my $eval = $check->eval;

  # false

=back

=over 4

=item eval example 2

  # given: synopsis

  package main;

  my $eval = $check->any->eval('');

  # true

=back

=cut

=head2 evaled

  evaled() (boolean)

The evaled method returns true if L</eval> has previously been executed, and
false otherwise.

I<Since C<3.35>>

=over 4

=item evaled example 1

  # given: synopsis

  package main;

  my $evaled = $check->evaled;

  # false

=back

=over 4

=item evaled example 2

  # given: synopsis

  package main;

  $check->any->eval;

  my $evaled = $check->evaled;

  # true

=back

=cut

=head2 evaler

  evaler(any @args) (coderef)

The evaler method returns a coderef which calls the L</eval> method with the
invocant when called.

I<Since C<3.55>>

=over 4

=item evaler example 1

  # given: synopsis

  package main;

  my $evaler = $check->evaler;

  # sub{...}

  # my $result = $evaler->();

  # false

=back

=over 4

=item evaler example 2

  # given: synopsis

  package main;

  my $evaler = $check->any->evaler;

  # sub{...}

  # my $result = $evaler->();

  # true

=back

=cut

=head2 fail

  fail(any $data, hashref $meta) (boolean)

The fail method captures data related to a failure and returns false.

I<Since C<3.55>>

=over 4

=item fail example 1

  # given: synopsis

  package main;

  my $fail = $check->fail('...', {
    from => 'caller',
  });

  # false

=back

=cut

=head2 failed

  failed() (boolean)

The failed method returns true if the result of the last operation was a
failure, otherwise returns false.

I<Since C<3.55>>

=over 4

=item failed example 1

  # given: synopsis

  package main;

  my $failed = $check->failed;

  # false

=back

=over 4

=item failed example 2

  # given: synopsis

  package main;

  $check->string->eval(12345);

  my $failed = $check->failed;

  # true

=back

=over 4

=item failed example 3

  # given: synopsis

  package main;

  $check->string->eval('hello');

  my $failed = $check->failed;

  # false

=back

=cut

=head2 float

  float(coderef @code) (Venus::Check)

The float method configures the object to accept floating-point values and
returns the invocant.

I<Since C<3.55>>

=over 4

=item float example 1

  # given: synopsis

  package main;

  $check = $check->float;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(1.2345);

  # true

=back

=over 4

=item float example 2

  # given: synopsis

  package main;

  $check = $check->float;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(12345);

  # false

=back

=over 4

=item float example 3

  # given: synopsis

  package main;

  $check = $check->float;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(1.2345);

  # 1.2345

=back

=over 4

=item float example 4

  # given: synopsis

  package main;

  $check = $check->float;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(12345);

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 hash

  hash(coderef @code) (Venus::Check)

The hash method configures the object to accept hash references and returns
the invocant.

I<Since C<3.55>>

=over 4

=item hash example 1

  # given: synopsis

  package main;

  $check = $check->hash;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({});

  # true

=back

=over 4

=item hash example 2

  # given: synopsis

  package main;

  $check = $check->hash;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval([]);

  # false

=back

=over 4

=item hash example 3

  # given: synopsis

  package main;

  $check = $check->hash;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # {}

=back

=over 4

=item hash example 4

  # given: synopsis

  package main;

  $check = $check->hash;

  # bless(..., 'Venus::Check')

  # my $result = $check->result([]);

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 hashkeys

  hashkeys(string | within[arrayref, string] @args) (Venus::Check)

The hashkeys method configures the object to accept hash based values
containing the keys whose values' match the specified types, and returns the
invocant.

I<Since C<3.55>>

=over 4

=item hashkeys example 1

  # given: synopsis

  package main;

  $check = $check->hashkeys('rand', 'float');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({rand => rand});

  # true

=back

=over 4

=item hashkeys example 2

  # given: synopsis

  package main;

  $check = $check->hashkeys('rand', 'float');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({});

  # false

=back

=over 4

=item hashkeys example 3

  # given: synopsis

  package main;

  $check = $check->hashkeys('rand', 'float');

  # bless(..., 'Venus::Check')

  # my $result = $check->result({rand => rand});

  # {rand => rand}

=back

=over 4

=item hashkeys example 4

  # given: synopsis

  package main;

  $check = $check->hashkeys('rand', 'float');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(undef);

  # Exception! (isa Venus::Check::Error) (see error_on_defined)

=back

=over 4

=item hashkeys example 5

  # given: synopsis

  package main;

  $check = $check->hashkeys('rand', 'float');

  # bless(..., 'Venus::Check')

  # my $result = $check->result([]);

  # Exception! (isa Venus::Check::Error) (see error_on_hashref)

=back

=over 4

=item hashkeys example 6

  # given: synopsis

  package main;

  $check = $check->hashkeys('rand', 'float', 'name');

  # bless(..., 'Venus::Check')

  # my $result = $check->result({rand => rand});

  # Exception! (isa Venus::Check::Error) (see error_on_pairs)

=back

=over 4

=item hashkeys example 7

  # given: synopsis

  package main;

  $check = $check->hashkeys('rand', 'float');

  # bless(..., 'Venus::Check')

  # my $result = $check->result({rndm => rand});

  # Exception! (isa Venus::Check::Error) (see error_on_missing)

=back

=cut

=head2 hashref

  hashref(coderef @code) (Venus::Check)

The hashref method configures the object to accept hash references and returns
the invocant.

I<Since C<3.55>>

=over 4

=item hashref example 1

  # given: synopsis

  package main;

  $check = $check->hashref;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({});

  # true

=back

=over 4

=item hashref example 2

  # given: synopsis

  package main;

  $check = $check->hashref;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval([]);

  # false

=back

=over 4

=item hashref example 3

  # given: synopsis

  package main;

  $check = $check->hashref;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # {}

=back

=over 4

=item hashref example 4

  # given: synopsis

  package main;

  $check = $check->hashref;

  # bless(..., 'Venus::Check')

  # my $result = $check->result([]);

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 identity

  identity(string $name) (Venus::Check)

The identity method configures the object to accept objects of the type
specified as the argument, and returns the invocant.

I<Since C<3.55>>

=over 4

=item identity example 1

  # given: synopsis

  package main;

  $check = $check->identity('Venus::Check');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Venus::Check->new);

  # true

=back

=over 4

=item identity example 2

  # given: synopsis

  package main;

  use Venus::Config;

  $check = $check->identity('Venus::Check');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Venus::Config->new);

  # false

=back

=over 4

=item identity example 3

  # given: synopsis

  package main;

  $check = $check->identity('Venus::Check');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Venus::Check->new);

  # bless(..., 'Venus::Check')

=back

=over 4

=item identity example 4

  # given: synopsis

  package main;

  $check = $check->identity('Venus::Check');

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=over 4

=item identity example 5

  # given: synopsis

  package main;

  use Venus::Config;

  $check = $check->identity('Venus::Check');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Venus::Config->new);

  # Exception! (isa Venus::Check::Error) (see error_on_identity)

=back

=cut

=head2 includes

  includes(string | within[arrayref, string] @args) (Venus::Check)

The include method configures the object to accept "all" of the conditions
provided, which may be a string or arrayref representing a method call, and
returns the invocant.

I<Since C<3.55>>

=over 4

=item includes example 1

  # given: synopsis

  package main;

  $check = $check->includes('string', 'yesno');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('yes');

  # true

=back

=over 4

=item includes example 2

  # given: synopsis

  package main;

  $check = $check->includes('string', 'yesno');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(0);

  # false

=back

=over 4

=item includes example 3

  # given: synopsis

  package main;

  $check = $check->includes('string', 'yesno');

  # bless(..., 'Venus::Check')

  # my $result = $check->result('Yes');

  # 'Yes'

=back

=over 4

=item includes example 4

  # given: synopsis

  package main;

  $check = $check->includes('string', 'yesno');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(1);

  # Exception! (isa Venus::Check::Error) (see error_on_includes)

=back

=cut

=head2 inherits

  inherits(string $base) (Venus::Check)

The inherits method configures the object to accept objects of the type
specified as the argument, and returns the invocant. This method is a proxy for
the L</identity> method.

I<Since C<3.55>>

=over 4

=item inherits example 1

  # given: synopsis

  package main;

  $check = $check->inherits('Venus::Kind::Utility');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Venus::Check->new);

  # true

=back

=over 4

=item inherits example 2

  # given: synopsis

  package main;

  $check = $check->inherits('Venus::Kind::Value');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Venus::Check->new);

  # false

=back

=over 4

=item inherits example 3

  # given: synopsis

  package main;

  $check = $check->inherits('Venus::Kind::Utility');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Venus::Check->new);

  # bless(..., 'Venus::Check')

=back

=over 4

=item inherits example 4

  # given: synopsis

  package main;

  $check = $check->inherits('Venus::Kind::Value');

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=over 4

=item inherits example 5

  # given: synopsis

  package main;

  $check = $check->inherits('Venus::Kind::Value');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Venus::Check->new);

  # Exception! (isa Venus::Check::Error) (see error_on_inherits)

=back

=cut

=head2 integrates

  integrates(string $role) (Venus::Check)

The integrates method configures the object to accept objects that support the
C<"does"> behavior and consumes the "role" specified as the argument, and
returns the invocant.

I<Since C<3.55>>

=over 4

=item integrates example 1

  # given: synopsis

  package main;

  $check = $check->integrates('Venus::Role::Throwable');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Venus::Check->new);

  # true

=back

=over 4

=item integrates example 2

  # given: synopsis

  package main;

  $check = $check->integrates('Venus::Role::Knowable');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Venus::Check->new);

  # false

=back

=over 4

=item integrates example 3

  # given: synopsis

  package main;

  $check = $check->integrates('Venus::Role::Throwable');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Venus::Check->new);

  # bless(..., 'Venus::Check')

=back

=over 4

=item integrates example 4

  # given: synopsis

  package main;

  $check = $check->integrates('Venus::Role::Knowable');

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=over 4

=item integrates example 5

  # given: synopsis

  package main;

  $check = $check->integrates('Venus::Role::Knowable');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Venus::Check->new);

  # Exception! (isa Venus::Check::Error) (see error_on_consumes)

=back

=cut

=head2 maybe

  maybe(string | within[arrayref, string] @args) (Venus::Check)

The maybe method configures the object to accept the type provided as an
argument, or undef, and returns the invocant.

I<Since C<3.55>>

=over 4

=item maybe example 1

  # given: synopsis

  package main;

  $check = $check->maybe('string');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('');

  # true

=back

=over 4

=item maybe example 2

  # given: synopsis

  package main;

  $check = $check->maybe('string');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval([]);

  # false

=back

=over 4

=item maybe example 3

  # given: synopsis

  package main;

  $check = $check->maybe('string');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(undef);

  # undef

=back

=over 4

=item maybe example 4

  # given: synopsis

  package main;

  $check = $check->maybe('string');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(0);

  # Exception! (isa Venus::Check::Error) (see error_on_either)

=back

=over 4

=item maybe example 5

  # given: synopsis

  package main;

  $check = $check->maybe('string');

  # bless(..., 'Venus::Check')

  # my $result = $check->result([]);

  # Exception! (isa Venus::Check::Error) (see error_on_either)

=back

=cut

=head2 number

  number(coderef @code) (Venus::Check)

The number method configures the object to accept numberic values and returns
the invocant.

I<Since C<3.55>>

=over 4

=item number example 1

  # given: synopsis

  package main;

  $check = $check->number;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(1234);

  # true

=back

=over 4

=item number example 2

  # given: synopsis

  package main;

  $check = $check->number;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(1.234);

  # false

=back

=over 4

=item number example 3

  # given: synopsis

  package main;

  $check = $check->number;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(1234);

  # 1234

=back

=over 4

=item number example 4

  # given: synopsis

  package main;

  $check = $check->number;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(1.234);

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 object

  object(coderef @code) (Venus::Check)

The object method configures the object to accept objects and returns the
invocant.

I<Since C<3.55>>

=over 4

=item object example 1

  # given: synopsis

  package main;

  $check = $check->object;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(bless{});

  # true

=back

=over 4

=item object example 2

  # given: synopsis

  package main;

  $check = $check->object;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({});

  # false

=back

=over 4

=item object example 3

  # given: synopsis

  package main;

  $check = $check->object;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(bless{});

  # bless{}

=back

=over 4

=item object example 4

  # given: synopsis

  package main;

  $check = $check->object;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 package

  package(coderef @code) (Venus::Check)

The package method configures the object to accept package names (which are
loaded) and returns the invocant.

I<Since C<3.55>>

=over 4

=item package example 1

  # given: synopsis

  package main;

  $check = $check->package;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('Venus::Check');

  # true

=back

=over 4

=item package example 2

  # given: synopsis

  package main;

  $check = $check->package;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('MyApp::Check');

  # false

=back

=over 4

=item package example 3

  # given: synopsis

  package main;

  $check = $check->package;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('Venus::Check');

  # 'Venus::Check'

=back

=over 4

=item package example 4

  # given: synopsis

  package main;

  $check = $check->package;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(0);

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=over 4

=item package example 5

  # given: synopsis

  package main;

  $check = $check->package;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('main');

  # Exception! (isa Venus::Check::Error) (see error_on_package)

=back

=over 4

=item package example 6

  # given: synopsis

  package main;

  $check = $check->package;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('MyApp::Check');

  # Exception! (isa Venus::Check::Error) (see error_on_package_loaded)

=back

=cut

=head2 pass

  pass(any $data, hashref $meta) (boolean)

The pass method captures data related to a success and returns true.

I<Since C<3.55>>

=over 4

=item pass example 1

  # given: synopsis

  package main;

  my $pass = $check->pass('...', {
    from => 'caller',
  });

  # true

=back

=cut

=head2 passed

  passed() (boolean)

The passed method returns true if the result of the last operation was a
success, otherwise returns false.

I<Since C<3.55>>

=over 4

=item passed example 1

  # given: synopsis

  package main;

  my $passed = $check->passed;

  # false

=back

=over 4

=item passed example 2

  # given: synopsis

  package main;

  $check->string->eval('hello');

  my $passed = $check->passed;

  # true

=back

=over 4

=item passed example 3

  # given: synopsis

  package main;

  $check->string->eval(12345);

  my $passed = $check->passed;

  # false

=back

=cut

=head2 reference

  reference(coderef @code) (Venus::Check)

The reference method configures the object to accept references and returns the
invocant.

I<Since C<3.55>>

=over 4

=item reference example 1

  # given: synopsis

  package main;

  $check = $check->reference;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval([]);

  # true

=back

=over 4

=item reference example 2

  # given: synopsis

  package main;

  $check = $check->reference;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('');

  # false

=back

=over 4

=item reference example 3

  # given: synopsis

  package main;

  $check = $check->reference;

  # bless(..., 'Venus::Check')

  # my $result = $check->result([]);

  # []

=back

=over 4

=item reference example 4

  # given: synopsis

  package main;

  $check = $check->reference;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(undef);

  # Exception! (isa Venus::Check::Error) (see error_on_defined)

=back

=over 4

=item reference example 5

  # given: synopsis

  package main;

  $check = $check->reference;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('');

  # Exception! (isa Venus::Check::Error) (see error_on_reference)

=back

=cut

=head2 regexp

  regexp(coderef @code) (Venus::Check)

The regexp method configures the object to accept regular expression objects
and returns the invocant.

I<Since C<3.55>>

=over 4

=item regexp example 1

  # given: synopsis

  package main;

  $check = $check->regexp;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(qr//);

  # true

=back

=over 4

=item regexp example 2

  # given: synopsis

  package main;

  $check = $check->regexp;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('');

  # false

=back

=over 4

=item regexp example 3

  # given: synopsis

  package main;

  $check = $check->regexp;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(qr//);

  # qr//

=back

=over 4

=item regexp example 4

  # given: synopsis

  package main;

  $check = $check->regexp;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('');

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 result

  result(any @args) (any)

The result method performs an L</eval> operation and returns the value provided
on success, and on failure raises an exception.

I<Since C<3.55>>

=over 4

=item result example 1

  # given: synopsis

  package main;

  $check->string;

  my $string = $check->result('hello');

  # 'hello'

=back

=over 4

=item result example 2

  # given: synopsis

  package main;

  $check->string;

  my $string = $check->result(12345);

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 routines

  routines(string @names) (Venus::Check)

The routines method configures the object to accept an object having all of the
routines provided, and returns the invocant.

I<Since C<3.55>>

=over 4

=item routines example 1

  # given: synopsis

  package main;

  $check = $check->routines('result');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Venus::Check->new);

  # true

=back

=over 4

=item routines example 2

  # given: synopsis

  package main;

  use Venus::Config;

  $check = $check->routines('result');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Venus::Config->new);

  # false

=back

=over 4

=item routines example 3

  # given: synopsis

  package main;

  $check = $check->routines('result');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Venus::Check->new);

  # bless(..., 'Venus::Check')

=back

=over 4

=item routines example 4

  # given: synopsis

  package main;

  use Venus::Config;

  $check = $check->routines('result');

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=over 4

=item routines example 5

  # given: synopsis

  package main;

  use Venus::Config;

  $check = $check->routines('result');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Venus::Config->new);

  # Exception! (isa Venus::Check::Error) (see error_on_missing)

=back

=cut

=head2 scalar

  scalar(coderef @code) (Venus::Check)

The scalar method configures the object to accept scalar references and returns
the invocant.

I<Since C<3.55>>

=over 4

=item scalar example 1

  # given: synopsis

  package main;

  $check = $check->scalar;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(\'');

  # true

=back

=over 4

=item scalar example 2

  # given: synopsis

  package main;

  $check = $check->scalar;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('');

  # false

=back

=over 4

=item scalar example 3

  # given: synopsis

  package main;

  $check = $check->scalar;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(\'');

  # \''

=back

=over 4

=item scalar example 4

  # given: synopsis

  package main;

  $check = $check->scalar;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('');

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 scalarref

  scalarref(coderef @code) (Venus::Check)

The scalarref method configures the object to accept scalar references and returns
the invocant.

I<Since C<3.55>>

=over 4

=item scalarref example 1

  # given: synopsis

  package main;

  $check = $check->scalarref;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(\'');

  # true

=back

=over 4

=item scalarref example 2

  # given: synopsis

  package main;

  $check = $check->scalarref;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('');

  # false

=back

=over 4

=item scalarref example 3

  # given: synopsis

  package main;

  $check = $check->scalarref;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(\'');

  # \''

=back

=over 4

=item scalarref example 4

  # given: synopsis

  package main;

  $check = $check->scalarref;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('');

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 string

  string(coderef @code) (Venus::Check)

The string method configures the object to accept string values and returns the
invocant.

I<Since C<3.55>>

=over 4

=item string example 1

  # given: synopsis

  package main;

  $check = $check->string;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('hello');

  # true

=back

=over 4

=item string example 2

  # given: synopsis

  package main;

  $check = $check->string;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(12345);

  # false

=back

=over 4

=item string example 3

  # given: synopsis

  package main;

  $check = $check->string;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('hello');

  # 'hello'

=back

=over 4

=item string example 4

  # given: synopsis

  package main;

  $check = $check->string;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(12345);

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 tuple

  tuple(string | within[arrayref, string] @args) (Venus::Check)

The tuple method configures the object to accept array references which conform
to a tuple specification, and returns the invocant. The value being evaluated
must contain at-least one element to match.

I<Since C<3.55>>

=over 4

=item tuple example 1

  # given: synopsis

  package main;

  $check = $check->tuple('string', 'number');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(['hello', 12345]);

  # true

=back

=over 4

=item tuple example 2

  # given: synopsis

  package main;

  $check = $check->tuple('string', 'number');

  # bless(..., 'Venus::Check')

  # my $result = $check->eval([]);

  # false

=back

=over 4

=item tuple example 3

  # given: synopsis

  package main;

  $check = $check->tuple('string', 'number');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(['hello', 12345]);

  # ['hello', 12345]

=back

=over 4

=item tuple example 4

  # given: synopsis

  package main;

  $check = $check->tuple('string', 'number');

  # bless(..., 'Venus::Check')

  # my $result = $check->result(undef);

  # Exception! (isa Venus::Check::Error) (see error_on_defined)

=back

=over 4

=item tuple example 5

  # given: synopsis

  package main;

  $check = $check->tuple('string', 'number');

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_arrayref)

=back

=over 4

=item tuple example 6

  # given: synopsis

  package main;

  $check = $check->tuple('string', 'number');

  # bless(..., 'Venus::Check')

  # my $result = $check->result([]);

  # Exception! (isa Venus::Check::Error) (see error_on_arrayref_count)

=back

=cut

=head2 type

  type(any $data) (string)

The type method returns the canonical data type name for the value provided.

I<Since C<3.55>>

=over 4

=item type example 1

  # given: synopsis

  package main;

  my $type = $check->type({});

  # 'hashref'

=back

=over 4

=item type example 2

  # given: synopsis

  package main;

  my $type = $check->type([]);

  # 'arrayref'

=back

=over 4

=item type example 3

  # given: synopsis

  package main;

  my $type = $check->type('Venus::Check');

  # 'string'

=back

=over 4

=item type example 4

  # given: synopsis

  package main;

  my $type = $check->type(Venus::Check->new);

  # 'object'

=back

=cut

=head2 undef

  undef(coderef @code) (Venus::Check)

The undef method configures the object to accept undefined values and returns
the invocant.

I<Since C<3.55>>

=over 4

=item undef example 1

  # given: synopsis

  package main;

  $check = $check->undef;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(undef);

  # true

=back

=over 4

=item undef example 2

  # given: synopsis

  package main;

  $check = $check->undef;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('');

  # false

=back

=over 4

=item undef example 3

  # given: synopsis

  package main;

  $check = $check->undef;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(undef);

  # undef

=back

=over 4

=item undef example 4

  # given: synopsis

  package main;

  $check = $check->undef;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('');

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 value

  value(coderef @code) (Venus::Check)

The value method configures the object to accept defined, non-reference,
values, and returns the invocant.

I<Since C<3.55>>

=over 4

=item value example 1

  # given: synopsis

  package main;

  $check = $check->value;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(1);

  # true

=back

=over 4

=item value example 2

  # given: synopsis

  package main;

  $check = $check->value;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({});

  # false

=back

=over 4

=item value example 3

  # given: synopsis

  package main;

  $check = $check->value;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(1);

  # 1

=back

=over 4

=item value example 4

  # given: synopsis

  package main;

  $check = $check->value;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(undef);

  # Exception! (isa Venus::Check::Error) (see error_on_defined)

=back

=over 4

=item value example 5

  # given: synopsis

  package main;

  $check = $check->value;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_value)

=back

=cut

=head2 within

  within(string $type, string | within[arrayref, string] @args) (Venus::Check)

The within method configures the object, registering a constraint action as a
sub-match operation, to accept array or hash based values, and returns a new
L<Venus::Check> instance for the sub-match operation (not the invocant). This
operation can traverse blessed array or hash based values. The value being
evaluated must contain at-least one element to match.

I<Since C<3.55>>

=over 4

=item within example 1

  # given: synopsis

  package main;

  my $within = $check->within('arrayref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(['hello']);

  # true

=back

=over 4

=item within example 2

  # given: synopsis

  package main;

  my $within = $check->within('arrayref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval([]);

  # false

=back

=over 4

=item within example 3

  # given: synopsis

  package main;

  my $within = $check->within('arrayref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(['hello']);

  # ['hello']

=back

=over 4

=item within example 4

  # given: synopsis

  package main;

  my $within = $check->within('arrayref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(undef);

  # Exception! (isa Venus::Check::Error) (see error_on_defined)

=back

=over 4

=item within example 5

  # given: synopsis

  package main;

  my $within = $check->within('arrayref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_arrayref)

=back

=over 4

=item within example 6

  # given: synopsis

  package main;

  my $within = $check->within('arrayref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result([]);

  # Exception! (isa Venus::Check::Error) (see error_on_arrayref_count)

=back

=over 4

=item within example 7

  # given: synopsis

  package main;

  my $within = $check->within('arrayref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result([rand]);

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=over 4

=item within example 8

  # given: synopsis

  package main;

  my $within = $check->within('hashref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({title => 'hello'});

  # true

=back

=over 4

=item within example 9

  # given: synopsis

  package main;

  my $within = $check->within('hashref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval({});

  # false

=back

=over 4

=item within example 10

  # given: synopsis

  package main;

  my $within = $check->within('hashref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({title => 'hello'});

  # {title => 'hello'}

=back

=over 4

=item within example 11

  # given: synopsis

  package main;

  my $within = $check->within('hashref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(undef);

  # Exception! (isa Venus::Check::Error) (see error_on_defined)

=back

=over 4

=item within example 12

  # given: synopsis

  package main;

  my $within = $check->within('hashref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result([]);

  # Exception! (isa Venus::Check::Error) (see error_on_hashref)

=back

=over 4

=item within example 13

  # given: synopsis

  package main;

  my $within = $check->within('hashref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({});

  # Exception! (isa Venus::Check::Error) (see error_on_hashref_empty)

=back

=over 4

=item within example 14

  # given: synopsis

  package main;

  my $within = $check->within('hashref', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({title => rand});

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 yesno

  yesno(coderef @code) (Venus::Check)

The yesno method configures the object to accept a string value, that's case
insensitive, and that's either C<"y"> or C<"yes"> or C<1> or C<"n"> or C<"no">
or C<0>, and returns the invocant.

I<Since C<3.55>>

=over 4

=item yesno example 1

  # given: synopsis

  package main;

  $check = $check->yesno;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('yes');

  # true

=back

=over 4

=item yesno example 2

  # given: synopsis

  package main;

  $check = $check->yesno;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval('yup');

  # false

=back

=over 4

=item yesno example 3

  # given: synopsis

  package main;

  $check = $check->yesno;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('yes');

  # 'yes'

=back

=over 4

=item yesno example 4

  # given: synopsis

  package main;

  $check = $check->yesno;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(undef);

  # Exception! (isa Venus::Check::Error) (see error_on_defined)

=back

=over 4

=item yesno example 5

  # given: synopsis

  package main;

  $check = $check->yesno;

  # bless(..., 'Venus::Check')

  # my $result = $check->result('yup');

  # Exception! (isa Venus::Check::Error) (see error_on_yesno)

=back

=cut

=head1 ERRORS

This package may raise the following errors:

=cut

=over 4

=item error: C<error_on_arrayref>

This package may raise an error_on_arrayref exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    throw => 'error_on_arrayref',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_arrayref"

  # my $message = $error->render;

  # "Failed checking test, value provided is not an arrayref or arrayref derived, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_arrayref_count>

This package may raise an error_on_arrayref_count exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    throw => 'error_on_arrayref_count',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_arrayref_count"

  # my $message = $error->render;

  # "Failed checking test, incorrect item count in arrayref or arrayref derived object, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_coded>

This package may raise an error_on_coded exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    expected => 'string',
    received => 'number',
    throw => 'error_on_coded',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_coded"

  # my $message = $error->render;

  # "Failed checking test, expected string, received number, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

  # my $expected = $error->stash('expected');

  # "string"

  # my $received = $error->stash('received');

  # "number"

=back

=over 4

=item error: C<error_on_consumes>

This package may raise an error_on_consumes exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    role => 'Example::Role',
    throw => 'error_on_consumes',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_consumes"

  # my $message = $error->render;

  # "Failed checking test, object does not consume the role \"Example::Role\", at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

  # my $role = $error->stash('role');

  # "Example::Role"

=back

=over 4

=item error: C<error_on_defined>

This package may raise an error_on_defined exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    throw => 'error_on_defined',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_defined"

  # my $message = $error->render;

  # "Failed checking test, value provided is undefined, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_either>

This package may raise an error_on_either exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    errors => [
      'Failed condition 1',
      'Failed condition 2',
    ],
    throw => 'error_on_either',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_either"

  # my $message = $error->render;

  # "Failed checking either-or condition:\n\nFailed condition 1\n\nFailed condition 2"

  # my $errors = $error->stash('errors');

  # ['Failed condition 1', Failed condition 2']

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_enum>

This package may raise an error_on_enum exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    data => 'black',
    enum => ['this', 'that'],
    throw => 'error_on_enum',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_enum"

  # my $message = $error->render;

  # "Failed checking test, received black, valid options are this, that, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

  # my $data = $error->stash('data');

  # "black"

  # my $enum = $error->stash('enum');

  # ['this', 'that']

=back

=over 4

=item error: C<error_on_hashref>

This package may raise an error_on_hashref exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    throw => 'error_on_hashref',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_hashref"

  # my $message = $error->render;

  # "Failed checking test, value provided is not a hashref or hashref derived, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_hashref_empty>

This package may raise an error_on_hashref_empty exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    throw => 'error_on_hashref_empty',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_hashref_empty"

  # my $message = $error->render;

  # "Failed checking test, no items found in hashref or hashref derived object, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_identity>

This package may raise an error_on_identity exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    name => 'Example',
    throw => 'error_on_identity',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_identity"

  # my $message = $error->render;

  # "Failed checking test, object is not a Example or derived object, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

  # my $name = $error->stash('name');

  # "Example"

=back

=over 4

=item error: C<error_on_includes>

This package may raise an error_on_includes exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    errors => [
      'Failed condition 1',
      'Failed condition 2',
    ],
    throw => 'error_on_includes',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_includes"

  # my $message = $error->render;

  # "Failed checking union-includes condition:\n\nFailed condition 1\n\nFailed condition 2"

  # my $errors = $error->stash('errors');

  # ['Failed condition 1', Failed condition 2']

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_inherits>

This package may raise an error_on_inherits exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    name => 'Example',
    throw => 'error_on_inherits',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_inherits"

  # my $message = $error->render;

  # "Failed checking test, object is not a Example derived object, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

  # my $name = $error->stash('name');

  # "Example"

=back

=over 4

=item error: C<error_on_missing>

This package may raise an error_on_missing exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    name => 'execute',
    throw => 'error_on_missing',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_missing"

  # my $message = $error->render;

  # "Failed checking test, "execute" is missing, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

  # my $name = $error->stash('name');

  # "execute"

=back

=over 4

=item error: C<error_on_package>

This package may raise an error_on_package exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    data => 'main',
    from => 'test',
    throw => 'error_on_package',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_package"

  # my $message = $error->render;

  # "Failed checking test, \"main\" is not a valid package name, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

  # my $data = $error->stash('data');

  # "main"

=back

=over 4

=item error: C<error_on_package_loaded>

This package may raise an error_on_package_loaded exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    data => 'main',
    from => 'test',
    throw => 'error_on_package_loaded',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_package_loaded"

  # my $message = $error->render;

  # "Failed checking test, \"main\" is not loaded, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

  # my $data = $error->stash('data');

  # "main"

=back

=over 4

=item error: C<error_on_pairs>

This package may raise an error_on_pairs exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    throw => 'error_on_pairs',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_pairs"

  # my $message = $error->render;

  # "Failed checking test, imblanced key/value pairs provided, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_reference>

This package may raise an error_on_reference exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    throw => 'error_on_reference',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_reference"

  # my $message = $error->render;

  # "Failed checking test, value provided is not a reference, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_unknown>

This package may raise an error_on_unknown exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_unknown',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_unknown"

  # my $message = $error->render;

  # "Failed performing check for unknown reason"

  # my $from = $error->stash('from');

  # undef

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_value>

This package may raise an error_on_value exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    throw => 'error_on_value',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_value"

  # my $message = $error->render;

  # "Failed checking test, value provided is a reference, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_within>

This package may raise an error_on_within exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    type => 'scalarref',
    throw => 'error_on_within',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_within"

  # my $message = $error->render;

  # "Invalid type \"scalarref\" provided to the \"within\" method"

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=over 4

=item error: C<error_on_yesno>

This package may raise an error_on_yesno exception.

B<example 1>

  # given: synopsis;

  my $input = {
    at => '.',
    from => 'test',
    throw => 'error_on_yesno',
  };

  my $error = $check->catch('error', $input);

  # my $name = $error->name;

  # "on_yesno"

  # my $message = $error->render;

  # "Failed checking test, value provided is not a recognized \"yes\" or \"no\" value, at ."

  # my $from = $error->stash('from');

  # "test"

  # my $at = $error->stash('at');

  # "."

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut