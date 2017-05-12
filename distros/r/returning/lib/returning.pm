package returning;

use 5.006;
use strict;
no warnings;

BEGIN {
	$returning::AUTHORITY = 'cpan:TOBYINK';
	$returning::VERSION   = '0.002';
}

use Carp            1.01    qw( croak );
use Scalar::Util    1.11    qw( set_prototype );
use Scope::Upper    0.16    qw( :all );
use Sub::Install    0.900   qw( install_sub reinstall_sub );
use Sub::Name       0.03    qw( subname );

sub import
{
	my $class = shift;
	my $default_target = caller;
	
	foreach my $arg (@_)
	{
		if (ref $arg eq 'HASH')
		{
			my $target = $arg->{-into} || $default_target;
			foreach my $func (keys %$arg)
			{
				next unless $func =~ /^[^\W\d]\w*$/;
				
				my $v    = $arg->{$func};
				my $code = ('CODE' eq ref $v) ? $v : sub(){$v if $]};
				
				install_sub {
					code  => subname("$target\::$func", $code),
					into  => $target,
					as    => $func,
				};
				
				$class->setup_for($target, $func);
			}
		}
		
		elsif ($arg =~ /^[^\W\d]\w*$/)
		{
			$class->setup_for($default_target, $arg);
		}
		
		else
		{
			croak "unrecognised import argument to returning: $arg";
		}
	}
}

sub setup_for
{
	my ($class, $target, $func) = @_;
	
	my $orig_code = do
	{
		no strict 'refs';
		\&{"$target\::$func"};
	};
	
	my $new_code = sub
	{
		my $cx   = SUB UP;
		my $want = want_at $cx;
		my @result;
		if ($want)
			{ @result = &uplevel($orig_code, @_, $cx) }
		elsif (defined $want)
			{ @result = scalar &uplevel($orig_code, @_, $cx) }
		else 
			{ &uplevel($orig_code, @_, $cx); @result = undef }
		unwind @result => $cx;
	};
	
	&set_prototype(
		$new_code,
		prototype($orig_code),
	)
		if defined prototype($orig_code);
	
	reinstall_sub {
		code  => subname("$target\::$func", $new_code),
		into  => $target,
		as    => $func,
	};
}

__PACKAGE__
__END__

=head1 NAME

returning - define subs that act like C<return>

=head1 SYNOPSIS

	use Test::Simple tests => 1;
	
	use returning {
		Yes   => 1,
		No    => 0,
	};
	
	sub beats_sissors
	{
		local $_ = shift;
		No  if /paper/i;
		Yes if /rock/i;
		No  if /scissors/;
	}
	
	ok beats_scissors("rock");

=head1 DESCRIPTION

The C<returning> module allows you to define subs which act like C<return>.
That is, they break out of their caller sub. In the SYNPOSIS example, the
C<< /scissors/i >> regexp is never even evaluated because the C<Yes>
statement breaks out of the the sub, returning "1". The C<beats_scissors>
function could have alternatively been written as:

	sub beats_sissors
	{
		local $_ = shift;
		return 0 if /paper/i;
		return 1 if /rock/i;
		return 0 if /scissors/;
	}

C<returning> may be especially useful for domain-specific languages.

=head2 Usage

There are three ways to define a returning sub using this module:

	use returning { subname => 'value' };

This creates the sub in the caller's namespace called C< subname > with
an empty prototype. (So when calling the sub, you don't need to use
parentheses; just like with L<constant> subs, but without as much
optimization.)

	use returning { subname => sub { ... } }

This installs the provided sub into the caller's namespace. This allows
you to define non-constant subs, including subs that take parameters and
do interesting stuff with them.

	BEGIN {
		sub subname { ... }
	};
	use returning 'subname'; # look, no hashref!

This does not install any sub into the caller's namespace, but modifies an
existing sub to act in a returning way. Note that because C<use> operates
at compile time, you need to take a lot of care to ensure that the sub has
already been defined.

These can be combined, a la...

	use constant ZeroButTrue => '0E0';
	use returning 'ZeroButTrue', {
		Affirm   => !!1,
		Deny     => !!0,
		Mu       => sub { return; },
	}

=head2 Implementation Notes

My first stab at this used L<Devel::Declare>, but I couldn't quite get it
working, and nobody in C<< #devel-declare >> seemed sure why it was not. It
seems possible that the ability to do this lies slightly beyond what
L<Devel::Declare> is capable of.

Instead L<Scope::Upper> has been used to create wrappers which jump up one
more subroutine than expected when they return. This means that some of the
magic happens at run-time rather than compile-time, so it perhaps executes
slightly slower, but probably compiled slightly faster.

An advantage of L<Scope::Upper> is that you can re-export your C<returning>
subs to other packages with no problem, and they'll continue to have their
special behaviour with no extra effort.

A feature I had been hoping to achieve with L<Devel::Declare> would be for
calling a sub with an ampersand (C<< &Affirm() >>) to act as a way of avoiding
the magic behaviour. This has not been possible with L<Scope::Upper>.

=head2 Class Method

=over

=item C<< returning->setup_for($package, $subname) >>

Given the package name and subname of an I<existing> sub, sets up the magic.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=returning>.

=head1 SEE ALSO

C<Scope::Upper> takes care of most of the black magic.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 CREDITS

Thanks OSFAMERON, Matt S Trout (MSTROUT), and Ash Berlin (ASH), for
helping me through some of the tricky bits.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

