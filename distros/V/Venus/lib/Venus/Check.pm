package Venus::Check;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

use Venus::What;

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

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
        received => $source->what($value),
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
        received => $source->what($value),
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
        received => $source->what($value),
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

  require Venus::What;

  return Venus::What->new($data)->coded($name) ? true : false;
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
        received => $source->what($value),
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
        received => $source->what($value),
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

sub dirhandle {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'scalar') && ref $value eq 'GLOB' && do{no warnings 'io'; -d $value}) {
      return $source->pass($value, {
        from => 'dirhandle',
      });
    }
    else {
      return $source->fail($value, {
        from => 'dirhandle',
        expected => 'dirhandle',
        received => $source->what($value),
        with => 'error_on_dirhandle',
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

sub filehandle {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'scalar') && ref $value eq 'GLOB' && defined(fileno($value)) && !-d $value) {
      return $source->pass($value, {
        from => 'filehandle',
      });
    }
    else {
      return $source->fail($value, {
        from => 'filehandle',
        expected => 'filehandle',
        received => $source->what($value),
        with => 'error_on_filehandle',
      });
    }
  }, @code;

  return $self;
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
        received => $source->what($value),
        with => 'error_on_coded',
      });
    }
  }, @code;

  return $self;
}

sub glob {
  my ($self, @code) = @_;

  push @{$self->on_eval}, sub {
    my ($source, $value) = @_;
    if ($source->coded($value, 'scalar') && ref $value eq 'GLOB') {
      return $source->pass($value, {
        from => 'glob',
      });
    }
    else {
      return $source->fail($value, {
        from => 'glob',
        expected => 'typeglob',
        received => $source->what($value),
        with => 'error_on_typeglob',
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
        received => $source->what($value),
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
        received => $source->what($value),
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
        received => $source->what($value),
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
        received => $source->what($value),
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
        received => $source->what($value),
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
        received => $source->what($value),
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
        received => $source->what($value),
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
        received => $source->what($value),
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
  my $okay = (delete $result->{okay}) || $eval;
  my $with = (delete $result->{with}) || 'error_on_unknown';

  $result->{at} = $result->{'branch'}
    ? join('.', '', @{$result->{'branch'}}) || '.' : '.';

  return $okay ? $data : $self->$with($result)->capture(@data)->throw;
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
        received => $source->what($value),
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
        received => $source->what($value),
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
        received => $source->what($value),
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

sub what {
  my ($self, $value) = @_;

  my $aliases = {
    array => 'arrayref',
    code => 'coderef',
    hash => 'hashref',
    regexp => 'regexpref',
    scalar => 'scalarref',
  };

  my $identity = lc(Venus::What->new(value => $value)->identify);

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
        received => $source->what($value),
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
    require Venus::Meta;
    require Venus::Space;
    my $meta = Venus::Meta->new(
      name => Venus::Space->new($type)->do('tryload')->package,
    );
    if ($type && !ref $type && $meta->role('Venus::Role::Mappable')) {
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
        if (UNIVERSAL::isa($value, $type)) {
          return $source->pass($value, {
            from => 'within',
          });
        }
        else {
          return $source->fail($value, {
            from => 'within',
            expected => $type,
            received => $source->what($value),
            with => 'error_on_mappable_isa',
          });
        }
      }, sub {
        my ($source, $value) = @_;
        if ($value->count) {
          return $source->pass($value, {
            from => 'within',
          });
        }
        else {
          return $source->fail($value, {
            from => 'within',
            with => 'error_on_mappable_empty',
          });
        }
      }, sub {
        my ($source, $value) = @_;
        my $result = true;
        for my $key (@{$value->keys}) {
          my $check = $where->branch($key);
          $check->on_eval($where->on_eval);
          if (!$check->eval($value->get($key))) {
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

sub error_on_arrayref {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is not an arrayref or arrayref derived',
    'at {{at}}';

  $error->name('on.arrayref');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_arrayref_count {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'incorrect item count in arrayref or arrayref derived object',
    'at {{at}}';

  $error->name('on.arrayref.count');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_coded {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'expected {{expected}}',
    'received {{received}}',
    'at {{at}}';

  $error->name('on.coded');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_consumes {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'object does not consume the role "{{role}}"',
    'at {{at}}';

  $error->name('on.consumes');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_defined {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is undefined',
    'at {{at}}';

  $error->name('on.defined');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_dirhandle {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is not a dirhandle (or is not open)',
    'at {{at}}';

  $error->name('on.dirhandle');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_either {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join "\n\n",
    'Failed checking either-or condition:',
    @{$data->{errors}};

  $error->name('on.either');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_enum {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'received {{data}}',
    'valid options are {{options}}',
    'at {{at}}';

  $error->stash(options => (join ', ', @{$data->{enum}}));
  $error->name('on.enum');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_filehandle {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is not a filehandle (or is not open)',
    'at {{at}}';

  $error->name('on.filehandle');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_hashref {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is not a hashref or hashref derived',
    'at {{at}}';

  $error->name('on.hashref');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_hashref_empty {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'no items found in hashref or hashref derived object',
    'at {{at}}';

  $error->name('on.hashref.empty');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_includes {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join "\n\n",
    'Failed checking union-includes condition:',
    @{$data->{errors}};

  $error->name('on.includes');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_identity {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'object is not a {{name}} or derived object',
    'at {{at}}';

  $error->name('on.identity');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_inherits {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'object is not a {{name}} derived object',
    'at {{at}}';

  $error->name('on.inherits');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_isa {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'expected instance (or subclass) of {{expected}}',
    'received {{received}}',
    'at {{at}}';

  $error->name('on.isa');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_mappable_isa {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'expected instance (or subclass) of {{expected}}',
    'received {{received}}',
    'at {{at}}';

  $error->name('on.mappable.isa');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_mappable_empty {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'no items found in mappable object',
    'at {{at}}';

  $error->name('on.mappable.empty');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_missing {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    '"{{name}}" is missing',
    'at {{at}}';

  $error->name('on.missing');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_package {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    '"{{data}}" is not a valid package name',
    'at {{at}}';

  $error->name('on.package');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_package_loaded {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    '"{{data}}" is not loaded',
    'at {{at}}';

  $error->name('on.package.loaded');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_pairs {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'imblanced key/value pairs provided',
    'at {{at}}';

  $error->name('on.pairs');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_reference {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is not a reference',
    'at {{at}}';

  $error->name('on.reference');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_typeglob {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is not a typeglob',
    'at {{at}}';

  $error->name('on.typeglob');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_value {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is a reference',
    'at {{at}}';

  $error->name('on.value');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_within {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Invalid type "{{type}}" provided to the "within" method';

  $error->name('on.within');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_unknown {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Failed performing check for unknown reason';

  $error->name('on.unknown');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_yesno {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = join ', ',
    'Failed checking {{from}}',
    'value provided is not a recognized "yes" or "no" value',
    'at {{at}}';

  $error->name('on.yesno');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
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
L<Venus::What/coded> operation.

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

=head2 dirhandle

  dirhandle(coderef @code) (Venus::Check)

The dirhandle method configures the object to accept dirhandles and returns the
invocant.

I<Since C<4.15>>

=over 4

=item dirhandle example 1

  # given: synopsis

  package main;

  $check = $check->dirhandle;

  # bless(..., 'Venus::Check')

  # opendir my $dh, './t';

  # my $result = $check->eval($dh);

  # true

=back

=over 4

=item dirhandle example 2

  # given: synopsis

  package main;

  $check = $check->dirhandle;

  # bless(..., 'Venus::Check')

  # opendir my $dh, './xyz';

  # my $result = $check->eval($dh);

  # false

=back

=over 4

=item dirhandle example 3

  # given: synopsis

  package main;

  $check = $check->dirhandle;

  # bless(..., 'Venus::Check')

  # opendir my $dh, './t';

  # my $result = $check->result($dh);

  # \*{'::$dh'}

=back

=over 4

=item dirhandle example 4

  # given: synopsis

  package main;

  $check = $check->dirhandle;

  # bless(..., 'Venus::Check')

  # opendir my $dh, './xyz';

  # my $result = $check->result($dh);

  # Exception! (isa Venus::Check::Error) (see error_on_dirhandle)

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

=head2 filehandle

  filehandle(coderef @code) (Venus::Check)

The filehandle method configures the object to accept filehandles and returns the
invocant.

I<Since C<4.15>>

=over 4

=item filehandle example 1

  # given: synopsis

  package main;

  $check = $check->filehandle;

  # bless(..., 'Venus::Check')

  # open my $fh, './t/Venus.t';

  # my $result = $check->eval($fh);

  # true

=back

=over 4

=item filehandle example 2

  # given: synopsis

  package main;

  $check = $check->filehandle;

  # bless(..., 'Venus::Check')

  # open my $fh, './xyz/Venus.t';

  # my $result = $check->eval($fh);

  # false

=back

=over 4

=item filehandle example 3

  # given: synopsis

  package main;

  $check = $check->filehandle;

  # bless(..., 'Venus::Check')

  # open my $fh, './t/Venus.t';

  # my $result = $check->result($fh);

  # \*{'::$fh'}

=back

=over 4

=item filehandle example 4

  # given: synopsis

  package main;

  $check = $check->filehandle;

  # bless(..., 'Venus::Check')

  # open my $fh, './xyz/Venus.t';

  # my $result = $check->result($fh);

  # Exception! (isa Venus::Check::Error) (see error_on_filehandle)

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

=head2 glob

  glob(coderef @code) (Venus::Check)

The glob method configures the object to accept typeglobs and returns the
invocant.

I<Since C<4.15>>

=over 4

=item glob example 1

  # given: synopsis

  package main;

  $check = $check->glob;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(\*main);

  # true

=back

=over 4

=item glob example 2

  # given: synopsis

  package main;

  $check = $check->glob;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(*main);

  # false

=back

=over 4

=item glob example 3

  # given: synopsis

  package main;

  $check = $check->glob;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(\*main);

  # \*::main

=back

=over 4

=item glob example 4

  # given: synopsis

  package main;

  $check = $check->glob;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(*main);

  # Exception! (isa Venus::Check::Error) (see error_on_typeglob)

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

=head2 new

  new(any @args) (Venus::Check)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Check;

  my $new = Venus::Check->new;

  # bless(..., "Venus::Check")

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

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.arrayref>

  # given: synopsis;

  $check->tuple('string');

  $check->result({});

  # Error! (on.arrayref)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.arrayref.count>

  # given: synopsis;

  $check->tuple('string', 'string');

  $check->result(['hello']);

  # Error! (on.arrayref.count)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.coded>

  # given: synopsis;

  $check->string;

  $check->result(12345);

  # Error! (on.coded)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.consumes>

  # given: synopsis;

  package Example;

  use Venus::Class;

  package main;

  $check->consumes('Venus::Role::Throwable');

  $check->result(Example->new);

  # Error! (on.consumes)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.defined>

  # given: synopsis;

  $check->string;

  $check->result(undef);

  # Error! (on.defined)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.dirhandle>

  # given: synopsis;

  $check->dirhandle;

  $check->result('hello');

  # Error! (on.dirhandle)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.either>

  # given: synopsis;

  $check->either('string', 'number');

  $check->result([]);

  # Error! (on.either)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.enum>

  # given: synopsis;

  $check->enum('this', 'that');

  $check->result('other');

  # Error! (on.enum)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.filehandle>

  # given: synopsis;

  $check->filehandle;

  $check->result('hello');

  # Error! (on.filehandle)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.hashref>

  # given: synopsis;

  $check->hashkeys('name', 'string');

  $check->result([]);

  # Error! (on.hashref)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.hashref.empty>

  # given: synopsis;

  $check->hashkeys('name', 'string');

  $check->result({});

  # Error! (on.hashref.empty)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.includes>

  # given: synopsis;

  $check->includes('string', 'number');

  $check->result([]);

  # Error! (on.includes)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.identity>

  # given: synopsis;

  $check->identity('Venus::String');

  $check->result(Venus::Check->new);

  # Error! (on.identity)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.inherits>

  # given: synopsis;

  $check->inherits('Venus::String');

  $check->result(Venus::Check->new);

  # Error! (on.inherits)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.missing>

  # given: synopsis;

  $check->attributes('name', 'string');

  $check->result(bless{});

  # Error! (on.missing)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.package>

  # given: synopsis;

  $check->package;

  $check->result('not-a-package!');

  # Error! (on.package)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.package.loaded>

  # given: synopsis;

  $check->package;

  $check->result('Example::Fake');

  # Error! (on.package.loaded)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.pairs>

  # given: synopsis;

  $check->hashkeys('name');

  $check->result({name => 'example'});

  # Error! (on.pairs)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.reference>

  # given: synopsis;

  $check->reference;

  $check->result('hello');

  # Error! (on.reference)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.typeglob>

  # given: synopsis;

  $check->glob;

  $check->result('hello');

  # Error! (on.typeglob)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.value>

  # given: synopsis;

  $check->value;

  $check->result([]);

  # Error! (on.value)

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.yesno>

  # given: synopsis;

  $check->yesno;

  $check->result('maybe');

  # Error! (on.yesno)

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

=head2 what

  what(any $data) (string)

The type method returns the canonical data type name for the value provided.

I<Since C<3.55>>

=over 4

=item what example 1

  # given: synopsis

  package main;

  my $what = $check->what({});

  # 'hashref'

=back

=over 4

=item what example 2

  # given: synopsis

  package main;

  my $what = $check->what([]);

  # 'arrayref'

=back

=over 4

=item what example 3

  # given: synopsis

  package main;

  my $what = $check->what('Venus::Check');

  # 'string'

=back

=over 4

=item what example 4

  # given: synopsis

  package main;

  my $what = $check->what(Venus::Check->new);

  # 'object'

=back

=cut

=head2 within

  within(string $type, string | within[arrayref, string] @args) (Venus::Check)

The within method configures the object, registering a constraint action as a
sub-match operation, to accept array references, hash references, or mappable
values (see L<Venus::Role::Mappable>), and returns a new L<Venus::Check>
instance for the sub-match operation (not the invocant). This operation can
traverse blessed array or hash based values, or objects derived from classes
which consume the "mappable" role. The value being evaluated must contain
at-least one element to match.

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

=over 4

=item within example 15

  # given: synopsis

  package main;

  my $within = $check->within('Venus::Hash', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result({title => 'engineer'});

  # Exception! (isa Venus::Check::Error) (see error_on_mappable_isa)

=back

=over 4

=item within example 16

  # given: synopsis

  package main;

  use Venus::Hash;

  my $within = $check->within('Venus::Hash', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->result(Venus::Hash->new);

  # Exception! (isa Venus::Check::Error) (see error_on_mappable_empty)

=back

=over 4

=item within example 17

  # given: synopsis

  package main;

  use Venus::Hash;

  my $within = $check->within('Venus::Hash', 'string');

  # bless(..., 'Venus::Check')

  $check;

  # bless(..., 'Venus::Check')

  # my $result = $check->eval(Venus::Hash->new({title => 'engineer'}));

  # true

=back

=over 4

=item B<may raise> L<Venus::Check::Error> C<on.within>

  # given: synopsis;

  $check->within('scalarref', 'string');

  # Error! (on.within)

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

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut