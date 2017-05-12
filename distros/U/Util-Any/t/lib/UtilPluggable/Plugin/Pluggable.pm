package UtilPluggable::Plugin::Pluggable;

sub utils {
  return
    {
     -pluggable => [
                    [
                     'UtilPluggable', '', # dummy,
                     {
                      "test" => sub {sub (){ return "test\n"}}
                     }
                    ]
                   ],
    }
}

1;


