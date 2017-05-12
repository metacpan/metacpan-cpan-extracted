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
    q1_jquery        => create($j->find('p')),
    web_query_libxml => create($wq->find('p)')),
    jquery           => create($jquery->find('p'))
};

foreach my $name (keys %$subs) {
    my $obj = $subs->{$name}->();
    printf "[%s]\n%s\n\n", $name, $obj->can('as_html') ? $obj->as_html : $obj->as_HTML;
}


cmpthese(shift || 20_000, $subs);


sub create {
    my $obj = shift;
    sub {
        $obj->before('<span/>')->end
    }
}

__END__


[cafe@cafepc][~/workspace/Q1]$ perl t/jquery/benchmark/before.pl 10000
[jquery]
<div>
<span></span><p></p>
</div>

[q1_jquery]
<div><span></span><p></p></div>

[web_query_libxml]
<div><span></span><p></p></div>

                   Rate web_query_libxml           jquery        q1_jquery
web_query_libxml 4202/s               --              -3%             -37%
jquery           4329/s               3%               --             -35%
q1_jquery        6623/s              58%              53%               --
[cafe@cafepc][~/workspace/Q1]$ perl t/jquery/benchmark/before.pl 20000
[jquery]
<div>
<span></span><p></p>
</div>

[q1_jquery]
<div><span></span><p></p></div>

[web_query_libxml]
<div><span></span><p></p></div>

                   Rate web_query_libxml           jquery        q1_jquery
web_query_libxml 4219/s               --              -3%             -36%
jquery           4357/s               3%               --             -34%
q1_jquery        6645/s              57%              52%               --
[cafe@cafepc][~/workspace/Q1]$ perl t/jquery/benchmark/before.pl 200000
[jquery]
<div>
<span></span><p></p>
</div>

[q1_jquery]
<div><span></span><p></p></div>

[web_query_libxml]
<div><span></span><p></p></div>

                   Rate web_query_libxml           jquery        q1_jquery
web_query_libxml 4200/s               --              -3%             -37%
jquery           4326/s               3%               --             -35%
q1_jquery        6631/s              58%              53%               --
