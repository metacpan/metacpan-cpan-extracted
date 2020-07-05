package Test2::Tools::PDL;

# ABSTRACT: Test2 tools for verifying Perl Data Language piddles

use 5.010;
use strict;
use warnings;

our $VERSION = '0.0005'; # VERSION

use PDL::Lite ();
use PDL::Primitive qw(which);
use PDL::Types;

use Safe::Isa;
use Scalar::Util qw(blessed);
use Test2::API 1.302175 qw(context);
use Test2::Compare 0.000130 qw(compare strict_convert);
use Test2::Util::Table qw(table);
use Test2::Util::Ref qw(render_ref);

use parent qw/Exporter/;
our @EXPORT = qw(pdl_ok pdl_is);

our $TOLERANCE     = $Test2::Compare::Float::DEFAULT_TOLERANCE;
our $TOLERANCE_REL = 0;


sub pdl_ok {
    my ( $thing, $name ) = @_;
    my $ctx = context();

    unless ( $thing->$_isa('PDL') ) {
        my $thingname = render_ref($thing);
        $ctx->fail( $name, "'$thingname' is not a piddle." );
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
        $ctx->fail( $name, "First argument '$gotname' is not a piddle." );
        $ctx->release;
        return 0;
    }
    unless ( $exp->$_isa('PDL') ) {
        my $expname = render_ref($exp);
        $ctx->fail( $name, "Second argument '$expname' is not a piddle." );
        $ctx->release;
        return 0;
    }

    my $exp_class = ref($exp);
    if ( ref($got) ne $exp_class ) {
        $ctx->fail( $name,
            "'$gotname' does not match the expected type '$exp_class'." );
        $ctx->release;
        return 0;
    }

    # compare dimensions
    my @exp_dims   = $exp->dims;
    my @got_dims   = $got->dims;
    my $delta_dims = compare( \@got_dims, \@exp_dims, \&strict_convert );

    if ($delta_dims) {
        $ctx->fail( $name, 'Dimensions do not match', $delta_dims->diag,
            @diag );
        $ctx->release;
        return 0;
    }

    # compare isbad
    my $both_bad;
    if ( $got->badflag or $exp->badflag ) {
        my $delta_isbad =
          compare( $got->isbad->unpdl, $exp->isbad->unpdl, \&strict_convert );

        if ($delta_isbad) {
            $ctx->fail( $name, 'Bad value patterns do not match',
                $delta_isbad->diag, @diag );
            $ctx->release;
            return 0;
        }

        $both_bad = ( $got->isbad & $exp->isbad );
    }

    # Compare data values.
    my $diff;
    my $is_numeric = !(
        List::Util::any { $exp->$_isa($_) }
        qw(PDL::SV PDL::Factor PDL::DateTime) or $exp->type eq 'byte'
    );
    eval {
        if ( $is_numeric
            and ( $exp->type >= PDL::float or $got->type >= PDL::float ) )
        {
            $diff = ( ( $got - $exp )->abs >
                  $TOLERANCE + ( $TOLERANCE_REL * $exp )->abs );
        }
        else {
            $diff = ( $got != $exp );
        }
        if ( $exp->badflag ) {
            $diff->where( $exp->isbad ) .= 0;
        }
    };
    if ($@) {
        my $gotname = render_ref($got);
        $ctx->fail( $name, "Error occurred during values comparison.",
            $@, @diag );
        $ctx->release;
        return 0;
    }
    my $diff_which = which($diff);
    unless ( $diff_which->isempty ) {
        state $at = sub {
            my ( $p, @position ) = @_;
            if ( $p->isa('PDL::DateTime') ) {
                return $p->dt_at(@position);
            }
            else {
                return $p->at(@position);
            }
        };

        my $gotname = render_ref($got);
        my @table   = table(
            sanitize  => 1,
            max_width => 80,
            collapse  => 1,
            header    => [qw(POSITION GOT CHECK)],
            rows      => [
                map {
                    my @position = $exp->one2nd($_);
                    [
                        join( ',', @position ),
                        $at->( $got, @position ),
                        $at->( $exp, @position )
                    ]
                } @{ $diff_which->unpdl }
            ]
        );
        $ctx->fail( $name, "Values do not match.", join( "\n", @table ),
            @diag );
        $ctx->release;
        return 0;
    }

    $ctx->ok( 1, $name );
    $ctx->release;
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::PDL - Test2 tools for verifying Perl Data Language piddles

=head1 VERSION

version 0.0005

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

=head2 pdl_is($got, $exp, $name)

Checks that piddle C<$got> is same as C<$exp>.

Now this method is internally similar as
C<is($got-E<gt>unpdl, $exp-E<gt>unpdl)>. It's possible to work with both
numeric PDLs as well as non-numeric PDLs (like L<PDL::Char>, L<PDL::SV>).

=head1 DESCRIPTION 

This module contains tools for verifying L<PDL> piddles.

=head1 VARIABLES

This module can be configured by some module variables.

=head2 TOLERANCE, TOLERANCE_REL

These two variables are used when comparing float piddles. For
C<pdl_is($got, $exp, ...)>, the effective tolerance is
C<$TOLERANCE + abs($TOLERANCE_REL * $exp)>.

Default value of C<$TOLERANCE> is same as
C<$Test2::Compare::Float::DEFAULT_TOLERANCE>, which is C<1e-8>.
Default value of C<$TOLERANCE_REL> is 0.

For example, to use only relative tolerance,

    {
        local $Test2::Tools::PDL::TOLERANCE = 0;
        local $Test2::Tools::PDL::TOLERANCE_REL = 1e-6;
        ...
    }

=head1 SEE ALSO

L<PDL>, L<Test2::Suite>, L<Test::PDL>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Mohammad S Anwar

Mohammad S Anwar <manwar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2020 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
