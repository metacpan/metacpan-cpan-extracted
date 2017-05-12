# NAME

VSO - Very Simple Objects

# SYNOPSIS

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
      => as 'Int'
      => where { $_ % 2 }
      => message { "$_ is not an odd number: %=:" . ($_ % 2) };

    subtype 'Number::Even'
      => as 'Int'
      => where { (! $_) || ( $_ % 2 == 0 ) }
      => message { "$_ is not an even number" };

    coerce 'Number::Odd'
      => from 'Int'
      => via  { $_ % 2 ? $_ : $_ + 1 };

    coerce 'Number::Even'
      => from 'Int'
      => via { $_ % 2 ? $_ + 1 : $_ };

    has 'favorite_number' => (
      is        => 'ro',
      isa       => 'Number::Odd',
      required  => 1,
      coerce    => 1, # Otherwise no coercion is performed.
    );

    ...

    my $ken = Ken->new( favorite_number => 3 ); # Works
    my $ken = Ken->new( favorite_number => 6 ); # Works, because of coercion.



# DESCRIPTION

VSO aims to offer a declarative OO style for Perl with very little overhead, without
being overly-minimalist.

VSO is a simplified Perl5 object type system _similar_ to [Moose](http://search.cpan.org/perldoc?Moose), but simpler.

## TYPES

VSO offers the following type system:

    Any
      Item
          Bool
          Undef
          Maybe[`a]*
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

Differences from the Moose type system include:

- Maybe[`a] (Different)

VSO converts `Maybe[Foo]` to `Undef|Foo` and converts `Maybe[HashRef[Foo]]` to `Undef|HashRef[Foo]`.

- RoleName (Missing)

VSO does not currently support 'roles'.

_(This may change)_.

# AUTHOR

John Drago <jdrago_999@yahoo.com>

# LICENSE

This software is Free software and may be used and redistributed under the same
terms as perl itself.