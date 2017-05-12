package Test::Mojo::Role::TestDeep;
# ABSTRACT: Add Test::Deep methods to Test::Mojo::WithRoles
$Test::Mojo::Role::TestDeep::VERSION = '0.007';

use strict;
use warnings;
use Role::Tiny;
use Test::More;
use Test::Deep qw( cmp_deeply );


sub json_deeply {
    my ( $t, $ptr, $expect, $desc ) = @_;

    # Pointer is an optional argument
    if ( @_ < 4 && !ref $expect ) {
        $desc = $expect;
        $expect = $ptr;
        $ptr = '';
    }

    die "expected value should be a data structure or Test::Deep test object, not a simple scalar (did you mean to use json_is()?)"
        if !ref $expect;

    $desc ||= qq{deeply match JSON Pointer "$ptr"};

    my $given = $t->tx->res->json( $ptr );

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $result = cmp_deeply( $given, $expect, $desc )
        or diag "Got JSON: ", explain $given;
    return $t->success( $result );
}


sub text_deeply {
    my ( $t, $sel, $expect, $desc ) = @_;
    $desc ||= qq{deeply match text for "$sel"};
    my @given = $t->tx->res->dom->find( $sel )->map( 'text' )->each;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $result = cmp_deeply( \@given, $expect, $desc )
        or diag "Got text: \n", explain \@given;
    return $t->success( $result );
}


sub all_text_deeply {
    my ( $t, $sel, $expect, $desc ) = @_;
    $desc ||= qq{deeply match all text for "$sel"};
    my @given = $t->tx->res->dom->find( $sel )->map( 'all_text' )->each;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $result = cmp_deeply( \@given, $expect, $desc )
        or diag "Got text: \n", explain \@given;
    return $t->success( $result );
}



sub attr_deeply {
    my ( $t, $sel, @args ) = @_;
    my $desc = qq{deeply match attributes for "$sel"};
    if ( @args % 2 == 1 ) {
        $desc = pop @args;
    }
    my %expect = @args;

    my %given;
    for my $elem ( $t->tx->res->dom->find( $sel )->each ) {
        for my $attr ( keys %expect ) {
            push @{ $given{ $attr } }, $elem->attr( $attr );
        }
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $result = cmp_deeply( \%given, \%expect, $desc )
        or diag "Got attrs: \n", explain \%given;
    return $t->success( $result );
}

1;

__END__

=pod

=head1 NAME

Test::Mojo::Role::TestDeep - Add Test::Deep methods to Test::Mojo::WithRoles

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Test::Mojo::WithRoles 'TestDeep';
    use Test::Deep; # Get Test::Deep comparison functions

    my $t = Test::Mojo::WithRoles->new( 'MyApp' );

    # Test JSON responses with Test::Deep
    $t->get_ok( '/data.json' )
      ->json_deeply(
        superhashof( { foo => 'bar' } ),
        'has at least a foo key with "bar" value',
      );

    # Test HTML with Test::Deep
    $t->get_ok( '/index.html' )
      ->text_deeply(
        'nav a',
        [qw( Home Blog Projects About Contact )],
        'nav link text matches site section titles',
      )
      ->attr_deeply(
        'nav a',
        href => [qw( / /blog /projects /about /contact )],
        'nav link href matches site section URLs',
      );

=head1 DESCRIPTION

This module adds some L<Test::Deep> functionality to L<Test::Mojo>.
C<Test::Deep> allows for extremely-customizable testing of data
structures. This module adds some helper methods to C<Test::Mojo> (using
L<Test::Mojo::WithRoles>) to test your web app's responses using
C<Test::Deep>.

=head1 METHODS

=head2 json_deeply

    $t->json_deeply( $expect, $desc )
    $t->json_deeply( $ptr, $expect, $desc )

Test that the current response (parsed as a JSON object) matches the given
tests. C<$expect> is a data structure containing L<Test::Deep
comparisons|Test::Deep/SPECIAL COMPARISONS PROVIDED> to run. C<$desc> is an
optional description of the test.

If given, C<$ptr> is a JSON pointer string to pick out a single part of the
data structure. This is more convenient than using Test::Deep's comparison
routines to do the same thing. See L<Mojo::JSON::Pointer>.

Corresponds to L<cmp_deeply in Test::Deep|Test::Deep/COMPARISON FUNCTIONS>.

=head2 text_deeply

    $t->text_deeply( $selector => $expect, $desc );

Test the text of the elements matched by the given C<$selector> against
the given test. C<$expect> is a data structure containing L<Test::Deep
comparisons|Test::Deep/SPECIAL COMPARISONS PROVIDED> to run. C<$desc> is
an optional description of the test.

The elements will always be an arrayref, even if only one
element matches.

For example:

    # test.html
    <nav>
        <ul>
            <li><a href="/">Home</a></li>
            <li><a href="/blog">Blog</a></li>
            <li><a href="/projects">Projects</a></li>
        </ul>
    </nav>

    # test.t
    $t->get_ok( 'test.html' )
      ->text_deeply(
        'nav a' => bag( qw( Home Blog Projects ) ),
        'nav element text is correct',
      );

This is equivalent to:

    $t->get_ok( 'test.html' );
    my $dom = $t->tx->res->dom;
    cmp_deeply
        [ $dom->find( 'nav a' )->map( 'text' )->each ],
        bag( qw( Home Blog Projects ) ),
        'nav element text is correct';

=head2 all_text_deeply

    $t->all_text_deeply( $selector => $expect, $desc );

Test the complete text of the elements and all child elements matched by
the given C<$selector> against the given test. C<$expect> is a data
structure containing L<Test::Deep comparisons|Test::Deep/SPECIAL
COMPARISONS PROVIDED> to run. C<$desc> is an optional description of the
test.

The elements will always be an arrayref, even if only one
element matches.

For example:

    # test.html
    <nav>
        <ul>
            <li><a href="/"><em>Home</em></a></li>
            <li><a href="/blog">Blog</a></li>
            <li><a href="/projects"><strong>Projects</strong></a></li>
        </ul>
    </nav>

    # test.t
    $t->get_ok( 'test.html' )
      ->all_text_deeply(
        'nav a' => bag( qw( Home Blog Projects ) ),
        'nav element text is correct',
      );

This is equivalent to:

    $t->get_ok( 'test.html' );
    my $dom = $t->tx->res->dom;
    cmp_deeply
        [ $dom->find( 'nav a' )->map( 'all_text' )->each ],
        bag( qw( Home Blog Projects ) ),
        'nav element text is correct';

=head2 attr_deeply

    $t->attr_deeply( $selector, $attr => $expect, ..., $desc );

Test the given attributes of the elements matched by the given selector
against the given test. C<$expect> is a data structure containing
L<Test::Deep comparisons|Test::Deep/SPECIAL COMPARISONS PROVIDED> to
run. C<$desc> is an optional description of the test.

The element attributes will always be an arrayref, even if only one
element matches.

For example:

    # test.html
    <form action="/search" method="GET">
        ...
    </form>

    # test.t
    $t->get_ok( 'test.html' )
      ->attr_deeply(
        'form',
        action => [qw( /search )],
        method => [re( qr( get )i )],
        'form element is correct',
      );

This is equivalent to:

    $t->get_ok( 'test.html' );
    my $dom = $t->tx->res->dom;
    cmp_deeply
        [ $dom->find( 'form' )->map( attr => 'action' )->each ],
        [ qw( /search ) ],
        'form element action is correct',
        ;
    cmp_deeply
        [ $dom->find( 'form' )->map( attr => 'method' )->each ],
        [ re( qr( get )i ) ],
        'form element method is correct',
        ;

=head1 SEE ALSO

=over 4

=item L<Test::Deep>

=item L<Test::Mojo>

=item L<Test::Mojo::WithRoles>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Doug Bell

Doug Bell <madcityzen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
