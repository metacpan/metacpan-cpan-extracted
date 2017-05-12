use strict;
use warnings;
package Overloader;

use ExporterModule qw/stuff/;
use Scalar::Util 'looks_like_number';
use namespace::autoclean;

sub new {
    my ($class, %args) = @_;
    bless { %args }, $class;
}

use overload
    '""' => sub { shift->{val} || 'fallback string' },
    '0+' => sub {
        my $self = shift;
        $self->{val} && looks_like_number($self->{val})
            ? $self->{val}
            : 42;
    },
    fallback => 1,
;

use constant CAN => [ qw(new) ];
use constant CANT => [ qw(stuff looks_like_number) ];
1;
