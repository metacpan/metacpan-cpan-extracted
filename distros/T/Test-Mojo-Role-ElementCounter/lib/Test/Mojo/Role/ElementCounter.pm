package Test::Mojo::Role::ElementCounter;

use Mojo::Base -base;
use Encode;
use Carp qw/croak/;
use Role::Tiny;

our $VERSION = '1.001008'; # VERSION

has _counter_selector_prefix => '';

sub dive_in {
    my ( $self, $selector ) = @_;
    $self->_counter_selector_prefix(
        $self->_counter_selector_prefix . $selector
    );
}

sub dive_out {
    my ( $self, $remove ) = @_;

    $remove = qr/\Q$remove\E$/ unless ref $remove eq 'Regexp';
    $self->_counter_selector_prefix(
        $self->_counter_selector_prefix =~ s/$remove//r,
    );
}

sub dive_up {
    shift->dive_out(qr/\S+\s*$/);
}

sub dive_reset {
    shift->_counter_selector_prefix('');
}

sub dived_text_is {
    my $self = shift;
    my @in = @_; # can't modify in-place
    $in[0] = $self->_counter_selector_prefix . $in[0];

    # Since Mojolicious 7.0 stupidly decided to stop trimming whitespace,
    # we work around it by using text_like instead with a regex that
    # does exact match, but ignores trailing/leading whitespace
    $in[1] = qr/ ^ \s* \Q$in[1]\E \s* $ /x;
    $self->text_like( @in );
}

sub element_count_is {
    my ($self, $selector, $wanted_count, $desc) = @_;

    croak 'You gave me an undefined element count that you want'
        unless defined $wanted_count;

    my $pref = $self->_counter_selector_prefix;
    $selector = join ',', map "$pref$_", split /,/,$selector;

    $desc ||= encode 'UTF-8', qq{element count for selector "$selector"};
    my $operator = $wanted_count =~ tr/<//d ? '<'
        : $wanted_count =~ tr/>//d ? '>' : '==';

    my $count = $self->tx->res->dom->find($selector)->size;
    return $self->test('cmp_ok', $count, $operator, $wanted_count, $desc);
}


q|
<Zoffix> GumbyBRAIN, Q: What did the computer do at lunchtime?
    A: Had a byte!
<GumbyBRAIN> So even that's only one byte undefined in the
    thing I ever had. Where is beer the reason siv didn't walk straight.
|;

__END__

=encoding utf8

=for stopwords Znet Zoffix app  natively

=head1 NAME

Test::Mojo::Role::ElementCounter - Test::Mojo role that provides element count tests

=head1 SYNOPSIS

Say, we need to test our app produces exactly this markup structure:

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    <ul id="products">
        <li><a href="/product/1">Product 1</a></li>
        <li>
            <a href="/products/Cat1">Cat 1</a>
            <ul>
                <li><a href="/product/2">Product 2</a></li>
                <li><a href="/product/3">Product 3</a></li>
            </ul>
        </li>
        <li><a href="/product/2">Product 2</a></li>
    </ul>

    <p>Select a product!</p>

=for html  </div></div>

The test we write:

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    use Test::More;
    use Test::Mojo::WithRoles 'ElementCounter';
    my $t = Test::Mojo::WithRoles->new('MyApp');

    $t->get_ok('/products')
    ->dive_in('#products ')
        ->element_count_is('> li', 3)
        ->dive_in('li:first-child ')
            ->element_count_is('a', 1)
            ->dived_text_is('a[href="/product/1"]' => 'Product 1')
        ->element_count_is('+ li > a', 1)
            ->dived_text_is('+ li > a[href="/products/Cat1"]' => 'Cat 1')
        ->dive_in('+ li > ul ')
            ->element_count_is('> li', 2)
            ->element_count_is('a', 2)
            ->dived_text_is('a[href="/product/2"]' => 'Product 2')
            ->dived_text_is('a[href="/product/3"]' => 'Product 3')
        ->dive_out('> ul')
        ->element_count_is('+ li a', 1);
    ->dive_reset
    ->element_count_is('#products + p', 1)
    ->text_is('#products + p' => 'Select a product!')

    done_testing;

=for html  </div></div>

=head1 SEE ALSO

Note that as of L<Mojolicious> version 6.06,
L<Test::Mojo> implements the exact match
version of C<element_count_is> natively (same method name).
This role is helpful only if you need dive methods or ranges.

=head1 DESCRIPTION

A L<Test::Mojo> role that allows you to do strict element count tests on
large structures.

=head1 METHODS

You have all the methods provided by L<Test::Mojo>, plus these:

=head2 C<element_count_is>


  $t = $t->element_count_is('.product', 6, 'we have 6 elements');
  $t = $t->element_count_is('.product', '<6', 'fewer than 6 elements');
  $t = $t->element_count_is('.product', '>6', 'more than 6 elements');

Check the count of elements specified by the selector. Second argument
is the number of elements you expect to find. The number can be
prefixed by either C<< < >> or C<< > >> to specify that you expect to
find fewer than or more than the specified number of elements.

You can shorten the selector by using C<dive_in> to store a prefix.

=head2 C<dive_in>

    $t = $t->dive_in('#products > li ');

    $t->dive_in('#products > li ')
        ->dive_in('ul > li ')
        ->element_count_is('a', 6);
        # tests: #products > li > ul > li a

To simplify selectors when testing complex structures, you can tell
the module to remember the prefix portion of the selector with
C<dive_in>. Note that multiple calls are cumulative. Use
C<dive_out>, C<dive_up>, or C<dive_reset> to go up in dive level.

B<Note:> be mindful of the last space in the selector when diving.
C<< ->dive_in('ul')->dive_in('li') >> would result in C<ulli> selector,
not C<ul li>.

B<Note:> the selector prefix only applies to C<element_count_is> and
C<dived_text_is> methods. It does not affect operation of other
methods provided by L<Test::Mojo>

=head2 C<dive_out>

    $t = $t->dive_out('li');
    $t = $t->dive_out(qr/\S+\s+(li|a)\s+$/);

    $t->dive_in('#products li ')
        ->dive_out('li'); # we're now testing: #products

Removes a portion of currently stored selector prefix (see C<dive_in>).
Takes a string or a regex as the argument that specifies
what should be removed. If a string is given, it will be taken as a literal
match to remove from I<the end> of the stored selector prefix.

=head2 C<dive_up>

    # these two are equivalent
    $t = $t->dive_up;
    $t = $t->dive_out(qr/\S+\s*$/);

Takes no arguments. A shortcut for C<< ->dive_out(qr/\S+\s*$/) >>.

=head2 C<dive_reset>

    $t = $t->dive_reset;

Resets stored selector prefix to an empty string (see C<dive_in>).

=head2 C<dived_text_is>

    $t = $t->dive('#products li:first-child ')
        ->dived_text_is('a' => 'Product 1');

Same as L<Test::Mojo>'s C<text_is> method, except the selector will
be prefixed by the stored selector prefix (see C<dive_in>).

B<NOTE:> as of version 1.001006, L<Test::Mojo>'s C<text_like> will be used
with a regex constructed to be the exact match, with any amount of whitespace
before and after the string. This is done to workaround Mojolicious Donut
breaking its whitespace handling in Mojo::DOM and by extention Test::Mojo,
and leaving useless whitespace all over the place.

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/Test-Mojo-Role-ElementCounter>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/Test-Mojo-Role-ElementCounter/issues>

If you can't access GitHub, you can email your request
to C<bug-test-mojo-role-elementcounter at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
