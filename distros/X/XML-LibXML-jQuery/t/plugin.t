#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use Test::Exception;
use XML::LibXML::jQuery qw/ j fn /;


my $j = j('<div/><div/>');


is $j->style('color:red')->as_html,
   '<div style="color:red"></div><div style="color:red"></div>',
   'plugin method';

is $j->style, 'color:red', 'get value';

dies_ok { $j->unknown } 'AUTOLOAD dies';

dies_ok { fn(style => sub {} ) } 'fn() dies';


done_testing;





BEGIN {
    package XML::LibXML::jQuery::Plugin::Style;
    use XML::LibXML::jQuery qw/ fn /;

    fn style => sub {

        my ($value) = @_;

        return $_->first->attr('style')
            unless defined $value;

        $_->each(sub { $_->setAttribute('style', $value) });

        $_;
    };

}
