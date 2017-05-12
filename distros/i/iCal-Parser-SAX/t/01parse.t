# -*- cperl -*-
use Test::More;
use Test::XML;
use IO::File;
use IO::String;
use XML::SAX::Writer;
use iCal::Parser::SAX;

my @files=glob("t/calendars/[0-9]*.ics");
plan tests => scalar @files + 5;

foreach my $f (@files) {
    my $expect=slurp($f . ".xml");
    my $got='';
    iCal::Parser::SAX->new(Handler=>XML::SAX::Writer
			   ->new(Escape=>{XXX=>'XXX'},Output=>\$got),
			   start=>'20040101',tz=>'America/New_York',
			  )->parse_uri($f);
    is_xml($got,$expect,$f=~/.+\d+(.+)\.ics/);
}

my $expect=slurp("t/calendars/10multi-cal.ics.xml");
my $got='';
iCal::Parser::SAX->new(Handler=>XML::SAX::Writer
		       ->new(Escape=>{},Output=>\$got),
		       start=>'20040101',tz=>'America/New_York',
		      )->parse_uris(qw{
				       t/calendars/02event-duration.ics
				       t/calendars/03all-day-event.ics});
is_xml($got,$expect,"multi-cal input");

my $f="t/calendars/03all-day-event.ics";
$expect=slurp($f . ".xml");
my $fh=IO::File->new($f,'r');
$got='';
iCal::Parser::SAX->new(Handler=>XML::SAX::Writer
		       ->new(Escape=>{},Output=>\$got),
		       start=>'20040101',tz=>'America/New_York',
		      )->parse_file($fh);
is_xml($got,$expect,'parse filehandle');
$got='';
my $input=slurp($f);
iCal::Parser::SAX->new(Handler=>XML::SAX::Writer
		       ->new(Escape=>{XXX=>'XXX'},Output=>\$got),
		       start=>'20040101',tz=>'America/New_York',
		      )->parse_string($input);
is_xml($got,$expect,'parse string');
my $h=iCal::Parser->new(start=>'20040101',tz=>'America/New_York')->parse($f);
#parse now tries to use filename
$h->{cals}[0]{'X-WR-CALNAME'}='Calendar 1';
$got='';
iCal::Parser::SAX->new(Handler=>XML::SAX::Writer
		       ->new(Escape=>{XXX=>'XXX'},Output=>\$got),
		       start=>'20040101',
		      )->parse_hash($h);
is_xml($got,$expect,'parse hash');

SKIP: {
    eval "use LWP::UserAgent";
    skip "http url", 1  unless -f "_build/DOHTTP" && !$@;
    my $url="http://www.rickster.com/xml-sax-ical/test-cal.ics";
    $got='';
    iCal::Parser::SAX->new(Handler=>XML::SAX::Writer
			   ->new(Escape=>{XXX=>'XXX'},Output=>\$got),
			   start=>'20040101',tz=>'America/New_York',
			  )->parse_uri($url);
    is_xml($got,$expect,'parse http url');
}
sub slurp {
    my $f=shift;
    local $/=undef;
    open IN, $f or die "Can't open $f, $!";
    my $s=<IN>;
    close IN;
    return $s;
}
