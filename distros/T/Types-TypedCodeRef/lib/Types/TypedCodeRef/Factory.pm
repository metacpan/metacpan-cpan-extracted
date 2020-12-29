package Types::TypedCodeRef::Factory;
use 5.010001;
use strict;
use warnings;
use utf8;
use Moo;
use overload ();
use Carp ();
use Type::Tiny ();
use Type::Coercion;
use Type::Params qw( compile compile_named multisig );
use Types::Standard -types;
use Scalar::Util;
use Sub::Meta;
use Sub::Meta::Param;
use Sub::Meta::Parameters;
use Sub::Meta::Returns;
use Sub::WrapInType qw( wrap_sub );
use Carp qw( croak );
use namespace::autoclean;

our @CARP_NOT;

sub _is_callable {
  my $callable = shift;
  my $reftype = Scalar::Util::reftype($callable);
  ( defined $reftype && $reftype eq 'CODE' ) || defined overload::Method($callable, '&{}');
}

my $CallableType = Type::Tiny->new(
  name       => 'Callable',
  constraint => \&_is_callable,
);

has name => (
  is      => 'ro',
  isa     => Str,
  default => 'TypedCodeRef',
);

has name_generator => (
  is      => 'ro',
  isa     => CodeRef,
  builder => '_build_name_generator',
);

has constraint_generator => (
  is      => 'ro',
  isa     => CodeRef,
  lazy    => 1,
  builder => '_build_constraint_generator',
);

has sub_meta_finders => (
  is       => 'ro',
  isa      => ArrayRef[CodeRef],
  required => 1,
);

has coercion_generator => (
  is       => 'ro',
  isa      => CodeRef,
  lazy     => 1,
  builder  => '_build_coercion_generator',
);

sub _build_name_generator {
  sub {
    my ($type_name, @type_parameters) = @_;
    $type_name . do {
      if (@type_parameters == 2) {
        my ($params_types, $return_types) = @type_parameters;

        my $params_types_name = do {
          if (ref $params_types eq 'ARRAY') {
            "[@{[ join(', ', @$params_types) ]}]"
          }
          elsif (ref $params_types eq 'HASH') {
            "{ @{[ join( ', ', map { qq{$_ => $params_types->{$_}} } sort keys %$params_types) ]} }"
          }
          else {
            $params_types
          }
        };

        my $return_types_name = ref $return_types eq 'ARRAY'
            ? "[@{[ join(', ', @$return_types) ]}]"
            : $return_types;

        "[ $params_types_name => $return_types_name ]";
      }
      elsif (@type_parameters == 1) {
        "[$type_parameters[0]]";
      }
      else {
        '[]';
      }
    };
  };
}

sub _build_constraint_generator {
  my $self = shift;

  sub {
    my $constraints_sub_meta = do {
      if ( @_ == 0 ) {
        create_unknown_sub_meta();
      }
      elsif ( @_ == 1 ) {
        state $validator = compile(InstanceOf['Sub::Meta']);
        my ($constraints_sub_meta) = $validator->(@_);
        $constraints_sub_meta;
      }
      elsif ( @_ == 2 ) {
        state $validator = do {
          my $TypeConstraint = HasMethods[qw( check get_message )];
          compile(
            $TypeConstraint | ArrayRef([$TypeConstraint]) | HashRef([$TypeConstraint]),
            $TypeConstraint | ArrayRef([$TypeConstraint])
          );
        };
        my ($params, $returns) = $validator->(@_);

        Sub::Meta->new(
          parameters => do {
            my @meta_params = do {
              if ( ref $params eq 'ARRAY' ) {
                map { Sub::Meta::Param->new($_) } @$params;
              }
              elsif ( ref $params eq 'HASH' ) {
                map {
                  Sub::Meta::Param->new({
                    name  => $_,
                    type  => $params->{$_},
                    named => 1,
                  });
                }
                sort keys %$params;
              }
              else {
                Sub::Meta::Param->new($params);
              }
            };
            Sub::Meta::Parameters->new(args => \@meta_params);
          },
          returns => Sub::Meta::Returns->new(
            scalar => $returns,
            list   => $returns,
            void   => $returns,
          ),
        );
      }
      else {
        Carp::croak 'Too many arguments.';
      }
    };

    sub {
        my $typed_code_ref = shift;
        my $maybe_sub_meta = $self->find_sub_meta($typed_code_ref);
        $constraints_sub_meta->is_same_interface($maybe_sub_meta // create_unknown_sub_meta());
    };
  };
}

sub find_sub_meta {
  my ($self, $typed_code_ref) = @_;
  for my $finder (@{ $self->sub_meta_finders }) {
    my $meta = $finder->($typed_code_ref);
    return $meta if defined $meta;
  }
  return;
}

sub create_unknown_sub_meta {
  Sub::Meta->new(
    parameters => Sub::Meta::Parameters->new(
      args   => [],
      slurpy => 1,
    ),
    returns => Sub::Meta::Returns->new(),
  );
}

sub _build_coercion_generator {
  my $self = shift;

  sub {
    my (undef, $type, @type_parameters) = @_;
    
    if (@type_parameters == 0) {
      local @CARP_NOT = (__PACKAGE__, 'Type::Tiny');
      croak 'No coercion for this type constraint';
    }

    my ($params_types, $return_types) = @type_parameters;
    Type::Coercion->new(
      display_name      => "to_${type}",
      type_constraint   => $type,
      type_coercion_map => [
        $CallableType => sub {
          my $coderef = shift;
          wrap_sub($params_types, $return_types, $coderef);
        },
      ],
    );
  };
}

sub create {
  my $self = shift;
  Type::Tiny->new(
    parent               => $CallableType,
    name                 => $self->name,
    name_generator       => $self->name_generator,
    constraint_generator => $self->constraint_generator,
    coercion_generator   => $self->coercion_generator,
  );
}

1;
