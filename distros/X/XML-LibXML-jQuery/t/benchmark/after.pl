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
        $obj->after('<span/>')->end
    }
}

__END__


[cafe@cafepc][~/workspace/Q1]$ perl t/jquery/benchmark/after.pl 10000
jquery -> <div>
<p></p>
<span></span>
</div>
q1_jquery -> <div><p></p><span></span></div>
web_query_libxml -> <div><p></p><span></span></div>
                   Rate web_query_libxml           jquery        q1_jquery
web_query_libxml 4184/s               --              -3%             -36%
jquery           4310/s               3%               --             -34%
q1_jquery        6536/s              56%              52%               --
