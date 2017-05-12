package UR::Value::FilePath;

use strict;
use warnings;

require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::FilePath',
    is => ['UR::Value::FilesystemPath'],
);

sub line_count {
    my $self = shift;
    my ($line_count) = qx(wc -l $self) =~ /^\s*(\d+)/;
    return $line_count;
}

1;
