package Venus::Task::Venus::Gen;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base';

# IMPORTS

use Venus::Path;
use Venus::Space;

# REQUIRES

require Venus;

# INHERITS

base 'Venus::Task::Venus';

# METHODS

sub name {
  'vns gen'
}

sub footer {

  return <<"EOF";
Copyright 2022-2023, Vesion $Venus::VERSION, The Venus "AUTHOR" and "CONTRIBUTORS"

More information on "vns" and/or the "Venus" standard library, visit
https://p3rl.org/vns.
EOF
}

sub perform {
  my ($self) = @_;

  my $data = $self->input_options_defined;

  $data->{name} ||= 'Example';

  my $space = Venus::Space->new($data->{name});

  my $lfile = $data->{lfile} = $space->format('lfile', 'lib/%s');
  my $tfile = $data->{tfile} = $space->format('tfile', 't/%s');

  my %known = map +($_, 1), qw(
    build-arg
    build-args
    build-nil
    build-self
  );

  if (grep {$known{$_}} keys %{$data}) {
    @{$data->{integrates}} = (
      'Venus::Role::Buildable',
      (grep { !/^Venus::Role::Buildable$/ } @{$data->{integrates}}),
    );
  }

  if (grep {/^build-/ && !$known{$_}} keys %{$data}) {
    @{$data->{integrates}} = (
      (grep { !/^Venus::Role::Optional$/ } @{$data->{integrates}}),
      'Venus::Role::Optional',
    );
  }

  if ($data->{kind}) {
    @{$data->{inherits}} = (
      'Venus::Kind',
      (grep { !/^Venus::Kind$/ } @{$data->{inherits}}),
    );
  }

  if ($data->{value}) {
    @{$data->{inherits}} = (
      'Venus::Kind::Value',
      (grep { !/^Venus::Kind::Value$/ } @{$data->{inherits}}),
    );
  }

  if ($data->{utility}) {
    @{$data->{inherits}} = (
      'Venus::Kind::Utility',
      (grep { !/^Venus::Kind::Utility$/ } @{$data->{inherits}}),
    );
  }

  if ($data->{accessible}) {
    @{$data->{integrates}} = (
      'Venus::Role::Accessible',
      (grep { !/^Venus::Role::Accessible$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{boxable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Boxable',
      (grep { !/^Venus::Role::Boxable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{buildable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Buildable',
      (grep { !/^Venus::Role::Buildable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{catchable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Catchable',
      (grep { !/^Venus::Role::Catchable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{coercible}) {
    @{$data->{integrates}} = (
      'Venus::Role::Coercible',
      (grep { !/^Venus::Role::Coercible$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{comparable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Comparable',
      (grep { !/^Venus::Role::Comparable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{defaultable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Defaultable',
      (grep { !/^Venus::Role::Defaultable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{deferrable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Deferrable',
      (grep { !/^Venus::Role::Deferrable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{digestable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Digestable',
      (grep { !/^Venus::Role::Digestable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{doable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Doable',
      (grep { !/^Venus::Role::Doable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{dumpable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Dumpable',
      (grep { !/^Venus::Role::Dumpable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{encaseable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Encaseable',
      (grep { !/^Venus::Role::Encaseable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{explainable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Explainable',
      (grep { !/^Venus::Role::Explainable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{fromable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Fromable',
      (grep { !/^Venus::Role::Fromable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{mappable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Mappable',
      (grep { !/^Venus::Role::Mappable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{matchable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Matchable',
      (grep { !/^Venus::Role::Matchable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{mockable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Mockable',
      (grep { !/^Venus::Role::Mockable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{optional}) {
    @{$data->{integrates}} = (
      'Venus::Role::Optional',
      (grep { !/^Venus::Role::Optional$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{patchable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Patchable',
      (grep { !/^Venus::Role::Patchable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{pluggable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Pluggable',
      (grep { !/^Venus::Role::Pluggable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{printable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Printable',
      (grep { !/^Venus::Role::Printable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{proxyable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Proxyable',
      (grep { !/^Venus::Role::Proxyable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{reflectable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Reflectable',
      (grep { !/^Venus::Role::Reflectable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{rejectable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Rejectable',
      (grep { !/^Venus::Role::Rejectable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{resultable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Resultable',
      (grep { !/^Venus::Role::Resultable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{serializable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Serializable',
      (grep { !/^Venus::Role::Serializable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{stashable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Stashable',
      (grep { !/^Venus::Role::Stashable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{subscribable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Subscribable',
      (grep { !/^Venus::Role::Subscribable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{superable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Superable',
      (grep { !/^Venus::Role::Superable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{testable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Testable',
      (grep { !/^Venus::Role::Testable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{throwable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Throwable',
      (grep { !/^Venus::Role::Throwable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{tryable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Tryable',
      (grep { !/^Venus::Role::Tryable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{unacceptable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Unacceptable',
      (grep { !/^Venus::Role::Unacceptable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{unpackable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Unpackable',
      (grep { !/^Venus::Role::Unpackable$/ } @{$data->{integrates}}),
    );
  }

  if ($data->{valuable}) {
    @{$data->{integrates}} = (
      'Venus::Role::Valuable',
      (grep { !/^Venus::Role::Valuable$/ } @{$data->{integrates}}),
    );
  }

  if (grep {$data->{$_}} 'class', 'mixin', 'role') {
    my $rendered = join "\n", $self->render_unit;

    if ($data->{stdout}) {
      $self->log_info($rendered);
    }
    else {
      my $path = Venus::Path->new($lfile);

      if (!$path->exists || $data->{overwrite}) {
        $path->parent->mkdirs;
        $path->write($rendered);
        $self->log_info("$path created");
      }
      else {
        $self->log_error("$path exists");
      }
    }
  }

  if ($data->{test}) {
    my $rendered = join "\n", $self->render_test;

    if ($data->{stdout}) {
      $self->log_info($rendered);
    }
    else {
      my $path = Venus::Path->new($tfile);

      if (!$path->exists || $data->{overwrite}) {
        $path->parent->mkdirs;
        $path->write($rendered);
        $self->log_info("$path created");
      }
      else {
        $self->log_error("$path exists");
      }
    }
  }

  return $self;
}

sub prepare {
  my ($self) = @_;

  $self->summary('generate Venus source code');

  # help
  $self->option('help', {
    name => 'help',
    help => 'Display the help text.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # name
  $self->option('name', {
    name => 'name',
    help => 'The name of the package.',
    aliases => ['package'],
    multiples => 0,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # abstract
  $self->option('abstract', {
    name => 'abstract',
    help => 'The package abstract.',
    multiples => 0,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # attributes
  $self->option('attribute', {
    name => 'attributes',
    help => 'A package attribute.',
    aliases => ['attr', 'attribute'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-arg
  $self->option('build-arg', {
    name => 'build-arg',
    help => 'A package object construction build condition.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # build-args
  $self->option('build-args', {
    name => 'build-args',
    help => 'A package object construction build condition.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # build-asserts
  $self->option('build-assert', {
    name => 'build-asserts',
    help => 'A package attribute assert condition.',
    aliases => ['build-assert'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-assert-selfs
  $self->option('build-assert-self', {
    name => 'build-assert-selfs',
    help => 'A package attribute self-assert condition.',
    aliases => ['build-assert-self'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-attributes
  $self->option('build-attribute', {
    name => 'build-attributes',
    help => 'A package attribute build-attribute condition.',
    aliases => ['build-attribute'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-attribute-lazys
  $self->option('build-attribute-lazy', {
    name => 'build-attribute-lazys',
    help => 'A package attribute lazy-build-attribute condition.',
    aliases => ['build-attribute-lazy'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-checks
  $self->option('build-check', {
    name => 'build-checks',
    help => 'A package attribute check-attribute condition.',
    aliases => ['build-check'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-coerces
  $self->option('build-coerce', {
    name => 'build-coerces',
    help => 'A package attribute coerce-attribute condition.',
    aliases => ['build-coerce'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-coerce-selfs
  $self->option('build-coerce-self', {
    name => 'build-coerce-selfs',
    help => 'A package attribute self-coerce-attribute condition.',
    aliases => ['build-coerce-self'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-defaults
  $self->option('build-default', {
    name => 'build-defaults',
    help => 'A package attribute default-attribute condition.',
    aliases => ['build-default'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-initials
  $self->option('build-initial', {
    name => 'build-initials',
    help => 'A package attribute initial-attribute value condition.',
    aliases => ['build-initial'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-nil
  $self->option('build-nil', {
    name => 'build-nil',
    help => 'A package object construction build condition.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # build-reads
  $self->option('build-read', {
    name => 'build-reads',
    help => 'A package attribute read-attribute condition.',
    aliases => ['build-read'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-readonlys
  $self->option('build-readonly', {
    name => 'build-readonlys',
    help => 'A package attribute readonly-attribute condition.',
    aliases => ['build-readonly'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-readwrites
  $self->option('build-readwrite', {
    name => 'build-readwrites',
    help => 'A package attribute readwrite-attribute condition.',
    aliases => ['build-readwrite'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-requires
  $self->option('build-require', {
    name => 'build-requires',
    help => 'A package attribute require-attribute condition.',
    aliases => ['build-require'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-self
  $self->option('build-self', {
    name => 'build-self',
    help => 'A package object construction build condition.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # build-triggers
  $self->option('build-trigger', {
    name => 'build-triggers',
    help => 'A package attribute trigger condition.',
    aliases => ['build-trigger'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # build-writes
  $self->option('build-write', {
    name => 'build-writes',
    help => 'A package attribute write-attribute condition.',
    aliases => ['build-write'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # class
  $self->option('class', {
    name => 'class',
    help => 'Create package as a class.',
    aliases => ['c'],
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # description
  $self->option('description', {
    name => 'description',
    help => 'A package description.',
    aliases => ['desc'],
    multiples => 0,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # errors
  $self->option('error', {
    name => 'errors',
    help => 'A package error.',
    aliases => ['error'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # functions
  $self->option('function', {
    name => 'functions',
    help => 'A package function.',
    aliases => ['function'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # imports
  $self->option('import', {
    name => 'imports',
    help => 'Declare package imports.',
    aliases => ['use', 'import'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # inherits
  $self->option('inherit', {
    name => 'inherits',
    help => 'Declare packages to inherit.',
    aliases => ['base', 'inherit'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # integrates
  $self->option('integrate', {
    name => 'integrates',
    help => 'Declare packages to integrate.',
    aliases => ['with', 'integrate'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # hook
  $self->option('hook', {
    name => 'hooks',
    help => 'Declare a package hook.',
    aliases => ['hook'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # methods
  $self->option('method', {
    name => 'methods',
    help => 'A package method.',
    aliases => ['method'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # mixin
  $self->option('mixin', {
    name => 'mixin',
    help => 'Create package as a mixin.',
    aliases => ['m'],
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # overwrite output file
  $self->option('overwrite', {
    name => 'overwrite',
    help => 'Option to overwrite the output file if it already exists.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # ours
  $self->option('our', {
    name => 'ours',
    help => 'A package variable.',
    aliases => ['our'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # requires
  $self->option('require', {
    name => 'requires',
    help => 'A package require.',
    aliases => ['require'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # role
  $self->option('role', {
    name => 'role',
    help => 'Create package as a role.',
    aliases => ['r'],
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # routines
  $self->option('routine', {
    name => 'routines',
    help => 'A package routine.',
    aliases => ['routine'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # states
  $self->option('state', {
    name => 'states',
    help => 'A package state variable.',
    aliases => ['state'],
    multiples => 1,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # output to stdout
  $self->option('stdout', {
    name => 'stdout',
    help => 'Output the generated code to STDOUT.',
    aliases => ['p', 'print'],
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # tagline
  $self->option('tagline', {
    name => 'tagline',
    help => 'A package tagline.',
    multiples => 0,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # test
  $self->option('test', {
    name => 'test',
    help => 'Create test for package.',
    aliases => ['t'],
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # kind
  $self->option('kind', {
    name => 'kind',
    help => 'Inherits from Venus::Kind.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # value
  $self->option('value', {
    name => 'value',
    help => 'Inherits from Venus::Kind::Value.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # utility
  $self->option('utility', {
    name => 'utility',
    help => 'Inherits from Venus::Kind::Utility.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # accessible
  $self->option('accessible', {
    name => 'accessible',
    help => 'Integrate with Venus::Role::Accessible.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # boxable
  $self->option('boxable', {
    name => 'boxable',
    help => 'Integrate with Venus::Role::Boxable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # buildable
  $self->option('buildable', {
    name => 'buildable',
    help => 'Integrate with Venus::Role::Buildable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # catchable
  $self->option('catchable', {
    name => 'catchable',
    help => 'Integrate with Venus::Role::Catchable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # coercible
  $self->option('coercible', {
    name => 'coercible',
    help => 'Integrate with Venus::Role::Coercible.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # comparable
  $self->option('comparable', {
    name => 'comparable',
    help => 'Integrate with Venus::Role::Comparable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # defaultable
  $self->option('defaultable', {
    name => 'defaultable',
    help => 'Integrate with Venus::Role::Defaultable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # deferrable
  $self->option('deferrable', {
    name => 'deferrable',
    help => 'Integrate with Venus::Role::Deferrable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # digestable
  $self->option('digestable', {
    name => 'digestable',
    help => 'Integrate with Venus::Role::Digestable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # doable
  $self->option('doable', {
    name => 'doable',
    help => 'Integrate with Venus::Role::Doable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # dumpable
  $self->option('dumpable', {
    name => 'dumpable',
    help => 'Integrate with Venus::Role::Dumpable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # encaseable
  $self->option('encaseable', {
    name => 'encaseable',
    help => 'Integrate with Venus::Role::Encaseable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # explainable
  $self->option('explainable', {
    name => 'explainable',
    help => 'Integrate with Venus::Role::Explainable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # fromable
  $self->option('fromable', {
    name => 'fromable',
    help => 'Integrate with Venus::Role::Fromable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # mappable
  $self->option('mappable', {
    name => 'mappable',
    help => 'Integrate with Venus::Role::Mappable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # matchable
  $self->option('matchable', {
    name => 'matchable',
    help => 'Integrate with Venus::Role::Matchable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # mockable
  $self->option('mockable', {
    name => 'mockable',
    help => 'Integrate with Venus::Role::Mockable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # optional
  $self->option('optional', {
    name => 'optional',
    help => 'Integrate with Venus::Role::Optional.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # patchable
  $self->option('patchable', {
    name => 'patchable',
    help => 'Integrate with Venus::Role::Patchable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # pluggable
  $self->option('pluggable', {
    name => 'pluggable',
    help => 'Integrate with Venus::Role::Pluggable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # printable
  $self->option('printable', {
    name => 'printable',
    help => 'Integrate with Venus::Role::Printable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # proxyable
  $self->option('proxyable', {
    name => 'proxyable',
    help => 'Integrate with Venus::Role::Proxyable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # reflectable
  $self->option('reflectable', {
    name => 'reflectable',
    help => 'Integrate with Venus::Role::Reflectable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # rejectable
  $self->option('rejectable', {
    name => 'rejectable',
    help => 'Integrate with Venus::Role::Rejectable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # resultable
  $self->option('resultable', {
    name => 'resultable',
    help => 'Integrate with Venus::Role::Resultable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # serializable
  $self->option('serializable', {
    name => 'serializable',
    help => 'Integrate with Venus::Role::Serializable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # stashable
  $self->option('stashable', {
    name => 'stashable',
    help => 'Integrate with Venus::Role::Stashable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # subscribable
  $self->option('subscribable', {
    name => 'subscribable',
    help => 'Integrate with Venus::Role::Subscribable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # superable
  $self->option('superable', {
    name => 'superable',
    help => 'Integrate with Venus::Role::Superable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # testable
  $self->option('testable', {
    name => 'testable',
    help => 'Integrate with Venus::Role::Testable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # throwable
  $self->option('throwable', {
    name => 'throwable',
    help => 'Integrate with Venus::Role::Throwable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # tryable
  $self->option('tryable', {
    name => 'tryable',
    help => 'Integrate with Venus::Role::Tryable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # unacceptable
  $self->option('unacceptable', {
    name => 'unacceptable',
    help => 'Integrate with Venus::Role::Unacceptable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # unpackable
  $self->option('unpackable', {
    name => 'unpackable',
    help => 'Integrate with Venus::Role::Unpackable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # valuable
  $self->option('valuable', {
    name => 'valuable',
    help => 'Integrate with Venus::Role::Valuable.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-args
  $self->option('event-args', {
    name => 'event-args',
    help => 'Declare a package "args" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-attr
  $self->option('event-attr', {
    name => 'event-attr',
    help => 'Declare a package "attr" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-audit
  $self->option('event-audit', {
    name => 'event-audit',
    help => 'Declare a package "audit" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-base
  $self->option('event-base', {
    name => 'event-base',
    help => 'Declare a package "base" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-bless
  $self->option('event-bless', {
    name => 'event-bless',
    help => 'Declare a package "bless" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-build
  $self->option('event-build', {
    name => 'event-build',
    help => 'Declare a package "build" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-buildargs
  $self->option('event-buildargs', {
    name => 'event-buildargs',
    help => 'Declare a package "buildargs" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-clone
  $self->option('event-clone', {
    name => 'event-clone',
    help => 'Declare a package "clone" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-construct
  $self->option('event-construct', {
    name => 'event-construct',
    help => 'Declare a package "construct" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-data
  $self->option('event-data', {
    name => 'event-data',
    help => 'Declare a package "data" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-deconstruct
  $self->option('event-deconstruct', {
    name => 'event-deconstruct',
    help => 'Declare a package "deconstruct" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-destroy
  $self->option('event-destroy', {
    name => 'event-destroy',
    help => 'Declare a package "destroy" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-does
  $self->option('event-does', {
    name => 'event-does',
    help => 'Declare a package "does" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-export
  $self->option('event-export', {
    name => 'event-export',
    help => 'Declare a package "export" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-from
  $self->option('event-from', {
    name => 'event-from',
    help => 'Declare a package "from" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-get
  $self->option('event-get', {
    name => 'event-get',
    help => 'Declare a package "get" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-import
  $self->option('event-import', {
    name => 'event-import',
    help => 'Declare a package "import" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-item
  $self->option('event-item', {
    name => 'event-item',
    help => 'Declare a package "item" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-mask
  $self->option('event-mask', {
    name => 'event-mask',
    help => 'Declare a package "mask" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-meta
  $self->option('event-meta', {
    name => 'event-meta',
    help => 'Declare a package "meta" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-metacache
  $self->option('event-metacache', {
    name => 'event-metacache',
    help => 'Declare a package "metacache" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-mixin
  $self->option('event-mixin', {
    name => 'event-mixin',
    help => 'Declare a package "mixin" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-name
  $self->option('event-name', {
    name => 'event-name',
    help => 'Declare a package "name" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-role
  $self->option('event-role', {
    name => 'event-role',
    help => 'Declare a package "role" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-set
  $self->option('event-set', {
    name => 'event-set',
    help => 'Declare a package "set" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-store
  $self->option('event-store', {
    name => 'event-store',
    help => 'Declare a package "store" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-subs
  $self->option('event-subs', {
    name => 'event-subs',
    help => 'Declare a package "subs" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-test
  $self->option('event-test', {
    name => 'event-test',
    help => 'Declare a package "test" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-unimport
  $self->option('event-unimport', {
    name => 'event-unimport',
    help => 'Declare a package "unimport" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # event-use
  $self->option('event-use', {
    name => 'event-use',
    help => 'Declare a package "use" lifecycle event.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  # authority
  $self->option('authority', {
    name => 'authority',
    help => 'The authority of the package.',
    multiples => 0,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # version
  $self->option('version', {
    name => 'version',
    help => 'The version of the package.',
    multiples => 0,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  return $self;
}

sub render_test {
  my ($self) = @_;

  my $data = $self->input_options;

  return (
    $self->render_test_head,
    $self->render_test_name,
    $self->render_test_tagline,
    $self->render_test_abstract,
    $self->render_test_includes,
    $self->render_test_synopsis,
    $self->render_test_description,
    $self->render_test_inherits,
    $self->render_test_integrates,
    $self->render_test_attributes,
    $self->render_test_functions,
    $self->render_test_methods,
    $self->render_test_routines,
    $self->render_test_errors,
    $self->render_test_tail,
    "ok 1 and done_testing;",
  );
}

sub render_test_abstract {
  my ($self) = @_;

  my $data = $self->input_options;

  my $abstract = $data->{abstract};

  return () if !$abstract;

  my $text = <<"EOF";
=abstract

${abstract}

=cut

\$test->for('abstract');
EOF

  return ($text);
}

sub render_test_attribute {
  my ($self, $data) = @_;

  my $text = <<"EOF";
=attribute ${data}

The ${data} attribute ...

=signature ${data}

  ${data}(any \@data) (any)

=metadata ${data}

{
  since => '0.00',
}

=example-1 ${data}

  # given: synopsis

  package main;

  my \$${data} = \$self->${data};

  # ()

=cut

\$test->for('example', 1, '${data}', sub {
  my (\$tryable) = \@_;
  my \$result = \$tryable->result;
  ok \$result;

  \$result
});
EOF

  return ($text);
}

sub render_test_attributes {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{attributes}
    ? (
      map $self->render_test_attribute($_),
        @{$data->{attributes}}
    )
    : ();
}

sub render_test_build_assert {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub assert_${data} {
  my (\$self, \$data) = \@_;

  return 'any';
}
EOF

  chomp $text;

  return ($text);
}

sub render_test_build_assert_self {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub self_assert_${data} {
  my (\$self, \$data) = \@_;

  die 'Bad ${data}' if \$data;
}
EOF

  chomp $text;

  return ($text);
}

sub render_test_description {
  my ($self) = @_;

  my $data = $self->input_options;

  my $description = $data->{description};

  return () if !$description;

  my $text = <<"EOF";
=description

${description}

=cut

\$test->for('description');
EOF

  return ($text);
}

sub render_test_error {
  my ($self, $data) = @_;

  my $text = <<"EOF";
=error error_on_${data}

This package may raise an C<on.${data}> error, as an instance of
C<Example::Error>, via the C<error_on_${data}> method.

=cut

\$test->for('error', 'error_on_${data}');

=example-1 error_on_${data}

  # given: synopsis;

  my \$error = \$self->error_on_${data}({});

  # ...

  # my \$name = \$error->name;

  # "on.${data}"

  # my \$render = \$error->render;

  # "Exception!"

=cut

\$test->for('example', 1, 'error_on_${data}', sub {
  my (\$tryable) = \@_;
  my \$result = \$tryable->result;
  isa_ok \$result, 'Venus::Error';
  my \$name = \$result->name;
  is \$name, "on.${data}";
  my \$render = \$result->render;
  is \$render, "...";

  \$result
});
EOF

  chomp $text;

  return ($text);
}

sub render_test_errors {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{errors}
    ? ((map $self->render_test_error($_), @{$data->{errors}}), "")
    : ();
}

sub render_test_function {
  my ($self, $data) = @_;

  my $text = <<"EOF";
=function ${data}

The ${data} function ...

=signature ${data}

  ${data}(any \@data) (any)

=metadata ${data}

{
  since => '0.00',
}

=example-1 ${data}

  # given: synopsis

  package main;

  my \$${data} = ${data}\(\);

  # ()

=cut

\$test->for('example', 1, '${data}', sub {
  my (\$tryable) = \@_;
  my \$result = \$tryable->result;
  ok \$result;

  \$result
});
EOF

  return ($text);
}

sub render_test_functions {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{functions}
    ? (map $self->render_test_function($_), @{$data->{functions}})
    : ();
}

sub render_test_head {
  my ($self) = @_;

  my $data = $self->input_options;

  my $text = <<"EOF";
package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my \$test = test(__FILE__);
EOF

  return ($text);
}

sub render_test_includes {
  my ($self) = @_;

  my $data = $self->input_options;

  my @text;

  push @text, $data->{functions}
    ? (
      map "function: $_",
        @{$data->{functions}}
    )
    : ();

  push @text, $data->{methods}
    ? (
      map "method: $_",
        @{$data->{methods}}
    )
    : ();

  push @text, $data->{routines}
    ? (
      map "routine: $_",
        @{$data->{routines}}
    )
    : ();

  @text = @text ? ("=includes", "", @text, "", "=cut", "", "\$test->for('includes');", "") : ();

  return (@text);
}

sub render_test_inherit {
  my ($self, $data) = @_;

  return ("${data}");
}

sub render_test_inherits {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{inherits}
    ? (
    "=inherits", "", (map $self->render_test_inherit($_), @{$data->{inherits}}),
    "", "=cut", "", "\$test->for('inherits');", ""
    )
    : ();
}

sub render_test_integrate {
  my ($self, $data) = @_;

  return ("${data}");
}

sub render_test_integrates {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{integrates}
    ? (
    "=integrates", "",
    (map $self->render_test_integrate($_), sort @{$data->{integrates}}),
    "", "=cut", "", "\$test->for('integrates');", ""
    )
    : ();
}

sub render_test_method {
  my ($self, $data) = @_;

  my $text = <<"EOF";
=method ${data}

The ${data} method ...

=signature ${data}

  ${data}(any \@data) (any)

=metadata ${data}

{
  since => '0.00',
}

=example-1 ${data}

  # given: synopsis

  package main;

  my \$${data} = \$self->${data};

  # ()

=cut

\$test->for('example', 1, '${data}', sub {
  my (\$tryable) = \@_;
  my \$result = \$tryable->result;
  ok \$result;

  \$result
});
EOF

  return ($text);
}

sub render_test_methods {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{methods}
    ? (map $self->render_test_method($_), @{$data->{methods}})
    : ();
}

sub render_test_name {
  my ($self) = @_;

  my $data = $self->input_options;

  my $name = $data->{name};

  my $text = <<"EOF";
=name

${name}

=cut

\$test->for('name');
EOF

  return ($text);
}

sub render_test_require {
  my ($self, $data) = @_;

  return ("require ${data};");
}

sub render_test_requires {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{requires}
    ? ("# REQUIRES", "", (map $self->render_test_require($_),
      @{$data->{requires}}), "")
    : ();
}

sub render_test_routine {
  my ($self, $data) = @_;

  my $name = $self->input_options->{name};

  my $text = <<"EOF";
=routine ${data}

The ${data} routine ...

=signature ${data}

  ${data}(any \@data) (any)

=metadata ${data}

{
  since => '0.00',
}

=example-1 ${data}

  package main;

  my \$${data} = ${name}->${data};

  # ()

=cut

\$test->for('example', 1, '${data}', sub {
  my (\$tryable) = \@_;
  my \$result = \$tryable->result;
  ok \$result;

  \$result
});
EOF

  return ($text);
}

sub render_test_routines {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{routines}
    ? (map $self->render_test_routine($_), @{$data->{routines}})
    : ();
}

sub render_test_synopsis {
  my ($self) = @_;

  my $data = $self->input_options;

  my $name = $data->{name};

  my $text = <<"EOF";
=synopsis

  package main;

  use ${name};

  my \$self = ${name}->new;

  # ()

=cut

\$test->for('synopsis', sub {
  my (\$tryable) = \@_;
  my \$result = \$tryable->result;
  ok \$result;

  \$result
});
EOF

  return ($text);
}

sub render_test_tagline {
  my ($self) = @_;

  my $data = $self->input_options;

  my $tagline = $data->{tagline};

  return () if !$tagline;

  my $text = <<"EOF";
=tagline

${tagline}

=cut

\$test->for('tagline');
EOF

  return ($text);
}

sub render_test_tail {
  my ($self) = @_;

  my $data = $self->input_options;

  my $space = Venus::Space->new($data->{name});

  my $pfile = $space->format('pfile', 'lib/%s');

  my $text = <<"EOF";
\$test->render('$pfile') if \$ENV{VENUS_RENDER};
EOF

  return ($text);
}

sub render_unit {
  my ($self) = @_;

  return (
    $self->render_unit_name,
    $self->render_unit_version,
    $self->render_unit_authority,
    $self->render_unit_type,
    $self->render_unit_imports,
    $self->render_unit_ours,
    $self->render_unit_states,
    $self->render_unit_attributes,
    $self->render_unit_inherits,
    $self->render_unit_integrates,
    $self->render_unit_requires,
    $self->render_unit_builders,
    $self->render_unit_hooks,
    $self->render_unit_functions,
    $self->render_unit_methods,
    $self->render_unit_routines,
    $self->render_unit_errors,
    $self->render_unit_events,
    "1;",
  );
}

sub render_unit_attribute {
  my ($self, $data) = @_;

  return ("attr '$data';");
}

sub render_unit_attributes {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{attributes}
    ? ("# ATTRIBUTES", "", (map $self->render_unit_attribute($_),
        @{$data->{attributes}}), "")
    : ();
}

sub render_unit_authority {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{authority}
    ? ( "# AUTHORITY", "", (
        sprintf("our \$AUTHORITY = '%s';", uc $data->{authority} || 'me')
      ), "")
    : ();
}

sub render_unit_build_arg {
  my ($self) = @_;

  my $data = $self->input_options;

  my $text = <<"EOF";
sub build_arg {
  my (\$self, \$data) = \@_;

  return {};
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_args {
  my ($self) = @_;

  my $data = $self->input_options;

  my $text = <<"EOF";
sub build_args {
  my (\$self, \$data) = \@_;

  return \$data;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_assert {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub assert_${data} {
  my (\$self, \$data) = \@_;

  return 'any';
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_assert_self {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub self_assert_${data} {
  my (\$self, \$data) = \@_;

  die 'Bad ${data}' if !\$data;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_attribute {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub build_${data} {
  my (\$self, \$data) = \@_;

  return \$data;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_attribute_lazy {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub lazy_build_${data} {
  my (\$self, \$data) = \@_;

  return \$data;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_check {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub check_${data} {
  my (\$self, \$data) = \@_;

  return \$data ? true : false;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_coerce {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub coerce_${data} {
  my (\$self, \$data) = \@_;

  return 'Venus::Box';
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_coerce_self {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub self_coerce_${data} {
  my (\$self, \$data) = \@_;

  require Venus::Box;

  return Venus::Box->new(\$data);
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_default {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub default_${data} {
  my (\$self, \$data) = \@_;

  return \$data;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_initial {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub initial_${data} {
  my (\$self, \$data) = \@_;

  return \$data;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_nil {
  my ($self) = @_;

  my $data = $self->input_options;

  my $text = <<"EOF";
sub build_nil {
  my (\$self, \$data) = \@_;

  return {};
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_read {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub read_${data} {
  my (\$self, \$data) = \@_;

  return \$data;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_readonly {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub readonly_${data} {
  my (\$self, \$data) = \@_;

  return true;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_readwrite {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub readwrite_${data} {
  my (\$self, \$data) = \@_;

  return true;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_require {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub require_${data} {
  my (\$self, \$data) = \@_;

  return true;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_self {
  my ($self) = @_;

  my $data = $self->input_options;

  my $text = <<"EOF";
sub build_self {
  my (\$self, \$data) = \@_;

  return \$self;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_trigger {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub trigger_${data} {
  my (\$self, \$data) = \@_;

  return \$data;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_build_write {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub write_${data} {
  my (\$self, \$data) = \@_;

  return \$data;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_builders {
  my ($self) = @_;

  my $data = $self->input_options;

  my @text;

  push @text,
    $data->{"build-arg"}
    ? $self->render_unit_build_arg
    : ();

  push @text,
    $data->{"build-args"}
    ? $self->render_unit_build_args
    : ();

  push @text,
    $data->{"build-nil"}
    ? $self->render_unit_build_nil
    : ();

  push @text,
    $data->{"build-self"}
    ? $self->render_unit_build_self
    : ();

  push @text,
    $data->{"build-asserts"}
    ? (join "\n\n", map $self->render_unit_build_assert($_),
        @{$data->{"build-asserts"}})
    : ();

  push @text,
    $data->{"build-checks"}
    ? (join "\n\n", map $self->render_unit_build_check($_),
        @{$data->{"build-checks"}})
    : ();

  push @text,
    $data->{"build-coerces"}
    ? (join "\n\n", map $self->render_unit_build_coerce($_),
        @{$data->{"build-coerces"}})
    : ();

  push @text,
    $data->{"build-attributes"}
    ? (join "\n\n", map $self->render_unit_build_attribute($_),
        @{$data->{"build-attributes"}})
    : ();

  push @text,
    $data->{"build-defaults"}
    ? (join "\n\n", map $self->render_unit_build_default($_),
        @{$data->{"build-defaults"}})
    : ();

  push @text,
    $data->{"build-initials"}
    ? (join "\n\n", map $self->render_unit_build_initial($_),
        @{$data->{"build-initials"}})
    : ();

  push @text,
    $data->{"build-attribute-lazys"}
    ? (join "\n\n", map $self->render_unit_build_attribute_lazy($_),
        @{$data->{"build-attribute-lazys"}})
    : ();

  push @text,
    $data->{"build-assert-selfs"}
    ? (join "\n\n", map $self->render_unit_build_assert_self($_),
        @{$data->{"build-assert-selfs"}})
    : ();

  push @text,
    $data->{"build-coerce-selfs"}
    ? (join "\n\n", map $self->render_unit_build_coerce_self($_),
        @{$data->{"build-coerce-selfs"}})
    : ();

  push @text,
    $data->{"build-reads"}
    ? (join "\n\n", map $self->render_unit_build_read($_),
        @{$data->{"build-reads"}})
    : ();

  push @text,
    $data->{"build-writes"}
    ? (join "\n\n", map $self->render_unit_build_write($_),
        @{$data->{"build-writes"}})
    : ();

  push @text,
    $data->{"build-readonlys"}
    ? (join "\n\n", map $self->render_unit_build_readonly($_),
        @{$data->{"build-readonlys"}})
    : ();

  push @text,
    $data->{"build-readwrites"}
    ? (join "\n\n", map $self->render_unit_build_readwrite($_),
        @{$data->{"build-readwrites"}})
    : ();

  push @text,
    $data->{"build-requires"}
    ? (join "\n\n", map $self->render_unit_build_require($_),
        @{$data->{"build-requires"}})
    : ();

  push @text,
    $data->{"build-triggers"}
    ? (join "\n\n", map $self->render_unit_build_trigger($_),
        @{$data->{"build-triggers"}})
    : ();

  @text = ("# BUILDERS", "", join("\n\n", @text), "") if @text;

  return (@text);
}

sub render_unit_error {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub error_on_${data} {
  my (\$self, \$data) = \@_;

  my \$error = \$self->error;

  my \$message = '...';

  \$error->name('on.${data}');
  \$error->message(\$message);
  \$error->offset(1);
  \$error->stash(\$data);
  \$error->reset;

  return \$error;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_errors {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{errors}
    ? ("# ERRORS", "", (join "\n\n", map $self->render_unit_error($_),
        @{$data->{errors}}), "")
    : ();
}

sub render_unit_event {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub ${data} {
  my (\$self, \@args) = \@_;

  # return \$self->SUPER::${data}(\@args);
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_events {
  my ($self) = @_;

  my $data = $self->input_options;

  my @events = (sort map /^event-(.*)/, grep /^event-/, keys %{$data});

  return @events
    ? ("# EVENTS", "", (join "\n\n", map $self->render_unit_event(uc $_), @events), "")
    : ();
}

sub render_unit_function {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub ${data} {
  my (\@args) = \@_;

  return (\@args);
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_functions {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{functions}
    ? ("# FUNCTIONS", "", (join "\n\n", map $self->render_unit_function($_),
        @{$data->{functions}}), "")
    : ();
}

sub render_unit_hook {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub ${data} {

  return;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_hooks {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{hooks}
    ? ( "# HOOKS", "", (join "\n\n", map $self->render_unit_hook($_),
        @{$data->{hooks}}), "")
    : ();
}

sub render_unit_import {
  my ($self, $data) = @_;

  return ("use ${data};");
}

sub render_unit_imports {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{imports}
    ? ("# IMPORTS", "", (map $self->render_unit_import($_),
        @{$data->{imports}}), "")
    : ();
}

sub render_unit_inherit {
  my ($self, $data) = @_;

  return ("base '${data}';");
}

sub render_unit_inherits {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{inherits}
    ? ( "# INHERITS", "", (map $self->render_unit_inherit($_),
        @{$data->{inherits}}), "")
    : ();
}

sub render_unit_integrate {
  my ($self, $data) = @_;

  return ("with '${data}';");
}

sub render_unit_integrates {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{integrates}
    ? ( "# INTEGRATES", "", (map $self->render_unit_integrate($_),
        sort @{$data->{integrates}}), "")
    : ();
}

sub render_unit_method {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub ${data} {
  my (\$self, \@args) = \@_;

  return \$self;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_methods {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{methods}
    ? ( "# METHODS", "", (join "\n\n", map $self->render_unit_method($_),
        @{$data->{methods}}), "")
    : ();
}

sub render_unit_name {
  my ($self) = @_;

  my $data = $self->input_options;

  my $name = $data->{name};

  my $text = <<"EOF";
package ${name};

use 5.018;

use strict;
use warnings;
EOF

  return ($text);
}

sub render_unit_our {
  my ($self, $data) = @_;

  return ("our \$${data};");
}

sub render_unit_ours {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{ours}
    ? ("# VARIABLES", "", (map $self->render_unit_our($_),
        @{$data->{ours}}), "")
    : ();
}

sub render_unit_require {
  my ($self, $data) = @_;

  return ("require ${data};");
}

sub render_unit_requires {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{requires}
    ? ( "# REQUIRES", "", (map $self->render_unit_require($_),
        @{$data->{requires}}), "")
    : ();
}

sub render_unit_routine {
  my ($self, $data) = @_;

  my $text = <<"EOF";
sub ${data} {
  my (\$self, \@args) = \@_;

  return \$self;
}
EOF

  chomp $text;

  return ($text);
}

sub render_unit_routines {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{routines}
    ? ( "# ROUTINES", "", (join "\n\n", map $self->render_unit_routine($_),
        @{$data->{routines}}), "")
    : ();
}

sub render_unit_state {
  my ($self, $data) = @_;

  return ("state \$${data};");
}

sub render_unit_states {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{states}
    ? ("# STATE", "", (map $self->render_unit_state($_),
        @{$data->{states}}), "")
    : ();
}

sub render_unit_type {
  my ($self) = @_;

  my $data = $self->input_options;

  my @text;
  my @with;

  if ($data->{attributes} && @{$data->{attributes}}) {
    push @with, 'attr';
  }

  if ($data->{inherits} && @{$data->{inherits}}) {
    push @with, 'base';
  }

  if (($data->{integrates} && @{$data->{integrates}}) || grep /^build-/,
    keys %{$data})
  {
    push @with, 'with';
  }

  if ($data->{class}) {
    push @text, ((join ' ', 'use Venus::Class',
      @with ? (join ', ', map "'$_'", @with) : ()) . ";");
  }
  elsif ($data->{mixin}) {
    push @text, ((join ' ', 'use Venus::Mixin',
      @with ? (join ', ', map "'$_'", @with) : ()) . ";");
  }
  elsif ($data->{role}) {
    push @text, ((join ' ', 'use Venus::Role',
      @with ? (join ', ', map "'$_'", @with) : ()) . ";");
  }
  else {
    push @text, ((join ' ', 'use Venus::Class',
      @with ? (join ', ', map "'$_'", @with) : ()) . ";");
  }

  return ("# VENUS", "", @text, "");
}

sub render_unit_version {
  my ($self) = @_;

  my $data = $self->input_options;

  return $data->{version}
    ? ( "# VERSION", "", (
        sprintf("our \$VERSION = '%s';", $data->{version} || 0.00)
      ), "")
    : ();
}

1;



=head1 NAME

Venus::Task::Venus::Gen - vns gen

=cut

=head1 ABSTRACT

Task Class for Venus CLI

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Task::Venus::Gen;

  my $task = Venus::Task::Venus::Gen->new;

  # bless(.., 'Venus::Task::Venus::Gen')

=cut

=head1 DESCRIPTION

This package is a task class for the C<vns-gen> CLI, and C<vns gen>
sub-command.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Task::Venus>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 new

  new(any @args) (Venus::Task::Venus::Gen)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Task::Venus::Gen;

  my $task = Venus::Task::Venus::Gen->new;

  # bless({...}, 'Venus::Task::Venus::Gen')

=back

=cut

=head2 perform

  perform() (Venus::Task::Venus::Gen)

The perform method executes the CLI logic.

I<Since C<4.15>>

=over 4

=item perform example 1

  # given: synopsis

  package main;

  $task->prepare;

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Gen')

=back

=over 4

=item perform example 2

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('--stdout', '--class');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Gen')

  # ...

=back

=over 4

=item perform example 3

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('--stdout', '--class', '--name', 'MyApp');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Gen')

  # ...

=back

=over 4

=item perform example 4

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('-pc', '--name', 'MyApp', '--method', 'execute');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Gen')

  # ...

=back

=over 4

=item perform example 5

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('-pc', '--name', 'MyApp', '--attr', 'domain', '--method', 'execute');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Gen')

  # ...

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