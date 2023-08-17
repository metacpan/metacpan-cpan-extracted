package Venus::Container;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Buildable';
with 'Venus::Role::Valuable';

# BUILDERS

sub build_args {
  my ($self, $data) = @_;

  if (keys %$data == 1 && exists $data->{value}) {
    return $data;
  }
  return {
    value => $data
  };
}

# METHODS

sub metadata {
  my ($self, $name) = @_;

  return $name ? $self->tokens->{metadata}->{$name} : $self->tokens->{metadata};
}

sub reify {
  my ($self, $name, $data) = @_;

  return if !$name;

  my $cache = $self->{'$cache'} ||= $self->service_cache;

  return $cache->{$name} if $cache->{$name};

  my $services = $self->services;
  my $service = $services->{$name} or return;

  if (my $extends = $service->{extends}) {
    $service = $self->service_merge($service, $services->{$extends});
  }

  my $value = $self->service_build($service,
      $data
    ? $self->service_reify($data)
    : $self->service_reify($service->{argument}));

  my $lifecycle = $service->{lifecycle};
  $self->{'$cache'}->{$name} = $value if $lifecycle && $lifecycle eq 'singleton';

  return $value;
}

sub resolve {
  my ($self, $name, $data) = @_;

  return if !$name;

  my $value = $self->get;

  return exists $value->{$name} ? $value->{$name} : $self->reify($name, $data);
}

sub service_build {
  my ($self, $service, $argument) = @_;

  my $space = $self->service_space($service->{package});

  $space->load;

  my $construct;

  if (my $builder = $service->{builder}) {
    my $original;

    my $injectables = $argument;

    for (my $i=0; $i < @$builder; $i++) {
      my $buildspec = $builder->[$i];
      my $argument = $buildspec->{argument};
      my $argument_as = $buildspec->{argument_as};
      my $inject = $buildspec->{inject};
      my $return = $buildspec->{return};
      my $result = $construct || $space->package;

      my @arguments;

      if ($inject) {
        @arguments = $self->service_props(
          $self->service_reify($injectables), $inject
        );
      }
      else {
        @arguments = $self->service_props(
          $self->service_reify($argument), $argument_as
        );
      }

      if (my $function = $buildspec->{function}) {
        $result = $space->call($function, @arguments);
      }
      elsif (my $method = $buildspec->{method}) {
        $result = $space->call($method, $result, @arguments);
      }
      elsif (my $routine = $buildspec->{routine}) {
        $result = $space->call($routine, $space->package, @arguments);
      }
      else {
        next;
      }

      if ($return eq 'class') {
        $construct = $space->package;
      }
      if ($return eq 'result') {
        $construct = $result;
      }
      if ($return eq 'self') {
        $construct = $original //= $result;
      }
    }
  }
  elsif (my $method = $service->{method}) {
    $construct = $space->package->$method(
      $self->service_props($argument, $service->{argument_as}));
  }
  elsif (my $function = $service->{function}) {
    $construct = $space->call($function,
      $self->service_props($argument, $service->{argument_as}));
  }
  elsif (my $routine = $service->{routine}) {
    $construct = $space->call($routine, $space->package,
      $self->service_props($argument, $service->{argument_as}));
  }
  elsif (my $constructor = $service->{constructor}) {
    $construct = $space->package->$constructor(
      $self->service_props($argument, $service->{argument_as}));
  }
  else {
    $construct = $space->package->can('new')
      ? $space->call('new', $space->package,
        $self->service_props($argument, $service->{argument_as}))
      : $space->package;
  }

  return $construct;
}

sub service_cache {
  my ($self) = @_;

  $self->{'$cache'} = {};

  my $cache = {};
  my $services = $self->services;

  for my $name (keys %$services) {
    next if $cache->{$name};

    my $service = $services->{$name};
    my $lifecycle = $service->{lifecycle};

    next if !$lifecycle;

    if ($lifecycle eq 'eager') {
      $cache->{$name} = $self->reify($name);
    }
  }

  return $cache;
}

sub service_merge {
  my ($self, $left, $right) = @_;

  my $new_service = {};

  if (my $extends = $right->{extends}) {
    $right = $self->service_merge($right, $self->services->{$extends});
  }

  $new_service = {%$right, %$left};

  delete $new_service->{extends};

  if ((my $arg1 = $left->{argument}) || (my $arg2 = $right->{argument})) {
    if ((defined $left->{argument} && !ref($arg1))
      || (defined $right->{argument} && !ref($arg2))) {
      $new_service->{argument} ||= $arg1 if $arg1;
    }
    elsif ((defined $left->{argument} && (ref($arg1) eq 'ARRAY'))
      && (defined $right->{argument} && (ref($arg2) eq 'ARRAY'))) {
      $new_service->{argument} = [@$arg2, @$arg1];
    }
    elsif ((defined $left->{argument} && (ref($arg1) eq 'HASH'))
      && (defined $right->{argument} && (ref($arg2) eq 'HASH'))) {
      $new_service->{argument} = {%$arg2, %$arg1};
    }
    else {
      $new_service->{argument} ||= $arg1 if $arg1;
    }
  }

  return $new_service;
}

sub service_props {
  my ($self, $prop, $prop_as) = @_;

  my @props;

  if ($prop && $prop_as) {
    if (lc($prop_as) eq 'array' || lc($prop_as) eq 'arrayref') {
      if (ref $prop eq 'HASH') {
        @props = ([$prop]);
      }
      else {
        @props = ($prop);
      }
    }
    if (lc($prop_as) eq 'hash' || lc($prop_as) eq 'hashref') {
      if (ref $prop eq 'ARRAY') {
        @props = ({@$prop});
      }
      else {
        @props = ($prop);
      }
    }
    if (lc($prop_as) eq 'list') {
      if (ref $prop eq 'ARRAY') {
        @props = (@$prop);
      }
      elsif (ref $prop eq 'HASH') {
        @props = (%$prop);
      }
      else {
        @props = ($prop);
      }
    }
  }
  else {
    @props = ($prop) if defined $prop;
  }

  return (@props);
}

sub service_reify {
  my ($self, $props) = @_;

  my $metadata = $self->metadata;
  my $services = $self->services;

  if (ref $props eq 'ARRAY') {
    $props = [map $self->service_reify($_), @$props];
  }

  # $metadata
  if (ref $props eq 'HASH' && (keys %$props) == 1) {
    if ($props && $props->{'$metadata'}) {
      $props = $metadata->{$props->{'$metadata'}};
    }
  }

  # $envvar
  if (ref $props eq 'HASH' && (keys %$props) == 1) {
    if (my $envvar = $props->{'$envvar'}) {
      if (exists $ENV{$envvar}) {
        $props = $ENV{$envvar};
      }
      elsif (exists $ENV{uc($envvar)}) {
        $props = $ENV{uc($envvar)};
      }
      else {
        $props = undef;
      }
    }
  }

  # $function
  if (ref $props eq 'HASH' && (keys %$props) == 1) {
    if ($props->{'$function'}) {
      my ($name, $next) = split /#/, $props->{'$function'};
      if ($name && $next) {
        if (my $resolved = $self->reify($name)) {
          if (Scalar::Util::blessed($resolved)
            || (!ref($resolved) && ($resolved =~ /^[a-z-A-Z]/))) {
            my $space = $self->service_space(ref $resolved || $resolved);
            $props = $space->call($next) if $next && $next =~ /^[a-zA-Z]/;
          }
        }
      }
    }
  }

  # $method
  if (ref $props eq 'HASH' && (keys %$props) == 1) {
    if ($props->{'$method'}) {
      my ($name, $next) = split /#/, $props->{'$method'};
      if ($name && $next) {
        if (my $resolved = $self->reify($name)) {
          if (Scalar::Util::blessed($resolved)
            || (!ref($resolved) && ($resolved =~ /^[a-z-A-Z]/))) {
            $props = $resolved->$next if $next && $next =~ /^[a-zA-Z]/;
          }
        }
      }
    }
  }

  # $routine
  if (ref $props eq 'HASH' && (keys %$props) == 1) {
    if ($props->{'$routine'}) {
      my ($name, $next) = split /#/, $props->{'$routine'};
      if ($name && $next) {
        if (my $resolved = $self->reify($name)) {
          if (Scalar::Util::blessed($resolved)
            || (!ref($resolved) && ($resolved =~ /^[a-z-A-Z]/)))
          {
            my $space = $self->service_space(ref $resolved || $resolved);
            $props = $space->call($next, $space->package)
              if $next && $next =~ /^[a-zA-Z]/;
          }
        }
      }
    }
  }

  # $callback
  if (ref $props eq 'HASH' && (keys %$props) == 1) {
    if (my $callback = $props->{'$callback'}) {
      $props = sub { $self->reify($callback) };
    }
  }

  # $service
  if (ref $props eq 'HASH' && (keys %$props) == 1) {
    if ($props->{'$service'}) {
      $props = $self->reify($props->{'$service'});
    }
  }

  if (ref $props eq 'HASH' && grep ref, values %$props) {
    @$props{keys %$props} = map $self->service_reify($_), values %$props;
  }

  return $props;
}

sub service_space {
  my ($self, $name) = @_;

  require Venus::Space;

  return Venus::Space->new($name);
}

sub services {
  my ($self, $name) = @_;

  return $name ? $self->tokens->{services}->{$name} : $self->tokens->{services};
}

sub tokens {
  my ($self) = @_;

  return $self->{'$tokens'} ||= {
    services => $self->get->{'$services'} || {},
    metadata => $self->get->{'$metadata'} || {},
  };
}

1;



=head1 NAME

Venus::Container - Container Class

=cut

=head1 ABSTRACT

Container Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Container;

  my $container = Venus::Container->new;

  # my $object = $container->resolve('...');

  # "..."

=cut

=head1 DESCRIPTION

This package provides methods for building objects with dependency injection.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

L<Venus::Role::Valuable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 metadata

  metadata(Str $name) (Any)

The metadata method returns the C<$metadata> section of the configuration data
if no name is provided, otherwise returning the specific metadata keyed on the
name provided.

I<Since C<3.20>>

=over 4

=item metadata example 1

  # given: synopsis

  package main;

  my $metadata = $container->metadata;

  # {}

=back

=over 4

=item metadata example 2

  # given: synopsis

  package main;

  $container->value({
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => { package => "Venus/Path", argument => { '$metadata' => "tmplog" } }
    }
  });

  my $metadata = $container->metadata;

  # {
  #   tmplog => "/tmp/log"
  # }

=back

=over 4

=item metadata example 3

  # given: synopsis

  package main;

  $container->value({
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => { package => "Venus/Path", argument => { '$metadata' => "tmplog" } }
    }
  });

  my $metadata = $container->metadata("tmplog");

  # "/tmp/log"

=back

=cut

=head2 reify

  reify(Str $name) (Any)

The reify method resolves and returns an object or value based on the service
name provided.

I<Since C<3.20>>

=over 4

=item reify example 1

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => {
        package => "Venus/Path",
        argument => {
          '$metadata' => "tmplog"
        }
      }
    }
  });

  my $reify = $container->reify('tmp');

  # undef

=back

=over 4

=item reify example 2

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => {
        package => "Venus/Path",
        argument => {
          '$metadata' => "tmplog"
        }
      }
    }
  });

  my $reify = $container->reify('log');

  # bless({value => '/tmp/log'}, 'Venus::Path')

=back

=over 4

=item reify example 3

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => {
        package => "Venus/Path",
        argument => {
          '$metadata' => "tmplog"
        }
      }
    }
  });

  my $reify = $container->reify('log', '.');

  # bless({value => '.'}, 'Venus::Path')

=back

=over 4

=item reify example 4

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => {
        package => "Venus/Path",
        argument => {
          '$metadata' => "tmplog"
        }
      }
    }
  });

  my $reify = $container->reify('log', {value => '.'});

  # bless({value => '.'}, 'Venus::Path')

=back

=cut

=head2 resolve

  resolve(Str $name) (Any)

The resolve method resolves and returns an object or value based on the
configuration key or service name provided.

I<Since C<3.20>>

=over 4

=item resolve example 1

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    name => 'app',
    log => '/tmp/log/app.log',
    '$metadata' => {
      tmplog => "/tmp/log",
      varlog => "/var/log"
    },
    '$services' => {
      log => {
        package => "Venus/Path",
        argument => '.'
      },
      tmp_log => {
        package => "Venus/Path",
        extends => 'log',
        argument => {
          '$metadata' => "tmplog"
        }
      },
      var_log => {
        package => "Venus/Path",
        extends => 'log',
        argument => {
          '$metadata' => "varlog"
        }
      }
    }
  });

  my $result = $container->resolve;

  # undef

=back

=over 4

=item resolve example 2

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    name => 'app',
    log => '/tmp/log/app.log',
    '$metadata' => {
      tmplog => "/tmp/log",
      varlog => "/var/log"
    },
    '$services' => {
      log => {
        package => "Venus/Path",
        argument => '.'
      },
      tmp_log => {
        package => "Venus/Path",
        extends => 'log',
        argument => {
          '$metadata' => "tmplog"
        }
      },
      var_log => {
        package => "Venus/Path",
        extends => 'log',
        argument => {
          '$metadata' => "varlog"
        }
      }
    }
  });

  my $result = $container->resolve('log');

  # "/tmp/log/app.log"

=back

=over 4

=item resolve example 3

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    name => 'app',
    log => '/tmp/log/app.log',
    '$metadata' => {
      tmplog => "/tmp/log",
      varlog => "/var/log"
    },
    '$services' => {
      log => {
        package => "Venus/Path",
        argument => '.'
      },
      tmp_log => {
        package => "Venus/Path",
        extends => 'log',
        argument => {
          '$metadata' => "tmplog"
        }
      },
      var_log => {
        package => "Venus/Path",
        extends => 'log',
        argument => {
          '$metadata' => "varlog"
        }
      }
    }
  });

  my $result = $container->resolve('tmp_log');

  # bless({value => '/tmp/log'}, 'Venus::Path')

=back

=over 4

=item resolve example 4

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    name => 'app',
    log => '/tmp/log/app.log',
    '$metadata' => {
      tmplog => "/tmp/log",
      varlog => "/var/log"
    },
    '$services' => {
      log => {
        package => "Venus/Path",
        argument => '.'
      },
      tmp_log => {
        package => "Venus/Path",
        extends => 'log',
        argument => {
          '$metadata' => "tmplog"
        }
      },
      var_log => {
        package => "Venus/Path",
        extends => 'log',
        argument => {
          '$metadata' => "varlog"
        }
      }
    }
  });

  my $result = $container->resolve('var_log');

  # bless({value => '/var/log'}, 'Venus::Path')

=back

=cut

=head2 services

  services(Str $name) (Any)

The services method returns the C<$services> section of the configuration data
if no name is provided, otherwise returning the specific service keyed on the
name provided.

I<Since C<3.20>>

=over 4

=item services example 1

  # given: synopsis

  package main;

  my $services = $container->services;

  # {}

=back

=over 4

=item services example 2

  # given: synopsis

  package main;

  $container->value({
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => { package => "Venus/Path", argument => { '$metadata' => "tmplog" } }
    }
  });

  my $services = $container->services;

  # {
  #   log => {
  #     package => "Venus/Path",
  #     argument => {'$metadata' => "tmplog"}
  #   }
  # }

=back

=over 4

=item services example 3

  # given: synopsis

  package main;

  $container->value({
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => { package => "Venus/Path", argument => { '$metadata' => "tmplog" } }
    }
  });

  my $services = $container->services('log');

  # {
  #   package => "Venus/Path",
  #   argument => {'$metadata' => "tmplog"}
  # }

=back

=cut

=head1 FEATURES

This package provides the following features:

=cut

=over 4

=item $callback

This package supports resolving services as callbacks to be passed around
and/or resolved by other services. The C<$callback> directive is used to
specify the name of a service to be resolved and passed as an argument.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      log => {
        package => "Venus/Path",
        argument => '.',
      },
      lazy_log => {
        package => "Venus/Code",
        argument => {
          '$callback' => 'log',
        }
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('lazy_log');

  # bless(..., 'Venus::Code')

  # my $return = $result->call;

  # bless(..., 'Venus::Path')

=back

=over 4

=item $envvar

This package supports inlining environment variables as arguments to services.
The C<$envvar> directive is used to specify the name of an environment variable,
and can also be used in metadata for reusability.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      home => {
        package => "Venus/Path",
        argument => {
          '$envvar' => 'home',
        }
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('home');

  # bless(..., 'Venus::Path')

B<example 2>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$metadata' => {
      home => {
        '$envvar' => 'home',
      }
    },
    '$services' => {
      home => {
        package => "Venus/Path",
        argument => {
          '$metadata' => 'home',
        }
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('home');

  # bless(..., 'Venus::Path')

=back

=over 4

=item $function

This package supports inlining the result of a service resolution and function
call as arguments to services. The C<#> delimited C<$function> directive is
used to specify the name of an existing service on the right-hand side, and an
arbitrary function to be call on the result on the left-hand side.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      filespec => {
        package => 'File/Spec/Functions',
      },
      tempdir => {
        package => "Venus/Path",
        argument => {
          '$function' => 'filespec#tmpdir',
        }
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('tempdir');

  # bless(..., 'Venus::Path')

=back

=over 4

=item $metadata

This package supports inlining configuration data as arguments to services. The
C<$metadata> directive is used to specify the name of a stashed configuration
value or data structure.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$metadata' => {
      home => '/home/ubuntu',
    },
    '$services' => {
      home => {
        package => "Venus/Path",
        argument => {
          '$metadata' => 'home',
        }
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('home');

  # bless(..., 'Venus::Path')

=back

=over 4

=item $method

This package supports inlining the result of a service resolution and method
call as arguments to services. The C<#> delimited C<$method> directive is used
to specify the name of an existing service on the right-hand side, and an
arbitrary method to be call on the result on the left-hand side.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      filespec => {
        package => 'File/Spec',
      },
      tempdir => {
        package => "Venus/Path",
        argument => {
          '$method' => 'filespec#tmpdir',
        }
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('tempdir');

  # bless(..., 'Venus::Path')

=back

=over 4

=item $routine

This package supports inlining the result of a service resolution and routine
call as arguments to services. The C<#> delimited C<$routine> directive is used
to specify the name of an existing service on the right-hand side, and an
arbitrary routine to be call on the result on the left-hand side.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      filespec => {
        package => 'File/Spec',
      },
      tempdir => {
        package => "Venus/Path",
        argument => {
          '$routine' => 'filespec#tmpdir',
        }
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('tempdir');

  # bless(..., 'Venus::Path')

=back

=over 4

=item $service

This package supports inlining resolved services as arguments to other
services. The C<$service> directive is used to specify the name of a service to
be resolved and passed as an argument.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      'path' => {
        'package' => 'Venus/Path',
      },
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('path');

  # bless(..., 'Venus::Path')

=back

=over 4

=item #argument

This package supports providing static and/or dynamic arguments during object
construction from metadata or other services.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      'date' => {
        'package' => 'Venus/Date',
        'argument' => 570672000,
      },
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('date');

  # bless(..., 'Venus::Date')

B<example 2>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      'date' => {
        'package' => 'Venus/Date',
        'argument' => {
          year => 1988,
          month => 2,
          day => 1,
        },
      },
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('date');

  # bless(..., 'Venus::Date')

=back

=over 4

=item #argument_as

This package supports transforming the way static and/or dynamic arguments are
passed to the operation during object construction. Acceptable options are
C<array> or C<arrayref> (which provides an arrayref), C<hash> or C<hashref>
(which provides a hashref), or C<list> (which provides a flattened list of
arguments).

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      'date' => {
        'package' => 'Venus/Date',
        'argument' => {
          year => 1988,
          month => 2,
          day => 1,
        },
        argument_as => 'list',
      },
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('date');

  # bless(..., 'Venus::Date')

B<example 2>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      'date' => {
        'package' => 'Venus/Date',
        'argument' => {
          year => 1988,
          month => 2,
          day => 1,
        },
        argument_as => 'hash',
      },
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('date');

  # bless(..., 'Venus::Date')

=back

=over 4

=item #builder

This package supports specifying multiple build steps as C<function>,
C<method>, and C<routine> calls and chaining them together. Each build step
supports any directive that can be used outside of a build step. Each build
step can be configured, with the C<return> directive, to use a particular value
to chain the next subroutine call. Acceptable C<return> values are C<class>
(package name string), C<result> (scalar return value from the current build
step), and C<self> (instantiated package). Additionally, you can use the
C<inject> directive (with any value accepted by C<argument_as>) to override the
default arguments using the arguments provided to the L</reify> or L</resolve>
method.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      datetime => {
        package => "Venus/Date",
        builder => [
          {
            method => 'new',
            argument => 570672000,
            return => 'self',
          },
          {
            method => 'string',
            return => 'result',
          }
        ],
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('datetime');

  # "1988-02-01T00:00:00Z"

B<example 2>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      datetime => {
        package => "Venus/Date",
        builder => [
          {
            method => 'new',
            argument => 570672000,
            return => 'self',
            inject => 'list',
          },
          {
            method => 'string',
            return => 'result',
          }
        ],
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('datetime', 604945074);

  # "1989-03-03T16:17:54Z"

=back

=over 4

=item #config

This package supports configuring services and metadata in the service of
building objects and values.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    'name' => 'app',
    'secret' => '...',
    '$metadata' => {
      home => {
        '$envvar' => 'home',
      }
    },
    '$services' => {
      date => {
        package => "Venus/Date",
      },
      path => {
        package => "Venus/Path",
        argument => {
          '$metadata' => 'home',
        },
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $path = $container->resolve('path');

  # bless(..., 'Venus::Path')

  # my $name = $container->resolve('name');

  # "app"

=back

=over 4

=item #constructor

This package supports specifying constructors other than the traditional C<new>
routine. A constructor is always called with the package name as the invocant.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      path => {
        package => "Venus/Path",
        constructor => "new",
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('path');

  # bless(..., 'Venus::Path')

=back

=over 4

=item #extends

This package supports extending services in the definition of other services,
recursively compiling service configurations and eventually executing the
requested compiled service.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      log => {
        package => "Venus/Log",
        argument => {
          level => "trace",
        },
      },
      development_log => {
        package => "Venus/Log",
        extends => "log",
        builder => [
          {
            method => "new",
            return => "self",
            inject => "hash",
          }
        ],
      },
      production_log => {
        package => "Venus/Log",
        extends => "log",
        argument => {
          level => "error",
        },
        builder => [
          {
            method => "new",
            return => "self",
            inject => "hash",
          }
        ],
      },
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('development_log');

  # bless(..., 'Venus::Log')

  # my $level = $result->level;

  # "trace"

  # $result = $container->resolve('production_log');

  # bless(..., 'Venus::Log')

  # $level = $result->level;

  # "error"

=back

=over 4

=item #function

This package supports specifying construction as a function call, which when
called does not provide an invocant.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      foo_hex => {
        package => "Digest/MD5",
        function => "md5_hex",
        argument => "foo",
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('foo_hex');

  # "acbd18db4cc2f85cedef654fccc4a4d8"

=back

=over 4

=item #lifecycle

This package supports different lifecycle options which determine when services
are built and whether they're persisted. Acceptable lifecycle values are
C<singleton> (which caches the result once encountered) and C<eager> (which
caches the service upon the first execution of any service).

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      match => {
        package => "Venus/Match",
        argument => {
          'a'..'h'
        },
        builder => [
          {
            method => "new",
            return => "result",
          },
          {
            method => "data",
            return => "result",
            inject => "hash",
          }
        ],
        lifecycle => 'eager',
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('thing');

  # undef

  # my $result = $container->resolve('match');

  # bless(..., 'Venus::Match')

B<example 2>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      match => {
        package => "Venus/Match",
        argument => {
          'a'..'h'
        },
        builder => [
          {
            method => "new",
            return => "result",
          },
          {
            method => "data",
            return => "result",
            inject => "hash",
          }
        ],
        lifecycle => 'singleton',
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('match');

  # bless(..., 'Venus::Match')

=back

=over 4

=item #metadata

This package supports specifying data and structures which can be used in the
construction of multiple services.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$metadata' => {
      'homedir' => '/home',
      'tempdir' => '/tmp',
    },
    '$services' => {
      home => {
        package => "Venus/Path",
        argument => {
          '$metadata' => 'homedir',
        },
      },
      temp => {
        package => "Venus/Path",
        argument => {
          '$metadata' => 'tempdir',
        },
      },
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('home');

  # bless(..., 'Venus::Path')

  # my $result = $container->resolve('temp');

  # bless(..., 'Venus::Path')

=back

=over 4

=item #method

This package supports specifying construction as a method call, which when
called provides the package or object instance as the invocant.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      date => {
        package => "Venus/Date",
        argument => 570672000,
        method => "new",
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('date');

  # bless(..., 'Venus::Date')

=back

=over 4

=item #routine

This package supports specifying construction as a function call, which when
called provides the package as the invocant.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      date => {
        package => "Venus/Date",
        argument => 570672000,
        routine => "new",
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('date');

  # bless(..., 'Venus::Date')

=back

=over 4

=item #service

This package supports defining services to be constructed on-demand or
automatically on instantiation.

B<example 1>

  package main;

  use Venus::Container;

  my $container = Venus::Container->new({
    '$services' => {
      path => {
        package => "Venus/Path",
      }
    }
  });

  # bless(..., 'Venus::Container')

  # my $result = $container->resolve('path');

  # bless(..., 'Venus::Path')

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut