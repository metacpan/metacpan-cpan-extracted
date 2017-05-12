use 5.008004;
use strict;
use warnings;

package warnings::MaybeFatal;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

BEGIN {
	if ( $] < 5.012 ) {
		require Lexical::SealRequireHints;
		Lexical::SealRequireHints->import;
	}
};

use B::Hooks::EndOfScope;
use Carp qw(croak);

BEGIN {
	B::Hooks::EndOfScope->Module::Implementation::implementation_for eq 'XS'
		or croak("Pure Perl implementation of B::Hooks::EndOfScope not supported");
};

sub _my_hints
{
	$^H |= 0x20000;
	\%^H;
}

sub import
{
	_my_hints->{+__PACKAGE__} = 1;
	
	# Keep original signal handler
	my $orig = $SIG{__WARN__};
	if (!ref($orig))
	{
		$orig = ($orig eq 'DEFAULT' or $orig eq 'IGNORE')
			? undef
			: do {
				no strict 'refs';
				exists(&{'main::'.$orig}) ? \&{'main::'.$orig} : undef;
			};
		$orig = sub { warn(@_) } unless defined $orig;
	}
	
	my @warnings;
	$SIG{__WARN__} = sub {
		_my_hints->{+__PACKAGE__}
			? push(@warnings, $_[0])
			: $orig->(@_);
	};
	
	on_scope_end {
		$SIG{__WARN__} = $orig;
		if (@warnings == 1)
		{
			die($warnings[0]);
		}
		elsif (@warnings)
		{
			$orig->($_) for @warnings;
			local $Carp::CarpLevel = $Carp::CarpLevel + 1;
			croak("Compile time warnings");
		}
	};
}

sub unimport
{
	_my_hints->{+__PACKAGE__} = 0;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

warnings::MaybeFatal - make warnings FATAL at compile-time only

=head1 SYNOPSIS

   use strict;
   use warnings qw(all);
   use warnings::MaybeFatal;
   
   # Use of uninitialized value.
   # Run-time warning, so this is non-fatal.
   print join(undef, "a", "b");
   
   # Useless use of constant in void context.
   # Compile-time warning, so this is fatalized.
   "Hello world"; 1;

=head1 DESCRIPTION

Because it's kind of annoying if a warning stops your program from
being compiled, but it's I<really> annoying if it breaks your program
part way through actually executing.

This lexically scoped pragma will make all warnings (including custom
warnings emitted with the C<warn> keyword) FATAL during compile time.
It does not enable or disable any warnings in its own right. It just
makes any warnings that happen to be enabled FATAL during the compile.

(Note that the compile phase and execute phase are not as cleanly
divided in Perl as they are in, say, C. If module X loads module Y at
run-time, then module Y's compile time happens during module X's
run-time. In this situation, a warning that is triggered while
compiling Y will be FATAL, even though from module X's perspective,
this is at run-time.)

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=warnings-MaybeFatal>.

=head1 SEE ALSO

L<warnings>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

