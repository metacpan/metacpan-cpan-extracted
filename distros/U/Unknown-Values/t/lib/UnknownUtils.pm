package UnknownUtils;

use strict;
use warnings;
use Test::Most;
use Unknown::Values;
use Scalar::Util 'looks_like_number';

use parent 'Exporter';
our @EXPORT_OK = qw(
  array_ok
);

sub array_ok ($$;$) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $have, $want, $message ) = @_;

    my $have_length = @$have;
    my $want_length = @$want;
    if ( $have_length != $want_length ) {
        return fail <<"END";
Got array length: $have_length
Wanted array length: $want_length
$message
END
    }

  ELEMENT: foreach my $i ( 0 .. $#$have ) {
        my ( $h, $w ) = ( $have->[$i], $want->[$i] );

        # let's avoid messy uninitialized warnings
        if ( !defined $h ) {
            if ( defined $w ) {
                return fail
"$message\nFound array element $i which is not defined in 'have', but it is in 'want'";
            }
            next ELEMENT;
        }
        elsif ( is_unknown $h ) {
            if ( !is_unknown $w ) {
                return fail
"$message\nFound array element $i which is unknown in 'have', not in 'want' ($w)";
            }
            next ELEMENT;
        }
        elsif ( looks_like_number($h) ) {
            if ( looks_like_number($w) && $h == $w ) {
                next ELEMENT;
            }
            return fail
"$message\nArrays began differing at elemement $i: Got '$h', expected '$w'";
        }
        else {
            if ( $h eq $w ) {
                next ELEMENT;
            }
            return fail
"$message\nArrays began differing at elemement $i: Got '$h', expected '$w'";
        }
    }
    return pass $message;
}

1;

__END__

=head1 NAME

UnknownUtils

=head1 SYNOPSIS

    use UnknownUtils 'array_ok';
    array_ok \@have, \@want, $message;

=head1 DESCRIPTION

Test2 is great, but is_deepl() tries to do some unoverloading of objects and
eventually some of our unknown values throw fatal exceptions when they're
stringified. Thus, our own test utilities.
