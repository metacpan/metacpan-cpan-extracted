%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%#
%#----------------------------------------------------------------------------

<& ePortal_database.htm:table_exists,
    table => 'SAuser',
    SQL => qq{
      CREATE TABLE `SAuser` (
        `id` int(11) NOT NULL auto_increment,
        `group_id` int(11) default NULL,
        `title` varchar(255) default NULL,
        `login_name` varchar(64) default NULL,
        `address` varchar(64) default NULL,
        `daily_limit` int(11) default NULL,
        `weekly_limit` int(11) default NULL,
        `mon_limit` int(11) default NULL,
        `daily_alert` int(11) default NULL,
        `end_date` date default NULL,
        `blocked` tinyint(4) default NULL,
        `ts` timestamp(14) NOT NULL,
        PRIMARY KEY  (`id`),
        KEY `address` (`address`)
      )
    } &>

<& ePortal_database.htm:table_exists,
    table => 'SAgroup',
    SQL => qq{
      CREATE TABLE `SAgroup` (
       `id` int(11) NOT NULL auto_increment,
       `title` varchar(255) default NULL,
       `daily_limit` int(11) default NULL,
       `weekly_limit` int(11) default NULL,
       `mon_limit` int(11) default NULL,
       `daily_alert` int(11) default NULL,
       `ts` timestamp(14) NOT NULL,
       PRIMARY KEY  (`id`)
      )
    } &>


<& ePortal_database.htm:table_exists,
    table => 'SAtraf',
    SQL => qq{
      CREATE TABLE `SAtraf` (
        `user_id` int(11) NOT NULL default '0',
        `domain` varchar(128) NOT NULL default '',
        `log_date` datetime NOT NULL default '0000-00-00 00:00:00',
        `bytes` int(11) NOT NULL default '0',
        PRIMARY KEY  (`user_id`,`log_date`,`domain`),
        KEY `log_date` (`log_date`,`domain`)
      )
    } &>


<& ePortal_database.htm:table_exists,
    table => 'SAurl_group',
    SQL => qq{
      CREATE TABLE `SAurl_group` (
        `id` int(11) NOT NULL auto_increment,
        `title` varchar(255) default NULL,
        `redir_type` enum('block_info','empty_html','white_img','black_img','custom','allow_local','allow_external') NOT NULL default 'block_info',
        `redir_url` varchar(255) default NULL,
        `ts` timestamp(14) NOT NULL,
        PRIMARY KEY  (`id`)
      )
    } &>

<& ePortal_database.htm:table_exists,
    table => 'SAurl',
    SQL => qq{
      CREATE TABLE `SAurl` (
        `id` int(11) NOT NULL auto_increment,
        `title` varchar(255) default NULL,
        `url_group_id` int(11) default NULL,
        `url_type` enum('domain_string','domain_regex','path_string','path_regex','regex') NOT NULL default 'domain_string',
        `ts` timestamp(14) NOT NULL,
        PRIMARY KEY  (`id`),
        KEY `url_type` (`url_type`,`title`)
      )
    } &>

%# @metags ePortal_sites
% my $uri = new URI($ePortal->www_server);
<& SELF:add_blocking_group,
  title => pick_lang(rus => "Внутренные сайты", eng => "Intranet sites"),
  redir_type => 'allow_local',
  URL_list => [
        ['domain_string', $uri->host],
        ['domain_regex', 'eportal']
  ] &>


%# @metags Banners
<& SELF:add_blocking_group,
  title => "Banners",
  redir_type => 'white_img',
  URL_list => [
    ['domain_string', '.spylog.com'],
    ['domain_string', 'ad.ir.ru'],
    ['domain_string', 'ad.rambler.ru'],
    ['domain_string', 'counter.rambler.ru'],
    ['domain_string', 'counter.yadro.ru'],
    ['domain_string', 'top.list.ru'],
    ['domain_string', 'hotlog.ru'],
    ['domain_string', 'linkexchange.ru'],
    ['domain_string', 'top100-images.rambler.ru'],

    ['path_string', '/adclick.exe'],
    ['path_string', '/ads.cgi'],
    ['path_string', '/ads/'],
    ['path_string', '/adserver.exe'],
    ['path_string', '/AdSwap.dll'],
    ['path_string', '/adverts/'],
    ['path_string', '/ajrotate.dll'],
    ['path_string', '/apromo/'],
    ['path_string', '/ban.ban'],
    ['path_string', '/ban.cgi/'],
    ['path_string', '/ban/ban'],
    ['path_string', '/banner'],
    ['path_string', '/bb.cgi'],
    ['path_string', '/cgi-bin/1000'],
    ['path_string', '/cgi-bin/advert'],
    ['path_string', '/cgi-bin/ban.cgi'],
    ['path_string', '/cgi-bin/banner'],
    ['path_string', '/cgi-bin/barimage'],
    ['path_string', '/cgi-bin/centralad'],
    ['path_string', '/cgi-bin/count.cgi'],
    ['path_string', '/cgi-bin/getimage.cgi'],
    ['path_string', '/cgi-bin/redir.pl'],
    ['path_string', '/cgi-bin/showad.pl'],
    ['path_string', '/click.asp'],
    ['path_string', '/click/banners/'],
    ['path_string', '/counter'],
    ['path_string', '/gif.cfm'],
    ['path_string', '/hit.counter'],
    ['path_string', '/image.ng/'],
    ['path_string', '/images/advert'],
    ['path_string', '/linkSO/banners'],
    ['path_string', '/newroulette.cgi'],
    ['path_string', '/ranker.asp'],
    ['path_string', '/rekl.exe'],
    ['path_string', '/reklama'],
    ['path_string', '/showban.cgi'],
    ['path_string', '/top\.'],
    ['path_string', '/cycounter\?'],

    ['path_regex', '100x100.*gif'],
    ['path_regex', '100x80.*gif'],
    ['path_regex', '120x60.*gif'],
    ['path_regex', '179x69.*gif'],
    ['path_regex', '193x72.*gif'],
    ['path_regex', '468x60.*gif'],
    ['path_regex', '468_60.*gif'],
    ['path_regex', '88x31.*GIF'],
    ['path_regex', '88x31.*gif'],
    ['path_regex', 'ads/.*gif'],
    ['path_regex', 'banner.*asp'],
    ['path_regex', 'banner.*gif'],
    ['path_regex', 'banner.*jp'],
    ['path_regex', 'banners.pbn'],

    ['regex', 'pics.rbc.ru/rbcmill/img'],
    ['regex', 'top100.rambler.ru/top100'],
  ] &>


%# @metags Banners
<& SELF:add_blocking_group,
  title => pick_lang(rus => "Нежелательные файлы", eng => 'Inwanted files'),
  redir_type => 'white_img',
  URL_list => [
    ['path_regex', '.*\.avi'],
    ['path_regex', '.*\.mp3'],
    ['path_regex', '.*\.mpeg'],
    ['path_regex', '.*\.mpg'],
    ['path_regex', '.*\.pif'],
    ] &>

%# @metags Porno
<& SELF:add_blocking_group,
  title => pick_lang(rus => "Материалы сексуального характера", eng => 'Sexual and porno sites'),
  redir_type => 'block_info',
  URL_list => [
    ['domain_string', 'ads.clubphoto.com'],
    ['domain_string', 'ads.sexplanets.com'],
    ['domain_string', 'adult.com'],
    ['domain_string', 'adult.ru'],
    ['domain_string', 'adultfreespace.com'],
    ['domain_string', 'adults-tgp.com'],
    ['domain_string', 'alexovo.narod.ru'],
    ['domain_string', 'allcelebs.by.ru'],
    ['domain_string', 'alt.com'],
    ['domain_string', 'amateur-hard.com'],
    ['domain_string', 'amateur-pages.com'],
    ['domain_string', 'amateurpages.com'],
    ['domain_string', 'amateurpie.com'],
    ['domain_string', 'anneta.info'],
    ['domain_string', 'aol.com'],
    ['domain_string', 'badgirls.ru'],
    ['domain_string', 'bannercity.ru'],
    ['domain_string', 'bigfreepics.com'],
    ['domain_string', 'blendasex.com'],
    ['domain_string', 'bum.ru'],
    ['domain_string', 'chatcity.ru'],
    ['domain_string', 'crazy-sex-pics.com'],
    ['domain_string', 'delit.net'],
    ['domain_string', 'diaspora.ru'],
    ['domain_string', 'diaspora.ru'],
    ['domain_string', 'dirtyvalley.com'],
    ['domain_string', 'discretesex.com'],
    ['domain_string', 'divan.ru'],
    ['domain_string', 'egor.ru'],
    ['domain_string', 'erogen.ru'],
    ['domain_string', 'erohost.com'],
    ['domain_string', 'eroman.ru'],
    ['domain_string', 'erotika.lv'],
    ['domain_string', 'erotism.com'],
    ['domain_string', 'exhibi-club.com'],
    ['domain_string', 'extra-porn.com'],
    ['domain_string', 'fetish.pornparks.com'],
    ['domain_string', 'freepornovideos.net'],
    ['domain_string', 'ichat.ru'],
    ['domain_string', 'kama-sutra-2.narod.ru'],
    ['domain_string', 'karasxxx.com'],
    ['domain_string', 'kartinky.ru'],
    ['domain_string', 'krovatka.ru'],
    ['domain_string', 'ksenia.com'],
    ['domain_string', 'lesbos.ru'],
    ['domain_string', 'lucasarts.com'],
    ['domain_string', 'models.ksenia.com'],
    ['domain_string', 'mp3.ru'],
    ['domain_string', 'natasexy.net'],
    ['domain_string', 'natasha.com.ua'],
    ['domain_string', 'pokazuha.ru'],
    ['domain_string', 'porndorado.com'],
    ['domain_string', 'pornhome.com'],
    ['domain_string', 'pornladies.com'],
    ['domain_string', 'porno-dream.com'],
    ['domain_string', 'porno.com'],
    ['domain_string', 'porno.ru'],
    ['domain_string', 'pornogirl.wethost.com'],
    ['domain_string', 'pornosite.ru'],
    ['domain_string', 'pornregion.com'],
    ['domain_string', 'pups.ru'],
    ['domain_string', 'pupsik.ru'],
    ['domain_string', 'pussyslot.com'],
    ['domain_string', 'sexbook.net.ru'],
    ['domain_string', 'sexplanets.com'],
    ['domain_string', 'sexru.net'],
    ['domain_string', 'sextracker.com'],
    ['domain_string', 'shoutcast.com'],
    ['domain_string', 'sleazydream.com'],
    ['domain_string', 'smutserver.com'],
    ['domain_string', 'tattoo.r2.ru'],
    ['domain_string', 'teen-girl-lickers.com'],
    ['domain_string', 'terra.es'],
    ['domain_string', 'tetki.ru'],
    ['domain_string', 'tgp-movies.com'],
    ['domain_string', 'virginpetites.com'],
    ['domain_string', 'web1000.com'],
    ['domain_string', 'wetivette.com'],
    ['domain_string', 'worldsexphotos.com'],
    ['domain_string', 'yadro.ru'],
    ] &>



%#=== @METAGS add_blocking_group ====================================================
<%method add_blocking_group><%perl>
  my $title = $ARGS{title};
  my $redir_type = $ARGS{redir_type};
  my $URL_list = $ARGS{URL_list};

  return if ! table_exists($gdata{app_dbh}, 'SAurl_group');
  return if ! table_exists($gdata{app_dbh}, 'SAurl');
    
  my $bg = new ePortal::App::SquidAcnt::SAurl_group;
  $bg->restore_where(title => $title);
  if ( ! $bg->restore_next ) {
    $bg->Title($title);
    $bg->redir_type($redir_type);
    $bg->insert;
    $m->print("<br>". pick_lang(rus => "Создана группа блокировок ", eng => "Created blocking group ") . $title);
  }

  my $new_count;
  foreach (@{ $URL_list }) {
    my $url = new ePortal::App::SquidAcnt::SAurl;
    $url->restore_where(title => $_->[1], url_type => $_->[0]);
    if ( ! $url->restore_next ) {
     if ( $bg->id  ) {
        $url->url_group_id($bg->id);
        $url->Title($_->[1]);
        $url->url_type($_->[0]);
        $url->insert;
        $new_count++;
      }
    }
  }
  $m->print("<br>". pick_lang(rus => "Добавлено блокировок ", eng => "Added URLs ") . $new_count) if $new_count;
</%perl></%method>
  


<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-SquidAcnt-link',
        parent_id  => 'ePortal',
        url        => '/app/SquidAcnt/index.htm',
        title      => pick_lang(
               rus => 'Приложение - статистика работы прокси-сервера Squid',
               eng => 'Application - Squid proxy server statistics'),
  &>
