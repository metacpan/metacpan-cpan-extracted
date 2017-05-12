#!/usr/bin/env perl

# Creation date: 2009-01-04T07:40:56Z
# Authors: don

use strict;
use warnings;

use Test;

eval 'use XML::LibXML::SAX;';
if ($@) {
    # don't have the module, so skip
    plan tests => 1;

    print "# Skipping SAX test since I can't find XML::LibXML::SAX\n";
    skip(1, 1);

    exit 0;
}

use File::Spec ();
BEGIN {
    my $path = File::Spec->rel2abs($0);
    (my $dir = $path) =~ s{(?:/[^/]+){2}\Z}{};
    unshift @INC, $dir . "/lib";
}

plan tests => 9;

use XML::Parser::Wrapper;

my $have_io_scalar;
eval { require IO::Scalar; };
$have_io_scalar = 1 unless $@;

my $xml = qq{<response><stuff>stuff val</stuff><more><stuff><foo><stuff>Hidden Stuff</stuff></foo></stuff></more><deep><deep_var1>deep val 1</deep_var1><deep_var2>deep val 2</deep_var2></deep><stuff>more stuff</stuff><some_cdata><![CDATA[blah]]></some_cdata><tricky><![CDATA[foo]]> bar</tricky></response>};

my @text;

my $handler = sub {
    my ($root) = @_;
    
    my $text = $root->text;
    push @text, $text;
};

my $root = XML::Parser::Wrapper->new_sax_parser({ class => 'XML::LibXML::SAX',
                                                  handler => $handler,
                                                  start_tag => 'stuff',
                                                  # start_depth => 2,
                                                }, $xml);

ok(scalar(@text) == 2 and $text[0] eq 'stuff val' and $text[1] eq 'more stuff');

@text = ();
$root = XML::Parser::Wrapper->new_sax_parser({ class => 'XML::LibXML::SAX',
                                               handler => $handler,
                                               start_tag => 'stuff',
                                               start_depth => 2,
                                             }, $xml);
ok(scalar(@text) == 1 and $text[0] eq 'Hidden Stuff');


my $file = "t/data/sax_test.xml";
if (-e $file) {
    @text = ();

    $root = XML::Parser::Wrapper->new_sax_parser({ class => 'XML::LibXML::SAX',
                                                   handler => $handler,
                                                   start_tag => 'stuff',
                                                   # start_depth => 2,
                                                 }, { file => $file });
    
    ok(scalar(@text) == 2 and $text[0] eq 'stuff val' and $text[1] eq 'more stuff');


}
else {
    skip("Skip cuz couldn't find test file", 1);
}

$xml = qq{<response xmlns:a="http://owensnet.com/schema"><stuff n="foo" a:o="bar&#x3e;"><level2><level3>code</level3><level3>"fu"</level3></level2></stuff><more><stuff><foo><stuff>Hidden Stuff</stuff></foo></stuff></more><deep><deep_var1>deep val 1</deep_var1><deep_var2>deep val 2</deep_var2></deep><stuff>more stuff</stuff><some_cdata><![CDATA[blah]]></some_cdata><tricky><![CDATA[foo]]> bar</tricky></response>};

my $count = 0;
$handler = sub {
    my ($root) = @_;

    $count++;
    
    if ($count == 1) {
        my $attr = $root->attr('n');
        ok($attr eq 'foo');

        $attr = $root->attr('a:o');
        ok($attr eq 'bar>');

        my $l2 = $root->kid_if('level2');
        my $l3_list = $l2->kids('level3');

        ok(@$l3_list == 2 and $l3_list->[0]->text eq 'code' and $l3_list->[1]->text eq '"fu"');

        my $out_xml = $root->to_xml;
        ok($out_xml eq '<stuff a:o="bar&gt;" n="foo"><level2><level3>code</level3><level3>"fu"</level3></level2></stuff>');
    }
};

 $root = XML::Parser::Wrapper->new_sax_parser({ class => 'XML::LibXML::SAX',
                                                  handler => $handler,
                                                  start_tag => 'stuff',
                                                  # start_depth => 2,
                                                }, $xml);


if ($have_io_scalar) {
   $xml = qq{<response><stuff>stuff val</stuff><more><stuff><foo><stuff>Hidden Stuff</stuff></foo></stuff></more><deep><deep_var1>deep val 1</deep_var1><deep_var2>deep val 2</deep_var2></deep><stuff>more stuff</stuff><some_cdata><![CDATA[blah]]></some_cdata><tricky><![CDATA[foo]]> bar</tricky></response>};
   @text = ();

   $handler = sub {
    my ($root) = @_;
    
    my $text = $root->text;
    push @text, $text;
};

    my $io = IO::Scalar->new(\$xml);
    $root = XML::Parser::Wrapper->new_sax_parser({ class => 'XML::LibXML::SAX',
                                                   handler => $handler,
                                                   start_tag => 'stuff',
                                                   # start_depth => 2,
                                                 }, $io);
    
    ok(scalar(@text) == 2 and $text[0] eq 'stuff val' and $text[1] eq 'more stuff');

      $xml = qq{<response><stuff>stuff val</stuff><more><stuff><foo><stuff>Hidden Stuff</stuff></foo></stuff></more><deep><deep_var1>deep val 1</deep_var1><deep_var2>deep val 2</deep_var2></deep><stuff>more stuff</stuff><some_cdata><![CDATA[blah]]></some_cdata><tricky><![CDATA[foo]]> bar</tricky></response>};
   @text = ();

   $handler = sub {
       my ($root) = @_;
    
       my $text = $root->text;
       push @text, $text;
};
   
   $io = IO::Scalar->new(\$xml);
   $root = XML::Parser::Wrapper->new_sax_parser({ class => 'XML::LibXML::SAX',
                                                  handler => $handler,
                                                  start_tag => 'stuff',
                                                  # start_depth => 2,
                                                }, { file => $io });
   
   ok(scalar(@text) == 2 and $text[0] eq 'stuff val' and $text[1] eq 'more stuff');
   
}
else {
    skip(1, 1);
}
