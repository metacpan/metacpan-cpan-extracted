### base.pm --- Tree::Range::base: base class for the range trees  -*- Perl -*-

### Copyright (C) 2013 Ivan Shmakov

## Permission to copy this software, to modify it, to redistribute it,
## to distribute modified versions, and to use it for any purpose is
## granted, subject to the following restrictions and understandings.

## 1.  Any copy made of this software must include this copyright notice
## in full.

## 2.  I have made no warranty or representation that the operation of
## this software will be error-free, and I am under no obligation to
## provide any services, by way of maintenance, update, or otherwise.

## 3.  In conjunction with products arising from the use of this
## material, there shall be no use of my name in any advertising,
## promotional, or sales literature without prior written consent in
## each case.

### Code:

package Tree::Range::base;

use strict;

our $VERSION = 0.22;

require Carp;

use Scalar::Util qw (refaddr);

sub safe_eq {
    ## return true if either both are undef, or the same ref
    my ($a, $b) = @_;
    ## .
    return (defined ($a)
            ?  (ref ($a) && ref ($b)
                && refaddr ($a) == refaddr ($b))
            : ! defined ($b));
}

sub del_range {
    my ($obj, $left, $cmp, $high) = @_;
    my ($last_ref, @delk);
    for (my $e = $left;
         defined ($e);
         $e = $e->successor ()) {
        my $c
            = &$cmp ($e->key (), $high);
        last
            if ($c >  0);
        # print STDERR ("-g: ", scalar (Data::Dump::dump ({ $e->key () => $e->val () })), "\n");
        $last_ref
            = [ $e->key, $e->val () ];
        last
            if ($c >= 0);
        ## FIXME: shouldn't there be a better way?
        push (@delk, $e->key ());
    }
    # print STDERR ("-g: ", scalar (Data::Dump::dump (\@delk)), "\n");
    foreach my $k (@delk) {
        $obj->delete ($k)
            or Carp::croak ($k, ": failed to delete key");
    }
    ## .
    return $last_ref;
}

sub get_range {
    my ($self, $key) = @_;
    my $left
        = $self->lookup_leq ($key);
    my $v
        = (defined ($left)
           ? $left->val ()
           : $self->leftmost_value ());
    ## .
    return $v
        unless (wantarray ());
    unless (defined ($left)) {
        my $right
            = $self->lookup_geq ($key);
        ## .
        return (defined ($right)
                ? ($v, undef, $right->key ())
                : ($v));
    }
    my ($l_k, $right)
        = ($left->key (), $left->successor ());
    ## .
    return (defined ($right)
            ? ($v, $l_k, $right->key ())
            : ($v, $l_k));
}

sub range_free_p {
    my ($self, $lower, $upper) = @_;
    my $cmp
        = $self->cmp_fn ();
    Carp::croak ("Upper bound (", $upper,
                 ") must be greater than the lower (", $lower,
                 ") one")
        unless (&$cmp ($upper, $lower) > 0);

    my $right
        = $self->lookup_leq ($upper);
    ## .
    return    1
        unless (defined ($right));
    ## FIXME: a crude ->lookup_lt ()
    $right
        = $right->predecessor ()
        if ($cmp->($upper, $right->key ()) == 0);
    ## .
    return    1
        unless (defined ($right));

    my ($r, $lm, $eq_u)
        = ($right->val (),
           $self->leftmost_value (),
           $self->value_equal_p_fn ());
    ## .
    return (! 1)
        unless (safe_eq   ($r, $lm)
                || $eq_u->($r, $lm));

    ## by now, we know that $upper is mapped to $lm
    ## check if $lower is covered by the same range
    ## .
    return ($cmp->($right->key (), $lower) <= 0);
}

sub prepare_range_iter_asc {
    my ($self, $fn_ref, $may_be_key) = @_;

    my $cur;
    my $fn = sub {
        ## .
        return
            unless (defined ($cur));
        my $next
            = $cur->successor ();
        my @r
            = (wantarray ()
               ? ($cur->val (), $cur->key (),
                  (defined ($next) ? ($next->key ()) : ()))
               : ($cur->val ()));
        $cur
            = $next;
        ## .
        @r;
    };

    if (defined ($may_be_key)) {
        ($$fn_ref, $cur)
            = ($fn, $self->lookup_leq ($may_be_key));
        ## .
        return $fn->();
    } else {
        my $n
            = $self->min_node ();
        ($$fn_ref, $cur)
            = ($fn, $n);
        ## .
        return (wantarray ()
                ? ($self->leftmost_value (),
                   undef,
                   (defined ($n) ? ($n->key ()) : ()))
                :  $self->leftmost_value ());
    }
}

sub prepare_range_iter_dsc {
    my ($self, $fn_ref, $may_be_key) = @_;

    my $cur;
    my $fn = sub {
        ## .
        return
            unless (defined ($cur));
        my $prev
            = $cur->predecessor ();
        my @r
            = (wantarray ()
               ? ((defined ($prev)
                   ? ($prev->val (),  $prev->key ())
                   : ($self->leftmost_value (), undef)),
                  $cur->key ())
               : (defined ($prev)
                  ? $prev->val ()
                  : $self->leftmost_value ()));
        $cur
            = $prev;
        ## .
        @r;
    };

    if (defined ($may_be_key)) {
        my $n
            = $self->lookup_geq ($may_be_key);
        ## FIXME: a crude ->lookup_gt ()
        $n
            = $n->successor ()
            if (defined ($n)
                && ($self->cmp_fn ()->($may_be_key,
                                       $n->key ()) == 0));
        ($$fn_ref, $cur)
            = ($fn, $n);
        ## .
        return $fn->();
    } else {
        my $n
            = $self->max_node ();
        ($$fn_ref, $cur)
            = ($fn, $n);
        ## .
        return (wantarray ()
                ? (defined ($n)
                   ? ($n->val (), $n->key ())
                   : ($self->leftmost_value ()))
                : (defined ($n)
                   ?  $n->val ()
                   :  $self->leftmost_value ()));
    }
}

sub range_iter_closure {
    my ($self, $may_be_key, $may_be_reverse_p) = @_;

    my $fn
        = undef;

    ## .
    sub {
        ## .
        return (defined ($fn)
                ? $fn->()
                : ($may_be_reverse_p
                   ? $self->prepare_range_iter_dsc (\$fn, $may_be_key)
                   : $self->prepare_range_iter_asc (\$fn, $may_be_key)));
    }
}

sub range_set {
    my ($self, $low, $high, $value) = @_;
    my $cmp
        = $self->cmp_fn ();
    Carp::croak ("Upper bound (", $high,
                 ") must be greater than the lower (", $low,
                 ") one")
        unless (&$cmp ($high, $low) > 0);

    ##  |      min      |       |       |      max      |
    ## .. Left  a   A   b   B   c   C   d   D   e   E   ..

    my $left
        = $self->lookup_geq ($low);
    if (! defined ($left)) {
        ## $low, and thus $high, are higher than max
        # print STDERR ("-g: ", scalar (Data::Dump::dump ({ $low => $value, $high => $self->leftmost_value () })), "\n");
        $self->put ($low,   $value);
        $self->put ($high,  $self->leftmost_value ());
    } else {
        ## preserve the value, if any
        my $pre
            = $left->predecessor ();
        my $pre_v
            = (defined ($pre)
               ? $pre->val ()
               : $self->leftmost_value ());
        ## remove everything up to the boundary at $high
        my $last_ref
            = del_range ($self, $left, $cmp, $high);
        my $last
            = (defined ($last_ref)
               ? $last_ref->[1]
               : $pre_v);
        ## there either already is a boundary at $low,
        ## or we add it now
        my $eq_u
            = $self->value_equal_p_fn ();
        my $eq_l
            = (safe_eq ($value, $pre_v) || $eq_u->($value, $pre_v));
        my $eq_h
            = (safe_eq ($value, $last)  || $eq_u->($value, $last));
        # print STDERR ("-g: ", scalar (Data::Dump::dump ({ (! $eq_l ? ($low => $value) : ()), (! $eq_h ? ($high => $last) : ()) })), "\n");
        if (! $eq_l) {
            $self->put ($low,   $value);
        } else {
            ## merge the segments
            $self->delete ($low);
        }
        if (! $eq_h) {
            $self->put ($high,  $last);
        } else {
            ## merge the segments
            $self->delete ($high);
        }
    }

    ## .
}

*range_set_over
    = \&range_set;

1;

### Emacs trailer
## Local variables:
## coding: us-ascii
## fill-column: 72
## indent-tabs-mode: nil
## ispell-local-dictionary: "american"
## End:
### base.pm ends here
