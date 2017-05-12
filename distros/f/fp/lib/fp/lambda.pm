
package fp::lambda;

use strict;
use warnings;

our $VERSION = '0.01';

BEGIN {
    require fp;
    *import = \&fp::import;
}

## Church Booleans

# TRUE := λ x. λ y. x
*TRUE = sub {
    my $x = shift;
    sub { $x }
};

# FALSE :=  λ x. λ y. x
*FALSE = sub {
    my $x = shift;
    sub { shift }
};

# AND := λ p. λ q. p q FALSE
*AND = sub {
    my $p = shift;
    sub {
        my $q = shift;
        $p->($q)->(\&FALSE);
    }
};

# OR := λ p. λ q. p TRUE q
*OR = sub {
    my $p = shift;
    sub {
        my $q = shift;
        $p->(\&TRUE)->($q);
    }
};

# NOT := λ p. p FALSE TRUE
*NOT = sub {
    my $p = shift;
    $p->(\&FALSE)->(\&TRUE);
};

# cond := λ p. λ x. λ y. p x y
*cond = sub {
    my $p = shift;
    sub {
        my $x = shift;
        sub {
            my $y = shift;
            $p->($x)->($y);
        }
    }
};

## Church Numeral 

# 0 := λ f. λ x. x
*zero = sub { 
    my $f = shift; 
    sub { shift } 
};

# succ := λ n. λ f. λ x. f (n f x)
*succ = sub { 
    my $n = shift; 
    sub { 
        my $f = shift; 
        sub { 
            my $x = shift; 
            $f->( $n->($f)->($x) ) 
        } 
    } 
};

# pred := λ m. first (m (λ p. pair (second p) (plus one (second p))) (pair zero zero))
*pred = sub {
    my $m = shift;
    sub {
        first($m->(sub {
                my $p = shift;
                pair(second($p))->(plus(\&one)->(second($p)))
            })->(pair(\&zero)->(\&zero)))
    }->()
};

# plus := λ m. λ n. λ f. λ x. m f (n f x)
*plus = sub { 
    my $m = shift; 
    sub { 
        my $n = shift; 
        sub { 
            my $f = shift; 
            sub { 
                my $x = shift; 
                $m->( $f )->( $n->($f)->($x) ) 
            } 
        } 
    } 
};

# subtract := λ m. λ n. n pred m
*subtract = sub {
    my $m = shift;
    sub {
        my $n = shift;
        $n->(\&pred)->($m);
    }
};

# multiply := λ m. λ n. m (plus n) zero 
*multiply = sub {
    my $m = shift;
    sub {
        my $n = shift;
        $m->(plus($n))->(\&zero);
    }
};

# now make 1 .. 10 

*one   = succ(\&zero);
*two   = succ(\&one);
*three = succ(\&two);
*four  = succ(\&three);
*five  = succ(\&four);
*six   = succ(\&five);
*seven = succ(\&six);
*eight = succ(\&seven);
*nine  = succ(\&eight);
*ten   = succ(\&nine);

## Predicates

# is_zero := λ n. n (λ x. FALSE) TRUE
*is_zero = sub {
    my $n = shift;
    $n->(sub { \&FALSE })->(\&TRUE);
};

# is_equal := λ m. λ n. and (is_zero (m pred n)) (is_zero (n pred m))
*is_equal = sub {
    my $m = shift;
    sub {
        my $n = shift;
        AND(
            is_zero($m->(\&pred)->($n))
        )->(
            is_zero($n->(\&pred)->($m))
        )
    }
};

## Data Structures

## Pairs

# pair := λ f. λ s. λ b. b f s
*pair = sub {
    my $f = shift;
    sub {
        my $s = shift;
        sub {
            my $b = shift;
            $b->($f)->($s);
        }
    }
};

# first := λ p p TRUE
*first = sub {
    my $p = shift;
    $p->(\&TRUE)
};

# second := λ p p FALSE
*second = sub {
    my $p = shift;
    $p->(\&FALSE)
};

# List functions

# NIL := pair TRUE TRUE
*NIL = pair(\&TRUE)->(\&TRUE);

# cons := λ h. λ t. pair FALSE (pair h t)
*cons = sub {
   my $h = shift;
   sub {
       my $t = shift;
       pair(\&FALSE)->(pair($h)->($t));
   }  
};

# head := λ z. first (second z)
*head = sub {
    my $z = shift;
    first(second($z));
};

# tail := λ z. second (second z)
*tail = sub {
    my $z = shift;
    second(second($z));
};

# is_NIL := first
*is_NIL = \&first;

# is_not_NIL := λ x. NOT is_NIL
*is_not_NIL = sub {
    my $x = shift;
    NOT(is_NIL($x))
};

# size := λ l. cond (is_not_NIL l) (λ x. succ (size (tail l))) (λ l. zero)
*size = sub {
    my $l = shift;
    cond(is_not_NIL($l))->(
        # have to wrap this to get lazy evaluation
        sub { succ(size(tail($l))) }
    )->(
        sub { \&zero }
    )->();
};

# sum := λ l. cond (is_not_NIL l) (λ x. plus (head l) (sum (tail l))) (λ l. zero)
*sum = sub {
    my $l = shift;
    cond(is_not_NIL($l))->(
        sub { plus(head($l))->(sum(tail($l))) }
    )->(
        sub { \&zero }
    )->()
};

# append := λ l1. λ l2. cond (is_NIL l1) (l2) (cons (head l1) (append (tail l1) l2))  
*append = sub {
    my $l1 = shift;
    sub {
        my $l2 = shift;
        cond(is_NIL($l1))->(
            sub { $l2 }
        )->(
            sub { cons(head($l1))->(append(tail($l1))->($l2)) }
        )->();
    }
};

# rev := λ l. cond (is_not_NIL) (NIL) (append rev(tail l) cons((head l) NIL))
*rev = sub {
    my $l = shift;
    cond(is_not_NIL($l))->(
        sub { append(rev(tail($l)))->(cons(head($l))->(\&NIL)) }
    )->(
        sub { \&NIL }
    )->()
};


# nth := λ n. λ l. cond (is_NIL l) (NIL) (cond (is_equal n zero) (head l) (nth (pred n)) (tail l)) ) 
*nth = sub {
  my $n = shift;
  sub {
      my $l = shift;
      cond(is_NIL($l))->(
          sub { \&NIL }
      )->(
          cond(is_equal($n)->(\&zero))->(
              sub { head($l) }
          )->(
              sub { nth(pred($n))->(tail($l)) }
          )
      )->()
  }  
};

# apply := λ f. λ l. cond (is_NIL l) (NIL) (cons (f (head l)) (apply f (tail l)))
*apply = sub {
    my $f = shift;
    sub {
        my $l = shift;
        cond(is_NIL($l))->(
            sub { \&NIL }
        )->(
            sub { cons($f->(head($l)))->(apply($f)->(tail($l))) }
        )->()
    }
};

1;

__END__

=pod

=head1 NAME

fp::lambda - lambda calculus in Perl

=head1 SYNOPSIS

  use fp::lambda;

  # add two Church numerals together
  add(\&two)->(\&two);
  
  # subtract them ...
  subtract(\&two)->(\&two);
  
  # check if a Church numeral is zero
  is_zero(\&zero); 

  # build a list of one through five
  my $one_through_five = cons(\&one)->(cons(\&two)->(cons(\&three)->(cons(\&four)->(cons(\&five)->(\&NIL)))));
  
  # check it's size
  is_equal(size($one_through_five))->(\&five);
  
  # get the sum of the list
  sum($one_through_five)); # returns 15 (as a Church numeral)

=head1 DESCRIPTION

This module implements lambda calculus using plain Perl subroutines as lambda abstractions. 

=head1 FUNCTIONS

=head2 Church Booleans

=over 4

=item TRUE :=  E<955> x. E<955> y. x

=item FALSE := E<955> x. E<955> y. x

=item AND := E<955> p. E<955> q. p q FALSE

=item OR :=  E<955> p. E<955> q. p TRUE q

=item NOT := E<955> p. p FALSE TRUE

=item cond :=  E<955> p. E<955> x. E<955> y. p x y

=back

=head2 Church Numerals

=over 4

=item zero := E<955> f. E<955> x. x

=item one := E<955> f. E<955> x. f x 

=item two := E<955> f. E<955> x. f (f x) 

=item three := E<955> f. E<955> x. f (f (f x))

=item four := E<955> f. E<955> x. f (f (f (f x)))

=item five := E<955> f. E<955> x. f (f (f (f (f x))))

=item six := E<955> f. E<955> x. f (f (f (f (f (f x)))))

=item seven := E<955> f. E<955> x. f (f (f (f (f (f (f x))))))

=item eight := E<955> f. E<955> x. f (f (f (f (f (f (f (f x))))))) 

=item nine := E<955> f. E<955> x. f (f (f (f (f (f (f (f (f x)))))))) 

=item ten := E<955> f. E<955> x. f (f (f (f (f (f (f (f (f (f x)))))))))  

=item succ :=  E<955> n. E<955> f. E<955> x. f (n f x)

=item pred := E<955> m. first (m (E<955> p. pair (second p) (plus one (second p))) (pair zero zero))

=item is_zero := E<955> n. n (E<955> x. FALSE) TRUE

=item is_equal := E<955> m. E<955> n. AND (is_zero (m pred n)) (is_zero (n pred m))

=item plus := E<955> m. E<955> n. E<955> f. E<955> x. m f (n f x)

=item subtract := E<955> m. E<955> n. n pred m

=item multiply := E<955> m. E<955> n. m (plus n) zero 

=back

=head2 List Functions

=over 4

=item NIL := pair TRUE TRUE 

=item is_NIL := first

=item is_not_NIL := E<955> x. NOT is_NIL

=item cons := E<955> h. E<955> t. pair FALSE (pair h t)

=item head := E<955> z. first (second z)

=item tail := E<955> z. second (second z)

=item size := E<955> l. cond (is_not_NIL l) (E<955> x. succ (size (tail l))) (E<955> l. zero)

=item sum := E<955> l. cond (is_not_NIL l) (E<955> x. plus (head l) (sum (tail l))) (E<955> l. zero)

=item append := E<955> l1. E<955> l2. cond (is_NIL l1) (l2) (cons (head l1) (append (tail l1) l2))

=item rev := E<955> l. cond (is_not_NIL) (NIL) (append rev(tail l) cons((head l) NIL))

=item nth := E<955> n. E<955> l. cond (is_NIL l) (NIL) (cond (is_equal n zero) (head l) (nth (pred n)) (tail l)) ) 

=item apply := E<955> f. E<955> l. cond (is_NIL l) (NIL) (cons (f (head l)) (apply f (tail l)))

=back

=head2 Pair Functions

=over 4

=item pair := E<955> f. E<955> s. E<955> b. b f s

=item first := E<955> p p TRUE 

=item second := E<955> p p FALSE 

=back

=head1 BUGS

None that I am currently aware of. Of course, that does not mean that they do not exist, so if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

See the C<CODE COVERAGE> section of B<fp> for this information.

=head1 SEE ALSO

=over 4

=item Types and Programming Languages

=item L<http://en.wikipedia.org/wiki/Lambda_calculus>

=item L<http://www.csse.monash.edu.au/~lloyd/tildeFP/Lambda/>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut