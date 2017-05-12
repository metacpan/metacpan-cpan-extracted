#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use YATT::Lite::Test::TestUtil;
use YATT::Lite::Breakpoint ();

my $CLASS = 'YATT::Lite::WebMVC0::SubRoutes';

require_ok($CLASS);

{
  my $results_params = sub {
    my ($pattern, @expect_params) = @_;
    my ($re, @got_params) = $CLASS->parse_pattern($pattern);
    is_deeply(\@got_params, \@expect_params, "params: $pattern");
  };

  $results_params->('/');
  $results_params->('/blog');
  $results_params->('/blog/:uid', ['uid']);
  $results_params->('/:uid',      ['uid']);


  $results_params->('/authors');
  $results_params->('/authors/:id'
		    , ['id']);
  $results_params->('/authors/:id/edit'
		    , ['id']);

  $results_params->('/:controller(/:action(/:id))'
		    , ['controller'], ['action'], ['id']);


  $results_params->('/articles/:article_id/comments'
		    , ['article_id']);
  $results_params->('/articles/:article_id/comments/:id'
		    , ['article_id'], ['id']);
  $results_params->('/articles/:article_id/comments/:id/edit'
		    , ['article_id'], ['id']);


  $results_params->("/{controller}/{action}/{id}"
		    , ['controller'], ['action'], ['id']);

  $results_params->('/blog/{year}/{month}'
		    , ['year'], ['month']);
  $results_params->('/blog/{year:[0-9]+}/{month:[0-9]{2}}'
		    , ['year'], ['month']);
  $results_params->('/blog/{year:\d+}/{month:\d{2}}'
		    , ['year'], ['month']);

  $results_params->('/blog/{year}-{month}'
		    , ['year'], ['month']);

  $results_params->('/{controller}(/{action}(/{id}))'
		    , ['controller'], ['action'], ['id']);

}

{
  my $builder = sub {
    my $obj = $CLASS->new;
    $obj->append(map {$obj->create(@$_)} @_);
    sub {
      my ($path, $expect) = @_;
      is_deeply [$obj->match($path)], $expect, "match: $path => $expect->[0]";
    };
  };


  # ['location' => item]
  # or
  # [[name => 'location'] => item]

  my $t;
  $t = $builder->(['/' => 'ROOT']

		  , [[article_list => '/articles'], ]
		  , [[show_article => '/article/:id'], ]
		  , [[article_comment => '/article/:article_id/comment/:id'], ]
		  , [[blog_archive => '/blog/{year:digits}-{month:[0-9]{2}}'],]
		  , [[blog_other   => '/blog/{other}'], ]

		  , [[generic      => '/:controller(/:action(/:id))'], ]
		 );

  # Results should be: [name//item => [formal params] => [actual params]]
  $t->("/"
       , [ROOT => []
	  => []]);

  $t->("/article/foo"
       , [show_article => [['id']]
	  => ['foo']]);

  $t->("/article/1234/comment/5678"
       , [article_comment => [['article_id'], ['id']]
	  => [1234, 5678]]);

  $t->("/blog/2001-01"
       , [blog_archive    => [[year => 'digits'], ['month']]
	  => [2001, '01']]);

  $t->("/blog/foobar"
       , [blog_other      => [['other']]
	  => ['foobar']]);

  $t->("/foo"
       , [generic => [['controller'], ['action'], ['id']]
	  => ['foo', undef, undef]]);
  $t->("/foo/bar"
       , [generic => [['controller'], ['action'], ['id']]
	  => ['foo', 'bar', undef]]);
  $t->("/foo/bar/baz"
       , [generic => [['controller'], ['action'], ['id']]
	  => ['foo', 'bar', 'baz']]);
}

done_testing();
