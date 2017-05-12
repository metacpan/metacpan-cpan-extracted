package WWW::AUR::UserAgent;

use warnings 'FATAL' => 'all';
use strict;

use LWP::UserAgent qw();
use WWW::AUR       qw();

our @ISA = qw(LWP::UserAgent);

sub new
{
    my $class = shift;

    $class->SUPER::new( 'agent' => "WWW::AUR/v$WWW::AUR::VERSION", @_ );
}

#---CLASS METHOD---
sub InitTLS
{
    eval { require LWP::Protocol::https; 1 } or
        die "failed to load LWP::Protocol::https, error:\n$@\n"
            . "(ensure that LWP::Protocol::https is installed)\n"
}

1;
