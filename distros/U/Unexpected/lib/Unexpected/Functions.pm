package Unexpected::Functions;

use strict;
use warnings;
use parent 'Exporter::Tiny';

use Carp         qw( croak );
use Package::Stash;
use Scalar::Util qw( blessed reftype );
use Sub::Install qw( install_sub );

our @EXPORT_OK = qw( catch_class exception has_exception
                     inflate_message inflate_placeholders is_class_loaded
                     is_one_of_us parse_arg_list throw throw_on_error );

my $Exception_Class = 'Unexpected'; my $Should_Quote = 1;

# Private functions
my $_catch = sub {
   my $block = shift; return ((bless \$block, 'Try::Tiny::Catch'), @_);
};

my $_clone_one_of_us = sub {
   return $_[ 1 ] ? { %{ $_[ 0 ] }, %{ $_[ 1 ] } } : { error => $_[ 0 ] };
};

my $_dereference_code = sub {
   my ($code, @args) = @_;

   $args[ 0 ] and ref $args[ 0 ] eq 'ARRAY' and unshift @args, 'args';

   return { class => $code->(), @args };
};

my $_exception_class_cache = {};

my $_exception_class = sub {
   my $caller = shift;

   exists $_exception_class_cache->{ $caller }
      and defined $_exception_class_cache->{ $caller }
      and return  $_exception_class_cache->{ $caller };

   my $code  = $caller->can( 'EXCEPTION_CLASS' );
   my $class = $code ? $code->() : $Exception_Class;

   return $_exception_class_cache->{ $caller } = $class;
};

my $_match_class = sub {
   my ($e, $ref, $blessed, $does, $key) = @_;

   return !defined $key                        ? !defined $e
        : $key eq '*'                          ? 1
        : $key eq ':str'                       ? !$ref
        : $key eq $ref                         ? 1
        : $blessed && $e->can( 'instance_of' ) ? $e->instance_of( $key )
        : $blessed && $e->$does( $key )        ? 1
                                               : 0;
};

my $_quote_maybe = sub {
   return $Should_Quote ? "'".$_[ 0 ]."'" : $_[ 0 ];
};

my $_gen_checker = sub {
   my @prototable = @_;

   return sub {
      my $e       = shift;
      my $ref     = ref $e;
      my $blessed = blessed $e;
      my $does    = ($blessed && $e->can( 'DOES' )) || 'isa';
      my @table   = @prototable;

      while (my ($key, $value) = splice @table, 0, 2) {
         $_match_class->( $e, $ref, $blessed, $does, $key ) and return $value
      }

      return;
   }
};

# Package methods
sub import {
   my $class       = shift;
   my $global_opts = { $_[ 0 ] && ref $_[ 0 ] eq 'HASH' ? %{+ shift } : () };
   my $ex_class    = delete $global_opts->{exception_class};
   # uncoverable condition false
   my $target      = $global_opts->{into} //= caller;
   my @want        = @_;
   my @args        = ();

   $ex_class or $ex_class = $_exception_class->( $target );

   for my $sym (@want) {
      if ($ex_class->can( 'is_exception' ) and $ex_class->is_exception( $sym )){
         my $code = sub { sub { $sym } };

         install_sub { as => $sym, code => $code, into => $target, };
      }
      else { push @args, $sym }
   }

   $class->SUPER::import( $global_opts, @args );
   return;
}

sub quote_bind_values { # Deprecated. Use third arg in inflate_placeholders defs
   defined $_[ 1 ] and $Should_Quote = !!$_[ 1 ]; return $Should_Quote;
}

# Public functions
sub parse_arg_list (;@) { # Coerce a hash ref from whatever was passed
   my $n = 0; $n++ while (defined $_[ $n ]);

   return (                $n == 0) ? {}
        : (is_one_of_us( $_[ 0 ] )) ? $_clone_one_of_us->( @_ )
        : ( ref $_[ 0 ] eq  'CODE') ? $_dereference_code->( @_ )
        : ( ref $_[ 0 ] eq  'HASH') ? { %{ $_[ 0 ] } }
        : (                $n == 1) ? { error => $_[ 0 ] }
        : ( ref $_[ 1 ] eq 'ARRAY') ? { error => (shift), args => @_ }
        : ( ref $_[ 1 ] eq  'HASH') ? { error => $_[ 0 ], %{ $_[ 1 ] } }
        : (            $n % 2 == 1) ? { error => @_ }
                                    : { @_ };
}

sub catch_class ($@) {
   my $check = $_gen_checker->( @{+ shift }, '*' => sub { die $_[ 0 ] } );

   wantarray or croak 'Useless bare catch_class()';

   return $_catch->( sub { ($check->( $_[ 0 ] ) || return)->( $_[ 0 ] ) }, @_ );
}

sub exception (;@) {
   return $_exception_class->( caller )->caught( @_ );
}

sub has_exception ($;@) {
   my ($name, %args) = @_; my $exception_class = caller;

   return $exception_class->add_exception( $name, \%args );
}

sub inflate_message ($;@) { # Expand positional parameters of the form [_<n>]
   return inflate_placeholders( [ '[?]', '[]' ], @_ );
}

sub inflate_placeholders ($;@) { # Sub visible strings for null and undef
   my $defaults = shift;
   my $msg      = shift;
   my @vals     = map { $defaults->[ 2 ] ? $_ : $_quote_maybe->( $_ ) }
                  # uncoverable condition false
                  map { (length) ? $_ :  $defaults->[ 1 ] }
                  map {            $_ // $defaults->[ 0 ] } @_,
                  map {                  $defaults->[ 0 ] } 0 .. 9;

   $msg =~ s{ \[ _ (\d+) \] }{$vals[ $1 - 1 ]}gmx;
   return $msg;
}

sub is_class_loaded ($) { # Lifted from Class::Load
   my $class = shift; my $stash = Package::Stash->new( $class );

   if ($stash->has_symbol( '$VERSION' )) {
      my $version = ${ $stash->get_symbol( '$VERSION' ) };

      if (defined $version) {
         not ref $version and return 1;
         # Sometimes $VERSION ends up as a reference to undef (weird)
         reftype $version eq 'SCALAR' and defined ${ $version } and return 1;
         blessed $version and return 1; # A version object
      }
   }

   $stash->has_symbol( '@ISA' ) and @{ $stash->get_symbol( '@ISA' ) }
      and return 1;
   # Check for any method
   return $stash->list_all_symbols( 'CODE' ) ? 1 : 0;
}

sub is_one_of_us ($) {
   return $_[ 0 ] && (blessed $_[ 0 ]) && $_[ 0 ]->isa( $Exception_Class );
}

sub throw (;@) {
   $_exception_class->( caller )->throw( @_ );
}

sub throw_on_error (;@) {
   return $_exception_class->( caller )->throw_on_error( @_ );
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Unexpected::Functions - A collection of functions used in this distribution

=head1 Synopsis

   package YourApp::Exception;

   use Moo;

   extends 'Unexpected';
   with    'Unexpected::TraitFor::ExceptionClasses';

   package YourApp;

   use Unexpected::Functions 'Unspecified';

   sub EXCEPTION_CLASS { 'YourApp::Exception' }

   sub throw { EXCEPTION_CLASS->throw( @_ ) }

   throw Unspecified, args => [ 'parameter name' ];

=head1 Description

A collection of functions used in this distribution

Also exports any exceptions defined by the caller's C<EXCEPTION_CLASS> as
subroutines that return a subroutine that returns the subroutines name as a
string. The calling package can then throw exceptions with a class attribute
that takes these subroutines return values

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 catch_class

   use Try::Tiny;

   try         { die $exception_object }
   catch_class [ 'exception_class' => sub { # handle exception }, ... ],
   finally     { # always do this };

See L<Try::Tiny::ByClass>. Checks the exception object's C<class> attribute
against the list of exception class names passed to C<catch_class>. If there
is a match, call the subroutine provided to handle that exception. Re-throws
the exception if there is no match or if the exception object has no C<class>
attribute

=head2 exception

   $exception_object_ref = exception $optional_error;

A function which calls the L<caught|Unexpected::TraitFor::Throwing/caught>
class method

=head2 has_exception

   has_exception 'exception_name' => parents => [ 'parent_exception' ],
      error => 'Error message for the exception with placeholders';

A function which calls L<Unexpected::TraitFor::ExceptionClasses/add_exception>
via the calling class which is assumed to inherit from a class that consumes
the L<Unexpected::TraitFor::ExceptionClasses> role

=head2 inflate_message

   $message = inflate_message $template, $val1, $val2, ...;

Substitute the placeholders in the C<$template> string, e.g. C<[_1]>,
with the corresponding value. Undefined values are represented as C<[?]>,
zero length strings are represented as C<[]>. Placeholder values will be
quoted when substituted

=head2 inflate_placeholders

   $message = inflate_placeholders $defaults, $template, $val1, $val2, ...;

Substitute the placeholders in the C<$template> string, e.g. C<[_1]>, with the
corresponding value. The C<$defaults> argument is a tuple (array reference)
containing the default substitution values for; an undefined value, a zero
length value, and a boolean which if true prevents quoting of the placeholder
values when they are substituted into the template

=head2 is_class_loaded

   $bool = is_class_loaded $classname;

Returns true is the classname as already loaded and compiled

=head2 is_one_of_us

   $bool = is_one_of_us $string_or_exception_object_ref;

Function which detects instances of this exception class

=head2 parse_arg_list

   $hash_ref = parse_arg_list( <whatever> );

Coerces a hash reference from whatever arguments are passed. This function is
responsible for parsing the arguments passed to the constructor. Supports
the following signatures

   # No defined arguments - returns and empty hash reference
   Unexpected->new();

   # First argument is one if our own objects - clone it
   Unexpected->new( $unexpected_object_ref );

   # First argument is one if our own objects, second is a hash reference
   # - clone the object but mutate it using the hash reference
   Unexpected->new( $unexpected_object_ref, { key => 'value', ... } );

   # First argument is a code reference - the code reference returns the
   # exception class and the remaining arguments are treated as a list of
   # keys and values
   Unexpected->new( Unspecified, args => [ 'parameter name' ] );
   Unexpected->new( Unspecified, [ 'parameter name' ] ); # Shortcut

   # First argmentt is a hash reference - clone it
   Unexpected->new( { key => 'value', ... } );

   # Only one scalar argement - the error string
   Unexpected->new( $error_string );

   # Second argement is a hash reference, first argument is the error
   Unexpected->new( $error_string, { key => 'value', ... } );

   # Odd numbered list of arguments is the error followed by keys and values
   Unexpected->new( $error_string, key => 'value', ... );
   Unexecpted->new( 'File [_1] not found', args => [ $filename ] );
   Unexecpted->new( 'File [_1] not found', [ $filename ] ); # Shortcut

   # Arguments are a list of keys and values
   Unexpected->new( key => 'value', ... );

=head2 quote_bind_values

   $bool = Unexpected::Functions->quote_bind_values( $bool );

Deprecated. Use third argument in L</inflate_placeholders> defaults
defaults. Accessor / mutator class method that toggles the state on quoting the
placeholder substitution values in C<inflate_message>. Defaults to true

=head2 throw

   throw 'Path [_1] not found', args => [ 'pathname' ];

A function which calls the L<throw|Unexpected::TraitFor::Throwing/throw> class
method

=head2 throw_on_error

   throw_on_error @optional_args;

A function which calls the
L<throw_on_error|Unexpected::TraitFor::Throwing/throw_on_error> class method

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Exporter::Tiny>

=item L<Package::Stash>

=item L<Sub::Install>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
