use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

const my $CONTENT => 'content';
const my $ERROR   => 'error';

my @result;
my $mock_this = mock $CLASS => ( override => [ _get_file_info => sub { @{ shift( @result ) } } ] );

plan( 2 );

my $expected;

@result   = ( [ $ERROR, undef ], [ undef, $CONTENT ] );
$expected = [ [ $ERROR ], undef, $CONTENT  ];
is(
  [ $METHOD_REF->( 'first_file', 'second_file', undef, 'first_name', 'second_name' ) ],
  $expected,
  'first file reading failed'
);

@result   = ( [ undef, $CONTENT ], [ $ERROR, undef ] );
$expected = [ [ $ERROR ], $CONTENT, undef  ];
is(
  [ $METHOD_REF->( 'first_file', 'second_file', undef, 'first_name', 'second_name' ) ],
  $expected,
  'second file reading failed'
);
