#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Benchmark qw(:all);
use Web::Query::LibXML;
use XML::LibXML::jQuery;
use jQuery;

my $source = '<div><p></p><b></b></div>';
my $j = j($source);
my $wq = wq($source);
my $jquery = jQuery($source);

my $subs = {
    q1_jquery        => create($j->find('p')),
#    web_query_libxml => create($wq->find('p)')),
    jquery           => create($jquery->find('p'), 'replaceWith')
};

foreach my $name (keys %$subs) {
    my $obj = $subs->{$name}->();
    printf "[%s]\n%s\n\n", $name, $obj->can('as_html') ? $obj->as_html : $obj->as_HTML;
}


cmpthese(shift || 10000, $subs);


sub create {
    my $obj = shift;
    my $method = shift || 'replace_with';
    sub {
        $obj->$method('<p/>')->end;
    }
}

__END__

NOTE:
Web::Query::LibXML was not evaluated coz is failed with this error:
[not supported] calling replace_with() in a node that is child of a document node, and its not the last child. at /home/cafe/perl5/perlbrew/perls/perl-5.16.3/lib/site_perl/5.16.3/HTML/TreeBuilder/LibXML/Node.pm line 237.



[cafe@cafepc][~/workspace/Q1]$ perl t/jquery/benchmark/replace_with.pl 10000
[jquery]
<div>
<p></p>
<b></b>
</div>

[q1_jquery]
<div><p></p><b></b></div>

            Rate    jquery q1_jquery
jquery    2874/s        --      -55%
q1_jquery 6410/s      123%        --

