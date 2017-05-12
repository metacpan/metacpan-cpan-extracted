use strict;
use Test::More;

use_ok "Text::QueryString";

$ENV{PERL_TEXT_QUERYSTRING_BACKEND} ||= "XS";
is Text::QueryString::BACKEND(), $ENV{PERL_TEXT_QUERYSTRING_BACKEND};

my $tqs = Text::QueryString->new;

{
    my @query = $tqs->parse("foo=bar");
    if (! is_deeply(\@query, [ foo => "bar" ])) {
        diag explain \@query;
    }
}

{
    my @query = $tqs->parse("foo=bar&bar=1");
    my $expect = [ foo => "bar", "bar" => "1" ];
    if (! is_deeply(\@query, $expect)) {
        diag explain \@query;
    }
    my @scquery = $tqs->parse("foo=bar;bar=1");
    if (! is_deeply(\@scquery, $expect)) {
        diag explain(\@scquery);
    }
}

{
    my @query = $tqs->parse("foo=bar&foo=baz");
    if (! is_deeply(\@query, [ foo => "bar", "foo" => "baz" ])) {
        diag explain \@query;
    }
}

{
    my @query = $tqs->parse("foo=bar&foo=baz&bar=baz");
    if (! is_deeply(\@query, [ foo => "bar", "foo" => "baz", "bar" => "baz" ])) {
        diag explain \@query;
    }
}

{
    my @query = $tqs->parse("foo_only");
    if (! is_deeply(\@query, [ foo_only => "" ])) {
        diag explain \@query;
    }
}

{
    my @query = $tqs->parse("foo&bar=baz");
    if (! is_deeply(\@query, [ foo => "", bar => "baz" ])) {
        diag explain \@query;
    }
}

{
    my @query = $tqs->parse("0");
    if (! is_deeply(\@query, [ 0 => "" ])) {
        diag explain \@query;
    }
}

{
    my @query = $tqs->parse("foo=&bar=1 foo=1&bar=");
    if (! is_deeply(\@query, [ foo => "", bar => "1 foo=1", bar => "" ])) {
        diag explain \@query;
    }
}

{
    my @query = $tqs->parse("foo=&bar=1+foo=1&bar=");
    if (! is_deeply(\@query, [ foo => "", bar => "1 foo=1", bar => "" ])) {
        diag explain \@query;
    }
}

{
    my @query = $tqs->parse("foo=1&=&bar=1");
    if (! is_deeply(\@query, [ foo => 1, "" => "", bar => 1 ])) {
        diag explain \@query;
    }
}

done_testing;