{

    package Type::Library::Compiler;
    use strict;
    use warnings;
    no warnings qw( once void );

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Type::Library::Compiler::Mite";
    our $MITE_VERSION = "0.013000";

    # Mite keywords
    BEGIN {
        my ( $SHIM, $CALLER ) =
          ( "Type::Library::Compiler::Mite", "Type::Library::Compiler" );
        (
            *after, *around, *before,        *extends, *field,
            *has,   *param,  *signature_for, *with
          )
          = do {

            package Type::Library::Compiler::Mite;
            no warnings 'redefine';
            (
                sub { $SHIM->HANDLE_after( $CALLER, "class", @_ ) },
                sub { $SHIM->HANDLE_around( $CALLER, "class", @_ ) },
                sub { $SHIM->HANDLE_before( $CALLER, "class", @_ ) },
                sub { },
                sub { $SHIM->HANDLE_has( $CALLER, field => @_ ) },
                sub { $SHIM->HANDLE_has( $CALLER, has   => @_ ) },
                sub { $SHIM->HANDLE_has( $CALLER, param => @_ ) },
                sub { $SHIM->HANDLE_signature_for( $CALLER, "class", @_ ) },
                sub { $SHIM->HANDLE_with( $CALLER, @_ ) },
            );
          };
    }

    # Mite imports
    BEGIN {
        require Scalar::Util;
        *STRICT  = \&Type::Library::Compiler::Mite::STRICT;
        *bare    = \&Type::Library::Compiler::Mite::bare;
        *blessed = \&Scalar::Util::blessed;
        *carp    = \&Type::Library::Compiler::Mite::carp;
        *confess = \&Type::Library::Compiler::Mite::confess;
        *croak   = \&Type::Library::Compiler::Mite::croak;
        *false   = \&Type::Library::Compiler::Mite::false;
        *guard   = \&Type::Library::Compiler::Mite::guard;
        *lazy    = \&Type::Library::Compiler::Mite::lazy;
        *lock    = \&Type::Library::Compiler::Mite::lock;
        *ro      = \&Type::Library::Compiler::Mite::ro;
        *rw      = \&Type::Library::Compiler::Mite::rw;
        *rwp     = \&Type::Library::Compiler::Mite::rwp;
        *true    = \&Type::Library::Compiler::Mite::true;
        *unlock  = \&Type::Library::Compiler::Mite::unlock;
    }

    # Gather metadata for constructor and destructor
    sub __META__ {
        no strict 'refs';
        my $class = shift;
        $class = ref($class) || $class;
        my $linear_isa = mro::get_linear_isa($class);
        return {
            BUILD => [
                map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
                map { "$_\::BUILD" } reverse @$linear_isa
            ],
            DEMOLISH => [
                map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
                map { "$_\::DEMOLISH" } @$linear_isa
            ],
            HAS_BUILDARGS        => $class->can('BUILDARGS'),
            HAS_FOREIGNBUILDARGS => $class->can('FOREIGNBUILDARGS'),
        };
    }

    # Standard Moose/Moo-style constructor
    sub new {
        my $class = ref( $_[0] ) ? ref(shift) : shift;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $self  = bless {}, $class;
        my $args =
            $meta->{HAS_BUILDARGS}
          ? $class->BUILDARGS(@_)
          : { ( @_ == 1 ) ? %{ $_[0] } : @_ };
        my $no_build = delete $args->{__no_BUILD__};

        # Attribute types (type: Map[NonEmptyStr,Object])
        # has declaration, file lib/Type/Library/Compiler.pm, line 17
        do {
            my $value =
              exists( $args->{"types"} )
              ? $args->{"types"}
              : $self->_build_types;
            do {

                package Type::Library::Compiler::Mite;
                ( ref($value) eq 'HASH' ) and do {
                    my $ok = 1;
                    for my $v ( values %{$value} ) {
                        ( $ok = 0, last )
                          unless (
                            do {

                                package Type::Library::Compiler::Mite;
                                use Scalar::Util ();
                                Scalar::Util::blessed($v);
                            }
                          );
                    };
                    for my $k ( keys %{$value} ) {
                        ( $ok = 0, last )
                          unless (
                            (
                                do {

                                    package Type::Library::Compiler::Mite;
                                    defined($k) and do {
                                        ref( \$k ) eq 'SCALAR'
                                          or ref( \( my $val = $k ) ) eq
                                          'SCALAR';
                                    }
                                }
                            )
                            && ( length($k) > 0 )
                          );
                    };
                    $ok;
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "types", "Map[NonEmptyStr,Object]";
            $self->{"types"} = $value;
        };

        # Attribute pod (type: Bool)
        # has declaration, file lib/Type/Library/Compiler.pm, line 19
        do {
            my $value = exists( $args->{"pod"} ) ? $args->{"pod"} : true;
            do {
                my $coerced_value = do {
                    my $to_coerce = $value;
                    (
                        (
                            !ref $to_coerce
                              and ( !defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and ( !defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "pod", "Bool";
                $self->{"pod"} = $coerced_value;
            };
        };

        # Attribute destination_module (type: NonEmptyStr)
        # has declaration, file lib/Type/Library/Compiler.pm, line 26
        croak "Missing key in constructor: destination_module"
          unless exists $args->{"destination_module"};
        (
            (
                do {

                    package Type::Library::Compiler::Mite;
                    defined( $args->{"destination_module"} ) and do {
                        ref( \$args->{"destination_module"} ) eq 'SCALAR'
                          or ref( \( my $val = $args->{"destination_module"} ) )
                          eq 'SCALAR';
                    }
                }
            )
              && do {

                package Type::Library::Compiler::Mite;
                length( $args->{"destination_module"} ) > 0;
            }
          )
          or croak "Type check failed in constructor: %s should be %s",
          "destination_module", "NonEmptyStr";
        $self->{"destination_module"} = $args->{"destination_module"};

        # Attribute constraint_module (type: NonEmptyStr)
        # has declaration, file lib/Type/Library/Compiler.pm, line 38
        do {
            my $value =
              exists( $args->{"constraint_module"} )
              ? $args->{"constraint_module"}
              : $self->_build_constraint_module;
            (
                (
                    do {

                        package Type::Library::Compiler::Mite;
                        defined($value) and do {
                            ref( \$value ) eq 'SCALAR'
                              or ref( \( my $val = $value ) ) eq 'SCALAR';
                        }
                    }
                )
                  && ( length($value) > 0 )
              )
              or croak "Type check failed in constructor: %s should be %s",
              "constraint_module", "NonEmptyStr";
            $self->{"constraint_module"} = $value;
        };

        # Attribute destination_filename (type: NonEmptyStr)
        # has declaration, file lib/Type/Library/Compiler.pm, line 47
        if ( exists $args->{"destination_filename"} ) {
            (
                (
                    do {

                        package Type::Library::Compiler::Mite;
                        defined( $args->{"destination_filename"} ) and do {
                            ref( \$args->{"destination_filename"} ) eq 'SCALAR'
                              or ref(
                                \( my $val = $args->{"destination_filename"} ) )
                              eq 'SCALAR';
                        }
                    }
                )
                  && do {

                    package Type::Library::Compiler::Mite;
                    length( $args->{"destination_filename"} ) > 0;
                }
              )
              or croak "Type check failed in constructor: %s should be %s",
              "destination_filename", "NonEmptyStr";
            $self->{"destination_filename"} = $args->{"destination_filename"};
        }

        # Call BUILD methods
        $self->BUILDALL($args) if ( !$no_build and @{ $meta->{BUILD} || [] } );

        # Unrecognized parameters
        my @unknown = grep not(
/\A(?:constraint_module|destination_(?:filename|module)|pod|types)\z/
        ), keys %{$args};
        @unknown
          and croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        return $self;
    }

    # Used by constructor to call BUILD methods
    sub BUILDALL {
        my $class = ref( $_[0] );
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        $_->(@_) for @{ $meta->{BUILD} || [] };
    }

    # Destructor should call DEMOLISH methods
    sub DESTROY {
        my $self  = shift;
        my $class = ref($self) || $self;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $in_global_destruction =
          defined ${^GLOBAL_PHASE}
          ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
          : Devel::GlobalDestruction::in_global_destruction();
        for my $demolisher ( @{ $meta->{DEMOLISH} || [] } ) {
            my $e = do {
                local ( $?, $@ );
                eval { $demolisher->( $self, $in_global_destruction ) };
                $@;
            };
            no warnings 'misc';    # avoid (in cleanup) warnings
            die $e if $e;          # rethrow
        }
        return;
    }

    my $__XS = !$ENV{PERL_ONLY}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for constraint_module
    # has declaration, file lib/Type/Library/Compiler.pm, line 38
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "constraint_module" => "constraint_module" },
        );
    }
    else {
        *constraint_module = sub {
            @_ == 1
              or croak(
                'Reader "constraint_module" usage: $self->constraint_module()');
            $_[0]{"constraint_module"};
        };
    }

    # Accessors for destination_filename
    # has declaration, file lib/Type/Library/Compiler.pm, line 47
    sub destination_filename {
        @_ == 1
          or croak(
            'Reader "destination_filename" usage: $self->destination_filename()'
          );
        (
            exists( $_[0]{"destination_filename"} )
            ? $_[0]{"destination_filename"}
            : (
                $_[0]{"destination_filename"} = do {
                    my $default_value = $_[0]->_build_destination_filename;
                    (
                        (
                            do {

                                package Type::Library::Compiler::Mite;
                                defined($default_value) and do {
                                    ref( \$default_value ) eq 'SCALAR'
                                      or ref( \( my $val = $default_value ) )
                                      eq 'SCALAR';
                                }
                            }
                        )
                          && ( length($default_value) > 0 )
                      )
                      or croak(
                        "Type check failed in default: %s should be %s",
                        "destination_filename",
                        "NonEmptyStr"
                      );
                    $default_value;
                }
            )
        );
    }

    # Accessors for destination_module
    # has declaration, file lib/Type/Library/Compiler.pm, line 26
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "destination_module" => "destination_module" },
        );
    }
    else {
        *destination_module = sub {
            @_ == 1
              or croak(
                'Reader "destination_module" usage: $self->destination_module()'
              );
            $_[0]{"destination_module"};
        };
    }

    # Accessors for pod
    # has declaration, file lib/Type/Library/Compiler.pm, line 19
    sub pod {
        @_ > 1
          ? do {
            my $value = do {
                my $to_coerce = $_[1];
                (
                    (
                        !ref $to_coerce
                          and ( !defined $to_coerce
                            or $to_coerce eq q()
                            or $to_coerce eq '0'
                            or $to_coerce eq '1' )
                    )
                  ) ? $to_coerce
                  : ( ( !!1 ) ) ? scalar( do { local $_ = $to_coerce; !!$_ } )
                  :               $to_coerce;
            };
            (
                !ref $value
                  and ( !defined $value
                    or $value eq q()
                    or $value eq '0'
                    or $value eq '1' )
              )
              or croak( "Type check failed in %s: value should be %s",
                "accessor", "Bool" );
            $_[0]{"pod"} = $value;
            $_[0];
          }
          : ( $_[0]{"pod"} );
    }

    # Accessors for types
    # has declaration, file lib/Type/Library/Compiler.pm, line 17
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "types" => "types" },
        );
    }
    else {
        *types = sub {
            @_ == 1 or croak('Reader "types" usage: $self->types()');
            $_[0]{"types"};
        };
    }

    # See UNIVERSAL
    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        if ( $INC{'Moose/Util.pm'}
            and my $meta = Moose::Util::find_meta( ref $self or $self ) )
        {
            $meta->can('does_role') and $meta->does_role($role) and return 1;
        }
        return $self->SUPER::DOES($role);
    }

    # Alias for Moose/Moo-compatibility
    sub does {
        shift->DOES(@_);
    }

    1;
}
