=pod

=encoding utf-8

=head1 PURPOSE

Check Test::Modern's C<object_ok> function seems to work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;

BEGIN {
	package XXX;
	sub xxx { 1 }
	$INC{'XXX.pm'} = __FILE__;
};

BEGIN {
	package YYY;
	our @ISA = 'XXX';
	sub yyy { 2 }
	$INC{'YYY.pm'} = __FILE__;
};

*UNIVERSAL::DOES = \&UNIVERSAL::isa
	unless exists(&UNIVERSAL::DOES);

my $return = object_ok(
	sub { bless [], 'YYY' },
	'$y',
	isa   => 'YYY',
	does  => [qw/ XXX YYY /],
	can   => [qw/ xxx /],
	api   => [qw/ xxx yyy /],
	clean => 1,
	more  => sub {
		my $object = shift;
		is($object->xxx, 1);
		is($object->yyy, 2);
	},
);

isa_ok($return, 'YYY', '$return');

done_testing;
