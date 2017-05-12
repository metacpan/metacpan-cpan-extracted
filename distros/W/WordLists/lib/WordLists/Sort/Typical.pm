package WordLists::Sort::Typical;
use utf8;
use strict;
use warnings;
use Unicode::Normalize; #provides NFD
use WordLists::Sort qw( atomic_compare complex_compare);
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;
our $AUTOLOAD;
require Exporter;
our @ISA       = qw (Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(
	cmp_alnum
	cmp_alnum_only
	cmp_accnum
	cmp_accnum_only
	cmp_ver
	cmp_dict
);
sub _cmp { $_[0] cmp $_[1] };

sub cmp_dict
{
	my $norm_remove_the = sub{$_[0] =~ s/^the\s+//;$_[0];};
	complex_compare (
		$_[0], $_[1],
		{
			functions =>
			[
				{
					n => $norm_remove_the,
					t=>[
						{
							re=>qr/.+/,
							c => \&cmp_accnum_only,
						},
					],
				},
				{
					n => sub{&{$norm_remove_the}($_[0]); $_[0] =~ s/[^\p{Script: Latin}0-9]/ /g; $_[0] =~ s/[a-z\p{Lowercase}]/ /g; $_[0];},
					c => \&_cmp,
				},
				{
					n => $norm_remove_the,
					t=>[
						{
							re=>qr/.+/,
							c => \&cmp_alnum_only,
						},
					],
				},
				{
					n => sub{&{$norm_remove_the}($_[0]); $_[0] =~ s/[^\p{Script: Latin}0-9]/ /g; $_[0] =~ s/[a-zA-Z]/ /g; $_[0];},
					c => \&_cmp,
				},
				{
					n => sub{&{$norm_remove_the}($_[0]); $_[0] =~ s/[\P{Uppercase}]/ /g; $_[0];},
					c => \&_cmp,
				},
				{
					n => sub { &{$norm_remove_the}($_[0]); $_[0]=~ s/[^\p{Script: Latin}0-9]//g; $_[0];},
					c => \&_cmp,
				},
				{
					n => $norm_remove_the,
					t=>[
						{
							re=>qr/.+/,
							c => \&cmp_alpha,
						},
					],
				},
				{
					c => sub { ($_[0] =~ s/^the\s+//) cmp ($_[1] =~ s/^the\s+//) },
				},
			]
		}
	);
}

sub cmp_alnum
{
	atomic_compare (
		$_[0], $_[1],
		{
			n => sub { lc $_[0];},
			t =>
			[
				{
					re => qr/[0-9]+/, 
					c => sub { $_[0] <=> $_[1]; } 
				},
			],
		}
	);
}
sub cmp_alpha
{
	atomic_compare (
		$_[0], $_[1],
		{
			n => sub { lc $_[0];},
		}
	);
}
sub cmp_alnum_only
{
	atomic_compare (
		$_[0], $_[1],
		{
			n => sub {
				$_[0] =~ s/[^\p{Script: Latin}0-9]//g;
				$_[0];
			},
			t=>[
				{
					re=>qr/.+/,
					c => \&cmp_alnum,
				}
			],
		}
	);
}
sub cmp_accnum_only
{
	atomic_compare (
		$_[0], $_[1],
		{
			n => sub {
				$_[0] =~ s/[^\p{Script: Latin}0-9]//g;
				$_[0];
			},
			t=>[
				{
					re=>qr/.+/,
					c => \&cmp_accnum,
				}
			],
		}
	);
}
sub cmp_accnum
{
	atomic_compare (
		$_[0], $_[1],
		{
			n => sub {
				$_[0] = NFD ($_[0]);
				$_[0] =~ s/\pM//g;
				lc $_[0];
			},
			t =>
			[
				{
					re => qr/[0-9]+/, 
					c => sub { $_[0] <=> $_[1]; } 
				},
			],
		}
	);
}

sub cmp_ver # compares version strings: anything that is not alphanumeric is a separator and doesn't have any preference 
# 1.1 = 1:1
# 1.1.a < 1.1a < 1.1.1
{
	atomic_compare (
		$_[0], $_[1],
		{
			n => sub {$_[0] =~ s/^v//i; $_[0];},
			t =>
			[
				{
					re => qr/[0-9]+/, 
					c => sub { $_[0] <=> $_[1]; } 
				},
				{
					re => qr/[a-zA-Z]+/, 
					c => sub { lc $_[0] cmp lc $_[1]; } 
				},
				{
					re => qr/[^a-zA-Z0-9]+/,
					c => 0
				},


			],
		}
	);
}



1;


=pod

=head1 NAME

WordLists::Sort::Typical

=head1 SYNOPSIS

	'A14' cmp 'A2'; # sadly returns -1, so instead do this:
	use WordLists::Sort::Typical qw(cmp_alnum);
	cmp_alnum('A14', 'A2'); # returns 1

=head1 DESCRIPTION	

This provides functions for sorting text.

=head3 cmp_alnum

Compares alphanumeric values sensibly, e.g. "Unit 10" comes after "Unit 9", not before "Unit 2". Case-insensitive.

=head3 cmp_alnum_only

Compares alphanumeric values sensibly as C<cmp_alnum>, but ignores all values except alphanumeric characters, so "re-factor" sorts with "refactor", not between "re" and "react". Case-insensitive.

=head3 cmp_accnum

Compares alphanumeric values sensibly as C<cmp_alnum>, and considers accented characters to be equivalent to unaccented characters, so "café" sorts with "cafe", not after "caftan".

=head3 cmp_accnum_only

Compares alphanumeric values sensibly and accent-insensitively as C<cmp_accnum>, and ignores non-alphanumeric content like C<cmp_alnum_only>

=head3 cmp_ver

Compares version numbers sensibly, even if they are of the form "v1.0028_01a".

=head3 cmp_dict

This uses a C<complex_sort>, the first stage being C<cmp_accnum_only>. Strings which are still equal are progressively sorted with tie-breakers so that order is reliable. Strings beginning "the " are sorted identically, except at the end, when strings without "the " have preference.

=over

=item *

Case - uppercase comes after lowercase.

=item *

Accents - uppercase comes after lowercase.

=item *

Non-alphanumeric characters - these are sorted, ignoring other intervening characters.

=item *

Definite article - if the strings are otherwise identical, a string beginning "the " comes after a string not beginning "the "

=back

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
