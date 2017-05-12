#!/usr/bin/env perl

BEGIN{ 
	@ARGV or
		push @ARGV, do { my $x = $0; $x =~ s{\.PL$}{};$x };
}
open STDOUT, ">$ARGV[0]~" or die "$ARGV[0]~: $!";

our $WARNS;
our $NOWARNS;
our $HINTS;
our %HINTS;

BEGIN {
	$HINTS = $^H;
	$WARNS = ${^WARNING_BITS};
	%HINTS = %^H;
}

use 5.010;
use strict;

no  warnings;
BEGIN {
	$NOWARNS = ${^WARNING_BITS};
}

use warnings qw(FATAL closed threads internal debugging pack substr malloc
                unopened portable prototype inplace io pipe unpack regexp
                deprecated exiting glob digit printf utf8 layer
                reserved parenthesis taint closure semicolon);
#use warnings qw(FATAL closed threads internal debugging pack substr malloc unopened portable prototype
#                inplace io pipe unpack regexp deprecated exiting glob digit printf
#                utf8 layer reserved parenthesis taint closure semicolon);
no  warnings qw(exec newline);

use feature ();

BEGIN {
	if ($^V >= 5.011) {
		feature->import( qw(say state switch unicode_strings) );
	} else {
		feature->import( qw(say state switch) );
	}
}

use utf8;
use open qw(:utf8 :std);
use mro 'c3';

BEGIN {
	$HINTS = $^H              & ~$HINTS;
	$WARNS = ${^WARNING_BITS} & ~( $WARNS // ("\0" x length ${^WARNING_BITS}) );
	my %h = %{^H};
	delete @h{ keys %HINTS };
	%HINTS = %h;
}

sub dumper($) {
	require Data::Dumper;
	my $s = Data::Dumper->new([@_])
			->Terse(1)
			->Indent(1)
			->Purity(0)
			->Useqq(1)
			->Quotekeys(0)
			->Dump;
	$s =~ s{\n+$}{}s;
	$s;
}

while (<DATA>) {
	if (/^SELFBEGIN/) {
		printf '	defined ${^WARNING_BITS}'."\n".
			'		?	${^WARNING_BITS} ^= ${^WARNING_BITS} ^ "%s"'."\n".
			'		:	${^WARNING_BITS} = "%s"'.";\n"
			,
			(join('', map "\\x$_", unpack "(H2)*", $WARNS))x2;
		printf "	\$^H |= 0x%x;\n\n", $HINTS;
	}
	elsif (/^IMPORT/) {
		print  "	# use warnings\n";
		printf '	${^WARNING_BITS} ^= ${^WARNING_BITS} ^ "%s";'."\n\n",
			join '', map "\\x$_", unpack "(H2)*", $WARNS;
		
		print  "	# use strict, utf8, open, 5.010, ...\n";
		printf "	\$^H |= 0x%x;\n\n", $HINTS;
		
		print  "	# use feature qw(@{[ keys %HINTS ]})\n";
		for (keys %HINTS) {
			print "	\$^H{'$_'} = ".dumper( $HINTS{$_}).";\n";
		}
		print "\n";
	}
	elsif (/^UNIMPORT/) {
		# TODO
		print  "	# no warnings\n";
		printf '	${^WARNING_BITS} = "%s";'."\n\n",
			join '', map "\\x$_", unpack "(H2)*", $NOWARNS;
		
		print  "	# no strict, utf8, open, 5.010, ...\n";
		printf "	\$^H &= ~0x%x;\n\n", $HINTS;
		
		print  "	# no feature qw(@{[ keys %HINTS ]})\n";
		for (keys %HINTS) {
			print "	delete \$^H{'$_'};\n";
		}
		print "\n";
	}
	else {
		print;
	}
}

close STDOUT;
rename "$ARGV[0]~", $ARGV[0];

__DATA__
package uni::perl;

our $VERSION = '0.92';

BEGIN {
SELFBEGIN
}
m{
use strict;
use warnings;
}x;
use mro ();

# paste this into perl to find bitmask

# no warnings;
# use warnings qw(FATAL closed threads internal debugging pack substr malloc unopened portable prototype
#                 inplace io pipe unpack regexp deprecated exiting glob digit printf
#                 utf8 layer reserved parenthesis taint closure semicolon);
# no warnings qw(exec newline);
# BEGIN { warn join "", map "\\x$_", unpack "(H2)*", ${^WARNING_BITS}; exit 0 };

BEGIN {
	for my $sub (qw(carp croak confess)) {
		no strict 'refs';
		*$sub = sub {
			my $caller = caller;
			local *__ANON__ = $caller .'::'. $sub;
			require Carp;
			*{ $caller.'::'.$sub } = \&{ 'Carp::'.$sub };
			goto &{ 'Carp::'.$sub };
		};
	}
}

sub import {
	my $me = shift;
	my $caller = caller;
	local $^W;
IMPORT
	# use mro 'c3';
	mro::set_mro($caller, 'c3');
	
	#use open (:utf8 :std);
	${^OPEN} = ":utf8\0:utf8";
	binmode(STDIN,   ":utf8");
	binmode(STDOUT,  ":utf8");
	binmode(STDERR,  ":utf8");
	
	for my $sub (qw(carp croak confess)) {
		no strict 'refs';
		*{ $caller .'::'. $sub } = \&$sub;
	}
	return if $caller =~ /^$me/;
	while (@_) {
		my $feature = shift;
		if ($feature =~ s/^://) {
			my $package = $me. '::'. $feature;
			eval "require $package; 1" or croak( "$@" );
			$package->load( $caller );
		}
	}
	require uni::perl::utf;
	uni::perl::utf->load($caller);
	return;
}

sub unimport {
	my $me = shift;
	my $caller = caller;
UNIMPORT
	${^OPEN} = ":raw\0:raw";
	binmode(STDIN,   ":raw");
	binmode(STDOUT,  ":raw");
	binmode(STDERR,  ":raw");
	return;
}

1;

__END__

=head1 NAME

uni::perl - all modern features + unicode support in one pragma

=head1 SYNOPSIS

There is most commonly used pragmas, such as L<strict>, L<feature>, L<warnings>, L<utf8>, L<open>, L<mro>. Also almost every modern program uses Encode and Carp

    use uni::perl;

    # is the same as

    use strict;
    use feature qw(say state switch);
    no warnings;
    use warnings qw(FATAL closed threads internal debugging pack substr malloc
                    unopened portable prototype inplace io pipe unpack regexp
                    deprecated exiting glob digit printf utf8 layer
                    reserved parenthesis taint closure semicolon);
    no warnings qw(exec newline);
    use utf8;
    use open (:utf8 :std);
    use mro 'c3';
    use Carp qw(carp croak confess);

    # With ':dumper' you got dumper() function, that similar to Data::Dumper::Dumper()
    use uni::perl ':dumper';

    # With ':xd' you got xd() function from Devel::Hexdump (if installed)
    use uni::perl ':xd';

=cut


=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 THANKS

Thanks to Marc Lehmann for useful hints, found in L<common::sense>

=head1 COPYRIGHT & LICENSE

Copyright 2009-2012 Mons Anderson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of uni::perl
