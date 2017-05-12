package enum::prefix;
use warnings;
use strict;
use 5.006;
our $VERSION = '0.04';

my $ident = '[^\W_0-9]\w*';

sub import
{
	my $class = shift;
	my $prefix = shift;
	my $name_sub_suffix = shift;
	@_ or return;

	my $pkg = caller() . '::';

	my $index = 0;

	my @enum;
	no strict 'refs';
	for my $name (@_)
	{
		if ( $name =~ /^$ident$/o )
		{
			my $n = $index;
			$index++;
			*{ $pkg . $prefix . $name } = sub(){ $n };
			$enum[$n] = $name;
		}
	}
	*{$pkg. $prefix . $name_sub_suffix } = sub($) { $enum[ $_[0] ] };
}

1;

__END__
=head1 NAME

enum::prefix

=head1 SYNOPSIS

	use enum::prefix BUG_ => qw(STATUS CLOSE FIXED REOPEN);
	# BUG_CLOSE = 0, BUG_FIXED = 1, BUG_REOPEN = 2;
	# BUG_STATUS(1) eq 'FIXED';

=head1 DESCRIPTION

This module is used to define a set of constanst with ordered numeric values,
and export a function for get the enum name by order, function name is the
concatenation of first two arguments.

=head1 SEE ALSO

There are a number of modules that can be used to define enumerations:
L<Class::Enum>, L<enum::fields>, L<enum::hash>, L<Readonly::Enum>,
L<Object::Enum>, L<Enumeration>.

=head1 AUTHOR

electricface

=cut
