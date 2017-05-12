package UtilPluggable::Plugin::Pluggable2;

sub utils {
  return
    {
     -pluggable => [
                    [
                     'UtilPluggable', '', # dummy,
                     {
                      "test2" => sub {sub (){ return "test2\n"}}
                     }
                    ]
                   ],
     -pluggable2 => [
                     [
                      'UtilPluggable', '', # dummy,
                      {
                       "test3" => sub {sub (){ return "test3\n"}}
                      }
                     ]
                    ]
    }
}

1;


