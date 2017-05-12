use Test::More tests => 1;
use XML::FeedLite::File;

my $xfl  = XML::FeedLite::File->new([qw(t/example-1-atom-1.0
					t/example-2-atom-1.0
					t/example-3-atom-1.0)]);
my $data = $xfl->entries();

is_deeply($data, {
          't/example-3-atom-1.0' => [
                                      {
                                        'published' => [
                                                         {
                                                           'content' => '2003-12-13T08:29:29-04:00'
                                                         }
                                                       ],
                                        'link' => [
                                                    {
                                                      'rel' => 'alternate',
                                                      'href' => 'http://example.org/2005/04/02/atom',
                                                      'type' => 'text/html'
                                                    },
                                                    {
                                                      'rel' => 'enclosure',
                                                      'length' => '1337',
                                                      'href' => 'http://example.org/audio/ph34r_my_podcast.mp3',
                                                      'type' => 'audio/mpeg'
                                                    }
                                                  ],
                                        'content' => [
                                                       {
                                                         'content' => '
      <div xmlns="http://www.w3.org/1999/xhtml">
        <p><i>[Update: The Atom draft is finished.]</i></p>
      </div>
    ',
                                                         'type' => 'xhtml',
                                                         'xml:base' => 'http://diveintomark.org/',
                                                         'xml:lang' => 'en'
                                                       }
                                                     ],
                                        'author' => [
                                                      {
                                                        'content' => '
      <name>Mark Pilgrim</name>
      <uri>http://example.org/</uri>
      <email>f8dy@example.com</email>
    '
                                                      }
                                                    ],
                                        'updated' => [
                                                       {
                                                         'content' => '2005-07-31T12:29:29Z'
                                                       }
                                                     ],
                                        'id' => [
                                                  {
                                                    'content' => 'tag:example.org,2003:3.2397'
                                                  }
                                                ],
                                        'title' => [
                                                     {
                                                       'content' => 'Atom draft-07 snapshot'
                                                     }
                                                   ],
                                        'contributor' => [
                                                           {
                                                             'content' => '
      <name>Sam Ruby</name>
    '
                                                           },
                                                           {
                                                             'content' => '
      <name>Joe Gregorio</name>
    '
                                                           }
                                                         ]
                                      }
                                    ],
          't/example-2-atom-1.0' => [
                                      {
                                        'link' => [
                                                    {
                                                      'href' => 'http://example.org/2003/12/13/atom03'
                                                    }
                                                  ],
                                        'summary' => [
                                                       {
                                                         'content' => 'Some text.'
                                                       }
                                                     ],
                                        'updated' => [
                                                       {
                                                         'content' => '2003-12-13T18:30:02Z'
                                                       }
                                                     ],
                                        'id' => [
                                                  {
                                                    'content' => 'urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a'
                                                  }
                                                ],
                                        'title' => [
                                                     {
                                                       'content' => 'Atom-Powered Robots Run Amok'
                                                     }
                                                   ]
                                      }
                                    ],
          't/example-1-atom-1.0' => [
                                      {
                                        'link' => [
                                                    {
                                                      'href' => 'http://example.org/2003/12/13/atom03'
                                                    }
                                                  ],
                                        'summary' => [
                                                       {
                                                         'content' => 'Some text.'
                                                       }
                                                     ],
                                        'updated' => [
                                                       {
                                                         'content' => '2003-12-13T18:30:02Z'
                                                       }
                                                     ],
                                        'id' => [
                                                  {
                                                    'content' => 'urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a'
                                                  }
                                                ],
                                        'title' => [
                                                     {
                                                       'content' => 'Atom-Powered Robots Run Amok'
                                                     }
                                                   ]
                                      }
                                    ]
        }, "data structures match");

