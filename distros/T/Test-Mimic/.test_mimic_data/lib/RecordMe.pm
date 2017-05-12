package RecordMe;

use strict;
use warnings;

BEGIN {
    Test::Mimic::prepare_for_use();
}

use Scalar::Util;

use Test::Mimic::Library qw< execute get_references HISTORY decode destringify >;
use Test::Mimic::Library::PlayScalar;
use Test::Mimic::Library::PlayArray;
use Test::Mimic::Library::PlayHash;

BEGIN {
    my $references = get_references();

    tie( $RecordMe::scalar_state, q<Test::Mimic::Library::PlayScalar>, $references->[3]->[HISTORY] );
    tie( @RecordMe::array_state, q<Test::Mimic::Library::PlayArray>, $references->[2]->[HISTORY] );
    tie( %RecordMe::hash_state, q<Test::Mimic::Library::PlayHash>, $references->[0]->[HISTORY] );
    tie( @RecordMe::ISA, q<Test::Mimic::Library::PlayArray>, $references->[1]->[HISTORY] );
}

use constant {
    'ARR' => decode( destringify( '$VAR1 = [
          202,
          [
            \'ARRAY\',
            [
              [
                200,
                \'a\'
              ],
              [
                200,
                \'b\'
              ],
              [
                200,
                \'c\'
              ],
              [
                200,
                \'d\'
              ],
              [
                200,
                \'e\'
              ],
              [
                200,
                \'f\'
              ],
              [
                200,
                \'g\'
              ],
              [
                200,
                \'h\'
              ],
              [
                200,
                \'i\'
              ],
              [
                200,
                \'j\'
              ],
              [
                200,
                \'k\'
              ],
              [
                200,
                \'l\'
              ],
              [
                200,
                \'m\'
              ],
              [
                200,
                \'n\'
              ],
              [
                200,
                \'o\'
              ],
              [
                200,
                \'p\'
              ],
              [
                200,
                \'q\'
              ],
              [
                200,
                \'r\'
              ],
              [
                200,
                \'s\'
              ],
              [
                200,
                \'t\'
              ],
              [
                200,
                \'u\'
              ],
              [
                200,
                \'v\'
              ],
              [
                200,
                \'w\'
              ],
              [
                200,
                \'x\'
              ],
              [
                200,
                \'y\'
              ],
              [
                200,
                \'z\'
              ]
            ]
          ]
        ];
' ) ),
    'PI' => decode( destringify( '$VAR1 = [
          200,
          3
        ];
' ) ),
};

{
    my %ancestors = qw< Grandpa 400 RecordMe 400 Grandma 400 Mom 400 Dad 400 >;

    sub isa {
        my ( $self, $type ) = @_;

        if ( Scalar::Util::reftype($self) ) {
            my $name = Scalar::Util::blessed($self);
            if ($name) {
                return exists( $ancestors{$name} );
            }
            else {
                return ();
            }
        }
        else {
            return exists( $ancestors{$self} );
        }
    }
}

{
my $behavior = destringify( '$VAR1 = {
          \'order\' => [
                       undef,
                       undef,
                       [
                         [
                           3,
                           {
                             \'0\' => [
                                      201,
                                      \'5\'
                                    ]
                           }
                         ],
                         [
                           300
                         ],
                         [
                           3,
                           {
                             \'0\' => [
                                      201,
                                      \'5\'
                                    ]
                           }
                         ],
                         [
                           300
                         ],
                         [
                           3,
                           {
                             \'0\' => [
                                      201,
                                      \'7\'
                                    ]
                           }
                         ],
                         [
                           300
                         ],
                         [
                           3,
                           {
                             \'0\' => [
                                      201,
                                      \'7\'
                                    ]
                           }
                         ],
                         [
                           300
                         ],
                         [
                           3,
                           {
                             \'0\' => [
                                      201,
                                      \'7\'
                                    ]
                           }
                         ],
                         [
                           300
                         ],
                         [
                           3,
                           {
                             \'1\' => [
                                      201,
                                      \'8\'
                                    ],
                             \'0\' => [
                                      201,
                                      \'7\'
                                    ]
                           }
                         ],
                         [
                           300
                         ],
                         [
                           3,
                           {
                             \'0\' => [
                                      201,
                                      \'10\'
                                    ]
                           }
                         ],
                         [
                           300
                         ],
                         [
                           3,
                           {
                             \'0\' => [
                                      201,
                                      \'10\'
                                    ],
                             \'2\' => [
                                      201,
                                      \'11\'
                                    ]
                           }
                         ],
                         [
                           300
                         ],
                         [
                           3,
                           {
                             \'0\' => [
                                      201,
                                      \'10\'
                                    ],
                             \'2\' => [
                                      201,
                                      \'13\'
                                    ]
                           }
                         ],
                         [
                           300
                         ]
                       ]
                     ]
        };
' );

    sub put {
        return execute( q<RecordMe>, q<put>, $behavior, \@_ );
    }
}

{
my $behavior = destringify( '$VAR1 = {
          \'order\' => [
                       [
                         [
                           1,
                           {}
                         ],
                         [
                           300,
                           [
                             200,
                             \'positive\'
                           ]
                         ],
                         [
                           1,
                           {}
                         ],
                         [
                           300,
                           [
                             200,
                             \'zero\'
                           ]
                         ],
                         [
                           1,
                           {}
                         ],
                         [
                           300,
                           [
                             200,
                             \'negative\'
                           ]
                         ]
                       ],
                       [
                         [
                           1,
                           {}
                         ],
                         [
                           300,
                           [
                             202,
                             [
                               \'ARRAY\',
                               [
                                 [
                                   200,
                                   \'positive\'
                                 ]
                               ]
                             ]
                           ]
                         ]
                       ],
                       [
                         [
                           1,
                           {}
                         ],
                         [
                           300
                         ],
                         [
                           1,
                           {}
                         ],
                         [
                           300
                         ],
                         [
                           1,
                           {}
                         ],
                         [
                           300
                         ]
                       ]
                     ]
        };
' );

    sub pos_or_neg {
        return execute( q<RecordMe>, q<pos_or_neg>, $behavior, \@_ );
    }
}

{
my $behavior = destringify( '$VAR1 = {
          \'order\' => [
                       [
                         [
                           2,
                           {
                             \'0\' => [
                                      201,
                                      \'5\'
                                    ]
                           }
                         ],
                         [
                           300,
                           [
                             200,
                             \'bill\'
                           ]
                         ],
                         [
                           2,
                           {
                             \'0\' => [
                                      201,
                                      \'5\'
                                    ]
                           }
                         ],
                         [
                           300,
                           [
                             200,
                             \'jane\'
                           ]
                         ]
                       ]
                     ]
        };
' );

    sub get {
        return execute( q<RecordMe>, q<get>, $behavior, \@_ );
    }
}

{
my $behavior = destringify( '$VAR1 = {
          \'order\' => [
                       [
                         [
                           1,
                           {}
                         ],
                         [
                           300,
                           [
                             201,
                             \'4\'
                           ]
                         ],
                         [
                           1,
                           {}
                         ],
                         [
                           300,
                           [
                             201,
                             \'6\'
                           ]
                         ],
                         [
                           1,
                           {}
                         ],
                         [
                           300,
                           [
                             201,
                             \'9\'
                           ]
                         ]
                       ]
                     ]
        };
' );

    sub new {
        return execute( q<RecordMe>, q<new>, $behavior, \@_ );
    }
}

{
my $behavior = destringify( '$VAR1 = {
          \'order\' => [
                       [
                         [
                           1,
                           {}
                         ],
                         [
                           300,
                           [
                             200,
                             \'alive and well\'
                           ]
                         ],
                         [
                           1,
                           {}
                         ],
                         [
                           301,
                           [
                             200,
                             \'throw threw at t/RecordMe.pm line 47.
\'
                           ]
                         ]
                       ]
                     ]
        };
' );

    sub throw {
        return execute( q<RecordMe>, q<throw>, $behavior, \@_ );
    }
}

{
my $behavior = destringify( '$VAR1 = {};
' );

    sub dad {
        return execute( q<RecordMe>, q<dad>, $behavior, \@_ );
    }
}

{
my $behavior = destringify( '$VAR1 = {};
' );

    sub with_prototype ($@) {
        return execute( q<RecordMe>, q<with_prototype>, $behavior, \@_ );
    }
}

{
my $behavior = destringify( '$VAR1 = {};
' );

    sub import {
        return execute( q<RecordMe>, q<import>, $behavior, \@_ );
    }
}

{
my $behavior = destringify( '$VAR1 = {
          \'order\' => [
                       [
                         [
                           2,
                           {}
                         ],
                         [
                           300,
                           [
                             200,
                             \'mom\'
                           ]
                         ]
                       ]
                     ]
        };
' );

    sub mom {
        return execute( q<RecordMe>, q<mom>, $behavior, \@_ );
    }
}

{
my $behavior = destringify( '$VAR1 = {};
' );

    sub grandpa {
        return execute( q<RecordMe>, q<grandpa>, $behavior, \@_ );
    }
}

{
my $behavior = destringify( '$VAR1 = {
          \'order\' => [
                       [
                         [
                           2,
                           {}
                         ],
                         [
                           300,
                           [
                             200,
                             \'grandma\'
                           ]
                         ]
                       ]
                     ]
        };
' );

    sub grandma {
        return execute( q<RecordMe>, q<grandma>, $behavior, \@_ );
    }
}

