{
  'time_zone' => 'GMT',
  'notes' => 'Winner: CrazyStone',
  'description' => "<p> This is the December 2013 KGS Computer Go Tournament. </p>
<p> It is open only to Go-playing programs, known as &apos;bots&apos;. Even for bots, there are some restrictions on entry. </p>
<p> It uses 13\x{d7}13 boards, and Chinese rules, with komi of 7\x{bd}. </p>
<p> The time setting is 19 minutes each plus Canadian overtime of 10 moves in 30 seconds. This time setting is intended to ensure that a game finishes within the period assigned to the round, while allowing a little time to respond to opponents who continue to play after the game is decided. </p>
<p> To enter, please read and follow the instructions at <a href=\"http://www.weddslist.com/kgs/how/index.html\">http://www.weddslist.com/kgs/how/index.html</a></p>
<p> The rules are given at <a href=\"http://www.weddslist.com/kgs/rules.html\">http://www.weddslist.com/kgs/rules.html</a></p>
<p> The schedule should be convenient for Europeans and Americans. I hope that Asians and others will also compete, leaving their bots connected and running overnight. KGS Computer Go Tournaments have a variety of schedules, to suit all timezones. </p>
<h2>Rules</h2>
<p>Swiss style, Simultaneous Schedule.</p>
",
  'links' => {
    'entrants' => [
      {
        'sort_by' => 'name',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournEntrants.jsp?sort=n&id=857')}, 'URI::http' )
      },
      {
        'sort_by' => 'result',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournEntrants.jsp?sort=s&id=857')}, 'URI::http' )
      }
    ],
    'rounds' => [
      {
        'end_time' => '2013-12-08T16:40',
        'round' => 1,
        'start_time' => '2013-12-08T16:00',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=857&round=1')}, 'URI::http' )
      },
      {
        'end_time' => '2013-12-08T17:20',
        'round' => 2,
        'start_time' => '2013-12-08T16:40',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=857&round=2')}, 'URI::http' )
      },
      {
        'end_time' => '2013-12-08T18:00',
        'round' => 3,
        'start_time' => '2013-12-08T17:20',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=857&round=3')}, 'URI::http' )
      },
      {
        'end_time' => '2013-12-08T18:40',
        'round' => 4,
        'start_time' => '2013-12-08T18:00',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=857&round=4')}, 'URI::http' )
      },
      {
        'end_time' => '2013-12-08T19:20',
        'round' => 5,
        'start_time' => '2013-12-08T18:40',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=857&round=5')}, 'URI::http' )
      },
      {
        'end_time' => '2013-12-08T20:00',
        'round' => 6,
        'start_time' => '2013-12-08T19:20',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=857&round=6')}, 'URI::http' )
      },
      {
        'end_time' => '2013-12-08T20:40',
        'round' => 7,
        'start_time' => '2013-12-08T20:00',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=857&round=7')}, 'URI::http' )
      },
      {
        'end_time' => '2013-12-08T21:20',
        'round' => 8,
        'start_time' => '2013-12-08T20:40',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=857&round=8')}, 'URI::http' )
      },
      {
        'end_time' => '2013-12-08T22:00',
        'round' => 9,
        'start_time' => '2013-12-08T21:20',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=857&round=9')}, 'URI::http' )
      },
      {
        'end_time' => '2013-12-08T22:40',
        'round' => 10,
        'start_time' => '2013-12-08T22:00',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=857&round=10')}, 'URI::http' )
      }
    ]
  },
  'name' => 'December 2013 KGS bot tournament'
}
