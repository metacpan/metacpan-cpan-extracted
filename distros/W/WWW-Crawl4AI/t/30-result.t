#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use WWW::Crawl4AI::Attempt;
use WWW::Crawl4AI::Result;

my $page = {
  url         => 'https://example.com',
  final_url   => 'https://example.com/',
  status_code => 200,
  markdown    => 'real content ' x 60,
  html        => '<html>...</html>',
  title       => 'Example',
};

my $a_fail = WWW::Crawl4AI::Attempt->new(
  backend    => 'crawl4ai_plain',
  cost_class => 'cheap',
  ok         => 0,
  page       => { status_code => 200, markdown => 'thin' },
  signals    => { thin_html => 1 },
  why_failed => 'thin_content',
  elapsed    => 0.12,
);

my $a_ok = WWW::Crawl4AI::Attempt->new(
  backend    => 'crawl4ai_stealth',
  cost_class => 'stealth',
  ok         => 1,
  page       => $page,
  signals    => {},
  elapsed    => 0.81,
);

subtest 'Attempt to_hash is JSON-safe + compact' => sub {
  my $h = $a_fail->to_hash;
  is $h->{backend}, 'crawl4ai_plain';
  is ${ $h->{ok} }, 0, 'ok is a boolean ref';
  is $h->{markdown_len}, 4, 'markdown reduced to length';
  is $h->{why_failed}, 'thin_content';
  ok !exists $h->{markdown}, 'no full markdown in attempt hash';
};

subtest 'Result::from_attempt copies content' => sub {
  my $r = WWW::Crawl4AI::Result->from_attempt( $a_ok, attempts => [ $a_fail, $a_ok ] );
  ok $r->ok, 'ok';
  is $r->backend, 'crawl4ai_stealth', 'winning backend';
  is $r->cost_class, 'stealth';
  is $r->final_url, 'https://example.com/';
  is $r->status, 200;
  like $r->markdown, qr/real content/, 'markdown carried over';
  is $r->attempt_count, 2, 'two attempts recorded';
};

subtest 'Result surfaces links + urls without raw fumbling' => sub {
  my $page_with_links = {
    url       => 'https://example.com',
    final_url => 'https://example.com/docs/',
    status_code => 200,
    markdown  => 'content ' x 60,
    links     => {
      internal => [
        { href => 'https://example.com/a',  text => 'A' },
        { href => '/docs/b',                text => 'B (relative)' },   # resolved vs final_url
        { href => 'https://example.com/a',  text => 'dup' },           # deduped
        { href => 'javascript:void(0);',    text => 'js' },            # dropped
        { href => '#section',               text => 'anchor' },        # dropped
      ],
      external => [
        { href => 'https://other.example/x', text => 'X' },
        { href => 'mailto:hi@example.com',   text => 'mail' },         # dropped
      ],
    },
  };
  my $attempt = WWW::Crawl4AI::Attempt->new(
    backend => 'crawl4ai_plain', cost_class => 'cheap', ok => 1, page => $page_with_links,
  );
  my $r = WWW::Crawl4AI::Result->from_attempt($attempt);
  is scalar @{ $r->internal_links }, 5, 'internal links carried verbatim';
  is scalar @{ $r->external_links }, 2, 'external links carried verbatim';
  is_deeply $r->urls,
    [ 'https://example.com/a', 'https://example.com/docs/b', 'https://other.example/x' ],
    'urls: deduped, relative resolved, javascript/mailto/anchor dropped, order kept';
};

subtest 'attempts_json round-trips' => sub {
  my $r = WWW::Crawl4AI::Result->from_attempt( $a_ok, attempts => [ $a_fail, $a_ok ] );
  my $decoded = decode_json( $r->attempts_json );
  is scalar @$decoded, 2, 'two attempts in json';
  is $decoded->[0]{backend}, 'crawl4ai_plain';
  is $decoded->[1]{backend}, 'crawl4ai_stealth';
};

subtest 'Result TO_JSON (whole result, convert_blessed)' => sub {
  my $r = WWW::Crawl4AI::Result->from_attempt( $a_ok, attempts => [ $a_fail, $a_ok ] );
  my $h = decode_json( JSON::MaybeXS->new( convert_blessed => 1 )->encode($r) );
  ok $h->{ok}, 'result ok serializes truthy';
  is scalar @{ $h->{attempts} }, 2, 'attempts nested in result json';
};

done_testing;
