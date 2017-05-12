#!/usr/bin/perl
use strict;
use warnings;

use Test::RequiresInternet ('thedailywtf.com' => 80);
use Test::More tests => 15;
BEGIN { use_ok('WebService::TDWTF') };

my $art = tdwtf_article;
ok $art->Title, 'article';
$art = tdwtf_article 8301;
is $art->Title, 'Your Recommended Virus', 'article 8301';
$art = tdwtf_article 'your-recommended-virus';
is $art->Title, 'Your Recommended Virus', 'article \'your-recommended-virus\'';

my @recent = tdwtf_list_recent;
is @recent, 8, 'tdwtf_list_recent';
@recent = tdwtf_list_recent 2;
is @recent, 2, 'tdwtf_list_recent 2';

my @dec15 = tdwtf_list_recent 2015, 12;
is $dec15[0]->Title, 'Best of 2015: The A(nti)-Team', 'tdwtf_list_recent 2015, 12';
#is $dec15[0]->BodyHtml, '', '->BodyHtml';
isnt $dec15[0]->Body, '', '->Body';
isnt $dec15[0]->Body, '', '->Body (cached)';

my @erik = tdwtf_list_author 'erik-gern';
is @erik, 8, 'tdwtf_list_author \'erik-gern\'';

my @sod = tdwtf_list_series 'code-sod', 5;
is @sod, 5, 'tdwtf_list_series \'code-sod\', 5';

my @series = tdwtf_series;
note 'Found ' . @series . ' series';
cmp_ok @series, '==', scalar tdwtf_series, 'tdwtf_series scalar context';
my ($codesod) = grep { $_->{Title} =~ /codesod/i } @series;
is $codesod->{Slug}, 'code-sod', 'tdwtf_series finds CodeSOD';

my ($last) = tdwtf_list_recent 1;
ok !defined $last->NextArticle, 'last article has no next article';
is $last->PreviousArticle->NextArticle->Id, $last->Id, 'next article of the previous article is current article';
