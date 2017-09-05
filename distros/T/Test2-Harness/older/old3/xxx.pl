use strict;
use warnings;

BEGIN {
    $INC{'XXX/Util.pm'} = __FILE__;
    package XXX;

    sub x { 1 }
}

use File::Temp qw/tempfile/;
use IO::Handle;

my ($fh, $name) = tempfile;
$fh->autoflush(1);

local %PerlIO::via::XXX::PARAMS = (foo => 1);
binmode($fh, ':via(PerlIO::via::XXX)') or die "Error: $!";

print $fh "Hi\n";
close($fh);
system("cat $name");

package PerlIO::via::XXX;

our %PARAMS;

sub PUSHED {
    my $class = shift;
    bless {%PARAMS}, $class;
}

sub WRITE {
    my ($self, $buffer, $handle) = @_;

    print $handle "XXX: $buffer";
    return length("XXX: $buffer");
}

1;
