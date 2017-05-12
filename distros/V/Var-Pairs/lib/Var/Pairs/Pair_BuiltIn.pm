package
Var::Pairs::Pair_BuiltIn;

use strict;
use warnings;
use experimental 'refaliasing';

# Class implementing each key/value pair...
# (aliasing via 5.22 built-in aliasing)
package Var::Pairs::Pair {
    use Scalar::Util qw< looks_like_number >;

    use Carp;

    # Each pair object has two attributes...
    my @key_for;
    my @value_for;
    my @freed;

    # Accessors for the attributes (value is read/write)...
    sub value :lvalue { $value_for[${shift()}] }
    sub index         {   $key_for[${shift()}] }
    sub key           {   $key_for[${shift()}] }
    sub kv            { my $self = shift;  $key_for[$$self], $value_for[$$self] }

    # The usual inside-out constructor...
    sub new {
        my ($class, $key, $container_ref, $container_type) = @_;

        # Create a scalar based object...
        my $scalar = @key_for;
        my $new_obj = bless \$scalar, $class;

        # Initialize its attributes (value needs to be an alias to the original)...
        $key_for[$scalar] = $key;
        \$value_for[$scalar] = $container_type eq 'array' ? \$container_ref->[$key]
                             : $container_type eq 'none'  ? \$_[2]
                             :                              \$container_ref->{$key};
        $freed[$scalar] = 0;

        return $new_obj;
    }

    # Type coercions...
    use overload (
        # As a string, a pair is just: key => value
        q{""}   => sub {
            my $self = shift;
            my $value = $value_for[$$self];
            $value = ref $value                ? ref $value
                   : looks_like_number($value) ? $value
                   :                             qq{"$value"};
            return "$key_for[$$self] => $value";
        },

        # Can't numerify a pair (make it a hanging offence)...
        q{0+}   => sub { croak "Can't convert Pair(".shift.") to a number" },

        # All pairs are true (just as in Perl 6)...
        q{bool} => sub { !!1 },

        # Everything else as normal...
        fallback => 1,
    );

    sub DESTROY {
        my $self = shift;

        # Mark current storage as reclaimable...
        $freed[$$self] = 1;

        # Reclaim everything possible...
        if ($freed[$#freed]) {
            my $free_from = $#freed;
            while ($free_from >= 0 && $freed[$free_from]) {
                $free_from--;
            }
            splice @key_for,   $free_from+1;
            splice @value_for, $free_from+1;
            splice @freed,     $free_from+1;
        }
    }
}

# Magic true value required at the end of a module...
1;
