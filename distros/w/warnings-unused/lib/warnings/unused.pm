package warnings::unused;

use 5.008_001;

use strict;

our $VERSION = '0.06';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub import{
	shift;
	if(@_){
		_set_mode(@_); # '-global' or '-lexical'
	}

	$^H |= 0x00020000; # HINT_LOCALIZE_HH
	$^H{(__PACKAGE__)} = 1;

	return;
}

1;
__END__

=head1 NAME

warnings::unused - Produces warnings when unused variables are detected

=head1 VERSION

This document describes warnings::unused version 0.06.

=head1 SYNOPSIS

	use warnings::unused; # installs the check routine as 'once'

	use warnings 'once';  # enables  the check routine
	# or
	use warnings;         # enables all warnings,
	                      # including this module

	sub foo{
		my($x, $y) = @_; # WARN: Unused variable my $x

		return $y * 2;
	}

	sub bar{
		my    $x; # WARN
		our   $y; # OK, it's global

		no warnings 'once';
		my $unused; # OK, the unused warnings are disabled
	}

	# Or from commmand line:
	# perl -Mwarnings::unused=-global -e 'use Foo'

=head1 DESCRIPTION

B<Note:> The author no longer maintain this module. Consider L<Test::Vars> if you detect unused vars as a unit test.

This pragmatic module extends lexical warnings to complain about unused
variables.

It produces warnings when a C<my> variable or C<state> variable is unused aside
from its declaration.

Given you write a subroutine like this:

	sub f{
		my($x, $y, $z) = @_;
		$y++;             # used
		return sub{ $z }; # used
	}

The code above will be complained about C<$x>, because it is used nowhere
aside from its declaration.

You should write C<f()> like this:

	sub f{
		my(undef, $y, $z) = @_;
		$y++;             # used
		return sub{ $z }; # used
	}

Here, one will see the obvious intention to ignore the first argument of
C<f()>.

The check routine works only at the compile time, so it affect nothing
about the run time.

=head1 INTERFACE

=head2 C<use warnings::unused> or C<use warnings::unused -lexical>

Installs the C<unused> check routine with lexical scope.

=head2 C<use warnings::unused -global>

Installs the C<unused> check routine with global scope,
where this pragma checks all programs.

=head2 C<use/no warnings 'once';>

Enables/Disables the C<unused> warnings.

Note that the C<once> warning is defined by default, so you can use it
anywhare, even if C<warnings::unused> is not loaded.

=head1 LIMITATIONS

This module cannot deal with cases where a variable appears only declared
but correctly used. For example:

	my $a = \my $used1;       # only its delcaration but used
	my $b = \do{ my $used2 }; # ditto.

And more complicated (and silly) cases:

	my $ref_to_foo_or_bar = \do{
		if(g()){
			my $foo;  # used if g() returns true.
		}
		else{
			my $bar; # used if g() returns false.
		}
	};

To avoid unexpected warnings, you can use the C<no warnings 'once'> directive.

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 SEE ALSO

L<perllexwarn>.

L<warnings::method>.

L<B::Lint>.

L<Perl::Critic>.

L<Perl::Critic::Policy::Variables::ProhibitUnusedVariables>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2009, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
