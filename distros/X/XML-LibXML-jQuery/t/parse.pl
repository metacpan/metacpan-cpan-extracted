#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Benchmark qw(:all);
use Web::Query::LibXML;
use XML::LibXML::jQuery;
use jQuery;

my $source =  <<HTML;
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>addClass demo</title>
  <style>
  p {
    margin: 8px;
    font-size: 16px;
  }
  .selected {
    color: blue;
  }
  .highlight {
    background: yellow;
  }
  </style>
  <script src="//code.jquery.com/jquery-1.10.2.js"></script>
</head>
<body>

<p>Hello</p>
<p>and</p>
<p>Goodbye</p>

<script>
\$( "p" ).last().addClass( "selected" );
</script>

</body>
</html>
HTML


my $subs = {
    q1_jquery        => create(\&j),
    web_query_libxml => create(\&wq),
    jquery           => create(\&jquery)
};

foreach my $name (keys %$subs) {
    my $obj = $subs->{$name}->();
#    printf "%s -> %s\n", $name, $obj->can('as_html') ? $obj->as_html : $obj->as_HTML;
}


cmpthese(shift || 1000, $subs);


sub create {
    my $obj = shift;
    sub {
        $obj->($source)
    }
}

__END__


[cafe@cafepc][~/workspace/Q1]$ perl t/jquery/benchmark/parse.pl 10000
                   Rate           jquery web_query_libxml        q1_jquery
jquery           2801/s               --             -45%             -61%
web_query_libxml 5102/s              82%               --             -28%
q1_jquery        7092/s             153%              39%               --







