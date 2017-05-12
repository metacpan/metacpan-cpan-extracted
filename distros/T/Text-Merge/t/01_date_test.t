
use Text::Merge;

require "t/test.pl";
$::data = $::data;

print "1..2\n";


##
##
## First check format of subordinate date function output (to get a warm and fuzzy)
##
##

my $time = $$::data{TestDate};

my $abbr_date = Text::Merge::abbrdate(0) ne ($_=Text::Merge::abbrdate($time)) && $_;
my $short_date = Text::Merge::shrtdate(0) ne ($_=Text::Merge::shrtdate($time)) && $_;
my $time_of_day = Text::Merge::timeoday(0) ne ($_=Text::Merge::timeoday($time)) && $_;
my $time_24hr = Text::Merge::time24hr(0) ne ($_=Text::Merge::time24hr($time)) && $_;
my $date_only = Text::Merge::dateonly(0) ne ($_=Text::Merge::dateonly($time)) && $_;
my $full_date = Text::Merge::fulldate(0) ne ($_=Text::Merge::fulldate($time)) && $_;
my $extended_date = Text::Merge::extdate(0) ne ($_=Text::Merge::extdate($time)) && $_;
my $localtime = localtime(0) ne ($_=localtime($time)) && $_;

$abbr_date && $abbr_date =~ /^\d+\/\d+\/\d{2}$/  or  die "abbr_date() failed with '$abbr_date'";
$short_date && $short_date =~ /^\d+\/\d+\/\d{2}\s+\d+\:\d{2}[pa]m$/  or  die "shrtdate() failed with '$short_date'";
$time_of_day && $time_of_day =~ /^\d+\:\d{2}[pa]m$/  or  die "timeoday() failed with '$time_of_day'";
$time_24hr && $time_24hr =~ /^\d\d\:\d\d(:\d\d)?$/  or  die "time24hr() failed with '$time_24hr'";
$date_only && $date_only =~ /^(Jan\.|Feb\.|Mar\.|Apr\.|May|June|July|Aug\.|Sep\.|Oct\.|Nov\.|Dec\.)\s\d+\,\s\d{4}$/  
									  or  die "dateonly() failed with '$date_only'";
$full_date && $full_date =~ 
	/^(Jan\.|Feb\.|Mar\.|Apr\.|May|June|July|Aug\.|Sep\.|Oct\.|Nov\.|Dec\.)\s\d+\,\s\d{4}\s+\d+\:\d\d[pa]m$/  
									  or  die "fulldate() failed with '$full_date'";
$extended_date && $extended_date =~ 
	/^[MTWFS][ondayueshrit]+\,\s[JFMASOND][anuryebchpilgstmov]+\s\d+(st|nd|rd|th),\s\d{4}\sat\s\d+\:\d\d[pa]m$/
								 or  die "extdate() failed with '$extended_date'";
$localtime  or  die "localtime() failed with '$localtime'";

print "ok\n";



##
##
## Next we generate our test results file with the 
## local dates to assure proper matches
##
##

## Send to  't/results.txt'
my $fh = new FileHandle(">t/results.txt");
$fh  or  die "Can't open results file";

print $fh "works
works
This works.
This works.
Some text before works
I love fireworks
Some text before this works.
Some text before this works.
works Some text after is here.
worksites galore
This works.  Some text after.
This works...some text after.
Some text before works.  Some text after.
I love fireworks!!!
Some text before this works.  Some text after.
Some text before this works...some text after.
apple pie
apple pie
This apple pie.
This apple pie.
Some text before apple pie
I love fireapple pie
Some text before this apple pie.
Some text before this apple pie.
apple pie Some text after is here.
apple pieites galore
This apple pie.  Some text after.
This apple pie...some text after.
Some text before apple pie.  Some text after.
I love fireapple pie!!!
Some text before this apple pie.  Some text after.
Some text before this apple pie...some text after.
this works

this works

text before this works
text before 
text before...this works
text before...
this works text after
text after
this works text after
...text after
text before this works text after
text before text after
text before...this works...text after
text before...text after
this works

this works

text before this works
text before 
text before...this works
text before...
this works text after
text after
this works text after
...text after
text before this works text after
text before text after
text before...this works...text after
text before...text after
BOOK
book
John Q. Smith
1
133%
100%
\$1.33
$abbr_date
$short_date
$time_of_day
$time_24hr
$date_only
$full_date
$extended_date
$localtime
\&#38;;\&#34;\&#35;\&#60;\&#62;
\&;\"#<>
     John Q. Smith
The quick brown snuffle-
uppagus jumped scr-ump-dilly-
iciously over the lazy superca
lifragilisticexpialidocious 
bug. 

     The quick brown snuffle-uppagus 
     jumped scr-ump-dilly-iciously over
     the lazy 
     supercalifragilisticexpialidocious
     bug. 
";

$fh->close;
print "ok\n";

exit;


