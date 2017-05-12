# -*- cperl -*-
use Test::More;
use iCal::Parser::HTML;

my $parser=iCal::Parser::HTML->new;
#map of calendars to start dates
my %testmap=(
	     'event-duration.ics'=>'20041112',
	     'all-day-event.ics'=>'20041115',
	     'complex.ics'=>'20041112',
	    );
plan tests => (scalar keys %testmap) * 4 + 7;
my $caldir='t/calendars';

while(my($f,$d)=each %testmap) {
    foreach my $type qw(day week month year) {
	my $got=$parser->parse(type=>$type,start=>$d,url=>"$f?",
					 files=>["$caldir/$f"]);
	$got=~s/today//g;
	$got=~s/ class=""//g;
	dump_html("$caldir/$f.$type.html",$got) if $ENV{_DUMP_TEST_HTML_};
	my $expect=slurp("$caldir/$f.$type.html");
	is($got,$expect,"$f -> $type");
    }
}
#multiple calendar input
foreach my $type qw(day week month year) {
    my $got=$parser
    ->parse(type=>$type,start=>'2004-11-12',url=>'multical?',
	    files=>[map {"t/calendars/$_"} keys %testmap]);
    $got=~s/today//g;
    $got=~s/ class=""//g;
    dump_html("$caldir/multical.$type.html",$got) if $ENV{_DUMP_TEST_HTML_};
    my $expect=slurp("t/calendars/multical.$type.html");
    is($got,$expect,"multical -> $type");
}
#no link output
foreach my $type qw(day week month) {
    my $got=$parser
    ->parse(type=>$type,start=>'2004-11-12',
	    files=>[map {"t/calendars/$_"} keys %testmap]);
    $got=~s/today//g;
    $got=~s/ class=""//g;
    dump_html("$caldir/multical.nolink.$type.html",$got) if $ENV{_DUMP_TEST_HTML_};
    my $expect=slurp("t/calendars/multical.nolink.$type.html");
    is($got,$expect,"multical -> $type (no links)");
}
sub dump_html {
    my($expect,$got)=@_;
    diag("dumping $expect");
    open OUT, ">$expect" or die "Can't open $expect, $!";
    print OUT $got;
    close OUT;
}
sub slurp {
    my $f=shift;
    local $/=undef;
    open IN, $f or die "Can't open $f, $!";
    my $s=<IN>;
    close IN;
    return $s;
}
