use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

use Test::Files::Constants qw( $FMT_ABSENT $FMT_FAILED_TO_SEE $FMT_UNEXPECTED );

const my $MISSING_FILE => 'MISSING_FILE';
my $expected;

plan( 5 );

{
  my $mockThis = mock $CLASS => ( override => [ _validate_args => sub { 'ERROR' } ] );
  is( $METHOD_REF->( $TEMP_DIR, [] ), [ 'ERROR' ], 'invalid arguments' );
}

const my @EXISTING_FILES => qw( file0 file1 subdir/file2 subdir/file3 );
foreach my $file ( map { [ split( m{/} ) ] } @EXISTING_FILES ) {
  path( $TEMP_DIR )->child( @$file[ 0 .. ( $#$file - 1 ) ] )->mkdir if $#$file;
  path( $TEMP_DIR )->child( @$file )->touch;
}

const my $SPECIAL_FILE => 'special_file';

SKIP: {
  const my $UNTESTABLE_OS => $^O eq 'MSWin32' || !path( '/dev/null' )->exists;
  skip "$^O does not support special device files" if $UNTESTABLE_OS;
  symlink( '/dev/null', path( $TEMP_DIR )->child( $SPECIAL_FILE ) );

  $expected = [
    [ sprintf( $FMT_FAILED_TO_SEE, path( $TEMP_DIR )->child( $MISSING_FILE ) ) ],
    [ map { path( $_ ) } @EXISTING_FILES ],
  ];
  is(
    [ $METHOD_REF->( $TEMP_DIR, [ @EXISTING_FILES, $MISSING_FILE ], { EXISTENCE_ONLY => 1, RECURSIVE => 1 } ) ],
    $expected,
    'check existence only with special file, name pattern omitted'
  );

  $expected = [
    [ sprintf( $FMT_ABSENT, path( $TEMP_DIR )->child( $SPECIAL_FILE ) ) ],
    [ map { /[01]/ ? path( $_ ) : () } @EXISTING_FILES ],
  ];
  is(
    [ $METHOD_REF->( $TEMP_DIR, \@EXISTING_FILES, { NAME_PATTERN => '[01]', RECURSIVE => 1 } ) ],
    $expected,
    'check something but existence with special file, specify name pattern'
  );
}

const my $UNACCESSIBLE_FILE => 'UNACCESSIBLE';
const my $UNEXPECTED_FILE   => 'UNEXPECTED';
path( $TEMP_DIR )->child( $_ )->touch foreach $UNACCESSIBLE_FILE, $UNEXPECTED_FILE;
path( $TEMP_DIR )->child( $SPECIAL_FILE )->remove;
my $mockPathTiny = mock 'Path::Tiny' => ( override => [ stat => sub {} ] );
$mockPathTiny->override(
  stat => sub {
    my $orig = $mockPathTiny->orig( 'stat' ); $_[ 0 ]->basename eq $UNACCESSIBLE_FILE ? undef : $_[ 0 ]->$orig;
  }
);
$expected = [
  [
    sprintf( $FMT_ABSENT, path( $TEMP_DIR )->child( $UNACCESSIBLE_FILE ) ),
    sprintf( $FMT_UNEXPECTED, path( $TEMP_DIR )->child( $UNEXPECTED_FILE ) ),
  ],
  [ map { path( $_ ) } @EXISTING_FILES ],
];
is(
  [ $METHOD_REF->( $TEMP_DIR, \@EXISTING_FILES, { EXISTENCE_ONLY => 1, RECURSIVE => 1, SYMMETRIC => 1 } ) ],
  $expected,
  'detect supefluous file in symmetric approach, name pattern omitted'
);

path( $TEMP_DIR )->child( $_ )->touch foreach $UNACCESSIBLE_FILE, $UNEXPECTED_FILE;
$expected = [
  [ sprintf( $FMT_ABSENT, path( $TEMP_DIR )->child( $UNACCESSIBLE_FILE ) ) ],
  [ map { path( $_ ) } @EXISTING_FILES ],
];
is(
  [ $METHOD_REF->( $TEMP_DIR, \@EXISTING_FILES, { EXISTENCE_ONLY => 1, RECURSIVE => 1 } ) ],
  $expected,
  'detect unaccessible file, name pattern omitted'
);
