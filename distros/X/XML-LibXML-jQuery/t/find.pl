#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Benchmark qw(:all);
use Web::Query::LibXML;
use XML::LibXML::jQuery;
use jQuery;

my $source = '<div><span></span><b></b></div>';
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
    printf "%s -> %s\n", $name, join '.', $obj->can('as_html') ? $obj->as_html : $obj->as_HTML;
}


cmpthese(shift || 1000, $subs);


sub create {
    my $obj = shift;
    sub {
        $obj->find('span,b')
    }
}

__END__


NOTE: jQuery did not return correct result (<span></span><b></b>)


[cafe@cafepc][~/workspace/Q1]$ perl t/jquery/benchmark/find.pl 100000
jquery -> <div>
<span></span><b></b>
</div>
q1_jquery -> <span></span><b></b>
web_query_libxml -> <span></span>.<b></b>
                     Rate web_query_libxml        q1_jquery           jquery
web_query_libxml   8993/s               --             -15%             -92%
q1_jquery         10627/s              18%               --             -91%
jquery           119048/s            1224%            1020%               --
