use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

use Test::Files::Constants qw( $FMT_ABSENT $FMT_FAILED_TO_SEE $FMT_UNEXPECTED );

const my $MISSING_FILE   => 'MISSING_FILE';
const my $SPECIAL_FILE   => 'special_file';
const my $UNTESTABLE_OS  => $^O =~ /^(?:MacOS|MSWin32|darwin|solaris)$/ || !path( '/dev/null' )->exists;
const my @EXISTING_FILES => qw( file0 file1 subdir/file2 subdir/file3 );

plan( 4 );

subtest 'invalid arguments' => sub {
  plan( 2 );

  my $expected = [ 'ERROR' ];
  my $mockThis = mock $CLASS => ( override => [ _validate_args => sub { shift->diag( $expected ) } ] );
  my $self     = $CLASS->_init;
  is( $self->$METHOD( $TEMP_DIR, [] ), [],        'empty result' );
  is( $self->diag,                     $expected, 'error message' );
};

foreach my $file ( map { [ split( m{/} ) ] } @EXISTING_FILES ) {
  path( $TEMP_DIR )->child( @$file[ 0 .. ( $#$file - 1 ) ] )->mkdir if $#$file;
  path( $TEMP_DIR )->child( @$file )->touch;
}


SKIP: {
  skip "$^O does not support special device files" if $UNTESTABLE_OS;
  symlink( '/dev/null', path( $TEMP_DIR )->child( $SPECIAL_FILE ) );

  subtest 'special file' => sub {
    plan( 2 );

    subtest 'check existence only, name pattern omitted' => sub {
      plan( 2 );

      my $expected = [ sprintf( $FMT_FAILED_TO_SEE, path( $TEMP_DIR )->child( $MISSING_FILE ) ) ];
      my $self     = $CLASS->_init;
      like(
        $self->$METHOD( $TEMP_DIR, [ @EXISTING_FILES, $MISSING_FILE ], { EXISTENCE_ONLY => 1, RECURSIVE => 1 } ),
        [ map { my $e = path( $_ ); qr/\b$e$/ } @EXISTING_FILES ], 'list of existing files returned'
      );
      is( $self->diag, $expected,                                  'error message' );
    };

    subtest 'check something but existence, specify name pattern' => sub {
      plan( 2 );

      my $expected = [ sprintf( $FMT_ABSENT, path( $TEMP_DIR )->child( $SPECIAL_FILE ) ) ];
      my $self     = $CLASS->_init;
      like(
        $self->$METHOD( $TEMP_DIR, \@EXISTING_FILES, { NAME_PATTERN => '[01]', RECURSIVE => 1 } ),
        [ map { if ( /[01]/ ) { my $e = path( $_ ); qr/\b$e$/ } else { () } } @EXISTING_FILES ],
        'list of existing files returned'
      );
      is( $self->diag, $expected, 'error message' );
    };
  };
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

subtest 'supefluous file in symmetric approach, name pattern omitted' => sub {
  plan( $UNTESTABLE_OS ? 1 : 2 );

  my $expected = [
    sprintf( $FMT_ABSENT,     path( $TEMP_DIR )->child( $UNACCESSIBLE_FILE ) ),
    sprintf( $FMT_UNEXPECTED, path( $TEMP_DIR )->child( $UNEXPECTED_FILE ) ),
  ];
  my $self     = $CLASS->_init;
  like(
    $self->$METHOD( $TEMP_DIR, \@EXISTING_FILES, { EXISTENCE_ONLY => 1, RECURSIVE => 1, SYMMETRIC => 1 } ),
    [ map { my $e = path( $_ ); qr/\b$e$/ } @EXISTING_FILES ], 'list of existing files returned'
  );
  is( $self->diag, $expected,                                  'error message' ) unless $UNTESTABLE_OS;
};

subtest 'unaccessible file, name pattern omitted' => sub {
  plan( $UNTESTABLE_OS ? 1 : 2 );

  path( $TEMP_DIR )->child( $_ )->touch foreach $UNACCESSIBLE_FILE, $UNEXPECTED_FILE;
  my $expected = [ sprintf( $FMT_ABSENT, path( $TEMP_DIR )->child( $UNACCESSIBLE_FILE ) ) ];
  my $self     = $CLASS->_init;
  like(
    $self->$METHOD( $TEMP_DIR, \@EXISTING_FILES, { EXISTENCE_ONLY => 1, RECURSIVE => 1 } ),
    [ map { my $e = path( $_ ); qr/\b$e$/ } @EXISTING_FILES ], 'list of existing files returned'
  );
  is( $self->diag, $expected,                                  'error message' ) unless $UNTESTABLE_OS;
};
