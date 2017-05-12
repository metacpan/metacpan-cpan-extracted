# Provides utility modules for use by file configuration manipulation classes
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf - Front end for class methods in various utility modules
under the Unix::Conf namespace.

=head1 DESCRIPTION

Methods in Unix::Conf are intended as a gateway into the various 
utility modules like Unix::Conf::ConfIO, Unix::Conf::Err. Unix::Conf 
is the preferred way to access class constructors in the above mentioned 
modules. Methods starting with a '_' are intended for use from other 
modules under the Unix::Conf namespace. Those without the '_' prefix 
are for general users of the Unix::Conf suite of modules.

=head1 METHODS

=cut

package Unix::Conf;

use 5.6.0;
use strict;
use warnings;
use Unix::Conf::Err;
use Unix::Conf::ConfIO;

$Unix::Conf::VERSION = "0.2";

=over 4

=item debuglevel ()

 Arguments 
 DEBUGLEVEL,
Set the class debuglevel variable in Unix::Conf::Err. This enables 
debugging messages to be printed for all class objects. The actual 
level at which debug messages are printed is the maximum of class 
debuglevel variable and the object specific debuglevel variable. 
Refer to Unix::Conf::Err for the behaviour of the three debuglevels.

   Example
   Unix::Conf->debuglevel (2);

=cut

sub debuglevel 
{
	shift (); 
	return (Unix::Conf::Err->debuglevel (@_)); 
}

=item _open_conf ()

 Arguments
 NAME        => 'PATHNAME',
 MODE        => FILE_OPEN_MODE,     # default is O_RDWR | O_CREAT 
 PERMS       => FILE_CREATION_PERMS,# default is 0600
 LOCK_STYLE  => 'flock'/'dotlock',  # default is 'flock'
 SECURE_OPEN => 0/1,                # default is 0 (disabled)
 PERSIST=> 0/1,                     # default is 0 (disabled)
Open a configuration file and return a Unix::Conf::ConfIO object.
A LOCK_STYLE of 'dotlock' is used to access /etc/passwd,
/etc/shadow, /etc/group, /etc/gshadow. Refer to Unix::Conf::ConfIO 
for the various methods that this object offers. Returns a new 
ConfIO object in case of success, or an Err object in case of 
failure. Refer to documentation for 

   Example
   my $conf = Unix::Conf->_open_conf (
      NAME        => '/etc/passwd',
      SECURE_OPEN => 1,
      LOCK_STYLE  => 'dotlock',
   );

=cut

# For use by other modules only. use goto &funcname to warp to that function
# replacing the frame for these functions. The actual functions/methods meddle
# with the stack and hence are sensitive to the calling sequence. We could 
# alter those methods to omit one frame, i.e. that of Unix::Conf->_*. However 
# this way, even if users call Unix::Conf::Err, or Unix::Conf::ConfIO directly, 
# it will still work
sub _open_conf 
{
	shift (); 
	unshift (@_, 'Unix::Conf::ConfIO'); 
	goto &Unix::Conf::ConfIO::open; 
}

=item _release_all ()

Release all objects which have been opened persistently by the 
calling class.

   Example
   my $conf = Unix::Conf->_open_conf (
      NAME       => 'some_conf',
      PERSISTENT => 1,
      LOCK       => 'flock',
   );
   # Now this object will be held in the Unix:Conf::ConfIO 
   # object cache even though $conf passes out of scope. 
   # This is for ancillary files which need to be held open 
   # so that they remain locked. It eases the user from 
   # having to prevent the user of these objects from going 
   # out of scope. Call this from the destructor to release 
   # all such objects.

   sub DESTROY 
   { 
      # do stuff 
      Unix::Conf->_release_all (); 
   }

   # Now all persistently held Unix::Conf::ConfIO objects 
   # will be released this triggering their destructors 
   # which will effectively sync the files and release 
   # the locks.

=cut

sub _release_all 
{ 
	shift (); 
	unshift (@_, 'Unix::Conf::ConfIO'); 
	goto &Unix::Conf::ConfIO::release_all; 
}

=item _err ()

 Arguments
 PREFIX, 
 ERRMSG,
Create a new Unix::Conf::Err object. This object remembers the stack 
at the creation. The returned object can thrown or returned to 
indicate an error condition as it evaluates to false in a boolean 
context. Refer to Unix::Conf::Err for the various methods that this 
object offers. If error message is missing, a stringified version of 
$! is stored as the error message.

   Example
   return (Unix::Conf::->_err ('chdir')) unless (chdir ('/etc'));

   return (
      Unix::Conf::->_err (
         'object_method', 'argument not an object of class BLAH'
      )
   ) unless (ref ($obj) eq 'BLAH');

=cut

sub _err 
{ 
	shift (); 
	unshift (@_, 'Unix::Conf::Err'); 
	goto &Unix::Conf::Err::new; 
}

1;
__END__

=head1 STATUS

Beta

=head1 BUGS

None that I know of.

=head1 AVAILABILITY

This module is available from
http://www.extremix.net/UnixConf/

It is also available from CPAN
http://www.cpan.org/modules/by-authors/id/K/KA/KARTHIKK/

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with the program; if not, write to the Free Software Foundation, Inc. :

59 Temple Place, Suite 330, Boston, MA 02111-1307

=head1 COPYRIGHT

Copyright (c) 2002, Karthik Krishnamurthy <karthik.k@extremix.net>.

=cut
