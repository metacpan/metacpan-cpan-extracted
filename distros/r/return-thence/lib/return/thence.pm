package return::thence;

use 5.008;
use strict;
use warnings;

BEGIN {
	$return::thence::AUTHORITY = 'cpan:TOBYINK';
	$return::thence::VERSION   = '0.003';
}

use Scope::Upper qw( unwind CALLER );

sub return::thence
{
	my @caller = caller(my $i = 0);
	my $ctx = CALLER(0);
	while (my @level = caller(++$i)) {
		next if $level[1] ne $caller[1];  # filename
		last if $level[3] =~ /^$caller[0]\::(\w+)$/ && $1 ne '__ANON__' && ($ctx = CALLER $i);
	}
	unwind @_ => $ctx;
}

1
__END__

=head1 NAME

return::thence - return values from up above

=head1 SYNOPSIS

C<return> has a seemed inconsistency when used within functions that take a
code block, such as C<try> below.

	use Try::Tiny;
	
	# will return 1
	sub foo {
		try { return(2) };
		return 1;
	}
	
This module introduces a C<return::thence> keyword which returns from
where you really mean:

	# will return 2
	sub bar {
		try { return::thence(2) };
		return 1;
	}

=head1 DESCRIPTION

This module needs to perform a bit of guesswork to figure out where you want
to return from. Looking at the call stack, it returns from the first named
function (see L<Sub::Name>, L<Sub::Identify>) that was defined in the same
file and same package as its immediate caller.

C<return::thence> doesn't especially differentiate between list and scalar
context.

	sub baz { return::thence('a' .. 'z') };
	my @baz = baz()     # 'a' .. 'z'	
	my $baz = baz();    # 'z'

If you need more power, use L<Scope::Upper> which is what this module uses
under the hood.

=head1 BUGS

Skipping over XS stack frames can cause segfaults.

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=return-thence>.

=head1 SEE ALSO

L<Scope::Upper>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

