package oo_sub v1.1.0;

use strict;   # https://perldoc.perl.org/strict
use warnings; # https://perldoc.perl.org/warnings

use Module::Load; # https://perldoc.perl.org/Module::Load

use User::pwent; # https://perldoc.perl.org/User::pwent
use User::grent; # https://perldoc.perl.org/User::grent

use File::stat; # https://perldoc.perl.org/File::stat

use Time::Piece; # https://perldoc.perl.org/Time::Piece

use Net::netent;   # https://perldoc.perl.org/Net::netent
use Net::protoent; # https://perldoc.perl.org/Net::protoent
use Net::servent;  # https://perldoc.perl.org/Net::servent
use Net::hostent;  # https://perldoc.perl.org/Net::hostent

my @modules = qw(
	User::pwent
	User::grent

	File::stat

	Time::Piece

	Net::netent
	Net::protoent
	Net::servent
	Net::hostent
); # TODO: Don't repeat: find a way to to detect use-d modules somehow

for my $module ( @modules ) {
	Module::Load::autoload_remote caller, $module;
}

# TODO: Import modules by export categories (eg. user, time, network, file)

# TODO: (?): Time::gmtime Time::localtime

# https://perldoc.perl.org/Module::Load#autoload_remote

1;

=pod

=head1 NAME

oo_sub - Use object-oriented versions of Perl built-in functions

=head1 SYNOPSIS

  use oo_sub;

  my $user = getpwnam 'root';
  print $user -> uid;

  my $group = getgrgid 0;
  say $group -> name; # use feature 'say';

  say my $file =
    stat ('.') -> ino;

  printf "%s: %s",
    getprotobyname ('tcp') -> proto,
    getservbyname ('ftp') -> port;

  say Dumper getnetbyname 'loopback'; # use Data::Dumper;

  p my $time = localtime; # use DDP; (ie. Data::Printer)

=head1 DESCRIPTION

Perl pragma to import the following modules to enable OOP in Perl for some built-in functions:

=over 2

=item L<User::pwent>

=item L<User::grent>

=item L<File::stat>

=item L<Time::Piece>

=item L<Net::netent>

=item L<Net::protoent>

=item L<Net::servent>

=item L<Net::hostent>

=back

Uses L<C<autoload_remote>|Module::Load/autoload_remote> to achieve this.

=cut

=head1 AUTHOR

L<Elvin Aslanov|https://rwp0.github.io/> L<(rwp.primary@gmail.com)|mailto:rwp.primary@gmail.com>

=head1 COPYRIGHT

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<User::pwent>, L<File::stat>, L<Time::Piece>, L<Module:Load>



=cut
