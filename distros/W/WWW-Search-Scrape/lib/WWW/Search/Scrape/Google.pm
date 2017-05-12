package WWW::Search::Scrape::Google;

use warnings;
use strict;
use Data::Dumper;

use Carp;

#use LWP::UserAgent;
use HTML::TreeBuilder;
use WWW::Mechanize;
use HTML::TreeBuilder::XPath;

=head1 NAME

  WWW::Search::Scrape::Google - Google search engine

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

You are not expected to use this module directly. Please use WWW::Search::Scrape instead.

=cut

=head1 FUNCTIONS

=head2 search

search is the most important function in this module.

Inputs

 +---------------------------+
 |        keyword            |
 +---------------------------+
 | desired number of results |
 +---------------------------+

Actually there is another optional argument, content, which is used in debug/test. It will replace LWP::UserAgent.

=cut

our $frontpage = 'http://www.google.com/ncr';
our $geo_location = '';

sub search($$;$)
{
    my ($keyword, $results_num, $content) = @_;
### search google using
###   keyword: $keyword
###   results number: $results_num
###   content: $content

    my $num = 0;

    if ($results_num >= 100) {
        carp 'WWW::Search::Scrape::Google can not process results more than 100.';
        return undef;
    }

    my @res;

    unless ($content)
    {
        my $mech = WWW::Mechanize->new(agent => 'NotWannaTellYou', cookie_jar => {});
        $mech->get($frontpage);
        #$mech->dump_forms;
        $mech->submit_form(
                           form_number => 1,
                           fields => {
                                      q => $keyword,
                                      num => $results_num,
                                      start => 0,
                                      gl => $geo_location
                                     },
                           button => 'btnG');
        if ($mech->success) {
            $content = $mech->response()->decoded_content();
        }
    }

    if (! $content)
    {
	    carp 'Failed to get content.';
	    return undef;
    }
    
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($content);
    $tree->eof;

    my $num_str = $tree->findvalue('//div[@id="resultStats"]');
    if ($num_str =~ /([\d,]+)/) {
	$num = $1;
	$num =~ s/,//g;
    }

    # parse Google returned number
    @res = $tree->findvalues('//li[@class="g"]/h3/a/@href');

### Result: @res
    return {num => $num, results => \@res};
}

1;
