# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-GaleChurch.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 18;
#use Test::More 'no_plan';
BEGIN { use_ok('Text::GaleChurch') };

#########################

can_ok('Text::GaleChurch',qw(align));
my $eScalar = 1;
my $fScalar = 1;
my ($eAlignedRef,$fAlignedRef); 
($eAlignedRef,$fAlignedRef) = Text::GaleChurch::align($eScalar,$fScalar);
ok(!defined($eAlignedRef),"Scalar first parameter returns undefined value");
ok(!defined($fAlignedRef),"Scalar second parameter returns undefined value");

my @eParagraph = ();
my @fParagraph = ();
($eAlignedRef,$fAlignedRef) = Text::GaleChurch::align(\@eParagraph,\@fParagraph);
is(@{$eAlignedRef},@{$fAlignedRef},"Length of returned arrays equivalent");
is(@{$eAlignedRef},0,"Empty list first parameter returns empty list");
is(@{$fAlignedRef},0,"Empty list second parameter returns empty list");

push @eParagraph, "According to our survey, 1988 sales of mineral water and soft drinks were much higher than in 1987, reflecting the growing popularity of these products.";
push @eParagraph, "Cola drink manufacturers in particular achieved above-average growth rates.";
push @eParagraph, "The higher turnover was largely due to an increase in the sales volume.";
push @eParagraph, "Employment and investment levels also climbed.";
push @eParagraph, "Following a two-year transitional period, the new Foodstuffs Ordinance for Mineral Water came into effect on April 1, 1988.";
push @eParagraph, "Specifically, it contains more stringent requirements regarding quality consistency and purity guarantees.";

push @fParagraph, "Quant aux eaux minérales et aux limonades, elles rencontrent toujours plus d'adeptes.";
push @fParagraph, "En effet, notre sondage fait ressortir des ventes nettement supérieures à celles de 1987, pour les boissons à base de cola notamment.";
push @fParagraph, "La progression des chiffres d'affaires résulte en grande partie de l'accroissement du volume des ventes.";
push @fParagraph, "L'emploi et les investissements ont également augmenté.";  
push @fParagraph, "La nouvelle ordonnance fédérale sur les denrées alimentaires concernant entre autres les eaux minérales, entrée en vigueur le 1er avril 1988 après une période transitoire de deux ans, exige surtout une plus grande constance dans la qualité et une garantie de la pureté.";
($eAlignedRef,$fAlignedRef) = Text::GaleChurch::align(\@eParagraph,\@fParagraph);

is(@{$eAlignedRef},@{$fAlignedRef},"Length of returned arrays equivalent");
is($eAlignedRef->[0],"According to our survey, 1988 sales of mineral water and soft drinks were much higher than in 1987, reflecting the growing popularity of these products.","e first alignment correct");
is($eAlignedRef->[1],"Cola drink manufacturers in particular achieved above-average growth rates.","e second alignment correct");
is($eAlignedRef->[2],"The higher turnover was largely due to an increase in the sales volume.","e third alignment correct");
is($eAlignedRef->[3],"Employment and investment levels also climbed.","e fourth alignment correct");
is($eAlignedRef->[4],"Following a two-year transitional period, the new Foodstuffs Ordinance for Mineral Water came into effect on April 1, 1988. Specifically, it contains more stringent requirements regarding quality consistency and purity guarantees.","e fifth alignment correct");

is($fAlignedRef->[0],"Quant aux eaux minérales et aux limonades, elles rencontrent toujours plus d'adeptes.","f first alignment correct");
is($fAlignedRef->[1],"En effet, notre sondage fait ressortir des ventes nettement supérieures à celles de 1987, pour les boissons à base de cola notamment.","f second alignment correct");
is($fAlignedRef->[2],"La progression des chiffres d'affaires résulte en grande partie de l'accroissement du volume des ventes.","f third alignment correct");
is($fAlignedRef->[3],"L'emploi et les investissements ont également augmenté.","f fourth alignment correct");
is($fAlignedRef->[4],"La nouvelle ordonnance fédérale sur les denrées alimentaires concernant entre autres les eaux minérales, entrée en vigueur le 1er avril 1988 après une période transitoire de deux ans, exige surtout une plus grande constance dans la qualité et une garantie de la pureté.","f fifth alignment correct");

