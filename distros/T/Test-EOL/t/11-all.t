use strict;
use warnings;

use Test::EOL;

use File::Temp qw( tempdir tempfile );

all_perl_files_ok("lib");

eol_unix_ok( $0, "$0 is unix eol" );

my $file1 = make_file1();
eol_unix_ok( $file1 );

my $file2 = make_file2();
eol_unix_ok( $file2 );

my $file3 = make_file3();
eol_unix_ok( $file3 );

my $file4 = make_file3();
eol_unix_ok( $file3, { trailing_whitespace => 1 });

unlink foreach ( $file1, $file2, $file3, $file4 );

sub make_file1 {
  my ($fh, $filename) = tempfile();
  print $fh <<'DUMMY';
#!/usr/bin/perl -w

=pod

=head1 NAME

This test script doesn't do anything.

=cut

sub main {
    my ($name) = @_;
    print "Hello $name!\n";
}

DUMMY
  return $filename;
}

sub make_file2 {
  my ($fh, $filename) = tempfile();
  print $fh <<'DUMMY';
#!/usr/bin/perl -w

=pod

=head1 NAME

This test script doesn't do anything.

=cut

sub main {
    my ($name) = @_;
    print "Hello $name!\n";
}

DUMMY
  return $filename;
}

sub make_file3 {
  my ($fh, $filename) = tempfile();
  print $fh <<'DUMMY';
package My::Test;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    return $self;
}

1;
__END__
DUMMY
  return $filename;
}

