use warnings;
use strict;
use Test::Most 0.34;
use Test::Moose 2.1805;
use Moose 2.1805;    # required to provide instrospection to Moo
use Test::TempDir::Tiny 0.016;
use File::Copy;
use File::Spec;

my $class = 'Test::Health::Harness';
require_ok($class);
can_ok( $class,
    qw(get_dir get_report_file set_report_file _get_lib BUILD test_health discard_report _has_lib get_formatter _set_formatter)
);
dies_ok { $class->new( { dir => 'foobar' } ) }
'dies if directory provided does not exist';
my $dir = tempdir();
my $instance = $class->new( { dir => $dir } );
isa_ok( $instance, $class );

foreach my $attrib (qw(dir report_file _lib formatter)) {
    has_attribute_ok( $instance, $attrib );
}

is( $instance->get_report_file,
    'results.html', 'instance report_file attribute defaults to' );
note('Submitting a test to the harness');
copy( File::Spec->catfile( 't', 'Email.t' ), $dir )
  or diag("Failed to copy test to $dir: $!");
is( $instance->test_health, undef,
    'test_health returns undef - means success' );
done_testing;
