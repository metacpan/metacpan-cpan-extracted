use strict;
use warnings;
use utf8;
use Test::Most;

use_ok 'Text::Names::Canonicalize';

sub canon {
	Text::Names::Canonicalize::canonicalize_name_struct(
		@_,
		strip_diacritics => 1,
	);
}

# 1. American suffixes
{
	my $r = canon("John Smith Esq", locale => 'en_US');
	is_deeply $r->{parts}{suffix}, ["esq"], "esq recognized as suffix";
}

{
	my $r = canon("Mary Jones PhD", locale => 'en_US');
	is_deeply $r->{parts}{suffix}, ["phd"], "phd recognized as suffix";
}

# 2. American titles
{
	my $r = canon("Rev John Smith", locale => 'en_US');
	is $r->{canonical}, "john smith", "Rev stripped";
}

{
	my $r = canon("Hon Jane Doe", locale => 'en_US');
	is $r->{canonical}, "jane doe", "Hon stripped";
}

# 3. Hyphens still preserved
{
	my $r = canon("Mary-Anne Smith-Jones", locale => 'en_US');
	is_deeply $r->{parts}{surname}, ["smith-jones"], "hyphen surname preserved";
}

# 4. Initials still work
{
	my $r = canon("J R R Tolkien", locale => 'en_US');
	is_deeply $r->{parts}{middle}, ["r","r"], "initials handled";
}

done_testing;
