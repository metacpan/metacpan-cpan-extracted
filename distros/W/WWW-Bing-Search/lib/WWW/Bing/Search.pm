package WWW::Bing::Search;
{
    $Bing::WWW::Search::VERSION = '0.011';
}

use warnings;
use strict;
use LWP::UserAgent;

BEGIN {
    use vars qw/ $proxy $timeout $query $rawResult @results $totalCount $resultsCount $first $minPages/;
    $proxy = 0;
    $timeout = 10;
    $query = undef;
    $rawResult = 0;
    @results = {};
    $totalCount = 0;
    $resultsCount = 0;
    $first = 0;
    $minPages = 1;
}

sub New {
    my ($name, %args) = @_;
    $proxy = $args{'proxy'} ? delete($args{'proxy'}) : $proxy;
    $timeout = $args{'timeout'} ? delete($args{'timeout'}) : $timeout;
    return $_[0];
}


sub Search {
    $query = $_[1] if (!defined($_[2]));
    if (!defined($query)) {
	my ($name, %args) = @_;
	$query = $args{'query'} ? delete($args{'query'}) : $query;
	$first = $args{'first'} ? delete($args{'first'}) : $first;
	$minPages = $args{'minPages'} ? delete($args{'minPages'}) : $minPages;
    }
    $query =~ s/\s/+/;
    my $pq = $query;
    $query =~ s/([^A-Za-z0-9+])/sprintf("%%%02X", ord($1))/seg;
    while ($minPages) {
	my $ua = LWP::UserAgent->new();
	$ua->timeout($timeout);
	$ua->proxy($proxy) if ($proxy ne 0);
	$rawResult = $ua->get("http://www.bing.com/search?q=$query&qs=n&filt=all&pq=$pq&sc=1-10&sp=-1&sk=&first=$first&FORM=PERE");
	_parse();
	$minPages--;
	$first+=10;
    }
}

sub _parse {
    my $answer = $rawResult->as_string;
    while ($answer=~m/"(\w+:\/\/[^"]+)"/gi) {  #"
	next if (index($1,"bing.com")!=-1 
	|| index($1,"w3.org")!=-1 
	|| index($1,"feedback.discoverbing.com")!=-1 
	|| index($1,"login.live.com")!=-1
	|| index($1,"www.microsofttranslator.com")!=-1
	|| index($1,"go.microsoft.com")!=-1
	|| index($1,"g.msn.com")!=-1
	|| index($1,"onlinehelp.microsoft.com")!=-1
	|| index($1,"cc.bingj.com")!=-1
	|| index($1,"schemas.live.com")!=-1
	);
	push @results,$1;
	$resultsCount++;
    }
    if ($answer =~ m/id="count">.+?([0-9&#;]+)<\/span>/gi){
	$totalCount = $1;
	$totalCount =~ s/&#\d+;//g;
    }
}

sub TotalCount { return $totalCount; }
sub Count { return $resultsCount; }
sub GetResult { return shift @results; }
sub GetResults { return @results; }

END {
    $proxy = undef;
    $timeout = undef;
    $query = undef;
    $rawResult = undef;
    @results = undef;
    $totalCount = undef;
    $resultsCount = undef;
    $first = undef;
    $minPages = undef;
}