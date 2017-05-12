{
  'zip_uri' => bless( do{\(my $o = 'http://www.gokgs.com/servlet/archives/en_US/anazawa-2013-7.zip')}, 'URI::http' ),
  'games' => [
    {
      'setup' => "19\x{d7}19 ",
      'white' => [
        {
          'link' => bless( do{\(my $o = 'http://www.gokgs.com/gameArchives.jsp?user=duty')}, 'URI::http' ),
          'name' => 'duty [3k]'
        }
      ],
      'black' => [
        {
          'link' => bless( do{\(my $o = 'http://www.gokgs.com/gameArchives.jsp?user=anazawa')}, 'URI::http' ),
          'name' => 'anazawa [4k]'
        }
      ],
      'kifu_uri' => bless( do{\(my $o = 'http://files.gokgs.com/games/2013/7/1/duty-anazawa.sgf')}, 'URI::http' ),
      'start_time' => '7/1/13 5:47 AM',
      'type' => 'Ranked',
      'result' => 'Unfinished'
    },
    {
      'setup' => "19\x{d7}19 H2",
      'white' => [
        {
          'link' => bless( do{\(my $o = 'http://www.gokgs.com/gameArchives.jsp?user=nishipapa')}, 'URI::http' ),
          'name' => 'nishipapa [2k]'
        }
      ],
      'black' => [
        {
          'link' => bless( do{\(my $o = 'http://www.gokgs.com/gameArchives.jsp?user=anazawa')}, 'URI::http' ),
          'name' => 'anazawa [4k]'
        }
      ],
      'kifu_uri' => bless( do{\(my $o = 'http://files.gokgs.com/games/2013/7/1/nishipapa-anazawa.sgf')}, 'URI::http' ),
      'start_time' => '7/1/13 5:55 AM',
      'type' => 'Ranked',
      'result' => 'B+Res.'
    }
  ],
  'summary' => 'Games of KGS player anazawa, Mon Jul 01 00:00:00 UTC 2013 (2 games)',
  'tgz_uri' => bless( do{\(my $o = 'http://www.gokgs.com/servlet/archives/en_US/anazawa-2013-7.tar.gz')}, 'URI::http' ),
  'calendar' => [
    {
      'link' => bless( do{\(my $o = 'http://www.gokgs.com/gameArchives.jsp?user=anazawa&year=2013&month=6')}, 'URI::http' ),
      'month' => 'Jun',
      'year' => '2013'
    },
    {
      'month' => 'Jul',
      'year' => '2013'
    }
  ]
}
