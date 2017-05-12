package oEdtk::TexDoc;
our $VERSION = 0.7004;

use base 'oEdtk::Doc';
use oEdtk::Config (config_read);
use oEdtk::Dict;
use oEdtk::TexTag;

use strict;
use warnings;


sub mktag {
	my ($self, $name, $value) = @_;

	return oEdtk::TexTag->new($name, $value);
}


sub append_table {
	my ($self, $name, @values) = @_;

	$self->append($name, \@values);
}


sub line_break {
	return "%\n";
}


my $_CFG		= config_read();
# ON OUVRE LE DICTIONNAIRE EN STATIQUE POUR ÉVITER LES ACCÈS MULTIPLES AU FICHIER CORRESPONDANT
my $_DICO_TEX_CHAR	= oEdtk::Dict->new($_CFG->{'EDTK_DICO_XLAT'}, , { section => 'LATEX' });

# http://woufeil.developpez.com/tutoriels/perl/poo/
sub escape {
	my $str = shift;
	# ESCAPE SPECIAL CARACTERS FOR TEXTAGS

	# Deal with backslashes and curly braces first and at the same
	# time, because escaping backslashes introduces curly braces, and,
	# inversely, escaping curly braces introduces backslashes.
	# see http://detexify.kirelabs.org/classify.html
	my $new = '';
	foreach my $s (split(/([{}\\])/, $str)) {
		if ($s eq "{") {
			$new .= "\\textbraceleft{}";
		} elsif ($s eq "}") {
			$new .= "\\textbraceright{}";
		} elsif ($s eq "\\") {
			$new .= "\\textbackslash{}";
		} else {
			$new .= $s;
		}
	}
	$new =~s/([%&\$_#])/\\$1/g;
	# warn "DEBUG : \$_DICO_TEX_CHAR = $_DICO_TEX_CHAR\n";
	$new = $_DICO_TEX_CHAR->substitue($new);

	# \\"{} => PROVOQUE DES ERREURS TEX DANS LE PROCESSUS D'INDEXATION (POUR INJECTION EN SGBD)
	$new =~ s/\\\"\{\}/\\textquotestraightdblbase{}/g;
	$new =~ s/\\\"/\\textquotestraightdblbase{}/g;
	# 01...@A...yz{}|~ 1°
	return $new;
}


1;