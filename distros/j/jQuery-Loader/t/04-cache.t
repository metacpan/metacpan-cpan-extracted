use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;
use Directory::Scratch;
my $scratch = Directory::Scratch->new;
my $base = $scratch->base;
sub file { return $base->file(@_) }

use jQuery::Loader::Source::URI;
use jQuery::Loader::Cache::URI;

my $template = jQuery::Loader::Template->new(version => "1.2.3");
my $uri = "http://jqueryjs.googlecode.com/files/\%j";
my $source = jQuery::Loader::Source::URI->new(template => $template, uri => $uri);
my $cache = jQuery::Loader::Cache::URI->new(source => $source, file => "$base/\%j", uri => "http://example.com/t/\%j");
ok($cache);

SKIP: {
    $ENV{TEST_RELEASE} or skip "Not testing going out to the Internet ($uri)";
    
    is($cache->uri, "http://example.com/t/jquery-1.2.3.js");
    is($cache->file, file "jquery-1.2.3.js");

    $cache = jQuery::Loader::Cache::URI->new(source => $source, file => "$base/\%l", uri => "http://example.com/t/\%l");

    is($cache->uri, "http://example.com/t/jquery-1.2.3.js");
    is($cache->file, file "jquery-1.2.3.js");
    ok(-s $cache->file);

    $cache->uri("http://example.com/t\%/v/\%j");
    is($cache->uri, "http://example.com/t/1.2.3/jquery-1.2.3.js");

    $template->version(undef);

    $cache->recalculate;
    is($cache->uri, "http://example.com/t/jquery.js");

    $template->version("1.2.3");
    $cache = jQuery::Loader::Cache::URI->new(source => $source, template => $template,
        location => "js/jq\%-v.js",
        uri => "http://localhost/assets/\%l",
        file => $base->file("htdocs/static/\%l"),

    );
    is($cache->location->location, "js/jq-1.2.3.js");
    is($cache->file, $base->file("htdocs/static/js/jq-1.2.3.js"));
    is($cache->uri, "http://localhost/assets/js/jq-1.2.3.js");

}
