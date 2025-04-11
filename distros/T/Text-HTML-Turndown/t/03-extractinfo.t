#!perl
use 5.020;
use Test2::V0 '-no_srand';
use XML::LibXML;
use File::Basename;
use Text::HTML::ExtractInfo 'extract_info';
use JSON::Tiny 'decode_json';

my @tests = (
    { html => '<html></html>',
      options => {},
      expected => {},
      name => 'Empty HTML'
    },
    { html => '<html><title>in head</title></html>',
      options => {},
      expected => { title => 'in head' },
      name => 'title tag'
    },
    { html => '<html><meta property="og:title" content="FB title" /></html>',
      options => {},
      expected => { title => 'FB title' },
      name => 'opengraph title tag'
    },
    { html => '<html><meta property="twitter:title" content="X title"/></html>',
      options => {},
      expected => { title => 'X title' },
      name => 'Twitter title tag'
    },
    { html => '<html><title>in head</title><h1>in first H1 tag</h1></html>',
      options => {},
      expected => { title => 'in head' },
      name => 'title tag takes precedence over H1 tag'
    },
    { html => '<html><h1>in first H1 tag</h1><h1>in second H1 tag</h1></html>',
      options => {},
      expected => { title => 'in first H1 tag' },
      name => 'H1 tag'
    },
    { html => '<html></html>',
      options => { url => 'https://example.com/other_link' },
      expected => { url => 'https://example.com/other_link' },
      name => 'URL is taken from options'
    },
    { html => '<html><link rel="canonical" href="https://example.com/link" /></html>',
      options => {},
      expected => { url => 'https://example.com/link' },
      name => 'canonical URL'
    },
    { html => '<html><link rel="canonical" href="https://example.com/link" /></html>',
      options => { url => 'https://example.com/other_link' },
      expected => { url => 'https://example.com/link' },
      name => 'canonical URL takes precedence'
    },
);

for my $t (@tests) {
    my $name = $t->{name};
    my $tree = XML::LibXML->new->parse_html_string(
      $t->{html},
      { recover => 2, encoding => 'UTF-8' }
    );
    my $expected = $t->{expected};

    if(! is( extract_info( $tree, $t->{options}->%* ), $expected, $name )) {
        diag $t->{html};
    }
}

done_testing();
