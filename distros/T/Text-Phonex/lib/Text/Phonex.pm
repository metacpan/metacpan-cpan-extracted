# -*- coding: UTF-8 -*-
package Text::Phonex;
use Carp;
use strict;
# $Id: Phonex.pm 429 2009-10-14 14:18:53Z gab $
BEGIN {
	use Exporter;
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK );
	@ISA=qw(Exporter);
	@EXPORT=qw( phonex );
	$VERSION='0.04';
	sub VERSION {
		(my $me, my $askedver)=@_;
		$VERSION=~s/(.*)_\d+/$1/;
		croak "Please update: $me is version $VERSION and you asked version $askedver" if ($VERSION < $askedver);
	}
}

#Origine : Algorithme Phonex de Frédéric BROUARD (31/3/99)
#Source : http://sqlpro.developpez.com/cours/soundex
#Version Python : Christian Pennaforte - 5 avril 2005
#Suite : Florent Carlier
#Perl version : Gabriel Guillon
sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self=\&phonex;
	bless $self, $class;
}
sub phonex {
	my $chaine=shift;
	my $precision=shift || 15;
	#0 On met la chaîne en majuscules, on vire les caractères parasites
	$chaine =~ tr/àâäãéèêëìîïòôöõùûüñ/AAAAYYYYIIIOOOOUUUN/;
	$chaine =~ s/[ -\.\+\*\/,:;_]//g;
	$chaine = uc($chaine);

	#1 remplacer les y par des i
	$chaine=~s/Y/I/g;

	#2 supprimer les h qui ne sont pas précédées de c ou de s ou de p
	$chaine =~ s/([^P|C|S])H/$1/g;

	#3 remplacement du ph par f
	$chaine=~s/PH/F/g;

	#4 remplacer les groupes de lettres suivantes :
	$chaine=~s/G(AI?[N|M])/K$1/g;

	#5 remplacer les occurrences suivantes, si elles sont suivies par une lettre a, e, i, o, ou u :
	$chaine =~ s/[A|E]I[N|M]([A|E|I|O|U])/YN$1/g;

	#6 remplacement de groupes de 3 lettres (sons 'o', 'oua', 'ein') :
	$chaine=~s/EAU/O/g;
	$chaine=~s/OUA/2/g;
	$chaine=~s/EIN/4/g;
	$chaine=~s/AIN/4/g;
	$chaine=~s/EIM/4/g;
	$chaine=~s/AIM/4/g;

	#7 remplacement du son É:
	$chaine=~s/É/Y/g; #CP : déjà fait en étape 0
	$chaine=~s/È/Y/g; #CP : déjà fait en étape 0
	$chaine=~s/Ê/Y/g; #CP : déjà fait en étape 0
	$chaine=~s/AI/Y/g;
	$chaine=~s/EI/Y/g;
	$chaine=~s/ER/YR/g;
	$chaine=~s/ESS/YS/g;
	$chaine=~s/ET/YT/g; #CP : différence entre la version Delphi et l'algo
	$chaine=~s/EZ/YZ/g;

	#8 remplacer les groupes de 2 lettres suivantes (son â..anâ.. et â..inâ..), sauf sâ..il sont suivi par une lettre a, e, i o, u ou un son 1 Ã  4 :
	$chaine=~s/AN([^A|E|I|O|U|1|2|3|4])/1$1/g;
	$chaine=~s/ON([^A|E|I|O|U|1|2|3|4])/1$1/g;
	$chaine=~s/AM([^A|E|I|O|U|1|2|3|4])/1$1/g;
	$chaine=~s/EN([^A|E|I|O|U|1|2|3|4])/1$1/g;
	$chaine=~s/EM([^A|E|I|O|U|1|2|3|4])/1$1/g;
	$chaine=~s/IN([^A|E|I|O|U|1|2|3|4])/4$1/g;

	#9 remplacer les s par des z sâ..ils sont suivi et prÃ©cÃ©dÃ©s des lettres a, e, i, o,u ou dâ..un son 1 Ã  4
	$chaine=~s/([A|E|I|O|U|Y|1|2|3|4])S([A|E|I|O|U|Y|1|2|3|4])/$1Z$2/g;
	#CP : ajout du Y Ã  la liste

	#10 remplacer les groupes de 2 lettres suivants :
	$chaine=~s/OE/E/g;
	$chaine=~s/EU/E/g;
	$chaine=~s/AU/O/g;
	$chaine=~s/OI/2/g;
	$chaine=~s/OY/2/g;
	$chaine=~s/OU/3/g; 

	#11 remplacer les groupes de lettres suivants
	$chaine=~s/CH/5/g;
	$chaine=~s/SCH/5/g;
	$chaine=~s/SH/5/g;
	$chaine=~s/SS/S/g;
	$chaine=~s/SC/S/g; #CP : problème pour PASCAL, mais pas pour PISCINE ?

	#12 remplacer le c par un s s'il est suivi d'un e ou d'un i
	#CP : à mon avis, il faut inverser 11 et 12 et ne pas faire la dernière ligne du 11
	$chaine=~s/C([E|I])/S$1/g;

	#13 remplacer les lettres ou groupe de lettres suivants :
	$chaine=~s/C/K/g;
	$chaine=~s/Q/K/g;
	$chaine=~s/QU/K/g;
	$chaine=~s/GU/K/g;
	$chaine=~s/GA/KA/g;
	$chaine=~s/GO/KO/g;
	$chaine=~s/GY/KY/g;

	#14 remplacer les lettres suivante :
	$chaine=~s/A/O/g;
	$chaine=~s/D/T/g;
	$chaine=~s/P/T/g;
	$chaine=~s/J/G/g;
	$chaine=~s/B/F/g;
	$chaine=~s/V/F/g;
	$chaine=~s/M/N/g;

	#15 Supprimer les lettres dupliquées
	my $oldc='#';
	my $newr='';
	foreach my $c (split(//,$chaine)) {
		$newr.=$c if ($oldc ne $c);
		$oldc=$c;
	}
	$chaine = $newr;

	#16 Supprimer les terminaisons suivantes : t, x
	$chaine=~s/(.*)[T|X]$/$1/g;

	#17 Affecter à chaque lettre le code numérique correspondant en partant de la dernière lettre
	my $num = '12345EFGHIKLNORSTUWXYZ';
	my @l;
	foreach my $c (split(//,$chaine)) {
		push @l, (index($num,$c));
	}
	#18 Convertissez les codes numériques ainsi obtenu en un nombre de base 22 exprimé en virgule flottante.
	my $res=0;
	my $i=1;
	foreach my $n (@l) {
		$res = $n*22**-$i+$res;
		$i++;
	}
	return sprintf("%.${precision}f",$res);
}
1;
