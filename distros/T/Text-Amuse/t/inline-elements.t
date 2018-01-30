#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 29;
use Text::Amuse::Document;
use Text::Amuse::Output;
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Deparse = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys = 1;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";



use File::Spec::Functions(qw/catfile/);

my $doc = Text::Amuse::Document->new(file => catfile(t => testfiles => 'broken-tags.muse'));

my @strings = (
               'Test <verbatim>*M \{#!_<"> e*</verbatim><br> =code=' . "\n" .
               'Test <verbatim>**M \{#!_<"> e**</verbatim><br>',
               '<em>This is a [1] long string with [[http://example.com][<strong><em>strong</em></strong>]] emph</em> and some material',
               '**This *is* a [1] long string** with [[http://example.com][<strong><em>strong</em></strong>]] <em>emph</em> and {3} =some= material',
               'syntax for =<example>= is ={{{= =}}}=:',
               'Test <verbatim><verbatim></verbatim> <verbatim></verbatim></verbatim>',
               '<code><verbatim>[[link]]</verbatim></code>',
               '<br>',
               "<em>à\n<br>\nđ</em>",
               "0",
               "\n0",
               "=== there =*=",
              );

foreach my $str (@strings) {
    foreach my $fmt (qw/ltx html/) {
        my $out = Text::Amuse::Output->new(document => $doc,
                                           format => $fmt);
        {
            my @out = $out->inline_elements($str);
            ok scalar(@out);
            # diag Dumper(\@out);
            diag $out->manage_regular($str);
        }
    }
}

{
    my $parser = Text::Amuse::Output->new(document => $doc,
                                          format => 'ltx');
    is $parser->manage_regular('=== there =*='), '\texttt{=} there \texttt{*}';
    is $parser->manage_regular('This (=should be code=).'), 'This (\texttt{should be code}).';
    is $parser->manage_regular('***Hello there ***'), '***Hello there ***';
    is $parser->manage_regular('This <code> should work'), 'This <code> should work';
    is $parser->manage_regular('This <code><code></code> should work'), 'This \texttt{<code>} should work';
    is $parser->manage_regular('Same **(*a is paired so it works a*)**'),
      'Same \textbf{(\emph{a is paired so it works a})}';
    is $parser->manage_regular('Same =here **(*a is paired so it works a*)** here='),
      'Same \texttt{here **(*a is paired so it works a*)** here}';

}
