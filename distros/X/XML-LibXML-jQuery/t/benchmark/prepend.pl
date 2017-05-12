#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Benchmark qw(:all);
use Web::Query::LibXML;
use XML::LibXML::jQuery;
use jQuery;

my $source = '<div><two/></div>';
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
    printf "%s -> %s\n", $name, $obj->can('as_html') ? $obj->as_html : $obj->as_HTML;
}


cmpthese(shift || 20_000, $subs);


sub create {
    my $obj = shift;
    sub {
        $obj->prepend('<one/>')
    }
}


__END__

=head1 last run

[cafe@cafepc][~/workspace/Q1]$ perl t/jquery/benchmark/prepend.pl 3000
jquery -> <div><span></span></div>
q1_jquery -> <div><span></span></div>
web_query_libxml -> <div><span></span></div>
                   Rate           jquery web_query_libxml        q1_jquery
jquery           81.8/s               --             -98%             -99%
web_query_libxml 4110/s            4923%               --             -38%
q1_jquery        6667/s

=cut
