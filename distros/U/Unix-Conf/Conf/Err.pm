# Error handling class. To be used by all modules.
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>
#
=head1 NAME

Unix::Conf::Err - This module is an internal module for error handling 
purposes.

=head1 SYNOPSIS

Refer to the documentation of Unix::Conf for creating error objects. 
Accessing the class constructor for Unix::Conf::Err is not preferred 
as the location of the class and consequently its namespace might 
change. The preferred way is

   use Unix::Conf;
   sub foo ()
   {
      return (Unix::Conf::->_err ('chdir')) 
      unless (chdir ('/etc'));
   }

   # or 

   sub foo ()
   {
      return (
         Unix::Conf::->_err (
            'object_method', 
            'argument not an object of class BLAH'
         )
      ) unless (ref ($obj) eq 'BLAH');
   }

In the calling function, save the return value, test it for 
truth, print error message on STDERR and continue.

   $ret->warn ("Error executing foo ()") 
   unless (($ret = foo ()));

Increase debugging information to print the cause of error 
and a full stacktrace and die.

   unless (($ret = foo ())) {
      $ret->debuglevel (2);
      $ret->die ("Error executing foo");
   }

Get state information from the error object and use it to 
print error ourselves instead of using the provided 'warn' 
and 'die' methods.

   use CGI;
   my $q = new CGI;
   # do stuff
   unless (($ret = foo ())) {
      my $stacktrace = $ret->stacktrace ();
      $stacktrace =~ s/\n/<BR>/g;
      print	$q->header ('text/html'),
      $q->start_html ( "Error" ),
      $q->h1 ( "Error" ),
      $q->p ( "Could not execute foo ()<BR>"),
      $q->p ( "because<BR>" ),
      $q->p ( $ret->errmsg () ),
      $q->p ("at<BR>"),
      $q->p ( $ret->where () ),
      $q->p ($stacktrace);
      $q->end_html;
      exit;
   }
	
=head1 DESCRIPTION

A Unix::Conf::Err object saves the state of the call stack at the 
time its creation. The idea behind a Unix::Conf::Err object style 
error handling is allowing the caller to decide how to handle the 
error without using eval blocks around all Unix::Conf::* library 
calls. The error object can be used to throw exceptions too, as the
string operator is overloaded to return the error string, depending 
on the debuglevel.

=cut

package Unix::Conf::Err;

use 5.6.0;
use strict;
use warnings;

=over 4

=item new ()

 Arguments
 PREFIX,
 ERRMSG,

Unix::Conf::Err class constructor. If ERRMSG is not specified, a
stringified version of "$!" is used. Using Unix::Conf::Err->new is
deprecated. The preferred way to create a Unix::Conf::Err object is 
to use the Unix::Conf->_err method. Call Unix::Conf->_err () at the
point of error so that it will store error data/stack at the time of
error to be used later.

=cut

sub new
{
	my $class = shift;
	my $errobj = {};
	$errobj->{DEBUGLEVEL} = 0;
	($errobj->{PREFIX}, $errobj->{ERRMSG}) = @_;
	$errobj->{ERRMSG} = "$!" unless ($errobj->{ERRMSG});
	my $ctr = 0;
	# store the stack context at time of constructor
	while (($errobj->{STACK}[$ctr]{PACKAGE}, $errobj->{STACK}[$ctr]{FILE}, $errobj->{STACK}[$ctr]{LINE}, $errobj->{STACK}[$ctr]{SUB}) = caller ($ctr)) {
		$ctr++;
	}
	return (bless ($errobj, $class));
}

=item debuglevel ()

 Arguments 
 DEBUGLEVEL,

This method can be invoked through both a class and object. When
invoked through Unix::Conf, it sets the class wide debuglevel to
the argument. When invoked through an object, it sets only the
object private debuglevel to the argument. In case both debuglevels
are set, error message is printed at the maximum of the class wide 
debuglevel and object specific debuglevel. Valid values for
DEBUGLEVEL are 0, 1, and 2. At level 0 only only the string passed
to warn ()/die () methods are printed. At 1, the output of 
errmsg () and where () is added. At level 2, the output of 
stacktrace () is added to the output.

=cut

my $Debug_Level = 0;
sub debuglevel
{
	my ($self, $d) = @_;
	if (defined ($d)) {
		# sanity check
		$d = 2 if ($d > 2);
		$d = 0 if ($d < 0);
		if (ref ($self)) {
			$self->{DEBUGLEVEL} = $d;
		}
		else {
			$Debug_Level = $d;
		}
		return ($d);
	}
	# whichever is greater must have been set. so return that one.
	return (
		$Debug_Level > $self->{DEBUGLEVEL} ? $Debug_Level : $self->{DEBUGLEVEL}
	);
}

=item where ()

Prints information about the stack frame in which the error occured
along with the line number and file.

=cut

sub where
{
	my $self = $_[0];
	return ("in $self->{STACK}[1]{SUB}() at line $self->{STACK}[0]{LINE} in $self->{STACK}[0]{FILE}\n");
}

=item why ()

Prints "PREFIX: ERRMSG".

=cut

sub why
{
	my $self = $_[0];
	return ("$self->{PREFIX}: $self->{ERRMSG}\n");
}

=item stacktrace ()

Prints the complete stacktrace information at the time of creation
of the object.

=cut

sub stacktrace
{
	my $self = $_[0];
	my $errmsg;
	# caller invoked in _err returns 2 extra stack frames. don't know why
	# need to debug later
	my ($ctr, $stacklength) = (1, scalar (@{$self->{STACK}}) - 2);
	while ($ctr <= $stacklength) {
		$errmsg .= "$self->{STACK}[$ctr]{SUB}() called at line $self->{STACK}[$ctr]{LINE} in $self->{STACK}[$ctr]{FILE}\n";
		$ctr++;
	}
	return $errmsg;
}

=item warn ()

 Arguments 
 ERRMSG,

Prints ERRMSG to STDERR.

=cut

# Arguments: errstr (optional)
sub warn (;$)	
{ 
	warn (&__stringify); 
}

=item die ()

 Arguments 
 ERRMSG,

Prints ERRMSG to STDERR and die's.

=cut

# Arguments: errstr (optional)
sub die (;$)	
{ 
	die (&__stringify); 
}

# Overloaded functions
use overload	'""'	=> \&__interpret_as_string,
				'bool'	=> \&__interpret_as_bool,
				'eq'	=> \&__interpret_as_string;

sub __interpret_as_string
{
	my $self = shift;
	return (__stringify ($self));
}

# If the PREFIX key exists then the constructor has been called. 
sub __interpret_as_bool
{
	my $self = shift;
	#return (exists ($self->{PREFIX}) ? undef : 1);
	return (exists ($self->{PREFIX}) ? 0 : 1);
}

sub __stringify ($;$)
{
	my ($self, $errstr) = @_;

	# The whole error message is constructed in $errmsg and returned
	my $errmsg = "";

	# if argument is present get it in $errmsg. it is usually present when
	# called from the die/warn methods
	if ($errstr) {
		$errmsg .= "$errstr\n";
	}

	# when debuglevel is 1 and above include reason and point of error
	$self->debuglevel () >= 1 && do {
		# $errmsg might be empty because no argument was passed to die/warn 
		# meth or because __stringify was called from the string overload 
		# handler.
		$errmsg .= "\nbecause\n"
			if ($errmsg);
		$errmsg .= &why.&where;
	};
	$self->debuglevel () == 2 && do {
		$errmsg .= "\nPrinting stack backtrace\n";
		$errmsg .= &stacktrace;
	};
	return ($errmsg);
}

1;
__END__

=head1 BUGS

None that I know of.

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
