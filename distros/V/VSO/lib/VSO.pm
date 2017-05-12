
package VSO;

use strict;
use warnings 'all';
use Carp qw( confess  );
use Scalar::Util qw( weaken openhandle );
use Data::Dumper;
use base 'Exporter';
use VSO::Subtype;

our $VERSION = '0.025';

our @EXPORT = qw(
  has
  before
  after
  extends
  
  subtype as where message
  coerce from via
  enum
);

my $_meta       = { };
my $_coercions  = { };

sub import
{
  # Turn on strict and warnings in the caller:
  import warnings;
  $^H |= 1538;
  my $class = shift;
  my %args = @_;
  my $caller = caller;
  return if $caller eq __PACKAGE__;
  no strict 'refs';
  map {
    *{"$caller\::$_"} = \&{$_}
  } @EXPORT;
  push @{"$caller\::ISA"}, $class if $class eq __PACKAGE__;
  $args{extends} ||= [ ];
  $args{extends} = [$args{extends}] if $args{extends} && ! ref($args{extends});
  push @{"$caller\::ISA"}, grep { load_class($_); 1 } @{ $args{extends} };
  
  $_meta->{ $caller } ||= _new_meta();
  no warnings 'redefine';
  *{"$caller\::meta"} = sub { $_meta->{$caller} };
  
  _extend_class( $caller => @{$args{extends}} ) if @{$args{extends}};
}# end import()


sub new
{
  my ($class, %args) = @_;
  
  my $s = bless \%args, $class;
  $s->_build();
  $s->BUILD() if $s->can('BUILD');
  
  return $s;
}# end new()


sub _build
{
  my $s = shift;
  
  my $class = ref($s);
  my $meta = $class->meta();
  $meta->{field_names} ||= [ sort keys %{ $meta->{fields} } ];
  my $fields = $meta->{fields};
  
  FIELD: foreach my $name ( @{ $meta->{field_names} } )
  {
    my $props = $fields->{$name};
    my $value = _build_arg( $s, $name, $s->{$name}, $props );
    
    if( $props->{weak_ref} )
    {
      weaken( $s->{$name} = $value );
    }
    else
    {
      $s->{$name} = $value;
    }# end if()
  }# end foreach()
}# end _build()


sub _build_arg
{
  my ($s, $name, $value, $props) = @_;
  
  # No value, no default and it's required:
  if( $props->{required} && (! defined($value) ) && (! $props->{default}) )
  {
    confess "Required param '$name' is required but was not provided.";
  }
  # No value, but we have a default:
  elsif( $props->{default} && (! defined($value) ) )
  {
    if( $props->{lazy} )
    {
      # Deal with this later.
      return;
    }
    else
    {
      return $s->{$name} = $value = $props->{default}->( $s );
    }# end if()
  }# end if()
  
  $value = _validate_field( $s, $name, $value, $props );
  
  if( $props->{where} && defined($value) )
  {
    local $_ = $value;
    confess "Invalid value for property '$name': '$_'"
      unless $props->{where}->( $s );
  }# end if()
  
  return $value;
}# end _build_arg()


sub _validate_field
{
  my ($s, $name, $new_value, $props) = @_;
  
  my $original_type = VSO::Subtype->find(_discover_type( $new_value ));
  my $original_value = $new_value;
  
  my $is_ok = 0;
  ISA: foreach my $isa ( split /\|/, $props->{isa} )
  {
    $isa = "$1\::of::$2" if $isa =~ m{^(.+?)\[(.+?)\]};
    TYPE_CHECK: {
      my $current_type = VSO::Subtype->find( _discover_type( $new_value ) );
      my $wanted_type = VSO::Subtype->find( $isa );
      
      # Don't worry about Undef when the field isn't required:
      if( $current_type eq 'Undef' )
      {
        if( (! $props->{required}) || ( ! defined $original_value ) )
        {
          $is_ok = 1;
          last ISA;
        }# end if()
      }# end if()
      
      # Verify that the value matches the entire chain of dependencies:
      if( $wanted_type eq 'Any' || $current_type->isa( $wanted_type ) )
      {
        if( my $ref = $wanted_type->can('where') )
        {
          local $_ = $new_value;
          if( $wanted_type->where( $s ) )
          {
            $is_ok = 1;
            last ISA;
          }# end if()
        }
        else
        {
          $is_ok = 1;
          last ISA;
        }# end if()
      }
      elsif( my $can_coerce = $props->{coerce} && exists($_coercions->{ $wanted_type }->{ $current_type }) )
      {
        # Can we coerce from this type to the wanted type?:
        my $coercion = $can_coerce ? $_coercions->{ $wanted_type }->{ "$current_type" } : undef;
        local $_ = $new_value;
        if( $coercion )
        {
          $new_value = $coercion->( $s );
          $is_ok = 1;
        }
        else
        {
          next TYPE_CHECK;
        }# end if()
      }
      elsif( eval { $wanted_type->as eq $current_type } )
      {
        local $_ = $new_value;
        if( $wanted_type->where( $s ) )
        {
          $is_ok = 1;
          last ISA;
        }# end if()
      }# end if()

    };
    next ISA;
  }# end foreach()
  
  unless( $is_ok )
  {
    local $_ = $original_value;
    confess "Invalid value for @{[ref($s)]}.$name: isn't a $props->{isa}: [$original_type] '$_'" . (eval{ ': ' . $props->{isa}->message($s) }||'');
  }# end unless()
  
  return $new_value;
}# end _validate_field()


sub extends(@)
{
  my $class = caller;
  
  _extend_class($class => @_);
}# end extends()


sub _extend_class
{
  my $class = shift;
  
  no strict 'refs';
  my $meta = $class->meta();
  map {
    load_class( $_ );
    push @{"$class\::ISA"}, $_;
    my $parent_meta = $_->meta or die "Class $_ has no meta!";
    map {
      $meta->{fields}->{$_} = $parent_meta->{fields}->{$_}
    } keys %{ $parent_meta->{fields} };
    map {
      $meta->{triggers}->{$_} = $parent_meta->{triggers}->{$_}
    } keys %{ $parent_meta->{triggers} };
  } @_;
}# end _extend_class()


sub before($&)
{
  my $class = caller;
  my ($name, $sub) = @_;
  my $meta = $class->meta;
  
  # Sanity:
  confess "You must define property $class.$name before adding triggers to it"
    unless exists($meta->{fields}->{$name}) || $class->can($name);
  
  if( exists($meta->{fields}->{$name}) )
  {
    $meta->{triggers}->{"before.$name"} ||= [ ];
    push @{ $meta->{triggers}->{"before.$name"} }, $sub;
  }
  else
  {
    my $orig = $class->can($name);
    no strict 'refs';
    no warnings 'redefine';
    *{"$class\::$name"} = sub {
      $sub->( @_ );
      $orig->( @_ );
    };
  }# end if()
}# end before()


sub after($&)
{
  my $class = caller;
  my ($name, $sub) = @_;
  my $meta = $class->meta;
  
  # Sanity:
  confess "You must define property $class.$name before adding triggers to it"
    unless exists($meta->{fields}->{$name}) || $class->can($name);
  
  if( exists($meta->{fields}->{$name}) )
  {
    $meta->{triggers}->{"after.$name"} ||= [ ];
    push @{ $meta->{triggers}->{"after.$name"} }, $sub;
  }
  else
  {
    my $orig = $class->can($name);
    no strict 'refs';
    no warnings 'redefine';
    *{"$class\::$name"} = sub {
      my $context = defined(wantarray) ? wantarray ? 'list' : 'scalar' : 'void';
      my ($res,@res);
      $context eq 'list' ? @res = $orig->( @_ ) : $context eq 'scalar' ? $res = $orig->( @_ ) : $orig->( @_ );
      $sub->( @_ );
      $context eq 'list' ? return @res : $context eq 'scalar' ? return $res : return;
    };
  }# end if()
}# end after()


sub has($;@)
{
  my $class = caller;
  my $name = shift;
  my %properties = @_;
  my $meta = $class->meta;
  
  $properties{isa} ||= 'Any';
  $properties{isa} =~ s{^Maybe\[(.*?)\]$}{Undef|$1}s;

  foreach my $type ( split /\|/, $properties{isa} )
  {
    if( my ($reftype, $valtype) = $type =~ m{^((?:Hash|Array)Ref)\[(.+?)\]$} )
    {
      load_class($valtype)
        unless VSO::Subtype->find($valtype);
      (my $classname = $type) =~ s{^(.+?)\[(.+?)\]}{$1 . "::of::$2"}e;
      unless( VSO::Subtype->subtype_exists($type) )
      {
        _add_collection_subtype( $type, $reftype, $valtype );
      }# end unless()
    }
    else
    {
      load_class($type)
        unless VSO::Subtype->find($type);
    }# end if()
  }# end foreach()
  
  my $props = $meta->{fields}->{$name} = {
    is        => 'rw',
    required  => 1,
    isa       => 'Any',
    lazy      => 0,
    weak_ref  => 0,
    coerce    => 0,
    %properties,
  };
  
  no strict 'refs';
  *{"$class\::$name"} = sub {
    my $s = shift;
    
    # Getter:
    unless( @_ )
    {
      # Support laziness:
      if( ( ! defined($s->{$name}) ) && $props->{default} )
      {
        if( $props->{weak_ref} )
        {
          weaken($s->{$name} = $props->{default}->( $s ));
        }
        else
        {
          $s->{$name} = $props->{default}->( $s );
        }# end if()
      }# end if()
      
      return $s->{$name};
    }# end unless()
    
    if( $props->{is} eq 'ro' )
    {
      confess "Cannot change readonly property '$name'";
    }
    elsif( $props->{is} eq 'rw' )
    {
      my $new_value = shift;
      my $old_value = $s->{$name};
      
      $new_value = _build_arg( $s, $name, $new_value, $props );
      
      if( my $triggers = $meta->{triggers}->{"before.$name"} )
      {
        map {
          $_->( $s, $new_value, $old_value );
        } @$triggers;
      }# end if()
      
      # Now change the value:
      if( $props->{weak_ref} )
      {
        weaken($s->{$name} = $new_value);
      }
      else
      {
        $s->{$name} = $new_value;
      }# end if()
      
      if( my $triggers = $meta->{triggers}->{"after.$name"} )
      {
        map {
          $_->( $s, $s->{$name}, $old_value);
        } @$triggers;
      }# end if()
      
      # Default to returning the new value:
      $new_value if defined wantarray();
    }# end if()
  };
}# end has()


sub _add_collection_subtype
{
  my ($type, $reftype, $valtype) = @_;
  
  _add_subtype(
    'name'    => $type,
    'as'      => $reftype,
    'where'   =>
      $reftype eq 'ArrayRef' ?
        sub {
          my $vals = $_;
          # Handle an empty value:
          return 1 unless @$vals;
          ! grep {! _discover_type($_)->isa($valtype) } @$vals
        }
        :
        sub {
          my $vals = [ values %$_ ];
          # Handle an empty value:
          return 1 unless @$vals;
          ! grep {! _discover_type($_)->isa($valtype) } @$vals
        },
    'message' => sub { "Must be a valid '$type'" },
  );
}# end _add_collection_subtype()


sub _discover_type
{
  my ($val) = @_;
  
  if( my $ref = ref($val) )
  {
    return 'ScalarRef' if $ref eq 'SCALAR';
    return 'ArrayRef' if $ref eq 'ARRAY';
    return 'HashRef' if $ref eq 'HASH';
    return 'CodeRef' if $ref eq 'CODE';
    return 'GlobRef' if $ref eq 'GLOB';
    return 'RegexpRef' if $ref eq 'Regexp';
    return 'FileHandle' if openhandle($val);
    # Otherwise, it's a reference to some kind of object:
    return $ref;
  }
  else
  {
    return 'Undef' unless defined($val);
    return 'Bool' if $val =~ m{^(?:0|1)$};
    return 'Int' if $val =~ m{^\d+$};
    return 'Num' if $val =~ m{^\d+\.?\d*?$};
    # ClassName?:
    (my $fn = "$val.pm") =~ s{::}{/}g;
    return 'ClassName' if exists($INC{$fn});
    return 'Str';
  }# end if()
}# end _discover_type()


sub _new_meta
{
  return {
    fields    => { },
    triggers  => { }
  };
}# end _new_meta()


sub load_class
{
  my $class = shift;
  
  (my $file = "$class.pm") =~ s|::|/|g;
  no strict 'refs';
  eval { require $file unless defined(@{"$class\::ISA"}) || $INC{$file}; 1 }
    or die "Can't require $file: $@";
  $INC{$file} ||= $file;
  $class->import(@_);
}# end load_class()


sub _add_subtype
{
  my %args = @_;

  $args{name} =~ s{^(.+?)\[(.+?)\]}{"$1" . "::of::$2"}e
    if $args{name} =~ m{^.+?\[.+?\]$};

  return if $VSO::Subtype::types{$args{name}};
  
  $args{as} ||= '';
  $args{as} =~ s{^(.+?)\[(.+?)\]}{"$1" . "::of::$2"}e
    if $args{as} =~ m{^.+?\[.+?\]$};
  
  my $name = $args{name};
  no strict 'refs';
  
  @{"$name\::ISA"} = (grep { $_ } 'VSO::Subtype', $args{as});
  *{"$name\::name"} = sub{$name};
  *{"$name\::as"} = sub{$args{as}};
  *{"$name\::where"} = $args{where};
  *{"$name\::message"} = $args{message};
  (my $file = "$name.pm") =~ s|::|/|g;
  $INC{$file} = $file;
  $name->init();
}# end _add_subtype()


sub subtype($;@)
{
  my ($name, %args) = @_;
  
  confess "Subtype '$name' already exists"
    if $VSO::Subtype::types{$name};
  _add_subtype(
    name    => $name,
    as      => $args{as},
    where   => $args{where} || sub { 1 },
    message => $args{message} || sub { "Must be a valid '$name'" },
  );
}# end subtype()
sub as          { as => shift, @_   }
sub where(&)    { where => $_[0]    }
sub message(&)  { message => $_[0]  }


sub coerce($;@)
{
  my ($to, %args) = @_;
  
  my ($pkg,$filename,$line) = caller;
  confess "Coercion from '$args{from}' to '$to' is already defined in $filename line $line"
    if defined($_coercions->{$to}->{$args{from}});
  $_coercions->{$to}->{$args{from}} = $args{via};
}# end coerce()
sub from    { from => shift, @_ }
sub via(&)  { via  => $_[0]     }


sub enum($$)
{
  my ($name, $vals) = @_;
  _add_subtype(
    name    => $name,
    as      => 'Str',
    where   => sub {
      my $val = $_;
      no warnings 'uninitialized';
      for( @$vals ) {
        return 1 if $_ eq $val;
      }
      return 0;
    },
    message => sub {
      "Must be a valid '$name'"
    }
  );
}# end enum($$)


# All things spring forth from the formless void:

subtype 'Any' =>
  as      '',
  where   { 1 },
  message { '' };

  subtype 'Item'  =>
    as      'Any',
    where   { 1 },
    message { '' };

    subtype 'Undef' =>
      as      'Item',
      where   { ! defined },
      message { "Must not be defined" };

    subtype 'Defined' =>
      as      'Item',
      where   { defined },
      message { "Must be defined" };

      subtype 'Value' =>
        as      'Defined',
        where   { ! ref },
        message { "Cannot be a reference" };

        subtype 'Str' =>
          as      'Value',
          where   { 1 },
          message { '' };

          subtype 'Num' =>
            as      'Str',
            where   { m{^[\+\-]?\d+\.?\d*?$} },
            message { 'Must contain only numbers and decimals' };

            subtype 'Int' =>
              as      'Num',
              where   { m{^[\+\-]?\d+$} },
              message { 'Must contain only numbers 0-9' };

              subtype 'Bool' =>
                as      'Int',
                where   { ( ! defined($_) ) || m{^(?:1|0)$} },
                message { "Must be a 1 or a 0" };

          subtype 'ClassName' =>
            as      'Str',
            where   { m{^[a-z\:0-9_]+$}i },
            message { 'Must match m{^[a-z\:0-9_]+$}i' };

      subtype 'Ref' =>
        as      'Defined',
        where   { ref },
        message { 'Must be a reference' };

        subtype 'ScalarRef' =>
          as      'Ref',
          where   { ref($_) eq 'SCALAR' },
          message { 'Must be a scalar reference (ScalarRef)' };

        subtype 'ArrayRef'  =>
          as      'Ref',
          where   { ref($_) eq 'ARRAY' },
          message { 'Must be an array reference (ArrayRef)' };

        subtype 'HashRef' =>
          as      'Ref',
          where   {ref($_) eq 'HASH' },
          message { 'Must be a hash reference (HashRef)' };

        subtype 'CodeRef' =>
          as      'Ref',
          where   { ref($_) eq 'CODE' },
          message { 'Must be a code reference (CodeRef)' };

        subtype 'RegexpRef' =>
          as      'Ref',
          where   { ref($_) eq 'Regexp' },
          message { 'Must be a Regexp' };

        subtype 'GlobRef' =>
          as      'Ref',
          where   { ref($_) eq 'GLOB' },
          message { 'Must be a GlobRef (GLOB)' };
        
          subtype 'FileHandle'  =>
            as      'GlobRef',
            where   { openhandle($_) },
            message { 'Must be a FileHandle' };
            
        subtype 'Object'  =>
          as      'Ref',
          where   { no strict 'refs'; scalar(@{ref($_) . "::ISA"}) },
          message { 'Must be an object' };

1;# return true:



=pod

=head1 NAME

VSO - Very Simple Objects

=head1 DEPRECATED

Do not use.  Look at L<Mo>, L<Moo>, L<Mouse> or L<Moose> instead.

=head1 SYNOPSIS

Basic point example:

  package Plane;
  use VSO;
  
  has 'width' => (
    is        => 'ro',
    isa       => 'Int',
  );
  
  has 'height' => (
    is        => 'ro',
    isa       => 'Int',
  );
  
  has 'points' => (
    is        => 'rw',
    isa       => 'ArrayRef[Point2d]',
    required  => 0,
  );


  package Point2d;
  use VSO;
  
  subtype 'ValidValue'
    => as      'Int'
    => where   { $_ >= 0 && $_ <= shift->plane->width }
    => message { 'Value must be between zero and ' . shift->plane->width };
  
  has 'plane' => (
    is        => 'ro',
    isa       => 'Plane',
    weak_ref  => 1,
  );
  
  has 'x' => (
    is        => 'rw',
    isa       => 'ValidValue'
  );
  
  has 'y' => (
    is        => 'rw',
    isa       => 'ValidValue'
  );
  
  after 'x' => sub {
    my ($s, $new_value, $old_value) = @_;
    warn "Moving $s from x$old_value to x$new_value";
  };
  
  after 'y' => sub {
    my ($s, $new_value, $old_value) = @_;
    warn "Moving $s from y$old_value to y$new_value";
  };

Fancy 3D Point:

  package Point3d;
  use VSO;
  
  extends 'Point2d';
  
  has 'z' => (
    is      => 'rw',
    isa     => 'Int',
  );

  sub greet { warn "Hello, World!" }
  
  before 'greet' => sub {
    warn "About to greet you";
  };
  
  after 'greet' => sub {
    warn "I have greeted you";
  };


Enums:

  package Foo;
  use VSO;

  enum 'DayOfWeek' => [qw( Sun Mon Tue Wed Thu Fri Sat )];

  has 'day' => (
    is        => 'ro',
    isa       => 'DayOfWeek',
    required  => 1,
  );

Coercions and Subtypes:

  package Ken;
  use VSO;

  subtype 'Number::Odd'
    => as       'Int'
    => where    { $_ % 2 }
    => message  { "$_ is not an odd number: %=:" . ($_ % 2) };

  subtype 'Number::Even'
    => as       'Int'
    => where    { (! $_) || ( $_ % 2 == 0 ) }
    => message  { "$_ is not an even number" };

  coerce 'Number::Odd'
    => from 'Int'
    => via  { $_ % 2 ? $_ : $_ + 1 };

  coerce 'Number::Even'
    => from 'Int'
    => via  { $_ % 2 ? $_ + 1 : $_ };

  has 'favorite_number' => (
    is        => 'ro',
    isa       => 'Number::Odd',
    required  => 1,
    coerce    => 1, # Otherwise no coercion is performed.
  );

  ...

  my $ken = Ken->new( favorite_number => 3 ); # Works
  my $ken = Ken->new( favorite_number => 6 ); # Works, because of coercion.

Compile-time Extension Syntax new in v0.024:

  package Root::Foo;
  use VSO;
  has ...;
  
  package Subclass::Foo;
  use VSO extends => 'Foo::Class'; # inheritance during compile-time, not runtime.
  
  package Subclass::Bar;
  use VSO extends => [qw( Foo::Class Bar::Class )]; # extend many at once.


=head1 DESCRIPTION

VSO aims to offer a declarative OO style for Perl with very little overhead, without
being overly-minimalist.

VSO is a simplified Perl5 object type system I<similar> to L<Moose>, but simpler.

=head2 TYPES

VSO offers the following type system:

  Any
    Item
        Bool
        Undef
        Maybe[`a]
        Defined
            Value
                Str
                    Num
                        Int
                    ClassName
            Ref
                ScalarRef
                ArrayRef
                HashRef
                CodeRef
                RegexpRef
                GlobRef
                    FileHandle
                Object

The key differences are that everything is derived from C<Any> and there are no roles.

VSO does not currently support roles.  I<(This may change soon.)>

=head2 "Another" Moose?

Yes, but not exactly.  VSO is B<not> intended as a drop-in replacement
for Moose, Mouse, Moo or Mo.  They are all doing a fantastic job and you should use them.

We've got a ways to go before version 1.000 is released, so don't get too excited
if the documentation isn't quite finished or it's not clear why VSO was made.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is Free software and may be used and redistributed under the same
terms as perl itself.

=cut

