package Tie::Scalar::Sticky;

use strict;
use warnings;
our $VERSION = '1.13';

use Symbol;
use Tie::Scalar;
use base 'Tie::StdScalar';

sub TIESCALAR {
    my $class = shift;
    my $self = *{gensym()};
    @$self = ('',@_);
    return bless \$self, $class;
}

sub STORE {
    my($self,$val) = @_;
    return unless defined $val;
    $$$self = $val unless grep $val eq $_, @$$self;
}

sub FETCH {
    my $self = shift;
    return $$$self;
}

sub DESTROY {
    my $self = shift;
    undef $$$self;
}

qw(jeffa);

=pod

=head1 NAME

Tie::Scalar::Sticky - Just another scalar assignment blocker.

=head1 SYNOPSIS

 use strict;
 use Tie::Scalar::Sticky;

 tie my $sticky, 'Tie::Scalar::Sticky';

 $sticky = 42;
 $sticky = '';       # still 42
 $sticky = undef;    # still 42
 $sticky = 0;        # now it's zero

 tie my $sticky, 'Tie::Scalar::Sticky' => qw/ foo bar /;

 $sticky = 42;
 $sticky = 'foo';    # still 42
 $sticky = 'bar';    # still 42
 $sticky = 0;        # now it's zero

=head1 DESCRIPTION

Scalars tie'ed to this module will 'reject' any assignments
of undef or the empty string or any of the extra arugments
provided to C<tie()>. It simply removes the need for
you to validate assignments, such as:

 $var = $val unless grep $val eq $_, qw(not one of these);

Actually, that is the exact idea used in this module ...

So, why do this? Because i recently had to loop through a
list where some items were undefined and the previously
defined value should be used instead. In a nutshell:

 tie my $sticky, 'Tie::Scalar::Sticky' => 9, 'string';
 for (3,undef,'string',2,'',1,9,0) {
    $sticky = $_;
    print $sticky, ' ';
 }

should print: 3 3 2 2 1 0

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to either

=over 4

=item * Email: C<bug-tie-scalar-sticky at rt.cpan.org>

=item * Web: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Scalar-Sticky>

=back

I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 GITHUB

The Github project is L<https://github.com/jeffa/Tie-Scalar-Sticky>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::Scalar::Sticky

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here) L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Scalar-Sticky>

=item * AnnoCPAN: Annotated CPAN documentation L<http://annocpan.org/dist/Tie-Scalar-Sticky>

=item * CPAN Ratings L<http://cpanratings.perl.org/d/Tie-Scalar-Sticky>

=item * Search CPAN L<http://search.cpan.org/dist/Tie-Scalar-Sticky>

=back

=head1 AUTHOR 

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 CREDITS 

Dan Brook added support for user-defined strings by changing
C<$self> to a glob. His patch was applied to Version 1.02
verbatim, i later 'simplified' the code by assuming that
undef and the empty strings (the only two items Version
1.00 will block) are already waiting inside C<@$$self>.
Dan then removed undef from C<@$$self>, and i added a simple
check that returns from C<STORE> unless C<$val> is defined.

=head1 COPYRIGHT

Copyright 2017 Jeff Anderson.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
