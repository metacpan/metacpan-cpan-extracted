#!/usr/bin/perl

#system("pod2html --css http://search.cpan.org/s/style.css --verbose --infile ../lib/Text/Embed.pm --outfile Text-Embed.html");
system("pod2html --verbose --infile ../lib/Text/Embed.pm --outfile Text-Embed.html");
unlink $_ foreach <*.tmp>;
