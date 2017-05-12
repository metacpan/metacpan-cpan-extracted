#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use WWW::DuckDuckGo::Icon;
use WWW::DuckDuckGo::Link;
use WWW::DuckDuckGo::ZeroClickInfo;

BEGIN {

	my $icon = WWW::DuckDuckGo::Icon->by({ 'URL' => 'http://i.duck.co/i/4bd98dc2.jpg' });
	
	isa_ok($icon, 'WWW::DuckDuckGo::Icon');
	is($icon->url->as_string, 'http://i.duck.co/i/4bd98dc2.jpg', 'Checking for correct url in icon');
	is($icon->has_width ? 1 : 0, 0, 'Checking for non-existance of width');
	is($icon->has_height ? 1 : 0, 0, 'Checking for non-existance of height');

	my $link = WWW::DuckDuckGo::Link->by({
		'Result' => '<a href="http://duckduckgo.com/Gordon_Getty">Gordon Getty</a>, J. Paul Getty\'s son',
		'Icon' => {},
		'FirstURL' => 'http://duckduckgo.com/Gordon_Getty',
		'Text' => 'Gordon Getty, J. Paul Getty\'s son'
	});
	
	isa_ok($link, 'WWW::DuckDuckGo::Link');
	is($link->first_url->as_string, 'http://duckduckgo.com/Gordon_Getty', 'Checking for correct url in link');
	is($link->has_icon ? 1 : 0, 0, 'Checking for non-existance of icon');
	is($link->has_result ? 1 : 0, 1, 'Checking for existance of result');
	is($link->result, '<a href="http://duckduckgo.com/Gordon_Getty">Gordon Getty</a>, J. Paul Getty\'s son', 'Checking for correct result');
	is($link->has_text ? 1 : 0, 1, 'Checking for existance of text');
	is($link->text, 'Gordon Getty, J. Paul Getty\'s son', 'Checking for correct text');

	my $zci = WWW::DuckDuckGo::ZeroClickInfo->by({
		'Definition' => '',
		'Heading' => 'Duck Duck Go',
		'DefinitionSource' => '',
		'AbstractSource' => 'Wikipedia',
		'Image' => 'http://i.duck.co/i/37bc399d.png',
		'RelatedTopics' => [
			{
				'Result' => '<a href="http://duckduckgo.com/c/Internet_search_engines">Internet search engines</a>',
				'Icon' => {},
				'FirstURL' => 'http://duckduckgo.com/c/Internet_search_engines',
				'Text' => 'Internet search engines'
			}
		],
		'Abstract' => 'Duck Duck Go is a search engine based in Valley Forge, Pennsylvania that uses information from crowd-sourced sites with the aim of augmenting traditional results and improving relevance.',
		'AbstractText' => 'Duck Duck Go is a search engine based in Valley Forge, Pennsylvania that uses information from crowd-sourced sites with the aim of augmenting traditional results and improving relevance.',
		'Type' => 'A',
		'AnswerType' => '',
		'DefinitionURL' => '',
		'Results' => [
			{
				'Result' => '<a href="http://duckduckgo.com/"><b>Official site</b></a><a href="http://duckduckgo.com/"></a>',
				'Icon' => {
					'URL' => 'http://i.duck.co/i/duckduckgo.com.ico',
					'Height' => 16,
					'Width' => 16
				},
				'FirstURL' => 'http://duckduckgo.com/',
				'Text' => 'Official site'
			}
		],
		'Answer' => '',
		'AbstractURL' => 'http://en.wikipedia.org/wiki/Duck_Duck_Go',
		'HTML' => '<a href="test">test</a>',
	});

	isa_ok($zci, 'WWW::DuckDuckGo::ZeroClickInfo');
	is($zci->has_definition ? 1 : 0, 0, 'Checking for non-existance of definition');
	is($zci->has_heading ? 1 : 0, 1, 'Checking for existance of heading');
	is($zci->heading, 'Duck Duck Go', 'Checking for correct heading');
	is($zci->has_definition_source ? 1 : 0, 0, 'Checking for non-existance of definition source');
	is($zci->has_abstract_source ? 1 : 0, 1, 'Checking for existance of abstract source');
	is($zci->abstract_source, 'Wikipedia', 'Checking for correct abstract source');
	is($zci->has_image ? 1 : 0, 1, 'Checking for existance of image');
	isa_ok($zci->image, 'URI::http');
	is($zci->image->as_string, 'http://i.duck.co/i/37bc399d.png', 'Checking for correct image url');
	is($zci->has_abstract ? 1 : 0, 1, 'Checking for existance of abstract');
	is($zci->abstract, 'Duck Duck Go is a search engine based in Valley Forge, Pennsylvania that uses information from crowd-sourced sites with the aim of augmenting traditional results and improving relevance.', 'Checking for correct abstract');
	is($zci->has_abstract_text ? 1 : 0, 1, 'Checking for existance of abstract text');
	is($zci->abstract_text, 'Duck Duck Go is a search engine based in Valley Forge, Pennsylvania that uses information from crowd-sourced sites with the aim of augmenting traditional results and improving relevance.', 'Checking for correct abstract text');
	is($zci->has_type ? 1 : 0, 1, 'Checking for existance of type');
	is($zci->type, 'A', 'Checking for correct type');
	is($zci->type_long, 'article', 'Checking for correct type long');
	is($zci->has_answer_type ? 1 : 0, 0, 'Checking for non-existance of answer type');
	is($zci->has_definition_url ? 1 : 0, 0, 'Checking for non-existance of definition url');
	is($zci->has_answer ? 1 : 0, 0, 'Checking for non-existance of answer');
	is($zci->has_abstract_url ? 1 : 0, 1, 'Checking for existance of abstract url');
	is($zci->html, '<a href="test">test</a>', 'Checking for correct html');
	is($zci->has_html ? 1 : 0, 1, 'Checking for existance of html');

}

done_testing;