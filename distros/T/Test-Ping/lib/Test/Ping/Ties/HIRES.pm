package Test::Ping::Ties::HIRES;
# ABSTRACT: HiRes Tie variable to Test::Ping
$Test::Ping::Ties::HIRES::VERSION = '0.210';
use strict;
use warnings;

use Net::Ping;
use Tie::Scalar;

sub TIESCALAR { return bless {}, shift;    }
sub FETCH     { return $Net::Ping::hires;  }
sub STORE     { $Net::Ping::hires = $_[1]; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Ping::Ties::HIRES - HiRes Tie variable to Test::Ping

=head1 VERSION

version 0.210

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

This software is Copyright (c) 2020 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
