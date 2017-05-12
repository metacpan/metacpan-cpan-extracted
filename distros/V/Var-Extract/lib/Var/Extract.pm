package Var::Extract;
use strict; 
use warnings;
use PadWalker qw(var_name);

use base qw(Exporter);
our @EXPORT_OK = qw(vars_from_hash vars_from_getters);
our $VERSION = "0.02";

sub vars_from_hash {
	my $h = shift;
	for my $i (0..$#_) {
		my $key = var_name(1, \$_[$i]);
		ord($key) == ord('$') or die __PACKAGE__.": must be scalar!";
		$key = substr($key,1);
		$_[$i] = $h->{$key};
	}
}

sub vars_from_getters {
	my $prefix = shift;
	my $obj;
	if (ref $prefix) {
		$obj = $prefix;
		$prefix = "";
	} else {
		$obj = shift;
	}
	for my $i (0..$#_) {
		my $key = var_name(1, \$_[$i]);
		ord($key) == ord('$') or die __PACKAGE__.": must be scalar!";
		$key = $prefix . substr($key,1);
		$_[$i] = $obj->$key if ($obj->can($key))
	}
	
}
1;

__END__

=head1 NAME

Var::Extract - Assign lexical scalar values from container types

=head1 SYNOPSIS

	use Var::Extract qw(vars_from_hash vars_from_getters);
	use Class::Struct qw(struct);
	
	my $h = {
		foo => "This is foo",
		bar => "This is bar", 
		baz => "This is baz",
	};
	vars_from_hash($h, my ($foo,$bar,$baz));
	print "foo:$foo\nbar:$bar\nbaz:$baz\n";

	# => "foo: This is foo..."
	
	struct Klass => [attr0 => '$', attr1 => '$'];
	my $klass = Klass->new(attr0 => 42, attr1 => '666');
	vars_from_getters($klass, my ($everything, $evil));
	
	print "Everything is $everything, evil is $evil\n";
	# => "Everything is 42, evil is 666"
	
=head1 DESCRIPTION

Ever came across something like this?
	my $foo = $h->{foo};
	my $bar = $h->{bar};
	my $bas = $h->{baz};
	
or something worse:
	my ($foo,$bar,$baz) = @{$h}{qw(foo bar baz)};

One involves a lot of boilerplate, and the other involves being a pain to modify
especially with many variables. As a bonus point, you also get to type each
variable name twice.

=head2 FUNCTIONS

Var::Extract exports two functions on request:

=over

=item vars_from_hash(\%hash, $some, $variables, $here)

Will assign values of the keys of the hash which correspond to the names of the
variables passed. If a key is not found, the variable will remain undefined (
perhaps i should add a switch here to adjust this behavior, but that would
mess up the calling convention).

=item vars_from_getters($optional_prefix, $class, $vars....)

Does the same thing as L<vars_from_hash>, except that instead of using hash keys,
it uses Class::-style accessors

An optional $prefix may be provided in the first argument, which is useful in case
accessors are named as get_foo, then C<vars_from_getters("get_", $obj, my $foo)
will be assigned the value of $obj->get_foo

=back

=head1 COPYRIGHT

Copyright 2011 M. Nunberg for Dynamite Data
This module is dual licensed as GPL (v2 or higher) and "The same license as
Perl itself"

=head1 SEE ALSO

L<Hash::Extract>, which is similar to vars_from_hash
