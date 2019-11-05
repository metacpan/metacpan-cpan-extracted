package Test::Ping::Ties::BIND;
$Test::Ping::Ties::BIND::VERSION = '0.204';
use strict;
use warnings;
# ABSTRACT: Bind Tie variable to Test::Ping

use Net::Ping;
use Test::Ping;
use Tie::Scalar;
use Carp;

sub TIESCALAR { return bless {}, shift;                    }
sub FETCH     { carp 'Usage: $p->bind($local_addr)';       }
sub STORE     { Test::Ping->_ping_object()->bind( $_[1] ); }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Ping::Ties::BIND - Bind Tie variable to Test::Ping

=head1 VERSION

version 0.204

=head1 DESCRIPTION

In order to allow complete procedural interface to Net::Ping, even though it's
an object, I use a Tie::Scalar interface. Every variable is also defined
separately to make it cleaner and easier.

At some point they might be joined together in a single file, but I doubt it.

Please refrain from using this directly.

=head1 EXPORT

None.

=head1 AUTHOR

Sawyer X

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
