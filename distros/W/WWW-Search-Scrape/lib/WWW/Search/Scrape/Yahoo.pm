package WWW::Search::Scrape::Yahoo;

use warnings;
use strict;

use Carp;
use WWW::Mechanize;
use HTML::TreeBuilder;
use URI::Escape;

=head1 NAME

  WWW::Search::Scrape::Yahoo - Yahoo search engine

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

=cut


sub search($$;$)
{
    my ($keyword, $results_num, $content) = @_;
### search Yahoo using
###   keyword: $keyword
###   results number: $results_num
###   content: $content

    my $num = 0;

    if ($results_num > 100) {
        carp 'WWW::Search::Scrape::Yahoo can not process results more than 100.';
        return undef;
    }

    my @res;

    unless ($content)
    {
#yahoo is funny about search result count. Valid values are: 10,15,20,30,40,100
# set up the value to provide at least the number required
	    my $yahoo_result_num;
	    if ($results_num < 10) {
		    $yahoo_result_num = 10;
	    } elsif ($results_num < 15) {
		    $yahoo_result_num = 15;
	    } elsif ($results_num < 20) {
		    $yahoo_result_num = 20;
	    } elsif ($results_num < 30) {
		    $yahoo_result_num = 30;
	    } elsif ($results_num < 40) {
		    $yahoo_result_num = 40;
	    } elsif ($results_num < 100) {
		    $yahoo_result_num = 100;
	    }

	    my $mech = WWW::Mechanize->new(cookie_jar => {});
	    $mech->agent_alias('Windows Mozilla');
	    $mech->get('http://search.yahoo.com/');
#$mech->dump_forms;
	    $mech->submit_form(
			    form_number => 1,
			    fields => {
			    p => $keyword,
			    'sb-top' => 'fr2',
			    ei => 'UTF-8',
			    n => $yahoo_result_num,                                      
			    });
	    if ($mech->success) {                                      
		    $content = $mech->response->decoded_content;
	    }
    }
    
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);
    $tree->eof;

# yahoo does not show the total result count
    
    my @x = $tree->look_down('_tag', 'h3');

    foreach (@x) {
	    my ($link) = $_->look_down('_tag', 'a');
	    if ($link) {
		    my $obfuscatedHref = $link->attr('href');
		    if ($obfuscatedHref =~ /.*\*\*(.*)/) {
			    push @res, uri_unescape($1);

#if we have reached the max size we originally asked for, leave now
			    last if (scalar(@res) >= $results_num);

		    }
	    }
    }

    return {num => $num, results => \@res};
}
