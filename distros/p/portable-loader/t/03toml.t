=pod

=encoding utf-8

=head1 PURPOSE

Test loading from TOML.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use portable::alias 'Animals';

sub does_ok {
	my ($obj, $role) = @_;
	@_ = (
		$obj->DOES($role),
		"Object does role $role",
	);
	goto \&Test::More::ok;
}

for my $class (qw/Animal Panda Cat Dog Cow Pig/) {
	my $factory = lc "new_$class";
	can_ok(Animals, $factory);
	my $obj = Animals->$factory(name => "My $class");
	isa_ok($obj, Animals('Animal')->class);
	isa_ok($obj, Animals($class)->class) unless $class eq 'Animal';
	does_ok($obj, Animals('Pet')->role) if $class =~ /Cat|Dog/;
	does_ok($obj, Animals('Livestock')->role) if $class =~ /Cow|Pig/;
	does_ok($obj, Animals('Milkable')->role) if $class =~ /Cow/;
}

is(Animals("Cow")->class->VERSION, 1.2);

my $d = Animals("Cow")->new(name => 'Daisy');
is($d->name, 'Daisy', '$d->name');
is($d->status, 'alive', '$d->status');
is($d->milk, 'the white stuff', '$d->milk');

is($d->FACTORY, Animals, '$d->FACTORY');

my $e = exception {
	Animals->new_cow(age => 1);
};
like($e, qr/Missing required/, 'required attribute');

$e = exception {
	Animals->new_cow(name => 1, age => 'Daisy');
};
like($e, qr/type constraint/, 'type constraint');

is(Animals->new_cat(name => "Grey")->mew, "meow");

my $tom    = Animals->new_cat(name => 'Tom');
my $jerry  = Animals->new_mouse(name => 'Jerry');
is($tom->catch(victim => $jerry), 'Caught Jerry', 'method with signature works');

done_testing;

