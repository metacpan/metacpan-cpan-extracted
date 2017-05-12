package WWW::Search::Scrape::Bing;

use warnings;
use strict;

use Carp;
use WWW::Mechanize;
use HTML::TreeBuilder;

# use Smart::Comments;

=head1 NAME

  WWW::Search::Scrape::Bing - Bing search engine

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


sub search($$;$)
{
    my ($keyword, $results_num, $content) = @_;
### search Bing using
###   keyword: $keyword
###   results number: $results_num
###   content: $content

    my $num = 0;

    if ($results_num > 50) {
        carp 'WWW::Search::Scrape::Bing can not process results more than 50.';
        return undef;
    }

    my @res;

    unless ($content)
    {
        my $mech = WWW::Mechanize->new(cookie_jar => {});
        $mech->agent_alias('Windows IE 6');
        $mech->get('http://www.bing.com/?mkt=en-us');
        #$mech->dump_links();
        $mech->follow_link(url_regex => qr/^\/settings.aspx/);
        #$mech->dump_forms;
        $mech->submit_form(
                           form_number => 1,
                           fields => {
                                      rpp => '50',
                                      sl => '40',
                                      setplang => 'en-US',
                                      langall => '0',
                                      });
        #$mech->dump_forms;
        $mech->submit_form(form_number => 1,
                           fields => {
                                      q => $keyword,
                                      });
        #print $mech->uri, "\n";
        #print $mech->title;
        $content = $mech->response->decoded_content;
    }
    
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);
    $tree->eof;

    # parse Bing returned number
    {
        my ($xx) = $tree->look_down('_tag', 'span',
                                    sub
                                    {
                                        return unless $_[0]->attr('class') && $_[0]->attr('class') eq 'sb_count';
                                    });
        return {num => 0, results => undef} unless $xx;

        my @r = $xx->content_list;
        my ($number) = $r[0] =~ /of ([\d,]+) res/;
        $num = join('', split(',', $number));
        ### Bing returns: $num
    }

    my @x = $tree->look_down('_tag', 'h3');

    foreach (@x) {
        my ($link) = $_->look_down('_tag', 'a');

        if ($link) {
            push @res, $link->attr('href') unless $link->attr('href') =~ /^\//;
        }
    }

### Result: @res
    return {num => $num, results => \@res};
}
    
