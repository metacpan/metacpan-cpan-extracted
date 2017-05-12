#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 58;
use Test::Weaken;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# constructor returning multiple values

{
  my $global = [ 123 ];
  my $test = Test::Weaken::leaks(sub {
                                   my $local = [ 456 ];
                                   return ($global, $local);
                                 });
  my $unfreed_count = $test ? $test->unfreed_count() : 0;
  ok (defined $test,
      'global/local multiple return -- leak detected');
  is ($unfreed_count, 2,
      'global/local multiple return -- count');
}
{
  my $global = [ 123 ];
  my $test = Test::Weaken::leaks(sub {
                                   my $local = [ 456 ];
                                   return ($local, $global);
                                 });
  ok (defined $test,
      'local/global multiple return -- leak detected');
  my $unfreed_count = $test ? $test->unfreed_count() : 0;
  is ($unfreed_count, 2,
      'local/global multiple return -- count');
}



#------------------------------------------------------------------------------
# destructor calls

{
  my $destructor_called;
  Test::Weaken::leaks(
                      sub { return [] },
                      sub {
                        $destructor_called = 1;
                        is (scalar(@_), 1,
                            'destructor called with 1 constructor values');
                        ok ($_[0] && ref $_[0] eq 'ARRAY');
                      }
                     );
  ok ($destructor_called);
}


# destructor called on multiple constructor values
{
  my $destructor_called;
  Test::Weaken::leaks(
                      sub { return [], {} },
                      sub {
                        $destructor_called = 1;
                        is (scalar(@_), 2,
                            'destructor called with 2 constructor values');
                        ok ($_[0] && ref $_[0] eq 'ARRAY');
                        ok ($_[1] && ref $_[1] eq 'HASH');
                      }
                     );
  ok ($destructor_called);
}

#------------------------------------------------------------------------------
# destructor_method calls

{
  my $my_destroy_called;
  my @my_destroy_objects;
  { package MyDestructorMethod;
    sub new {
      my $class = shift;
      return bless { @_ }, $class;
    }
    sub my_destroy {
      my ($self) = @_;
      Test::More::is (scalar(@_), 1, 'my_destroy() called with 1 value');
      $my_destroy_called++;
      push @my_destroy_objects, $self->{'n'};
    }
  }

  # destructor_method called
  {
    $my_destroy_called = 0;
    Test::Weaken::leaks({ constructor => sub {
                            return MyDestructorMethod->new;
                          },
                          destructor_method => 'my_destroy'});
    is ($my_destroy_called, 1);
  }

  # destructor_method called on each constructor return
  {
    $my_destroy_called = 0;
    @my_destroy_objects = ();
    Test::Weaken::leaks({ constructor => sub {
                            return (MyDestructorMethod->new(n=>1),
                                    MyDestructorMethod->new(n=>2),
                                    MyDestructorMethod->new(n=>3));
                          },
                          destructor_method => 'my_destroy'});
    is ($my_destroy_called, 3);
    is_deeply (\@my_destroy_objects, [1,2,3]);
  }
}


#------------------------------------------------------------------------------
# GLOB not tracked by default, but can be requested

is (Test::Weaken::leaks(sub { return \*FOO }),
    undef);

ok (Test::Weaken::leaks({ constructor => sub { return \*FOO },
                          tracked_types => ['GLOB'] }));


#------------------------------------------------------------------------------
# file handle tracking claimed in the POD

{
  my $contents_glob_IO = sub {
    my ($ref) = @_;
    if (ref($ref) eq 'GLOB') {
      return *$ref{IO};
    } else {
      return;
    }
  };

  {
    my $leaky_IO;
    my $leaks = Test::Weaken::leaks
      ({ constructor => sub {
           require Symbol;
           require File::Spec;
           my $fh = Symbol::gensym();
           open $fh, File::Spec->devnull;
           $leaky_IO = *$fh{IO};
           return [ $fh ];
         },
         contents => $contents_glob_IO,
         tracked_types => [ 'GLOB', 'IO' ],
       });
    ok ($leaks);
    my $unfreed = ($leaks ? $leaks->unfreed_proberefs : []);
    is ($unfreed->[0], $leaky_IO);
  }
  {
    my $leaky_GLOB;
    my $leaks = Test::Weaken::leaks
      ({ constructor => sub {
           require Symbol;
           require File::Spec;
           my $fh = Symbol::gensym();
           open $fh, File::Spec->devnull;
           $leaky_GLOB = $fh;
           return [ $fh ];
         },
         contents => $contents_glob_IO,
         tracked_types => [ 'GLOB', 'IO' ],
       });
    ok ($leaks);
    my $unfreed = ($leaks ? $leaks->unfreed_proberefs : []);
    is ($unfreed->[0], $leaky_GLOB);
  }
}


#------------------------------------------------------------------------------
# poof

{
  my ($weak_count, $strong_count, $weak_unfreed_aref, $strong_unfreed_aref)
    = Test::Weaken::poof (sub { return [] });
  is ($weak_count, 0);
  is ($strong_count, 2);
  is (ref $weak_unfreed_aref, 'ARRAY');
  is (ref $strong_unfreed_aref, 'ARRAY');
}


#------------------------------------------------------------------------------
# weak reference not descended into

{
  my $global = [];
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $href = { foo => $global };
         require Scalar::Util;
         Scalar::Util::weaken($href->{'foo'});
         return $href;
       },
       # trace_following => 1,
     });
  ok (defined $leaks);
  is ($leaks && $leaks->unfreed_count, 1);
}


#------------------------------------------------------------------------------
# ignore_preds

{
  my $one = [ ];
  my $two = { };
  my $threething = 3;
  my $three = \$threething;

  sub my_pred1 {
    my ($ref) = @_;
    return $ref == $one;
  }
  sub my_pred2 {
    my ($ref) = @_;
    return $ref == $two;
  }
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return ($one, $two, $three);
                                      },
                                      ignore_preds => [ \&my_pred1 ],
                                    });
    is ($leaks && $leaks->unfreed_count, 2);
  }
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return ($one, $two);
                                      },
                                      ignore_preds => [ \&my_pred1,
                                                        \&my_pred2 ],
                                    });
    is ($leaks, undef);
  }
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return ($one, $two, $three);
                                      },
                                      ignore_preds => [ \&my_pred1 ],
                                      ignore => \&my_pred2,
                                    });
    is ($leaks && $leaks->unfreed_count, 1);
  }
}

#------------------------------------------------------------------------------
# ignore_class, ignore_classes

{
  {
    package MyClassOne;
    sub new {
      my $class = shift;
      return bless { @_ }, $class;
    }
  }
  {
    package MyClassTwo;
    sub new {
      my $class = shift;
      return bless { @_ }, $class;
    }
  }
  {
    package MyClassThree;
    sub new {
      my $class = shift;
      my $self = shift;
      return bless \$self, $class;
    }
  }
  my $one = MyClassOne->new;
  my $two = MyClassTwo->new;
  my $three = MyClassThree->new;
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return $one;
                                      },
                                      ignore_class => 'MyClassOne',
                                    });
    ok (! $leaks, 'ignore_class');
  }
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return ($one, $two, $three);
                                      },
                                      ignore_class => 'MyClassOne',
                                    });
    ok ($leaks);
    is ($leaks && $leaks->unfreed_count, 2);
  }
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return ($one, $two, $three);
                                      },
                                      ignore_classes => ['MyClassOne',
                                                         'MyClassTwo'],
                                    });
    ok ($leaks);
    is ($leaks && $leaks->unfreed_count, 1);
    is ($leaks && $leaks->unfreed_proberefs->[0], $three);
  }
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return ($one, $two, $three);
                                      },
                                      ignore_class => 'MyClassTwo',
                                      ignore_classes => ['MyClassThree'],
                                    });
    ok ($leaks);
    is ($leaks && $leaks->unfreed_count, 1);
    is ($leaks && $leaks->unfreed_proberefs->[0], $one);
  }
}



#------------------------------------------------------------------------------
# ignore_object, ignore_objects

{
  my $one = [ ];
  my $two = { };
  my $threething = 3;
  my $three = \$threething;
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return $one;
                                      },
                                      ignore_object => $one,
                                    });
    ok (! $leaks, 'ignore_object');
  }
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return $one;
                                      },
                                      ignore_object => undef,
                                    });
    ok ($leaks);
    is ($leaks && $leaks->unfreed_count, 1);
  }
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return $one;
                                      },
                                      ignore_object => undef,
                                      ignore_objects => [ undef, undef ],
                                    });
    ok ($leaks);
    is ($leaks && $leaks->unfreed_count, 1);
  }
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return ($one, $two, $three);
                                      },
                                      ignore_object => $two,
                                    });
    ok ($leaks);
    is ($leaks && $leaks->unfreed_count, 2);
  }
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return ($one, $two, $three);
                                      },
                                      ignore_objects => [$one, $two],
                                    });
    ok ($leaks);
    is ($leaks && $leaks->unfreed_count, 1);
    is ($leaks && $leaks->unfreed_proberefs->[0], $three);
  }
  {
    my $leaks = Test::Weaken::leaks({ constructor => sub {
                                        return ($one, $two, $three);
                                      },
                                      ignore_object => $two,
                                      ignore_objects => [$three],
                                    });
    ok ($leaks);
    is ($leaks && $leaks->unfreed_count, 1);
    is ($leaks && $leaks->unfreed_proberefs->[0], $one);
  }
}


#------------------------------------------------------------------------------
# ignore of tied hashes as shown in the POD

{
  my %global;
  my $test = Test::Weaken::leaks(sub {
                                   my $aref = [ \%global ];
                                   return $aref;
                                 },
                                 sub {
                                   my ($ref) = @_;
                                   return (ref $ref eq 'HASH' && tied %$ref);
                                 });
  my $unfreed_count = $test ? $test->unfreed_count() : 0;
  ok (defined $test);
  is ($unfreed_count, 1);
}
{
  {
    package MyTieHash;
    sub TIEHASH {
      my ($class) = @_;
      return bless {}, $class;
    }
    sub FIRSTKEY {
      return;
    }
  }
  sub ignore_all_tied_hashes {
    my ($ref) = @_;
    return (ref $ref eq 'HASH' && tied %$ref);
  }
  my %global;
  tie %global, 'MyTieHash';
  ### tied: tied %global
  my $test = Test::Weaken::leaks({ constructor => sub {
                                     my $aref = [ \%global ];
                                     return $aref;
                                   },
                                   ignore      => \&ignore_all_tied_hashes,
                                 });
  is ($test, undef);
}






#------------------------------------------------------------------------------
exit 0;
