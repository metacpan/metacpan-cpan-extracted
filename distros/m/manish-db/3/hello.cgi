#!/usr/bin/perl -w
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
my $text = param('text'); 
print header;
print start_html("mirror says this plz see nbelow.....");
$text = reverse($text);

print <<EndHTML;
<center>
<p>this is the work manish</p>
<p>$text</p>
</center>
EndHTML


print end_html;
