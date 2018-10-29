package Test2::Tools::PDL;

# ABSTRACT: Test2 tools for verifying Perl Data Language piddles

use strict;
use warnings;

our $VERSION = '0.0001'; # VERSION

use Safe::Isa;
use Scalar::Util qw(blessed);
use Test2::API qw(context);
use Test2::Compare qw(compare strict_convert);
use Test2::Compare::Float;
use Test2::Tools::Compare qw(within string);
use Test2::Util::Table qw(table);
use Test2::Util::Ref qw(render_ref);

use parent qw/Exporter/;
our @EXPORT = qw(pdl_ok pdl_is);

our $TOLERANCE = $Test2::Compare::Float::DEFAULT_TOLERANCE;


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
    unless ( $got->$_DOES('PDL') ) {
        $ctx->ok( 0, $name, ["First argument '$gotname' is not a piddle."] );
        $ctx->release;
        return 0;
    }
    unless ( $exp->$_DOES('PDL') ) {
        my $expname = render_ref($exp);
        $ctx->ok( 0, $name, ["Second argument '$expname' is not a piddle."] );
        $ctx->release;
        return 0;
    }

    my $exp_class = ref($exp);
    unless ( $got->$_DOES($exp_class) ) {
        $ctx->ok( 0, $name,
            ["'$gotname' does not match the expected type '$exp_class'."] );
        $ctx->release;
        return 0;
    }

    my $is_numeric = !( $exp->type eq 'byte' or $exp->$_DOES('PDL::SV') );

    my $delta = compare( $got->unpdl, $exp->unpdl,
        sub { convert( $_[0], $is_numeric ) } );

    if ($delta) {
        $ctx->ok( 0, $name, [ $delta->table, @diag ] );
    }
    else {
        $ctx->ok( 1, $name );
    }

    $ctx->release;
    return !$delta;
}

sub convert {
    my ( $check, $is_numeric ) = @_;

    if ( not ref($check) ) {
        if ($is_numeric) {
            return within( $check, $TOLERANCE );
        }
        else {
            return string($check);
        }
    }
    return strict_convert(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::PDL - Test2 tools for verifying Perl Data Language piddles

=head1 VERSION

version 0.0001

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

Default is same as C<$Test2::Compare::Float::DEFAULT_TOLERANCE>, which is
C<1e-8>.

    $Test2::Tools::PDL::TOLERANCE = 0.01;

=head1 SEE ALSO

L<PDL>, L<Test2::Suite>, L<Test::PDL>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
