package oEdtk::TexTag;

our $VERSION = '0.08';
my $_FLAG_DIGITS = 1;


# A SIMPLE OBJECT THAT DESCRIBES A TEX TAG.
sub new {
	my ($class, $name, $val) = @_;

	my $ref = ref($val);
	if ($ref ne '' && $ref ne 'ARRAY' && $ref ne 'HASH' && $ref ne 'oEdtk::TexDoc') {
		die "ERROR: Unexpected value type, must be a scalar or an oEdtk::TexDoc object\n";
	}

	if ($name =~ /\d/ && $_FLAG_DIGITS) {
		warn "INFO : Tex Tag name cannot contain digits : $name !\n";
		warn "INFO : further messages for Tex Tag containing digits will be ignored\n";
		$_FLAG_DIGITS = 0;
	}

	my $self = {
		name 	=> $name,
		value 	=> $val
	};
	bless $self, $class;
#	warn "INFO : objet TexTag $self créé...\n";
	return $self;
}


sub emit {
	my ($self) = @_;

	if (defined $self->{'name'} &&  $self->{'name'}=~/^_include_$/){
		return "\\input{" . $self->{'value'} . "\}";
	}
	
	# A tag containing a scalar value or an HASH/ARRAY/TexDoc object.
	if (defined $self->{'value'}) {
		my $ref = ref($self->{'value'});
		my $name = $self->{'name'};
		# A list of values.
		if ($ref eq 'ARRAY') {
			my $macro = "\\edListNew{$self->{'name'}}";
			foreach (@{$self->{'value'}}) {
#				my $val = escape($_);
				my $val = oEdtk::TexDoc::escape($_); # NOT CLEAN ! 
#				warn "INFO : Appel à oEdtk::Doc::escape dans TexTag $val\n";
				$macro .= "\\edListAdd{$self->{'name'}}{$val}";
			}
			return $macro;
		}

		# A tag containing other tags.
		my $value = $self->{'value'};
		if ($ref eq 'HASH') {
			my $inner = oEdtk::TexDoc->new();
			while (my ($key, $val) = each %{$self->{'value'}}) {
				$inner->append($key, $val);
			}
			$value = $inner;
		}

		# Escape if we have a scalar value.
		if (ref($value) eq '') {
			$value =~ s/\s+/ /g;
#			$value = escape($value);
			$value = oEdtk::TexDoc::escape($value);
#			warn "INFO : Appel à oEdtk::Doc::escape dans TexTag $value\n";
		}

		return "\\long\\gdef\\$name\{$value\}";
	}
	# A command call.
	return "\\$self->{'name'}";
}


use oEdtk::Config (config_read);
use oEdtk::Dict;
my $_CFG		= config_read();
# ON OUVRE LE DICTIONNAIRE EN STATIQUE POUR ÉVITER LES ACCÈS MULTIPLES AU FICHIER CORRESPONDANT
my $_DICO_CHAR	= oEdtk::Dict->new($_CFG->{'EDTK_DICO_XLAT'}, , { section => 'LATEX' });

# http://woufeil.developpez.com/tutoriels/perl/poo/
sub escape_0 { # NOT CLEAN passer par l'héritage ! TexTag->TexDoc
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
#	warn "INFO : \$_DICO_CHAR = $_DICO_CHAR\n";
# xxx la ligne qui suit provoque une erreur après la fin de programme
#	$new = $_DICO_CHAR->substitue($new);

	# \\"{} => PROVOQUE DES ERREURS TEX DANS LE PROCESSUS D'INDEXATION (POUR INJECTION EN SGBD)
	$new =~ s/\\\"\{\}/\\textquotestraightdblbase{}/g;
	$new =~ s/\\\"/\\textquotestraightdblbase{}/g;
	# 01...@A...yz{}|~ 1°
	return $new;
}


#END {
#	undef $_DICO_CHAR;
#	undef $_CFG;
#	warn "INFO : Objet TexTag supprimé !\n";
#}

1;