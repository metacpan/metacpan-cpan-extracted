package Zed::Plugin::Host::Space;

use strict;
use Zed::Plugin;

use Zed::Config::Space;
use Zed::Output;

=head1 SYNOPSIS

    Show Space 
    ex:
        space
        space foo

=cut
invoke "space" => sub {
    my $key = shift;
    my $space = space( $key );
    info( $key ? "space:[$key], host: " : "all host: " , $space);
};
1
