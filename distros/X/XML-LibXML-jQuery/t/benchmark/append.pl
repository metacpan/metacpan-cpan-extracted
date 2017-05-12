#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Benchmark qw(:all);
use Web::Query::LibXML;
use XML::LibXML::jQuery;
use jQuery;
use Mojo::DOM;

my $source = '<div/>';
my $j = j($source);
my $wq = wq($source);
my $jquery = jQuery($source);

my $subs = {
    q1_jquery        => create($j),
    web_query_libxml => create($wq),
    # jquery           => create($jquery)
};

foreach my $name (keys %$subs) {
    my $obj = $subs->{$name}->();
    printf "%s -> %s\n", $name, $obj->can('as_html') ? $obj->as_html : $obj->as_HTML;
}


cmpthese(shift || 20_000, $subs);


sub create {
    my $obj = shift;
    sub {
        $obj->append('<span/>')
    }
}

__END__


[cafe@cafepc][~/workspace/Q1]$ perl t/jquery/benchmark/append.pl 3000
jquery -> <div><span></span></div>
q1_jquery -> <div><span></span></div>
web_query_libxml -> <div><span></span></div>
                   Rate           jquery web_query_libxml        q1_jquery
jquery           80.7/s               --             -98%             -99%
web_query_libxml 4225/s            5137%               --             -41%
q1_jquery        7143/s            8752%              69%               --
