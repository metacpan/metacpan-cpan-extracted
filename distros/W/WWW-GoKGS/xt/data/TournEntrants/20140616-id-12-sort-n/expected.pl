{
  'entrants' => [
    {
      'name' => 'jonathan',
      'rank' => '10k',
      'standing' => 'Knocked out in round 2'
    },
    {
      'name' => 'morel',
      'rank' => '16k',
      'standing' => 'Winner'
    },
    {
      'name' => 'OlManWintr',
      'rank' => '18k',
      'standing' => 'Knocked out in round 1'
    },
    {
      'name' => 'wms',
      'rank' => '2k',
      'standing' => 'Knocked out in round 1'
    }
  ],
  'links' => {
    'entrants' => [
      {
        'sort_by' => 'name',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournEntrants.jsp?sort=n&id=12')}, 'URI::http' )
      },
      {
        'sort_by' => 'result',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournEntrants.jsp?sort=s&id=12')}, 'URI::http' )
      }
    ],
    'rounds' => [
      {
        'end_time' => '2002-02-11T21:30',
        'round' => 1,
        'start_time' => '2002-02-11T21:00',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=12&round=1')}, 'URI::http' )
      },
      {
        'end_time' => '2002-02-11T22:00',
        'round' => 2,
        'start_time' => '2002-02-11T21:30',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=12&round=2')}, 'URI::http' )
      }
    ]
  },
  'name' => 'Demo Tournament',
  'time_zone' => 'GMT'
}
