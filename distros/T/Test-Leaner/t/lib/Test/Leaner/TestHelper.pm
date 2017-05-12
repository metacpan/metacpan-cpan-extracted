package Test::Leaner::TestHelper;

use strict;
use warnings;

my $memory_stream;
my $buf_ref;

sub capture_to_buffer {
 return unless "$]" >= 5.008;

 die "Can't call capture_to_buffer twice" if $memory_stream;

 $buf_ref = \$_[0];
 open $memory_stream, '>', $buf_ref
                           or die 'could not create the in-memory file';

 Test::Leaner::tap_stream($memory_stream);

 return 1;
}

# The ";&" prototype does not work well with perl 5.6
sub reset_buffer (&) {
 my $code = shift;

 die "The memory stream has not been initialized" unless $memory_stream;

 $$buf_ref = '';
 seek $memory_stream, 0, 0;

 goto $code if $code;
}

our @EXPORT = qw<
 capture_to_buffer
 reset_buffer
>;

use Exporter ();

sub import { goto &Exporter::import }

1;
