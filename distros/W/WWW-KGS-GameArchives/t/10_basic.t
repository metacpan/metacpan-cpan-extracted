use strict;
use warnings;
use WWW::KGS::GameArchives;
use Test::More tests => 5;

my $archives = WWW::KGS::GameArchives->new;

isa_ok $archives, 'WWW::KGS::GameArchives';

can_ok $archives, qw(
    base_uri
    user_agent
    has_user_agent
    _scraper
    scrape
    query
);

isa_ok $archives->base_uri, 'URI';
is $archives->base_uri->as_string, 'http://www.gokgs.com/gameArchives.jsp';

isa_ok $archives->_scraper, 'Web::Scraper';
