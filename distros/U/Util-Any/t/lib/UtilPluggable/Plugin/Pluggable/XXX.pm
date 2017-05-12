package UtilPluggable::Plugin::Pluggable::XXX;

use strict;

sub utils {
  return {
          -pluggable_xxx => [
                             [
                              'UtilPluggable', '', # dummy,
                              {
                               "xxx" => sub {sub (){ return "xxx\n"}}
                              }
                             ]
                            ],
         };
}

1;
