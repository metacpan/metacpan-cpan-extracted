package autobox::List::Util;

use warnings;
use strict;

use base 'autobox';

sub import {
	my $class = shift;
	$class->SUPER::import(ARRAY => 'autobox::List::Util::_private');
}

package autobox::List::Util::_private;

use strict;
use warnings;
use Module::Load;

sub first {
	load List::Util;
	my ($self, $coderef) = @_;
	return List::Util::first { $coderef->() } @$self
}

sub max {
	load List::Util;
	my $self = shift;
	return List::Util::max @$self
}

sub maxstr {
	load List::Util;
	my $self = shift;
	return List::Util::maxstr @$self
}

sub min {
	load List::Util;
	my $self = shift;
	return List::Util::min @$self
}

sub minstr {
	load List::Util;
	my $self = shift;
	return List::Util::minstr @$self
}

sub reduce {
	load List::Util;
	my ($self, $coderef) = @_;
	return List::Util::reduce {
		#FIXME: this needs to know the package we are exporting to
		local ($main::a, $main::b) = ($a, $b);
		$coderef->();
	} @$self
}

sub shuffle {
	load List::Util;
	my $self = shift;
	return List::Util::shuffle @$self if wantarray;
	return [ List::Util::shuffle @$self ];
}

sub sum {
	load List::Util;
	my $self = shift;
	return List::Util::sum @$self
}

package autobox::List::Util;

=head1 NAME

autobox::List::Util - bring the List::Util functions to autobox

=head1 VERSION

Version 20090629

=cut

our $VERSION = '20090629';

=head1 SYNOPSIS

C<autobox::List::Util> brings all of the functions from List::Util
to arrays as methods. 

    use autobox::List::Util;

    my @array = qw/ foo bar baz /;

    print @array->first(sub { /ar/ }), "\n"; # "bar"

    print [5, 6, 3, 4]->max, "\n"; # 6

    print @array->maxstr, "\n"; # baz
    
    print [5, 6, 3, 4]->min, "\n"; # 3

    print @array->minstr, "\n"; # foo

    print [1 .. 10]->shuffle, "\n"; #1 to 10 randomly shuffled

    print [1 .. 10]->sum, "\n"; # 55

    print [1 .. 10]->reduce( sub { $a + $b } ), "\n"; # 55

=head1 METHODS

=head2 first(coderef) 

This method behaves nearly the same as the first function from List::Util,
but it takes a coderef not a block because methods can't use prototypes.

=head2 reduce(coderef)

This method behaves nearly the same as the reduce function from List::Util,
but it takes a coderef not a block for the same reason.  It also has a bug
(see L<BUGS>)

=head2 shuffle

If called in scalar context it returns a reference to an array instead
of a list.  This allows shuffle to be chained with other calls.

=head2 max, maxstr, min, minstr, sum

These methods behave exactly the same as their List::Util counterparts.

=head1 AUTHOR

Chas. J. Owens IV, C<< <chas.owens at gmail.com> >>

=head1 BUGS

The reduce method works with $main::a and $main::b, not your current
package's $a and $b, so you need to say

    print @array->reduce( sub { $main::a + $main::b } ), "\n";

if you are not in the main package.  Reduce uses $_, so it doesn't
suffer from this problem.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc autobox::List::Util


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=autobox-List-Util>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/autobox-List-Util>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/autobox-List-Util>

=item * Search CPAN

L<http://search.cpan.org/dist/autobox-List-Util/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Chas. J. Owens IV, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of autobox::List::Util
