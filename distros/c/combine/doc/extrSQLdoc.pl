#!/usr/bin/perl

open(I,"<../bin/combineINIT");

#Skip initialization phase of combineINIT
while(<I>) {
 last if (/##START DOC SQL##/);
}
 open(CONF,">../conf/SQLstruct.sql");

 print  "\\subsection{SQL database}\n";
 print "\\label{sqlstruct}\n";

while(<I>) {
    last if (/##END DOC SQL##/);
    if (/print\s*"(.*)\\n";/) {
	my $subs=$1;
	$subs =~ s/\$//g;
	$subs =~ s/^([^:]+):.*$/$1/;
	print  "\\subsubsection{$subs}\n";
	print CONF "\n#$subs\n";
    } elsif (/sv->do\(qq\{(.*);?\}\);/) {
	print  '\verb+' . $1 . '+\\\\' . "\n";
	print CONF $1 . "\n";
    } elsif (/##(.*)$/) {
	print  '\verb+' . $1 . '+\\\\' . "\n";
	print CONF '#' . $1 . "\n";
    } elsif (/sv->do\(qq\{(.*)$/) {
	print  '\begin{verbatim}' . "\n";
        print  $1 . "\n";
	print CONF $1 . "\n";
	while (<I>) {
	    if ( /^(.*);?\}\);\s*$/ ) {
	        print   $1 . "\n";
	        print  CONF $1 . "\n";
	        last;
	    } else { print ; print CONF; }
	}
	print  '\end{verbatim}' . "\n\n";
        print CONF "\n";
    }
}

close(I);
close(CONF);
