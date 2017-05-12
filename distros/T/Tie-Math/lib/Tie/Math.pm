package Tie::Math;

use strict;

require Exporter;
use vars qw(@EXPORT @Variables @EXPORT_OK @ISA $VERSION);

@ISA = qw(Exporter);

@EXPORT = qw(f N);

# @Variables is defined below.
@EXPORT_OK = @Variables;

$VERSION = '0.10';

# Need lvalue subroutines.
use 5.006;

use constant DEBUG => 0;


# Alas, I can't use Tie::StdHash and Tie::Hash is too bloody slow.
# So I'll just copy the meat of Tie::StdHash in here and do a little
# s///
sub STORE    { $_[0]->{hash}->{$_[1]} = $_[2] }
sub FIRSTKEY { my $a = scalar keys %{$_[0]->{hash}}; each %{$_[0]->{hash}} }
sub NEXTKEY  { each %{$_[0]->{hash}} }
sub EXISTS   { exists $_[0]->{hash}->{$_[1]} }
sub DELETE   { delete $_[0]->{hash}->{$_[1]} }
sub CLEAR    { %{$_[0]->{hash}} = () }


=pod

=head1 NAME

Tie::Math - Hashes which represent mathematical functions.


=head1 SYNOPSIS

  use Tie::Math;
  tie %fibo, 'Tie::Math', sub { f(n) = f(n-1) + f(n-2) },
                          sub { f(0) = 0;  f(1) = 1 };

  # Calculate and print the fifth fibonacci number
  print $fibo{5};


=head1 DESCRIPTION

Defines hashes which represent mathematical functions, such as the
fibonacci sequence, factorials, etc...  Functions can be expressed in
a manner which a math or physics student might find a bit more
familiar.  It also automatically employs memoization.

Multi-variable functions are supported.  f() is simply passed two
variables (f(X,Y) for instance) and the hash is accessed in the same
way ($func{3,-4}).

=over 4

=item B<tie>

  tie %func, 'Tie::Math', \&function;
  tie %func, 'Tie::Math', \&function, \&initialization;

&function contains the definition of the mathematical function.  Use
the f() subroutine and N index provided.  So to do a simple
exponential function represented by "f(N) = N**2":

    tie %exp, 'Tie::Math', sub { f(N) = N**2 };

&initialization contains any special cases of the function you need to
define.  In the fibonacci example in the SYNOPSIS you have to define
f(0) = 1 and f(1) = 1;

    tie %fibo, 'Tie::Math', sub { f(N) = f(N-1) + f(N-2) },
                            sub { f(0) = 1;  f(1) = 1; };

The &initializaion routine is optional.

Each calculation is "memoized" so that for each element of the array the
calculation is only done once.

While the variable N is given by default, A through Z are all
available.  Simply import them explicitly:

    # Don't forget to import f()
    use Tie::Math qw(f X);

There's no real difference which variable you use, its just there for
your preference.  (NOTE: I had to use captial letters to avoid
clashing with the y// operator)

=cut

#'#

use vars qw($Obj $Idx $IsInit @Curr_Idx %Vars);

sub TIEHASH {
    my($class, $func, $init) = @_;

    my $self = bless {}, $class;

    $self->{func}  = $func;
    $self->{hash} = {};

    if( defined $init ) {
        local $Obj = $self;
        local $IsInit = 1;
        $init->();
    }

    return $self;
}


sub _normal_idx {
    return join $;, @_;
}


sub _split_idx {
    return split /$;/, $_[0];
}


sub f : lvalue {
    my(@idx) = @_;

    warn "f() got ", join(" ", @_), "\n" if DEBUG;

    my($norm_idx) = _normal_idx(@idx);
    my($hash) = $Obj->{hash};

    warn "f() index - ", join(" ", @idx), "\n"  if DEBUG;
    warn "\$Idx - $Idx\n"                       if DEBUG;
    warn "\$IsInit == $IsInit\n"                if DEBUG;
    select(undef,undef,undef,0.200)             if DEBUG;

    unless( $IsInit || exists $hash->{$norm_idx} || $Idx eq $norm_idx ) 
    {   
        warn "FETCHing $norm_idx\n" if DEBUG;
        $Obj->FETCH($norm_idx);
    }

    # Can't return an array element from an lvalue routine, but we
    # can return a dereferenced reference to it!
    my $tmp = \$hash->{$norm_idx};
    warn "tmp is $$tmp\n" if DEBUG;
    $$tmp;
}


# "variable" routines.
BEGIN {
    no strict 'refs';

    @Variables = ('A'..'Z');

    foreach my $var (@Variables) {
        *{$var} = sub () {
            $Vars{$var} = shift @Curr_Idx if @Curr_Idx;
            warn "$var() is $Vars{$var}\n" if DEBUG;
            return $Vars{$var};
        }
    }
}


sub FETCH {
    my($self, $idx) = @_;
    my $hash = $self->{hash};

    warn "\@Curr_Idx == ", join "\n", _split_idx($idx), "\n" if DEBUG;

    my($call_pack) = caller;

    warn "FETCH() idx is $idx\n"                        if DEBUG;
    warn "FETCH() calling pack is $call_pack\n"         if DEBUG;

    unless( exists $hash->{$idx} ) {
        warn "Generating ", join(" ", @Curr_Idx), "\n" if DEBUG;

        no strict 'refs';

        # Yes, LOCAL.  I have to maintain my own stack.
        local @Curr_Idx = _split_idx($idx);
        local $Obj = $self;

        # This goes away once wantlvalue() is implemented.
        local $IsInit = 0;

        local $Idx = $idx;
        local %Vars;

        $self->{func}->(@Curr_Idx);
    }

    return $hash->{$idx};
}

=pod

=head1 EXAMPLE

Display a polynomial equation in a table.

    use Tie::Math;

    tie %poly, 'Tie::Math', sub { f(N) = N**2 + 2*N + 1 };

    print "  f(N) = N**2 + 2*N + 1 where N == -3 to 3\n";
    print "\t x \t poly\n";
    for my $x (-3..3) {
        printf "\t % 2d \t % 3d\n", $x, $poly{$x};
    }

This should display:

  f(N) = N**2 + 2*N + 1 where N == -3 to 3
         x       poly
         -3        4
         -2        1
         -1        0
          0        1
          1        4
          2        9
          3       16


How about Pascal's Triangle!

    use Tie::Math qw(f X Y);

    my %pascal;
    tie %pascal, 'Tie::Math', sub { 
                                  if( X <= Y and Y > 0 and X > 0 ) {
                                      f(X,Y) = f(X-1,Y-1) + f(X,Y-1);
                                  }
                                  else {
                                      f(X,Y) = 0;
                                  }
                              },
                              sub { 
                                  f(1,1) = 1;  
                                  f(1,2) = 1;  
                                  f(2,2) = 1; 
                              };

    #'#
    $height = 5;
    for my $y (1..$height) {
        print " " x ($height - $y);
        for my $x (1..$y) {
            print $pascal{$x,$y};
        }
        print "\n";
    }

This should produce a nice neat little triangle:

        1
       1 1
      1 2 1
     1 3 3 1
    1 4 6 4 1


=head1 EFFICIENCY

Memoization is automatically employed so no f(X) is calculated twice.
This radically increases efficiency in many cases.


=head1 BUGS, CAVAETS and LIMITATIONS

Certain functions cannot be properly expressed.  For example, the
equation defining a circle, f(X) = sqrt(1 - X**2), has two solutions
for each f(X).

There's some horrific hacks in here to make up for the limitations of the
current lvalue subroutine implementation.  Namely missing wantlvalue().

This code use the experimental lvalue subroutine feature which will
hopefully change in the future.

The interface is currently very alpha and will probably change in the
near future.

This module BREAKS 5.6.0's DEBUGGER!  Neat, eh?

This module uses the old multidimensional hash emulation from the Perl
4 days.  While this isn't currently a bad thing, it may eventually be
destined for the junk heap.


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>


=head1 TODO

Easier ways to set boundries ie. "f(X,Y) = X + Y where X > 0 and Y > 1"

=cut

#'#

1;
