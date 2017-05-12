=== static
--- input read_file html
xt/data/Top100/20140630/input.html
--- expected read_file strict eval
xt/data/Top100/20140630/expected.pl

=== dynamic
--- input strict eval
use WWW::GoKGS::Scraper::Top100;
WWW::GoKGS::Scraper::Top100->build_uri;

