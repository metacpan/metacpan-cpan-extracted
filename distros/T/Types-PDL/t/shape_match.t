#! perl

use Test2::V0;
use Types::PDL;

#<<< notidy

my @tests = (
            # examples from documentation
            {
                str  => '2, 2',
                arr  => [ 2, 2 ],
                pass => ['2,2'],
            },
              {
                str  => '3,3,3',
                arr  => [ 3, 3, 3 ],
                pass => ['3,3,3'],
              },
              {
                str  => '3{3}',
                arr  => ['3{3}'],
                pass => ['3,3,3'],
              },
              {
                str  => '3{2,3}',
                arr  => ['3{2,3}'],
                pass => [ '3,3',
                          '3,3,3',
                        ],
              },
              {
                str  => '1,X',
                arr  => [ 1, 'X' ],
                pass => ['1,1'],
              },
              {
                str  => '1,X+',
                arr  => [ 1, 'X+' ],
                pass => [ '1,1',
                          '1,2,3',
                          '1,2,3,4',
                        ],
              },
              {
                str  => '1,X{1,}',
                arr  => [ 1, 'X{1,}' ],
                pass => [ '1,2',
                          '1,2,3',
                          '1,2,3,4',
                        ],
              },
              {
                str  => '1,X?,3',
                arr  => [ 1, 'X?', 3 ],
                pass => [ '1,2,3',
                          '1,3',
                        ],
              },
              {
                str  => '1,2,X*',
                arr  => [ 1, 2, 'X*' ],
                pass => [ '1,2',
                          '1,2,3',
                          '1,2,3,4',
                        ],
              },
              {
                str  => '1,2,3*,5',
                arr  => [ 1, 2, '3*', 5 ],
                pass => [ '1,2,5',
                          '1,2,3,5',
                          '1,2,3,3,5',
                        ],
              },

              # handle leading zeros and spaces
              {
                str => ' 01 , 02, 03 , 04, X* , 05 ',
                arr => [ 1, 2, 3, 4, 'X*', 5 ],
              },

              # other tests

              {
                str  => '1, 2, 3, 4, X*, 5',
                arr  => [ 1, 2, 3, 4, 'X*', 5 ],
                pass => [ '1,2,3,4,1,2,5',
                          '1,2,3,4,5',
                        ],
                fail => [ '1,2,3,5',
                          '1,2,3,4',
                          '1,2,3,4,1',
                        ],
              },
              {
                str  => '1, 2, 3, 4, X+, 5',
                arr  => [ 1, 2, 3, 4, 'X+', 5 ],
                pass => [ '1,2,3,4,2,5',
                          '1,2,3,4,5,5',
                        ],
                fail => [ '1,2,3,4,5,5,6',
                          '1,2,3,4',
                          '1,2,3,4,1',
                        ],
              },
              {
                str  => '1, 2, 3, 4, X?,5',
                arr  => [ 1, 2, 3, 4, 'X?', 5 ],
                pass => [ '1,2,3,4,1,5',
                          '1,2,3,4,5',
                        ],
                fail => [ '1,2,3,4',
                          '1,2,3,4,5,6',
                        ],
              },
              {
                str  => ' 1, 2, 3, 4, :{3,4}',
                arr  => [ 1, 2, 3, 4, ':{3,4}' ],
                pass => [ '1,2,3,4,1,2,3', '1,2,3,4,1,2,3,4', ],
                fail => [ '1,2,3,5',
                          '1,2,3,4',
                          '1,2,3,4,1,2',
                          '1,2,3,4,1,2,3,4,5',
                        ],
              },
              {
                str => '1, 2, 3, 4, X{3}, 5',
                arr => [ 1, 2, 3, 4, 'X{3}', 5 ],
                pass => [ '1,2,3,4,1,2,3,5',
                          '1,2,3,4,1,2,5,5',
                          '1,2,3,4,5,5,5,5',
                        ],
                fail => [ '1,2,3,5',
                          '1,2,3,4',
                          '1,2,3,4,1,2,3,4',
                          '1,2,3,4,5,5,5,5,5',
                        ],
              },
            );

#>>> tidy once more

for my $test ( @tests ) {

  my ( $str, $arr ) = @$test{ 'str', 'arr' };

  subtest $str => sub {

      my ( $re_str, $re_arr );

    SKIP: {

      ok( lives { $re_str = Types::PDL::_mk_shape_regexp( $str ) },
          'parse string' )
        or do { note $@; skip };
      ok( lives { $re_arr = Types::PDL::_mk_shape_regexp( $arr ) },
          'parse array' )
        or do { note $@; skip };

      is( $re_str, $re_arr, "string and array regexp equivalent" );

      my $regexp = qr/$re_str/x;

      subtest "expected pass" => sub {
          for ( @{ $test->{pass} } ) {
              ok( $_ =~ $regexp, $_ )
                or note $re_str;
        }
        }
        if defined $test->{pass};

      subtest "expected fail" => sub {
          for ( @{ $test->{fail} } ) {
              ok( $_ !~ $regexp, $_ )
                or note $re_str;
        }
        }
        if defined $test->{fail};
  }

  };
}


#--------------------------------------------------------

my @failures = ( [ '0,1,2' => 'cannot be zero' ],
  [ 'a1,2'      => 'error in spec.*>a1,2' ],
  [ '1,,2'      => 'error in spec.*>,2' ],
  [ '1,*,2'     => 'error in spec.*>*,2' ],
  [ '1,+,2'     => 'error in spec.*>\+,2' ],
  [ '1,{1,2},2' => 'error in spec.*>\{1,2},2' ],
  [ '1{},2'     => 'error in spec.*>\{},2' ],
  # trailing commas should be illegal, but aren't
  # [ '1,2,'  => 'error in spec.*>,2' ],
  );

subtest 'expected failures' => sub {

  for my $test ( @failures ) {

      my ( $spec, $failure ) = @$test;

      like( dies { Types::PDL::_mk_shape_regexp( $spec ) },
          qr/$failure/, $spec );
}

  };



done_testing;
