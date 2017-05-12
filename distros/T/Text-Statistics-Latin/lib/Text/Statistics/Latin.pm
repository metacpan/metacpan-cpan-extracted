package Text::Statistics::Latin;


use strict;
no warnings;

require Exporter;

our @ISA = qw(Exporter);

=head1 NAME

Text::Statistics::Latin - Performs statistical analysis of corpora 

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';
use 5.006;
use Text::ParseWords;
use utf8;
use base 'Exporter';

our @EXPORT = qw(LATIN);
our @words;
our $tokens;
our @out11;
our @outtott;
our $tokensgeral;

=head1 SYNOPSIS
    use CText::CStatiBR;  
    &Text::CStatiBR::CSTATIBR();

DESCRIPTION

Given a copus as input, Text::Statistics::Latin creates a seven column
CSV file as output, with one line for each token per text. Names of
input files need match the following pattern:

    1 (1). txt', '1 (2). txt', ..., '1 (n).txt'

or

    1 \(([1-9]|[1-9][0-9]+)\)\.txt

Columns store statistical information:

    (1) number of word forms in document d;  
    (2) number of tokens in d;  
    (3) Id number of d, ie., n;  
    (4) frequency of term t in d;  
    (5) corpus frequency of t ;  
    (6) document frequency of t (number of documents where t occurs at
+ least once);  
    (7) t, UTF8 latin coded token-string delimited by C<< /[ -@]|[\[-`
+]|[{-¿]|[&#592;-&#745;]|[&#884;-&#65533;]/ >>
     
    Main output file name is '1 (n + 5).txt' and it is stored in the s
+ame directory as
    the corpus, together with residual files on each input file with .
+txu and .txv ad hoc extensions.  
     
    This code was written under CAPES BEX-09323-5
    
Example:

    #!/usr/bin/perl  
    use strict;  
    use Text::CStatiBR;  

    &Text::CStatiBR::CSTATIBR("5");     #5 files are analised.  
                                        #Main output
                                        #file created is  
                                        #1 (10).txt

=head1 EXPORT

    &LATIN();

=cut

sub LATIN{
    
    print "inicio de programa, aguardes", "\n";
    my $min = 1;                                                                    #number of start file
    our $max=shift;
    
    my $dif = $max - $min;
    my $tempo = 1;
    
    while ($tempo < 3){                                                             #start and meta procedures limitation
        my $nome4 = "1 ($max).txt";                                                 #file of sharing for document frrequency calculation
        my $nome5 = "registro1 ($max).txt";	                                    #log file for data and metadata
        open (our $result, ">", $nome4) || die "Não posso escrever $nome4: $!";                
        open (my $registro, ">", $nome5) || die "Não posso escrever $nome5: $!";
        my $num = $min;                                                             #number of start file
        my $maximo = $max;                                                          #number of final file + 1
        while ($num < $maximo){        
            
            my $nome1 = "1 ($num).txt";                                             #text file
            my $nome2 = "1 ($num).txu";                                             #\sToken\n
            my $nome3 = "1 ($num).txv";                                             #file number,frequency,\sType
            
            my $i = 1;                                                              #fisrt string
            my $reg = /\r\n/;                                                       #needed for UTF-8 cleaning
            my $reg2 = /\s/;                                                        #see http://unicode.org/reports/tr13/tr13-5.html
            
            ###start of tokens
            
            open (my $in, "<", $nome1) || die "Can not open", $nome1, ": $!";
            open (my $out, ">", $nome2) || die "Can not write", $nome2, ": $!";
            print "inicio de tokenização, aguardes", "\n"; 
            
            while (1) {
                my $line = <$in>;
                our $tokens = $i;            
                last unless $line;
                for ($line) {                
                    s/[-@]|[\[-`]|[{-¿]|[ɐ-˩]|[ʹ-�]/ /g;                         #delimiters of latin coded texts
                }   
                @words = &shellwords(' ', 0, $line);                                #previous delimiter: \s+
                foreach (@words) {
                    unless ($_ eq "s+"|$_ eq "0"|$_ eq $reg|$_ eq $reg2){           #last cleaning
                        print $out " $_\n";
                        $i++;
                    }
                }     
            }
            close $in;

            if ($tempo < 2){
                our $tokensgeral = $tokensgeral + $tokens;
            }
            close $out;
            print "fim de tokenização", "\n";
            print "início de typeficação, aguardes", "\n";
            
            # start of types
            
            my $ii = ($i - 1);                                                      #last string processed in the previous procedure - 1
            open (my $in2, "<", $nome2) || die "Can not open $nome2: $!";
            open (my $out2, ">", $nome3) || die "Can not write $nome3: $!";
            our @lista = <$in2>;
            my $controle2 = 0;
            my $types = 0;
            while ($controle2 < $ii){
                our $inicio = -1;
                my $controle = 0;                                                   #term frequency
                my $pesquisa = $lista[$controle2];                                  #searched terms
                while (1){
                    last unless ($lista[$inicio]);
                    foreach ($lista[$inicio]){        
                        $inicio++;
                        if ($lista[$inicio] =~ /$pesquisa/i){                       #finds the word
                            $controle++;                                            #increases a "bean"
                        }   
                    }
                }
                if ($controle < $ii){
                    $types++;
                    print $out2 "$num,$controle,$pesquisa";
                    print $result $num, ",", $controle, ",", $pesquisa;             #not yet...
                }
                for (@lista){
                    s/$pesquisa/\n/i;                                               #cleans previous data
                }
                $controle2++; 
            }
            print "Foram encontrados ", $types, " types no arquivo ", $nome1, "!", "\n";
            print $registro $types, ",", $ii, ",", $nome1, "\n";        
            close $in2;
            close $out2;
            $num++;
        } 
        close $result;
        $tempo++;                                                                   #increases a been in time
        $min = $max;                                                                #changes target intervalls
        $max++;                                                                     #for meta-data extraction
        print "fim de typeficação", "\n";
        print "início de primeira contagem, aguardes", "\n";
        
        #start of collection frequency
        
        if ($tempo == 3){       
            do{
            $num = $num - 1;
            my $nome1 = "1 ($num).txv";
            my $nome2 = "1 ($num).txt";
            
            $num = $num + 2;
            my $nome3 = "1 ($num).txt";
            
            open (my $in1, "<", $nome1) || die "Não posso abrir $nome1: $!";
            open (my $in2, "<", $nome2) || die "Não posso abrir $nome2: $!";
            open (my $out1, ">", $nome3) || die "Não posso escrever $nome3: $!";
            
            my @in1 = <$in1>;
            my @in2 = <$in2>;
            
            my $tempo1 = 0;
            
            while ($in1[$tempo1]){  
                my $linha1 = $in1[$tempo1];
                for ($linha1){
                    s/.+,.+, / /g;
                }    
                my $tempo2 = 0;
                my $cont = 0;
                while ($in2[$tempo2]){
                    my $linha2 = $in2[$tempo2];
                    if ($linha2 =~ /.+,.+,$linha1/i){
                        for ($linha2){
                            s/[^0-9]/ /ig;
                            s/[0-9]+\s//;
                        }            
                        for ($linha2){
                            $cont = $cont + $linha2;
                        }
                    }
                    $tempo2++;
                }    
                $out11[$tempo1] = "$cont,$linha1";                                  #ok
                $tempo1++;   
            }
            close $in1;
            close $in2;
            print $out1 @out11;
            close $out1;
            print "fim de primeira contagem", "\n";        };
            
            #start of unification: tf df cf
            #cf,df, termo, file

            do{
                print "início de terceira contagem, aguardes", "\n";
                my $numm = $num - 2;
                my $nome2 = "1 ($num).txt";
                open (my $incf, "<", $nome2) || die "Não posso abrir $nome2: $!";
                $num = $num - 1;
                $nome2 = "1 ($num).txt";
                open (my $indf, "<", $nome2) || die "Não posso abrir $nome2: $!";
                $num = $num + 2;
                $nome2 = "1 ($num).txt";
                open (my $out, ">", $nome2) || die "Não posso abrir $nome2: $!";
                
                my @lista1 = <$indf>;
                my @lista2 = <$incf>;
                my $linha = 0;
                
                while(1){
                    last unless ($lista1[$linha]);                              
                    for ($lista1[$linha]){
                        s/$numm,//i;
                    }
                    for ($lista2[$linha]){
                        s/, .+//;
                        s/\n//;
                    }   
                    print $out "$lista2[$linha],$lista1[$linha]";
                    $linha = $linha + 1;
                }
                close $out;
                close $incf;
                close $indf;
                print "fim de terceira contagem", "\n";
                
                #last unification: doc, tf, cf, df, termo, last txt
                
                print "inicio de unificação, aguardes", "\n";
                open (my $incfdf, "<", $nome2) || die "Não posso abrir $nome2: $!";
                $num = $num - 3;
                $nome2 = "1 ($num).txt";
                open (my $intf, "<", $nome2) || die "Não posso abrir $nome2: $!";
                $num = $num + 4;
                $nome2 = "1 ($num).txt";
                open (my $outtot, ">", $nome2) || die "Não posso abrir $nome2: $!"; #file of last unification
                                                                                                                    #text, tf, cf, df, term
                my @listatf = <$intf>;
                my @listadf = <$incfdf>;
                my @listadf1 = @listadf;
                my $linhatf = 0;

                while (1){
                    last unless ($listatf[$linhatf]);
                    my $linhadf = 0;
                    while (1){
                        last unless ($listadf[$linhadf]);
                        for ($listadf[$linhadf]){
                            s/.+,.+,//;
                        }                
                        if ($listatf[$linhatf] =~ /.+,.+,$listadf[$linhadf]/i){     #finds the line where df occurs
                                                                                                #the term of each line of tf
                            for ($listatf[$linhatf]){
                                s/, .+\n/,/i;
                            }                        
                            $outtott[$listadf[$linhatf]] = "$listatf[$linhatf]$listadf1[$linhadf]";
                        }            
                        $linhadf++;
                    }
                    print $outtot @outtott;
                    $linhatf++;                    
                }
                print "fim de unificação", "\n";
                close $outtot;
                close $intf;
                close $incfdf;
                print "inicio de unificação para Okapi BM 25", "\n";

                #unification for Okapi data

                my $znum = $num;
                open (my $zincinco, "<", "1 ($znum).txt") || die "Não posso escrever registro1 ($znum).txt: $!";
                my @zin2 = <$zincinco>;
                my @zin3 = @zin2;
                $znum++;
                open (my $zoutx, ">", "1 ($znum).txt") || die "Não posso escrever 1 ($znum).txt: $!";
                $znum = $znum - 5;        
                open (my $zregistro, "<", "registro1 ($znum).txt") || die "Não posso escrever registro1 ($znum).txt: $!";          
                my @zin1 = <$zregistro>;
                my $zindex = 0;
                my $zinic = 0;
                while (1){
                    last unless ($zin1[$zinic]);
                    my $zlinhac = 0;            
                    for ($zin1[$zinic]){
                        s/1 .+\n//;
                    }            
                    my $zinicc = $zinic + 1;            
                    while (1){
                        last unless ($zin2[$zlinhac]);
                        for ($zin3[$zlinhac]){
                            s/,.+\n//;
                        }                
                        if ("$zin3[$zlinhac]\n" =~ /$zinicc\n/){
                            print $zoutx "$zin1[$zinic]$zin2[$zlinhac]";
                            $zindex++;
                        }                    
                        $zlinhac++;
                    }
                    $zinic++;            
                }
            };       
            $tokensgeral = $tokensgeral - $dif;
            print "Neste corpus há ", $tokensgeral, " tokens!", "\n";               #export this information for the last registry
        }  
    }
    print "\n", "fim de programa";
}
=head1 AUTHOR

Rodrigo Panchiniak Fernandes, C<< <fernandes at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-statistics-latin at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Statistics-Latin>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Statistics::Latin

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Statistics-Latin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Statistics-Latin>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Statistics-Latin>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Statistics-Latin>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2007 Rodrigo Panchiniak Fernandes, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Written under CAPES BEX-09323-5
=cut

1; # End of Text::Statistics::Latin
__END__

