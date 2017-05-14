#!/usr/bin/perl -w
print "content-type: text/html\n\n" ;
use Uniq ;
#qw(camel $weight);

#unshift(@INC,"/usr/lib/perl5/site_perl/Uniq.pm");
use List::Uniq ;
while(<>)
{
$mani = uniq($_);
print "$mani\n";
}

