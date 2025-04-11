#!/usr/bin/env perl
use 5.020;
use PerlX::Maybe;
use Getopt::Long;
use Pod::Usage;

use XML::LibXML;
use Text::HTML::Turndown;
use Text::HTML::ExtractInfo 'extract_info';
use Text::FrontMatter::YAML;
use Text::CleanFragment 'clean_fragment';

our $VERSION = '0.05';

GetOptions(
    'url|u=s' => \my $url,
    'outfile|o=s' => \my $outname,
    'outfile-from-title|t' => \my $guess_outname,
) or pod2usage(2);

my $html = do { local $/; <> }; # sluuurp
my $tree = XML::LibXML->new->parse_html_string(
      $html,
      { recover => 2, encoding => 'UTF-8' }
);

my $frontmatter = extract_info(
    $tree, 
    maybe url => $url,
);

my $convert = Text::HTML::Turndown->new();
my $markdown = $convert->turndown($tree);


my $tfm = Text::FrontMatter::YAML->new(
    frontmatter_hashref => $frontmatter,
    data_text => $markdown,
);

if( $guess_outname ) {
    $outname //= sprintf '%s.markdown', clean_fragment($frontmatter->{title});
}
if( $outname ) {
    open *STDOUT, '>:encoding(UTF-8)', $outname;
}
say $tfm->document_string;

