package Thread::Task::Concurrent::Util;

use warnings;
use strict;

use threads::shared;

use Scalar::Util qw/refaddr reftype blessed/;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.01';

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(unshared_clone);

my ($make_unshared);

# neary 1 to 1 copied from threads::shared
sub unshared_clone {
    if ( @_ != 1 ) {
        require Carp;
        Carp::croak('Usage: shared_clone(REF)');
    }

    return $make_unshared->( shift, {} );
}

$make_unshared = sub {
    my ( $item, $cloned ) = @_;

    # Just return the item if:
    # 1. Not a ref;
    # 2. NOT shared; or
    # 3. Not running 'threads'.
    return $item if ( !ref($item) || !$threads::threads );

    # Check for previously cloned references
    #   (this takes care of circular refs as well)
    my $addr;
    if(is_shared($item)) {
        $addr = "s_" . is_shared($item);
    } else {
        $addr = "r_" . refaddr($item);
    }

    if ( exists( $cloned->{$addr} ) ) {
        # Return the already existing clone
        return $cloned->{$addr};
    }

    # Make copies of array, hash and scalar refs and refs of refs
    my $copy;
    my $ref_type = reftype($item);

    # Copy an array ref
    if ( $ref_type eq 'ARRAY' ) {
        # Make empty shared array ref
        $copy = [];
        # Add to clone checking hash
        $cloned->{$addr} = $copy;
        # Recursively copy and add contents
        push( @$copy, map { $make_unshared->( $_, $cloned ) } @$item );
    }

    # Copy a hash ref
    elsif ( $ref_type eq 'HASH' ) {
        # Make empty shared hash ref
        $copy = {};
        # Add to clone checking hash
        $cloned->{$addr} = $copy;
        # Recursively copy and add contents
        foreach my $key ( keys( %{$item} ) ) {
            $copy->{$key} = $make_unshared->( $item->{$key}, $cloned );
        }
    }

    # Copy a scalar ref
    elsif ( $ref_type eq 'SCALAR' ) {
        $copy = \do { my $scalar = $$item; };
        # Add to clone checking hash
        $cloned->{$addr} = $copy;
    }

    # Copy of a ref of a ref
    elsif ( $ref_type eq 'REF' ) {
        # Special handling for $x = \$x
        if ( $addr == is_shared($$item) ) {
            $copy = \$copy;
            $cloned->{$addr} = $copy;
        } else {
            my $tmp;
            $copy = \$tmp;
            # Add to clone checking hash
            $cloned->{$addr} = $copy;
            # Recursively copy and add contents
            $tmp = $make_unshared->( $$item, $cloned );
        }

    } else {
        require Carp;
        Carp::croak( "Unsupported ref type: ", $ref_type );
    }

    # If input item is an object, then bless the copy into the same class
    if ( my $class = blessed($item) ) {
        bless( $copy, $class );
    }

    # Clone READONLY flag
    if ( $ref_type eq 'SCALAR' ) {
        if ( Internals::SvREADONLY($$item) ) {
            Internals::SvREADONLY( $$copy, 1 ) if ( $] >= 5.008003 );
        }
    }
    if ( Internals::SvREADONLY($item) ) {
        Internals::SvREADONLY( $copy, 1 ) if ( $] >= 5.008003 );
    }

    return $copy;
};

1;

__END__

=head1 NAME

Thread::Task::Concurrent::Util - utility functions for threads::shared

=head1 SYNOPSIS

    use Thread::Task::Concurrent::Util qw(unshared_clone);

    $unshared_var = unshared_clone($shared_var);

=head1 DESCRIPTION

L<Thread::Task::Concurrent::Util> provides utility functions for L<threads::shared>.

=head1 SUBROUTINES

=over 4

=item B<< unshared_clone REF >>

C<unshared_clone> takes a reference, and returns a B<UN>shared version of its
argument, performing a deep copy on any shared elements.  Any unshared
elements in the argument are used as is (i.e., they are not cloned).

  my $cpy = shared_clone({'foo' => [qw/foo bar baz/]});

  my $unshared_cpy = unshared_clone($cpy);

Object status (i.e., the class an object is blessed into) is also cloned.
  my $obj = {'foo' => [qw/foo bar baz/]};
  bless($obj, 'Foo');
  my $cpy = shared_clone($obj);

  my $unshared_cpy = unshared_clone($cpy);

This functionality comes in extremely handy for serialization purposes with
e.g. L<YAML::XS>. L<YAML::XS> is not able to serialize shared variables with
nested structures.

=back

=cut

=head1 SEE ALSO

L<threads::shared>, L<YAML::XS>

=head1 AUTHOR

jw bargsten, C<< <cpan at bargsten dot org> >>

=head1 ACKNOWLEDGEMENTS

Thanks to the authors of the module L<threads::shared> form which the code was
borrowed.

=head1 LICENSE

Thread::Task::Concurrent::Util is released under the same license as Perl.

=cut
