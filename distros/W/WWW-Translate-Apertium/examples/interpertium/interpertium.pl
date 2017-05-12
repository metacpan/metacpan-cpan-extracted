#!/usr/bin/perl -w
use strict;
use 5.010;
use Encode;
use Text::WordDiff;
use WWW::Translate::interNOSTRUM;
use WWW::Translate::Apertium;

$|++;

##################################################################
#                                                                #
# Interpertium - interNOSTRUM vs. Apertium Comparison report     #
#                                                                #
# Copyright (C) 2008 by Enrique Nell, all rights reserved.       #
#                                                                #
# Usage: perl interpertium.pl <lang_pair> <file_path>            #
#                                                                #
# <lang_pair> must be es-ca or ca-es                             #
#                                                                #
# Output: diff.htm, in the same folder that contains this script #
#                                                                #
##################################################################


die "Usage: perl interpertium.pl <lang_pair> <file_path>\n" if @ARGV != 2;

my ($pair, $txt_path) = @ARGV;

die "<lang_pair> must be es-ca or ca-es\n" if $pair !~ /es-ca|ca-es/;

die "Couldn't find $txt_path\n" unless -e $txt_path;


open my $file, "<:encoding(iso-8859-1)", $txt_path
        || die "Couldn't open $txt_path: $!";


# Create interNOSTRUM object
my $inter = WWW::Translate::interNOSTRUM->new( lang_pair => $pair );

# Create Apertium object
my $apert = WWW::Translate::Apertium->new( lang_pair => $pair );


# Open output file
my $output = 'diff.htm';
open my $out, '>:encoding(UTF-8)', $output;

print $out <<"END_HEADER";
<html>
<head>
<META HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=UTF-8'>
<link rel='stylesheet' href='word_diff.css' type='text/css'>
</head>
<title>Apertium-interNOSTRUM comparison</title>
<body>
<h1>Comparison results for $txt_path</h1>
</br>
END_HEADER


while (<$file>) {
    chomp;
    if ($_ !~ /^\s*$/) {
        say $out "<span style='color:green'><b>Source:</b></span></br>\n" .
                 "$_</br>";
                 
        my $apert_trans = $apert->translate($_);
        $apert_trans =~ s/\s+$//; # Remove trailing spaces
        
        # The input encoding in WWW::Translate::interNOSTRUM is Latin-1
        my $inter_trans = $inter->translate(encode('iso-8859-1', $_));
        $inter_trans =~ s/\s+$//; # Remove trailing spaces
        
        if ($apert_trans ne $inter_trans) {
            
            my $diff = word_diff \$inter_trans, \$apert_trans, { STYLE => 'HTML' };
            
            say $out "<span style='color:blue'><b>interNOSTRUM:</b></span></br>\n" .
                     "$inter_trans</br>";
                     
            say $out "<span style='color:red'><b>Apertium:</b></span></br>\n" .
                     "$apert_trans</br>";
                     
            say $out "<span style='color:blueviolet'><b>interNOSTRUM to " .
                     "Apertium:</b></span></br>";
                     
            say $out $diff;
            
        } else {
            
            say $out "<span style='color:blue'><b>interNOSTRUM</b></span> " .
                     "<b>and</b></n> " .
                     "<span style='color:red'><b>Apertium</b></span>" .
                     "<b>:</b></br>\n"  .
                     "$apert_trans</br>";
                     
            say $out "<span style='color:darkorange'><b>No differences.</b> ".
                     "</span></br>";
                     
        }
        
        say $out "</br></br>";
    }
}

say $out "</body>\n</html>";

close $file;
close $out;


