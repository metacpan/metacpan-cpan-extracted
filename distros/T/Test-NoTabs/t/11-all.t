use strict;
use warnings;

use Test::NoTabs;
use FindBin qw/$Bin/;

use File::Temp qw( tempdir tempfile );

all_perl_files_ok("$Bin/../lib");

notabs_ok( $0, "$0 is tab free" );

my $tabbed_file1 = make_tabbed_file1();
notabs_ok( $tabbed_file1 );

my $tabbed_file2 = make_tabbed_file2();
notabs_ok( $tabbed_file2 );

my $tabbed_file3 = make_tabbed_file3();
notabs_ok( $tabbed_file3 );

unlink foreach ( $tabbed_file1, $tabbed_file2, $tabbed_file3 );

sub make_tabbed_file1 {
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

sub make_tabbed_file2 {
  my ($fh, $filename) = tempfile();
  print $fh <<'DUMMY';
#!/usr/bin/perl -w

=pod

=head1 NAME

This test script doesn't do anything.

	Its OK to have tabs in pod

=cut

sub main {
    my ($name) = @_;
    print "Hello $name!\n";
}

DUMMY
  return $filename;
}

sub make_tabbed_file3 {
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
	I can have tabs here too!
DUMMY
  return $filename;
}
