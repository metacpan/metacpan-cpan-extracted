#!/usr/bin/perl -wT
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

my $text = param('text');

print header;
print start_html("The Mirror Says...");

$text = reverse($text);
print <<EndHTML;
<center>
<p>The words in the mirror read...</p>
<p>$text</p>
</center>
EndHTML

print end_html;


