use strict;

use lib ('./blib','../blib', './lib','../lib');

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-FixEOL.t'

#########################
# change 'tests => 3' to 'tests => last_test_to_print';


use Test::More (tests => 6);

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########
# Test 1
BEGIN {
    use_ok('Tie::ListKeyedHash');
}

#########
# Test 2
require_ok ('Tie::ListKeyedHash');

#########
# Test 3
ok (test_constructor_modes());

#########
# Test 4
ok (test_constructor_bad_parameters());

#########
# Test 5
ok (test_put_get_delete_exist());

#########
# Test 6
ok (test_imported_put_get_delete_exist());

exit;

#####################################################################

sub test_imported_put_get_delete_exist {
    eval {
        my %test_hash = %{hoh()};
        my $test_obj = Tie::ListKeyedHash->new(\%test_hash);
        unless ($test_obj) {
            die("failed to get object instance");
        }
        
        my $tests = hoh_data();

        my @hash_keys = keys %test_hash;
        foreach my $key (@hash_keys) {
            unless ($test_obj->exists([$key])) {
                die("first level key enumeration failed");
            }
        }
        foreach my $test_item (values %$tests) {
            my $test_key          = $test_item->{'key'};
            my $test_value        = $test_item->{'value'};
            if (ref($test_key) eq '') {
                $test_key = [$test_key];
            }
            unless ($test_obj->exists($test_key)) {
                die("Value failed existance test after setting");
            }
            my $extracted = $test_obj->get($test_key);
            unless (ref($extracted) eq ref($test_value)) {
                die("Read a different value for key than was set originally");
            }
            { 
                local $^W = undef;
                if ((ref($test_value) eq '') and ($extracted ne $test_value)) {
                    die("expected $test_value, found $extracted");
                }
            }
            $test_obj->delete($test_key);
            if ($test_obj->exists($test_key)) {
                die("Failed to delete test key");
            }
        }
        $test_obj->clear;
        foreach my $key (@hash_keys) {
            if ($test_obj->exists([$key])) {
                die("hash clearing failed");
            }
        }

        eval {
            $test_obj->delete;
        };
        unless ($@) {
            die("failed to catch malformed delete request");
        }

        eval {
            $test_obj->delete([]);
        };
        unless ($@) {
            die("failed to catch malformed delete request");
        }

        eval {
            $test_obj->put; 
        };
        unless ($@) {
            die("failed to catch malformed put request");
        }

        eval {
            $test_obj->put([],0); 
        };
        unless ($@) {
            die("failed to catch malformed put request");
        }

        eval {
            $test_obj->put(['a']); 
        };
        unless ($@) {
            die("failed to catch malformed put request");
        }

        eval {
            $test_obj->get; 
        };
        unless ($@) {
            die("failed to catch malformed get request");
        }

        eval {
            $test_obj->exists('a'); 
        };
        unless ($@) {
            die("failed to catch malformed exists request");
        }

    }; 
    if ($@) {
        diag("fatal error with importing hash put/get/delete: $@");
        return 0;
    }

    return 1;
}

#########################

sub test_put_get_delete_exist {
    eval {
        my %test_hash = ();
        my $test_obj = tie (%test_hash, 'Tie::ListKeyedHash');
        unless ($test_obj) {
            die("failed to tie test hash\n");
        }
        while (my ($key, $value) = each %test_hash) {
            die("spurious returned results from empty hash");
        }

        my $ref_instance = $test_obj->get([]);
        unless (ref($ref_instance) eq ref($test_obj)) {
            die("Empty list get failed to return instance ref");
        }
        
        my $tests = hoh_data();
        foreach my $test_item (values %$tests) {
            my $test_key          = $test_item->{'key'};
            my $test_value        = $test_item->{'value'};
            $test_hash{$test_key} = $test_value;
        }
        my @hash_keys = keys %test_hash;
        foreach my $key (@hash_keys) {
            unless (exists $test_hash{$key}) {
                die("first level key enumeration failed");
            }
        }
        foreach my $test_item (values %$tests) {
            my $test_key          = $test_item->{'key'};
            my $test_value        = $test_item->{'value'};
            unless (exists $test_hash{$test_key}) {
                die("Value failed existance test after setting");
            }
            my $extracted         = $test_hash{$test_key};
            unless (ref($extracted) eq ref($test_value)) {
                die("Read a different value for key than was set originally");
            }
            { 
                local $^W = undef;
                if ((ref($test_value) eq '') and ($extracted ne $test_value)) {
                    die("expected $test_value, found " . $test_hash{$test_key});
                }
            }
            delete $test_hash{$test_key};
            if (exists $test_hash{$test_key}) {
                die("Failed to delete test key");
            }
        }
        %test_hash = ();
        foreach my $key (@hash_keys) {
            if (exists $test_hash{$key}) {
                die("hash clearing failed");
            }
        }

        eval {
            $test_obj->delete;
        };
        unless ($@) {
            die("failed to catch malformed delete request");
        }

        eval {
            $test_obj->delete([]);
        };
        unless ($@) {
            die("failed to catch malformed delete request");
        }

        eval {
            $test_obj->put; 
        };
        unless ($@) {
            die("failed to catch malformed put request");
        }

        eval {
            $test_obj->put([],0); 
        };
        unless ($@) {
            die("failed to catch malformed put request");
        }

        eval {
            $test_obj->put(['a']); 
        };
        unless ($@) {
            die("failed to catch malformed put request");
        }

        eval {
            $test_obj->get; 
        };
        unless ($@) {
            die("failed to catch malformed get request");
        }
    }; 
    if ($@) {
        diag("fatal error with imported hash put/get/delete: $@");
        return 0;
    }

    return 1;
}

#########################

sub test_constructor_modes {
    {
        my $result = eval {
            my $fixer = Tie::ListKeyedHash::new('');
            return $fixer;
        };
        if ($@ or not $result) {
            diag("no proto constructor failed");
            return 0;
        }
    }

    ######
    {
        my $result = eval {
            my $fixer = Tie::ListKeyedHash::new;
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Class mode constructor failed");
            return 0;
        }
    }

    ######
    {
        my $result = eval {
            my $fixer = Tie::ListKeyedHash->new;
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Direct mode constructor failed");
            return 0;
        }
    }

    ######

    {
        my $result = eval {
            my %hash = ();
            my $fixer = tie %hash, 'Tie::ListKeyedHash';
            return $fixer;
        };
        if ($@ or not $result) {
            diag("tie failed");
            return 0;
        }
    }

    ######

    {
        my $result = eval {
            my $fixer_proto = Tie::ListKeyedHash->new;
            my $fixer       = $fixer_proto->new;
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Instance mode constructor failed");
            return 0;
        }
    }

    ######
    {
        my $result = eval {
            my $fixer = Tie::ListKeyedHash::new;
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Static mode constructor failed");
            return 0;
        }
    }

    ######

    {
        my $result = eval {
            my $fixer = new Tie::ListKeyedHash;
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Indirect syntax constructor failed");
            return 0;
        }
    }

    ######


    {
        my $result = eval {
            my $fixer       = 'Tie::ListKeyedHash'->new;
            return $fixer;
        };
        if ($@ or not $result) {
            diag("symbolic syntax constructor failed");
            return 0;
        }
    }

    ######

    return 1;
}

#########################

sub test_constructor_bad_parameters {
    eval { my $fixer = Tie::ListKeyedHash->new( BadDog => 1 ); };
    unless ($@) {
        diag("Constructor failed to catch invalid parameter names as a list");
        return 0;
    }

    eval { my $fixer = Tie::ListKeyedHash->new('BadDog'); };
    unless ($@) {
        diag("Constructor failed to catch invalid parameter typing as a last");
        return 0;
    }

    return 1;
}

#########################

sub hoh {
    my $hoh = {
          '11' => {
            '12' => {
              '13' => {
                '14' => {
                  '15' => 'deep5'
                }
              }
            }
          },
          'a' => 'b',
          '7' => {
            '8' => {
              '9' => {
                '10' => {
                  '11' => {
                    '12' => {
                      '13' => {
                        '14' => {
                          '15' => 'deep9'
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          '2' => {
            '3' => {
              '4' => {
                '5' => {
                  '6' => {
                    '7' => {
                      '8' => {
                        '9' => {
                          '10' => {
                            '11' => {
                              '12' => {
                                '13' => {
                                  '14' => {
                                    '15' => 'deep14'
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          '2a' => {
            '3' => {
              '4' => {
                '5' => {
                  '6' => {
                    '7' => {
                      '8' => {
                        '9' => {
                          '10' => {
                            '11' => {
                              '12' => {
                                '13' => {
                                  '14' => {
                                    '15' => 'deep14a'
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          '13' => {
            '14' => {
              '15' => 'deep3'
            }
          },
          '16' => undef,
          'e' => {
            'c' => {}
          },
          '6' => {
            '7' => {
              '8' => {
                '9' => {
                  '10' => {
                    '11' => {
                      '12' => {
                        '13' => {
                          '14' => {
                            '15' => 'deep10'
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          '3' => {
            '4' => {
              '5' => {
                '6' => {
                  '7' => {
                    '8' => {
                      '9' => {
                        '10' => {
                          '11' => {
                            '12' => {
                              '13' => {
                                '14' => {
                                  '15' => 'deep13'
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          '9' => {
            '10' => {
              '11' => {
                '12' => {
                  '13' => {
                    '14' => {
                      '15' => 'deep7'
                    }
                  }
                }
              }
            }
          },
          '12' => {
            '13' => {
              '14' => {
                '15' => 'deep4'
              }
            }
          },
          '15' => 'deep1',
          '14' => {
            '15' => 'deep2'
          },
          '8' => {
            '9' => {
              '10' => {
                '11' => {
                  '12' => {
                    '13' => {
                      '14' => {
                        '15' => 'deep8'
                      }
                    }
                  }
                }
              }
            }
          },
          '4' => {
            '5' => {
              '6' => {
                '7' => {
                  '8' => {
                    '9' => {
                      '10' => {
                        '11' => {
                          '12' => {
                            '13' => {
                              '14' => {
                                '15' => 'deep12'
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          'b' => {
            'c' => 'd'
          },
          '10' => {
            '11' => {
              '12' => {
                '13' => {
                  '14' => {
                    '15' => 'deep6'
                  }
                }
              }
            }
          },
          '5' => {
            '6' => {
              '7' => {
                '8' => {
                  '9' => {
                    '10' => {
                      '11' => {
                        '12' => {
                          '13' => {
                            '14' => {
                              '15' => 'deep11'
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        };
    return $hoh;
}

sub hoh_data {
    my $test_data = {
            1 => { 'key'   => 'a',
                   'value' => 'b',
                 },
            2 => { 'key'   => ['b','c'],
                   'value' => 'd', 
                 },
            3 => { 'key'   => ['e','c'],
                   'value' => {}, 
                 },
            4 => { 'key'   => [qw(2 3 4 5 6 7 8 9 10 11 12 13 14 15)],
                   'value' => 'deep14', 
                 },
            '4a' => { 'key' => [qw(2a 3 4 5 6 7 8 9 10 11 12 13 14 15)],
                   'value' => 'deep14a', 
                 },
            5 => { 'key'   => [qw(3 4 5 6 7 8 9 10 11 12 13 14 15)],
                   'value' => 'deep13', 
                 },
            6 => { 'key'   => [qw(4 5 6 7 8 9 10 11 12 13 14 15)],
                   'value' => 'deep12', 
                 },
            7 => { 'key'   => [qw(5 6 7 8 9 10 11 12 13 14 15)],
                   'value' => 'deep11', 
                 },
            8 => { 'key'   => [qw(6 7 8 9 10 11 12 13 14 15)],
                   'value' => 'deep10', 
                 },
            9 => { 'key'   => [qw(7 8 9 10 11 12 13 14 15)],
                   'value' => 'deep9', 
                 },
            10 => { 'key'   => [qw(8 9 10 11 12 13 14 15)],
                   'value' => 'deep8', 
                 },
            11 => { 'key'   => [qw(9 10 11 12 13 14 15)],
                   'value' => 'deep7', 
                 },
            12 => { 'key'   => [qw(10 11 12 13 14 15)],
                   'value' => 'deep6', 
                 },
            13 => { 'key'   => [qw(11 12 13 14 15)],
                   'value' => 'deep5', 
                 },
            14 => { 'key'   => [qw(12 13 14 15)],
                   'value' => 'deep4', 
                 },
            15 => { 'key'   => [qw(13 14 15)],
                   'value' => 'deep3', 
                 },
            16 => { 'key'   => [qw(14 15)],
                   'value' => 'deep2', 
                 },
            17 => { 'key'   => [qw(15)],
                   'value' => 'deep1', 
                 },
            18 => { 'key'   => [qw(16)],
                   'value' => undef, 
                 },
        };
    return $test_data;
}
