#
# Syntax highlighting :
#    2) user input
#
# If putting color on a generated file
# can help you read it better, on a file
# that you are editing, this should give
# you precise indications about what
# is wrong.
#
# So input highlighting should be more
# complex than output highlighting
#
# Press F5 to execute...

use strict;
use lib 'lib';

use Text::Editor::Easy;

# Start from a distant path
use File::Basename;
my ($file_name, $file_path ) = fileparse($0);

my %compte = (
    "ASV" => 1,
    "TAH" => 1,
    "TAF" => 1,
    "ORA" => 1,
    "ENE" => 1,
    "IMR" => 1,
    "DVO" => 1,
    "LOY" => 1,
    "APP" => 1,
    "CAU" => 1,
    "PEL" => 1,
    "INT" => 1,
    "PEE" => 1,
    "VOI" => 1,
    "CCP" => 1,
    "CCA" => 1,
    "CCM" => 1,
    "LBM" => 1,
    "EMP" => 1,
    "CPA" => 1,
    "DIV" => 1,
    "CFI" => 1,
    "SAN" => 1,
    "CMA" => 1,
    "SAL" => 1,
    "RFS" => 1,
    "RFD" => 1,
    "PFI" => 1,
    "PEX" => 1,
    "EMP" => 1,
    "ESS" => 1,
    "DIT" => 1,
    "CEX" => 1,
    "ASL" => 1
);

Text::Editor::Easy->new(
    {
        'file'      => "${file_path}expenses.cpt",
        'highlight' => { 'sub' => 'highlight', },
        'font_size' => 10,
        'width' => 500,
        'height' => 400,
    }
);

Text::Editor::Easy->manage_event;

sub highlight {
    my ($text) = @_;

    #print "Texte reçu=$text=\n";

    if ( $text =~ /^(#|$)/ ) {
        return [ $text, "comment" ];
    }

    #return [ $text,  "default" ];
    my (
        $periode,          $e1,      $debit, $e2,    $credit,
        $e3,               $montant, $e4,    $carte, $e5,
        $date_transaction, $e6,      $libelle
      )
      = unpack( "a7 a1 a3 a1 a3 a1 a13 a1 a1 a1 a10 a1 a*", $text );
    my ( $mois, $e7, $annee ) = unpack( "a2 a1 a4", $periode );

    #print "mois = $mois\n";
    if ( $mois !~ /\d\d/ or $mois < 1 or $mois > 12 ) {

        #print "mois incorrect : $mois\n";
        return ( [ $mois, "error" ],
            [ substr( $text, length($mois) ), "pink" ] );
    }
    if ( $e7 !~ /^\s*$/ ) {
        return (
            [ $mois, "yellow" ],
            [ $e7,   "error" ],
            [ substr( $text, 3 ), "pink" ]
        );
    }
    if ( $annee < 2001 or $annee > 2030 ) {
        return (
            [ substr( $text, 0, 3 ), "yellow" ],
            [ $annee, "error" ],
            [ substr( $text, 7 ), "pink" ]
        );
    }
    if ( $e1 !~ /^\s*$/ ) {
        return (
            [ substr( $text, 0, 7 ), "yellow" ],
            [ $e1, "error" ],
            [ substr( $text, 8 ), "pink" ]
        );
    }
    if ( !$compte{$debit} ) {
        return (
            [ substr( $text, 0, 8 ), "yellow" ],
            [ $debit, "error" ],
            [ substr( $text, 11 ), "pink" ]
        );
    }
    if ( $e2 !~ /^\s*$/ ) {
        return (
            [ substr( $text, 0, 11 ), "yellow" ],
            [ $e2, "error" ],
            [ substr( $text, 12 ), "pink" ]
        );
    }
    if ( !$compte{$credit} ) {
        return (
            [ substr( $text, 0, 12 ), "yellow" ],
            [ $credit, "error" ],
            [ substr( $text, 15 ), "pink" ]
        );
    }
    if ( $e3 !~ /^\s*$/ ) {
        return (
            [ substr( $text, 0, 15 ), "yellow" ],
            [ $e3, "error" ],
            [ substr( $text, 16 ), "pink" ]
        );
    }
    my (
        $space,    $centaine_m, $dizaine_m, $unite_m, $point,
        $centaine, $dizaine,    $unite,     $virgule, $decimal
      )
      = unpack(
"a3        a1        a1         a1      a1       a1      a1     a1       a1      a2",
        $montant
      );
    my $erreur_montant;
    if ( $space !~ /^\s*$/ ) {
        $erreur_montant = 1;
    }
    if ( $point ne "." and $point !~ /^\s*$/ ) {
        $erreur_montant = 2;
    }
    if (
        $point =~ /^\s*$/
        and (  $centaine_m !~ /^\s*$/
            or $dizaine_m !~ /^\s*$/
            or $unite_m !~ /^\s*$/ )
      )
    {
        $erreur_montant = 3;
    }
    if (
        $centaine_m !~ /^\s*$/
        and (  $dizaine_m =~ /^\s*$/
            or $unite_m =~ /^\s*$/ )
      )
    {
        $erreur_montant = 4;
    }
    if ( $dizaine_m !~ /^\s*$/ and $unite_m =~ /^\s*$/ ) {
        $erreur_montant = 5;
    }
    if (    $point eq "."
        and $centaine_m =~ /^\s*$/
        and $dizaine_m  =~ /^\s*$/
        and $unite_m    =~ /^\s*$/ )
    {
        $erreur_montant = 6;
    }
    if (
        $point eq "."
        and (  $centaine =~ /^\s*$/
            or $dizaine =~ /^\s*$/
            or $unite   =~ /^\s*$/ )
      )
    {
        $erreur_montant = 12;
    }
    if (
        $centaine !~ /^\s*$/
        and (  $dizaine =~ /^\s*$/
            or $unite =~ /^\s*$/ )
      )
    {
        $erreur_montant = 7;
    }
    if ( $dizaine !~ /^\s*$/ and $unite =~ /^\s*$/ ) {
        $erreur_montant = 8;
    }
    if ( $unite !~ /\d/ ) {
        $erreur_montant = 9;
    }
    if ( $virgule ne "," ) {
        $erreur_montant = 10;
    }
    if ( $decimal !~ /\d{2}/ ) {
        $erreur_montant = 11;
    }
    if ($erreur_montant) {
        print "Erreur montant : $erreur_montant\n\t$text\n\n";
        return (
            [ substr( $text, 0, 16 ), "yellow" ],
            [ $montant, "error" ],
            [ substr( $text, 29 ), "pink" ]
        );
    }
    if ( $e4 !~ /^\s*$/ ) {
        return (
            [ substr( $text, 0, 29 ), "yellow" ],
            [ $e4, "error" ],
            [ substr( $text, 30 ), "pink" ]
        );
    }
    if ( $carte !~ /^\s*$/ and $carte ne "C" ) {
        return (
            [ substr( $text, 0, 30 ), "yellow" ],
            [ $carte, "error" ],
            [ substr( $text, 31 ), "pink" ]
        );
    }
    if ( $e5 !~ /^\s*$/ ) {
        return (
            [ substr( $text, 0, 31 ), "yellow" ],
            [ $e5, "error" ],
            [ substr( $text, 32 ), "pink" ]
        );
    }

    my ( $jour_t, $slash_1, $mois_t, $slash_2, $annee_t ) =
      unpack( "a2 A1 a2 a1 a4", $date_transaction );
    if ( $jour_t !~ /^\d{2}$/ or $jour_t > 31 ) {
        return (
            [ substr( $text, 0, 32 ), "yellow" ],
            [ $jour_t, "error" ],
            [ substr( $text, 34 ), "pink" ]
        );
    }
    if ( $slash_1 ne "/" ) {
        print "slash 1 = :$slash_1:\n";
        return (
            [ substr( $text, 0, 34 ), "yellow" ],
            [ $slash_1, "error" ],
            [ substr( $text, 35 ), "pink" ]
        );
    }
    if ( $mois_t !~ /^\d{2}$/ or $mois_t > 12 or $mois_t < 1 ) {
        return (
            [ substr( $text, 0, 35 ), "yellow" ],
            [ $mois_t, "error" ],
            [ substr( $text, 37 ), "pink" ]
        );
    }
    if ( $slash_2 ne "/" ) {
        return (
            [ substr( $text, 0, 37 ), "yellow" ],
            [ $slash_2, "error" ],
            [ substr( $text, 38 ), "pink" ]
        );
    }
    if ( $annee_t !~ /^\d{4}$/ or $annee_t > 2030 or $annee_t < 2001 ) {
        return (
            [ substr( $text, 0, 38 ), "yellow" ],
            [ $annee_t, "error" ],
            [ substr( $text, 42 ), "pink" ]
        );
    }
    if ( $e6 !~ /^\s*$/ ) {
        return (
            [ substr( $text, 0, 42 ), "yellow" ],
            [ $e6, "error" ],
            [ substr( $text, 43 ), "pink" ]
        );
    }

    return (
        [ substr( $text, 0,    3 ),  "green" ],
        [ substr( $text, 3,    5 ),  "dark purple" ],
        [ substr( $text, 8,    4 ),  "black" ],
        [ substr( $text, 12,   4 ),  "dark red" ],
        [ substr( $text, 16,   13 ), "dark blue" ],
        [ substr( $text, 29,   3 ),  "red" ],
        [ substr( $text, 32,   11 ), "dark red" ],
        [ substr( $text, 43 ), "comment" ],
    );

}