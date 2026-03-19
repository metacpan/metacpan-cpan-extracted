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

# 1. Simple particle surname
{
	my $r = canon("Jean de Gaulle", locale => 'fr_FR');
	is_deeply $r->{parts}{surname}, ["de", "gaulle"], "de Gaulle surname";
}

# 2. Multi-token particle cluster
{
	my $r = canon("Charles de la Tour", locale => 'fr_FR');
	is_deeply $r->{parts}{surname}, ["de", "la", "tour"], "de la Tour surname";
}

# 3. Apostrophe particle (d')
{
	my $r = canon("Jean d'Ormesson", locale => 'fr_FR');
	is_deeply $r->{parts}{surname}, ["d'", "ormesson"], "d'Ormesson surname";
}

# 4. Apostrophe particle (l')
{
	my $r = canon("Pierre L'Enfant", locale => 'fr_FR');
	is_deeply $r->{parts}{surname}, ["l'", "enfant"], "L'Enfant surname";
}

# 5. Hyphenated given name
{
	my $r = canon("Jean-Luc Picard", locale => 'fr_FR');
	is_deeply $r->{parts}{given}, ["jean-luc"], "hyphenated given name";
	is_deeply $r->{parts}{surname}, ["picard"], "simple surname";
}

# 6. Title stripping
{
	my $r = canon("M. Jean de Gaulle", locale => 'fr_FR');
	is $r->{canonical}, "jean de gaulle", "title stripped";
}

done_testing;
