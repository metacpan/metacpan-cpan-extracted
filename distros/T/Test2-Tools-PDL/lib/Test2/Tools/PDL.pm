package Test2::Tools::PDL;

# ABSTRACT: Test2 tools for verifying Perl Data Language piddles

use 5.010;
use strict;
use warnings;

our $VERSION = '0.0002'; # VERSION

use PDL::Core;
use PDL::Lite;
use PDL::Primitive qw(which);
use PDL::Types;
use Safe::Isa;
use Scalar::Util qw(blessed);
use Test2::API qw(context);
use Test2::Compare qw(compare strict_convert convert);
use Test2::Compare::Float;
use Test2::Tools::Compare qw(number within string);
use Test2::Util::Table qw(table);
use Test2::Util::Ref qw(render_ref);

use parent qw/Exporter/;
our @EXPORT = qw(pdl_ok pdl_is);

use constant DEFAULT_TOLERANCE => $Test2::Compare::Float::DEFAULT_TOLERANCE;
our $TOLERANCE = DEFAULT_TOLERANCE;


sub pdl_ok {
    my ( $thing, $name ) = @_;
    my $ctx = context();

    unless ( $thing->$_DOES('PDL') ) {
        my $thingname = render_ref($thing);
        $ctx->ok( 0, $name, ["'$thingname' is not a piddle."] );
        $ctx->release;
        return 0;
    }

    $ctx->ok( 1, $name );
    $ctx->release;
    return 1;
}


sub pdl_is {
    my ( $got, $exp, $name, @diag ) = @_;
    my $ctx = context();

    my $gotname = render_ref($got);
    unless ( $got->$_isa('PDL') ) {
        $ctx->ok( 0, $name, ["First argument '$gotname' is not a piddle."] );
        $ctx->release;
        return 0;
    }
    unless ( $exp->$_isa('PDL') ) {
        my $expname = render_ref($exp);
        $ctx->ok( 0, $name, ["Second argument '$expname' is not a piddle."] );
        $ctx->release;
        return 0;
    }

    my $exp_class = ref($exp);
    if ( ref($got) ne $exp_class ) {
        $ctx->ok( 0, $name,
            ["'$gotname' does not match the expected type '$exp_class'."] );
        $ctx->release;
        return 0;
    }

    # compare dimensions
    my @exp_dims   = $exp->dims;
    my @got_dims   = $got->dims;
    my $delta_dims = compare( \@got_dims, \@exp_dims, \&strict_convert );

    if ($delta_dims) {
        $ctx->ok( 0, $name,
            [ $delta_dims->table, 'Dimensions do not match', @diag ] );
        $ctx->release;
        return 0;
    }

    # compare isbad
    my $both_bad;
    if ( $got->badflag or $exp->badflag ) {
        my $delta_isbad =
          compare( $got->isbad->unpdl, $exp->isbad->unpdl, \&strict_convert );

        if ($delta_isbad) {
            $ctx->ok(
                0, $name,
                [
                    $delta_isbad->table, 'Bad value patterns do not match',
                    @diag
                ]
            );
            $ctx->release;
            return 0;
        }

        $both_bad = ( $got->isbad & $exp->isbad );
    }

    # Compare data values.
    # 
    # Here we directly compare the $got and $exp's unpdl via standard
    # Test2::Compare::Array, this way is slower but does not require the
    # effort for diag message. Another possible approach would be checking
    # if ($got == $exp) has all ones, but that needs further generating
    # the diag message ourselves.
    my $is_numeric = !( $exp->type eq 'byte' or $exp->$_DOES('PDL::SV') );
    my $converter_scalar = !$is_numeric
        ? \&string : ( $got->type < PDL::float and $exp->type < PDL::float )
        ? \&number 
        : sub { within( $_[0], $TOLERANCE ) } ;

    my $delta_equal  = compare( $got->unpdl, $exp->unpdl,
            gen_convert->($both_bad, $converter_scalar) );
    if ($delta_equal) {
        $ctx->ok( 0, $name,
            [ $delta_equal->table, 'Values do not match', @diag ] );
    }
    else {
        $ctx->ok( 1, $name );
    }

    $ctx->release;
    return !$delta_equal;
}

sub gen_convert {
    my ($both_bad, $converter_scalar) = @_;

    unless (defined $both_bad) {
        return sub {
            my ($check) = @_;

            if ( not ref($check) ) {
                return $converter_scalar->(@_);
            } else {
                return strict_convert(@_);
            }
        };
    }

    # pdl dimensions is in reversion to array
    if ( $both_bad->ndims > 1 ) {
        $both_bad = $both_bad->transpose;
    }

    # Have a state in the subroutine, so it knows which indices to ignore.
    return sub {
        my ($check) = @_;

        unless ( defined $check and ref($check) eq 'ARRAY' ) {
            return strict_convert($check);
        }

        # get number of dimensions of $check
        my $check_ndims = 0;
        my $tmp         = $check;
        while ( defined $tmp and ref($tmp) eq 'ARRAY' ) {
            $check_ndims += 1;
            $tmp = $tmp->[0];
        }

        state $indices = [ (-1) x $both_bad->ndims ];

        my $indices_idx = $both_bad->ndims - $check_ndims - 1;
        if ( $indices_idx < $#$indices ) {

            # reset indices of later dimensions
            for ( $indices_idx + 1 .. $#$indices ) {
                $indices->[$_] = -1;
            }
        }
        $indices->[$indices_idx] += 1;

        # implicit_end has be 0 as otherwise it fails in case bad is at end
        # of piddle.
        my $converted = convert( $check,
            { implicit_end => 0, use_regex => 0, use_code => 0 } );

        # last dimension
        if ( $indices_idx == $both_bad->ndims - 2 ) {
            my $order =
                $indices_idx >= 0
              ? $both_bad->index( @$indices[ 0 .. $indices_idx ] )
              : $both_bad;
            $order = which( !$order )->unpdl;
            $converted->set_order($order);
        }

        return $converted;
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::PDL - Test2 tools for verifying Perl Data Language piddles

=head1 VERSION

version 0.0002

=head1 SYNOPSIS

    use Test2::Tools::PDL;

    # Functions are exported by default.
    
    # Ensure something is a piddle.
    pdl_ok($x);

    # Compare two piddles.
    pdl_is($got, $expected, 'Same piddle.');

=head1 FUNCTIONS

=head2 pdl_ok($thing, $name)

Checks that the given C<$thing> is a L<PDL> object.

=head2 pdl_is($got, $exp, $name);

Checks that piddle C<$got> is same as C<$exp>.

Now this method is internally similar as
C<is($got-E<gt>unpdl, $exp-E<gt>unpdl)>. It's possible to work with both
numeric PDLs as well as non-numeric PDLs (like L<PDL::Char>, L<PDL::SV>).

=head1 DESCRIPTION 

This module contains tools for verifying L<PDL> piddles.

=head1 VARIABLES

This module can be configured by some module variables.

=head2 TOLERANCE

Defaultly it's same as C<$Test2::Compare::Float::DEFAULT_TOLERANCE>, which
is C<1e-8>. For piddle of float types piddles the tolerance is applied for
comparison.

    $Test2::Tools::PDL::TOLERANCE = 0.01;

You can set this variable to 0 to force exact numeric comparison. For
example,

    {
        local $Test2::Tools::PDL::TOLERANCE = 0;
        ...
    }

=head1 SEE ALSO

L<PDL>, L<Test2::Suite>, L<Test::PDL>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
