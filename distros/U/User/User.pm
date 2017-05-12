package User;

use strict;

use vars qw(@ISA $VERSION);

$VERSION = '1.9';


# Preloaded methods go here.

sub Home {

  return $ENV{HOME}        if $ENV{HOME};
  return $ENV{USERPROFILE} if $ENV{USERPROFILE};
  return  "";

}

sub Login {
    return getlogin || getpwuid( $< ) || $ENV{ LOGNAME } || $ENV{ USER } ||
        $ENV{ USERNAME } || 'unknown';
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

User - API for locating user information regardless of OS

=head1 SYNOPSIS

  use User;

  my $cfg = Config::IniFiles->new
        (
          -file    => sprintf("%s/%s", User->Home, ".ncfg"),
          -default => 'Default'
        );

  print "Your login is ", User->Login, "\n";

=head1 DESCRIPTION

This module is allows applications to retrieve per-user characteristics.

=head1 METHODS

=over 4

=item Home

Returns a location that can be expected to be a users "Home" directory
on either Windows or Unix.

While one way of writing this would be to check for operating system
and then check the expected location for an operation system of that type,
I chose to do the following:

 sub Home {

  return $ENV{HOME}        if $ENV{HOME};
  return $ENV{USERPROFILE} if $ENV{USERPROFILE};
  return  "";

 }

In other words, if $HOME is defined in the user's environment, then
that is used. Otherwise $USERPROFILE is used. Otherwise "" is returned.

A contribution for Macintosh (or any other number of OS/arch combinations) is
greatly solicited.

=item Login

Returns login id of user on either Unix or NT by checking C<getlogin>,
C<getpwuid>, and various environment variables.

=back

=head1 SEE ALSO

L<File::HomeDir> seems to be a very well-done update of the same concept as this module.


=head1 COPYRIGHT INFO

Copyright: Copyright (c) 2002-2010 Terrence Brannon.
All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

License: GPL, Artistic, available in the Debian Linux Distribution at
/usr/share/common-licenses/{GPL,Artistic}

=head1 AUTHOR

T.M. Brannon, tbone@cpan.org

I am grateful for additions by Rob Napier and Malcom Nooning.


=head1 ACKNOWLEDGEMENTS

I would like to offer profuse thanks to my fellow perl monk at 
www.perlmonks.org, the_slycer, who told me where HOME could be
found on Windows machines.

I would also like to thank Bob Armstrong for providing me with the
text of the copyright notice and for including this in the Debian
Linux distribution.

perl(1).

=cut
