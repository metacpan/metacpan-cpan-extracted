#!/usr/bin/perl

print <<HEAD;
\\subsection{Simple installation test}
\\label{InstTest}

The following simple script is available in the {\\tt
doc/InstallationTest.pl} file. It must be run as 'root' 
and tests that basic functions of the Combine installation works.

Basicly it creates and initializes a new jobname, crawls one
specific test page and exports it as XML. This XML is then
compared to a correct XML-record for that page. 

\\subsubsection{InstallationTest.pl}
\\begin{verbatim}
HEAD

open(INSTTEST,"<./InstallationTest.pl");
while (<INSTTEST>) { print; }
close(INSTTEST);

print "\\end{verbatim}\n";
