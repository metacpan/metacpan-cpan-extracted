package unconstant;
use Sub::Util ();
use warnings;

use constant ();
my $constant_import;
my $installed;

BEGIN { $constant_import = \&constant::import };

use 5.020;
use strict;
use warnings;

our $VERSION = '0.09';

our %declared;

#=======================================================================

# Some names are evil choices.
my %keywords = map +($_, 1), qw{ BEGIN INIT CHECK END DESTROY AUTOLOAD UNITCHECK };

my %forced_into_main = map +($_, 1),
    qw{ STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG };

my %forbidden = (%keywords, %forced_into_main);

my $normal_constant_name = qr/^_?[^\W_0-9]\w*\z/;
my $tolerable = qr/^[A-Za-z_]\w*\z/;
my $boolean = qr/^[01]?\z/;

sub unconstant_import {
	return if $installed;
	*constant::import = *constant_import;
	$installed = 1;
}

sub unconstant_unimport {
	return unless $installed;
	no warnings 'redefine';
	*constant::import = $constant_import;
	$installed = 0;
}

sub constant_import {

	my $caller = caller();
	my $package = shift;
	my $flush_mro;
	return unless @_;
	my $multiple  = ref $_[0];

	my $constants;
	if ( $multiple ) {
		if ($multiple ne 'HASH') {
			require Carp;
			Carp::croak("Invalid reference type '".ref(shift)."' not 'HASH'");
		}
		$constants = shift;
	}
	else {
		unless (defined $_[0]) {
			require Carp;
			Carp::croak("Can't use undef as constant name");
		}
		$constants->{+shift} = undef;
	}


	my $symtab;
	{
		no strict 'refs';
		$symtab = \%{$caller . "::"};
	}

	foreach my $name ( keys %$constants ) {
		my $pkg = $caller;
		my $symtab = $symtab;
		my $orig_name = $name;

		if ($name =~ s/(.*)(?:::|')(?=.)//s) {
			$pkg = $1;
			if ($pkg ne $caller) {
				no strict 'refs';
				$symtab = \%{$pkg . '::'};
			}
		}

		# Normal constant name
		if ($name =~ $normal_constant_name and !$forbidden{$name}) {
			# Everything is okay
		}
		
		# Name forced into main, but we're not in main. Fatal.
		elsif ($forced_into_main{$name} and $pkg ne 'main') {
			require Carp;
			Carp::croak("Constant name '$name' is forced into main::");
		}
		
		# Starts with double underscore. Fatal.
		elsif ($name =~ /^__/) {
			require Carp;
			Carp::croak("Constant name '$name' begins with '__'");
		}
		
		# Maybe the name is tolerable
		elsif ($name =~ $tolerable) {
			# Then we'll warn only if you've asked for warnings
			if (warnings::enabled()) {
				if ($keywords{$name}) {
					warnings::warn("Constant name '$name' is a Perl keyword");
				} elsif ($forced_into_main{$name}) {
					warnings::warn("Constant name '$name' is " .
					"forced into package main::");
				}
			}
		}

		# Looks like a boolean
		# use constant FRED == fred;
		elsif ($name =~ $boolean) {
			require Carp;
			if (@_) {
				Carp::croak("Constant name '$name' is invalid");
			}
			else {
				Carp::croak("Constant name looks like boolean value");
			}
		}
		else {
			# Must have bad characters
			require Carp;
			Carp::croak("Constant name '$name' has invalid characters");
		}

		no strict 'refs';
		my $full_name = "${pkg}::$name";

		# This is required to fool namespace::autoclean
		my $const_name = "constant::$name";

		$declared{$full_name}++;
		if ($multiple || @_ == 1) {
			my $scalar = $multiple ? $constants->{$orig_name} : $_[0];

			#$symtab->{$name} = sub () { $scalar };
			{
				no warnings;
				*$full_name = Sub::Util::set_prototype( '', Sub::Util::set_subname("constant::$name", sub { $scalar } ) );
			}
			++$flush_mro->{$pkg};
		}
		elsif (@_) {
			my @list = @_;
			{
				no warnings;
				*$full_name = Sub::Util::set_prototype( '', Sub::Util::set_subname("constant::$name", sub { @list } ) );
			}
			$flush_mro->{$pkg}++;
		}
		else {
			die 'should never hit this';
		}
	}
	# Flush the cache exactly once if we make any direct symbol table changes.
	if ($flush_mro) {
		mro::method_changed_in($_) for keys %$flush_mro;
	}
}


{
	no warnings;
	*import   = \&unconstant_import;
	*unimport = \&unconstant_unimport;
}


1;

__END__

=head1 NAME

unconstant - sometimes you need to un- em'.

=head1 DESCRIPTION

This module provides an alternative implementation of L<constant>. This
implementation stops perl from inlining the constant, stops constant folding,
and stops dead code removal.

This is supremely useful for testing where a package internally declares and
uses a constant that you want to change. This is common when wanting to test
modules that make use of constants.

B<Note: this module does I<NOT> stop `use` from hoisting the statement to the top.>

=head1 SYNOPSIS

	# Disable constant optimizations in my_test
	perl -Munconstant ./my_test.pl

	package MyTest {
		use constant BAR => 7;
		sub baz { BAR }
	}

	# All of these will change the return of `MyTest::baz()`
	package main {
		use constant *MyTest::BAR => 42;
		use constant "MyTest::BAR" => 42;
		*MyTest::BAR = sub { 42 };
		*MyTest::BAR = sub () { 42 };
	}

=head1 AUTHOR

Evan Carroll, C<< <me at evancarroll.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-unconstant at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=unconstant>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc unconstant

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=unconstant>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/unconstant>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/unconstant>

=item * Search CPAN

L<https://metacpan.org/release/unconstant>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Evan Carroll.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of unconstant
