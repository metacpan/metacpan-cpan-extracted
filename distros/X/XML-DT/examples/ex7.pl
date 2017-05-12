#!/usr/bin/perl
#
# see comments in the end
#

use XML::DT ;
my $filename = shift;
my $beginLatex = '\documentclass{article}
  \usepackage[latin1]{inputenc}
  \usepackage{t1enc}
  \bibliographystyle{plain}
  \begin{document}
';
my $endLatex = '\end{document}
';

my @aut=();

%handler=(
    '-outputenc' => 'ISO-8859-1',
#    '-default'   => sub{"<$q>$c</$q>"},
     '-begin'  => sub{print"BEGIN\n"},
     '-end'  => sub{print"end\n";"$beginLatex$c$endLatex"},
     '-pcdata' => sub{ 
         if(inctxt('(SECTION|SUBSEC1)')) {$c =~ s/[\s\n]+/ /g; $c }
         $c },
     'RANDLIST' => sub{"\\begin{itemize}$c\\end{itemize}"},
     'AFFIL' => sub{""},
     'TITLE' => sub{
                  if(inctxt('SECTION')){"\\section{$c}"}
               elsif(inctxt('SUBSEC1')){"\\subsection{$c}"}
               else                    {"\\title{$c}"}
            },
     'GCAPAPER' => sub{"$c"},
     'PARA' => sub{"$c\n\n"},
     'ADDRESS' => sub{"\\thanks{$c}"},
     'PUB' => sub{"} $c"},
     'FNAME' => sub{" $c"},
     'EMAIL' => sub{"(\\texttt{$c}) "},
     'FRONT' => sub{"$c\n"},
     'REAR' => sub{"$c"},
     'BIB' => sub{"$c"},
     'BODY' => sub{"$c"},
     'AUTHOR' => sub{ push @aut, $c ; ""},
     'ABSTRACT' => sub{
       sprintf('\author{%s}\maketitle\begin{abstract}%s\end{abstract}',
               join ('\and', @aut) ,
               $c) },
     'CODE.BLOCK' => sub{"\\begin{verbatim}\n$c\\end{verbatim}\n"},
     'XREF' => sub{"\\cite{$v{REFLOC}}"},
     'SECTION' => sub{"$c"},
     'LI' => sub{"\\item $c"},
     'SUBSEC1' => sub{"$c"},
     'BIBLIOG' => sub{"\n\\begin{thebibliography}{1}\n$c\n\\end{thebibliography}\n"},
     'HIGHLIGHT' => sub{" \\emph{$c} "},
     'BIO' => sub{""},
     'SURNAME' => sub{" $c "},
     'CODE' => sub{"\\verb!$c!"},
     'BIBITEM' => sub{"\n\\bibitem{$c"},
);
print dt($filename,%handler); 

=head1 NAME

gcapaper2tex.pl - a perl script to translate XML gcapaper DTD to latex

=head1 SYNOPSIS

   gcapapape2tex.pl mypaper.xml > mupaper.tex

=head1 notes

This is an example of the use of XML::DT module

=head1 The Code

 use XML::DT ;
 my $filename = shift;
 my $beginLatex = '\documentclass{article}
   \usepackage[latin1]{inputenc}
   \usepackage{t1enc}
   \bibliographystyle{plain}
   \begin{document}
 ';
 my $endLatex = '\end{document}
 ';

 my @aut=();

 %handler=(
     '-outputenc' => 'ISO-8859-1',
 #    '-default'   => sub{"<$q>$c</$q>"},
      '-pcdata' => sub{ 
 	 if(inctxt('(SECTION|SUBSEC1)')) {$c =~ s/[\s\n]+/ /g; $c }
 	 $c },
      'RANDLIST' => sub{"\\begin{itemize}$c\\end{itemize}"},
      'AFFIL' => sub{""},
      'TITLE' => sub{
 		  if(inctxt('SECTION')){"\\section{$c}"}
 	       elsif(inctxt('SUBSEC1')){"\\subsection{$c}"}
 	       else                    {"\\title{$c}"}
 	    },
      'GCAPAPER' => sub{"$beginLatex $c $endLatex"},
      'PARA' => sub{"$c\n\n"},
      'ADDRESS' => sub{"\\thanks{$c}"},
      'PUB' => sub{"} $c"},
      'FNAME' => sub{" $c"},
      'EMAIL' => sub{"(\\texttt{$c}) "},
      'FRONT' => sub{"$c\n"},
      'REAR' => sub{"$c"},
      'BIB' => sub{"$c"},
      'BODY' => sub{"$c"},
      'AUTHOR' => sub{ push @aut, $c ; ""},
      'ABSTRACT' => sub{
        sprintf('\author{%s}\maketitle\begin{abstract}%s\end{abstract}',
 	       join ('\and', @aut) ,
 	       $c) },
      'CODE.BLOCK' => sub{"\\begin{verbatim}\n$c\\end{verbatim}\n"},
      'XREF' => sub{"\\cite{$v{REFLOC}}"},
      'SECTION' => sub{"$c"},
      'LI' => sub{"\\item $c"},
      'SUBSEC1' => sub{"$c"},
      'BIBLIOG' => sub{"\n\\begin{thebibliography}{1}\n$c\n\\end{thebibliography}\n"},
      'HIGHLIGHT' => sub{" \\emph{$c} "},
      'BIO' => sub{""},
      'SURNAME' => sub{" $c "},
      'CODE' => sub{"\\verb!$c!"},
      'BIBITEM' => sub{"\n\\bibitem{$c"},
 );
 print dt($filename,%handler); 

=head1 author

J.Joao Almeida (jj@di.uminho.pt)
