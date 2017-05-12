#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Benchmark qw(:all);
use Web::Query::LibXML;
use XML::LibXML::jQuery;
use jQuery;

my $source = '<div><p></p></div>';
my $j = j($source);
my $wq = wq($source);
my $jquery = jQuery($source);

my $subs = {
    q1_jquery        => create($j),
    web_query_libxml => create($wq),
    jquery           => create($jquery)
};

foreach my $name (keys %$subs) {
    my $obj = $subs->{$name}->();
    printf "[%s]\n%s\n\n", $name, $obj;
}


cmpthese(shift || 10000, $subs);


sub create {
    my $obj = shift;
    sub {
        $obj->html;
    }
}

__END__

[cafe@cafepc][~/my/workspace/Q1]$ perl t/jquery/benchmark/html.pl 20000
[jquery]
<p/>

[q1_jquery]
<p></p>

[web_query_libxml]
<p></p>

                    Rate web_query_libxml        q1_jquery           jquery
web_query_libxml 15625/s               --             -26%             -67%
q1_jquery        21053/s              35%               --             -56%
jquery           47619/s             205%             126%               --


( now using eval() in html() )

[cafe@cafepc][~/my/workspace/Q1]$ perl t/jquery/benchmark/html.pl 20000
[jquery]
<p/>

[q1_jquery]
<p></p>

[web_query_libxml]
<p></p>

                    Rate web_query_libxml        q1_jquery           jquery
web_query_libxml 15625/s               --             -27%             -67%
q1_jquery        21505/s              38%               --             -55%
jquery           47619/s             205%             121%               --
