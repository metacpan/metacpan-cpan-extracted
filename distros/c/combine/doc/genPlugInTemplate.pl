#!/usr/bin/perl

print <<HEAD;
\\subsection{Example topic filter plug in}
\\label{classifyPlugInTemplate}

This example gives more
details on how to write a topic filter Plug-In. 

\\subsubsection{classifyPlugInTemplate.pm}
\\begin{verbatim}
HEAD

open(INSTTEST,"<../templates/classifyPlugInTemplate.pm");
while (<INSTTEST>) { print; }
close(INSTTEST);

print "\\end{verbatim}\n";
