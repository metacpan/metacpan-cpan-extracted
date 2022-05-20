#!perl

use utf8;
use FindBin qw($Bin);
use Test::More tests => 23;

BEGIN {
    use_ok( 'WWW::Wappalyzer' ) || print "Bail out!\n";
}

ok my $wappalyzer = WWW::Wappalyzer->new;
ok $wappalyzer->isa( WWW::Wappalyzer );

my @cats = $wappalyzer->get_categories_names();
ok scalar @cats, 'get_categories_names';
ok scalar( grep { $_ eq 'CMS' } @cats ), 'get_categories_names cms';

my $html = q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ru-ru" lang="ru-ru" >
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <meta name="robots" content="index, follow" />
  <meta name="keywords" content="joomla, CMS Joomla, движок сайта" />
  <meta name="description" content="Joomla! - система управления содержимым - основа динамического портала" />
  <meta name="generator" content="Joomla! 1.5 - Open Source Content Management" />
  <title>Lib</title>
  <link href="/index.php?format=feed&amp;type=rss" rel="alternate" type="application/rss+xml" title="RSS 2.0" />
  <link href="/index.php?format=feed&amp;type=atom" rel="alternate" type="application/atom+xml" title="Atom 1.0" />
  <link href="/templates/rhuk_milkyway/favicon.ico" rel="shortcut icon" type="image/x-icon" />
  <script type="text/javascript" src="/media/system/js/jquery.1.5.4.js"></script>
  <script type="text/javascript" src="/media/system/js/caption.js"></script>};

my %detected = $wappalyzer->detect(
    html     => $html,
    headers  => {
        Server => 'nginx',
        'X-Powered-By' => 'PleskLin',
    },
);

is_deeply \%detected, {
    'Web servers'           => [ 'Nginx'  ],
    'Reverse proxies'       => [ 'Nginx'  ],
    'CMS'                   => [ 'Joomla' ],
    'JavaScript libraries'  => [ 'jQuery' ],
    'Hosting panels'        => [ 'Plesk'  ],
}, 'detect by html & headers';

%detected = $wappalyzer->detect( url => 'http://myblog.livejournal.com' );
is_deeply \%detected, { Blogs => [ 'LiveJournal' ] }, 'detect by url';

%detected = $wappalyzer->detect(
    headers  => { Server => 'nginx' },
    cats => [ 'Web servers' ],
);
is_deeply \%detected, { 'Web servers' => [ 'Nginx' ] }, 'detect single cat';

%detected = $wappalyzer->detect(
    html => q{<link href="./dist/css/bootstrap.css" rel="stylesheet">},
    cats => [ 'UI frameworks' ],
);
is_deeply \%detected, { 'UI frameworks' => [ 'Bootstrap' ] }, 're with html entity';

$html = q{
var rls = {b1: {position: '1',use_from: '0',start: '0',end: '9',amount: '10',type: 'manual'}}</script>
<script type="text/javascript" language="JavaScript" src="http://img.sedoparking.com/jspartner/google.js"></script>
<script type="text/javascript" language="JavaScript">var ads_label = '<h2><span>
<a class="ad_sense_help" href="https://www.google.com/adsense/support/bin/request.py?
};

%detected = $wappalyzer->detect( html => $html );
is_deeply \%detected, {}, 'detect before add techs file';
$wappalyzer->add_categories_files( "$Bin/add_categories.json" );
$wappalyzer->add_technologies_files( "$Bin/add_techs.json" );

%detected = $wappalyzer->detect(
    html => $html,
    headers  => { Server => 'nginx' },
);
is_deeply
    \%detected,
    {
        Parkings          => [ 'sedoparking' ],
        'Web servers'     => [ 'Nginx' ],
        'Reverse proxies' => [ 'Nginx' ]
    },
    'detect after add files'
;

$wappalyzer->reload_files();
%detected = $wappalyzer->detect(
    html => $html,
    headers  => { Server => 'nginx' },
);
is_deeply
    \%detected,
    {
        Parkings          => [ 'sedoparking' ],
        'Web servers'     => [ 'Nginx' ],
        'Reverse proxies' => [ 'Nginx' ]
    },
    'detect still works after reload files'
;

$wappalyzer = WWW::Wappalyzer->new(
    categories => [ "$Bin/add_categories.json" ],
    technologies => [ "$Bin/add_techs.json" ],
);

%detected = $wappalyzer->detect(
    html => $html,
    headers  => { Server => 'nginx' },
);
is_deeply
    \%detected,
    {
        Parkings          => [ 'sedoparking' ],
        'Web servers'     => [ 'Nginx' ],
        'Reverse proxies' => [ 'Nginx' ]
    },
    'detect works when add files in constructor'
;

%detected = $wappalyzer->detect(
    html => 'aaa { bbb',
);
is_deeply \%detected, { Parkings => [ 'open_curly_bracket' ] }, 'detect open curly bracket';

$html = q{
<!doctype html>
<HTML>
<HEAD>
<META name="robots" content="index,follow">
<META http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<TITLE>SALVADOR регистрация доменов RU,COM,NET,ORG,etc,...</TITLE>
};

%detected = $wappalyzer->detect(
    html => $html,
    headers  => { Server => 'nginx' },
);
is_deeply
    \%detected,
    {
        'Web servers'     => [ 'Nginx' ],
        'Reverse proxies' => [ 'Nginx' ],
    },
    'detect parking with confidence, 50% found'
;

$html .= q{
    <meta http-equiv="Content-Language" Content="ru">
<meta name="copyright" Content="1'st Domain Name Service">
<meta name="revisit-after" Content="7 days">
<LINK href="style.css" rel="stylesheet" type="text/css">
<LINK REL="SHORTCUT ICON" href="/favicon.ico">
};

%detected = $wappalyzer->detect(
    html => $html,
    headers  => { Server => 'nginx' },
);
is_deeply
    \%detected,
    {
        Parkings => [ '1reg.online' ],
        'Web servers'     => [ 'Nginx' ],
        'Reverse proxies' => [ 'Nginx' ],
     },
     'detect parking with confidence, 100% found';

eval { $wappalyzer->detect(
    html => 1,
    headers => 'bad',
) };
like $@, qr/Bad headers/;

eval { $wappalyzer->detect(
    html => 1,
    headers => { key => { 1 => 2 } },
) };
ok !$@, 'header skip hashes';

%detected = $wappalyzer->detect( headers => { 'seT-Header' => 'C' } );
is_deeply \%detected, { Parkings => [ 'header-value-test' ] }, 'header single value';

%detected = $wappalyzer->detect( headers => { 'Set-Header' => [ 'a', 'b', 'c' ] } );
is_deeply \%detected, { Parkings => [ 'header-value-test' ] }, 'header multi value';

my @cookies = (
    'ZezzionId=ddd; Expires=Mon, 21-May-2012 12:58:39 GMT; Domain=.yandex.ru; Path=/',
);
%detected = $wappalyzer->detect( headers => { 'Set-Cookie' => \@cookies } );
is_deeply \%detected, { Parkings => [ 'cookies-empty-re' ] }, 'cookies-empty-re';

@cookies = (
    '_ym_d=; Expires=Mon, 21-May-2012 12:58:39 GMT; Domain=.yandex.ru; Path=/',
    'maps_routes_travel_mode=kkk123lll; Expires=Mon, 21-May-2012 12:58:39 GMT; Domain=.yandex.ru; Path=/',
    'skid=; Expires=Mon, 21-May-2012 12:58:39 GMT; Domain=.yandex.ru; Path=/',
);
%detected = $wappalyzer->detect( headers => { 'Set-Cookie' => \@cookies } );
is_deeply \%detected, { Parkings => [ 'cookies-simple-re' ] }, 'cookies-simple-re';

@cookies = (
    '_numeric_session=12345; Expires=Mon, 21-May-2012 12:58:39 GMT; Domain=.yandex.ru; Path=/',
);
%detected = $wappalyzer->detect( headers => { 'Set-Cookie' => \@cookies } );
is_deeply \%detected, { Parkings => [ 'cookies-whole-string-re' ] }, 'cookies-whole-string-re';
