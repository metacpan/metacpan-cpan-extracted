use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

use Test::Files::Constants qw(
  $DIRECTORY_OPTIONS $FMT_FILTER_ISNT_CODEREF $FILE_OPTIONS $FMT_INVALID_NAME_PATTER $FMT_INVALID_OPTIONS $FILE_OPTIONS
);

my $expected;

plan( 2 );

subtest failure => sub {
  plan( 3 );

  const my $DEFAULT => $DIRECTORY_OPTIONS;

  $expected = sprintf( $FMT_INVALID_OPTIONS, 'X' );
  is  ( $METHOD_REF->( { X            => 0   }, $DEFAULT ),    $expected, 'invalid option' );

  $expected = sprintf( $FMT_FILTER_ISNT_CODEREF, '.+' ) =~ s/([()])/\\$1/gr;
  like( $METHOD_REF->( { FILTER       => 0   }, $DEFAULT ), qr/$expected/, 'filter is not a code reference' );

  $expected = sprintf( $FMT_INVALID_NAME_PATTER, '\[', '.+', '.+' );
  like( $METHOD_REF->( { NAME_PATTERN => '[' }, $DEFAULT ), qr/$expected/, 'invalid name pattern' );
};

subtest success => sub {
  plan( 2 );

  subtest 'both filter and name pattern supplied' => sub {
    plan( 2 );

    const my $DEFAULT => $DIRECTORY_OPTIONS;

    my $filter = sub {};
    my ( $diag, %args ) = $METHOD_REF->( { FILTER => $filter, NAME_PATTERN => '..' }, $DEFAULT );
    is( $diag,  undef,                                                      'no errors' );
    is( \%args, { ( %$DEFAULT, FILTER => $filter, NAME_PATTERN => '..' ) }, 'arguments determined' );
  };

  subtest 'both filter and name pattern omitted' => sub {
    plan( 2 );

    const my $DEFAULT => $FILE_OPTIONS;

    my ( $diag, %args ) = $METHOD_REF->( {}, $DEFAULT );
    is( $diag,  undef,    'no errors' );
    is( \%args, $DEFAULT, 'arguments determined' );
  };
};
