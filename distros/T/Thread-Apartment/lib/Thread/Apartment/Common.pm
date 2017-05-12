#/**
# Provides common marshalling/unmarshalling methods, and common
# exported constants.
# <p>
# Licensed under the Academic Free License version 2.1, as specified in the
# License.txt file included in this software package, or at
# <a href="http://www.opensource.org/licenses/afl-2.1.php">OpenSource.org</a>.
#
# @author D. Arnold
# @since 2005-12-01
# @self	$self
# @exports TA_SIMPLEX	flag indicating a method/closure is simplex (i.e., does not return results)
# @exports TA_URGENT	flag indicating a method/closure is urgent (i.e., should be posted to the head of the proxied object's TQD)
# @exports TA_NO_OBJECTS flag indicating a method does not return objects. Used by
#						<a href='./Server.html'>Thread::Apartment::Server</a> objects
#						to optimize the marhsalling of returned method results.
#
#*/
package Thread::Apartment::Common;

use threads;
use threads::shared;
use Carp;
use Exporter;
use Storable qw(freeze thaw);
use IO::Handle;
use IO::Socket::INET;
use IO::Socket::UNIX;
use Thread::Apartment;

BEGIN {
our @ISA = qw(Exporter);

use constant TA_SIMPLEX => 1;
use constant TA_URGENT => 2;
use constant TA_NO_OBJECTS => 4;

our @EXPORT    = ();		    # we export nothing by default
our @EXPORT_OK = ();

our %EXPORT_TAGS = (
	ta_method_flags => [
		qw/TA_SIMPLEX TA_URGENT TA_NO_OBJECTS/
	]);

Exporter::export_tags(keys %EXPORT_TAGS);
}

use strict;
use warnings;

our $VERSION = '0.51';

#/**
# Marshall input parameters into a TQD-compatible format.
# Each parameter is converted to a 2-tuple of a class descriptor
# string (undef for simple scalar parameters), and the marshalled
# version of the parameter. Marshalling rules are:
# <p>
# <ol>
# <li>Scalars and threads::shared values are marshalled as is.
# <li>non-threads::shared references to scalars, arrays, or hashes, or
#   objects which do not implement <a href='http://search.cpan.org/perldoc?Thread::Queue::Queueable'>Thread::Queue::Queueable</a>
#	are marshalled via <a href='http://search.cpan.org/perldoc?Storable'>Storable</a>
# <li>closures are converted to <a href='./Closure.html'>Thread::Apartment::Closure</a> objects.
# <li><a href='./Server.html'>Thread::Apartment::Server</a> objects are marshalled using their TAC's
# <li><a href='http://search.cpan.org/perldoc?Thread::Queue::Queueable'>Thread::Queue::Queueable</a>
#	objects are marshalled using their onEnqueue()/curse() methods.
# </ol>
# <p>
# <b>NOTE:</b> Passing of GLOBs or other I/O objects is not currently supported; applications
# are responsible for implementing TQQ to curse() them into their fileno, and redeem() them
# via an fdopen() operation in the receiving thread.
#
# @param @params	parameters/results to be marshalled
#
# @return		threads::shared arrayref of marshalled parameters
#*/
sub marshal {
	my $self = shift;
	my @params : shared = ();
	my ($type, $tac, $shared);
#
#	marshal params, checking for Queueable or shared objects
#
	foreach (@_) {
		$type = defined($_) ? ref $_ : undef;
#
#	if undef or scalar, use as is
#
		push (@params, undef, $_),
		next
			unless $type;

		$shared = threads::shared::is_shared($_);
#
#	if non-object ref, then
#	if shared, use as is
#	else, invoke Storable
#
		push (@params, ($shared ? (undef, $_) : ('Storable', freeze($_)))),
		next
			if (($type eq 'ARRAY') ||
				($type eq 'HASH') ||
				($type eq 'SCALAR'));
#
#	SORRY NO CAN DO!!!
#	At least, not until Perl gets its shit together...
#
#	if a GLOB, then convert to a fileno open() string
#	with mode
#	need to collect its r/w/append status ?
#
#		if ($type eq 'GLOB') {
#			push (@params, $type, fileno($_));
#			next;
#		}
#
#	if a IO::Handle, then collect fileno and mode string
#
#		if ($_->isa('IO::Handle')) :
#			push (@params, 'IO::Handle', $type, fileno($_), mode($_));
#			next;
#		}
#
#	if a code ref, create a TACl for it
#	NOTE: if supplied as a TACl, it gets handle w/ usual
#	TQQ objects
#
		if ($type eq 'CODE') {
			my $closure = Thread::Apartment::register_closure($_, 0);
#			print STDERR "Closure is $closure\n";
			push (@params, $closure->onEnqueue());
			next;
		}
#
#	its an object, check if its TAS; if so,
#	grab its TAC
#
		$tac = $_->get_client(),
		push(@params, $tac->onEnqueue()),
		next
			if (!$_->isa('Thread::Apartment::Client')) &&
				$_->isa('Thread::Apartment::Server');
#
#	its an object, check if its TQQ
#
		push (@params, $_->onEnqueue()),
		next
			if $_->isa('Thread::Queue::Queueable');
#
#	else if shared use as is, else freeze it
#
#	print "Marshalling a $type as ", ($shared ? 'shared' : 'private'), "\n";
		push(@params, ($shared ? ($type, $_) : ('Storable', freeze($_))));
	}
	return \@params;
}

#/**
# Unmarshall the contents of the arrayref previsouly marshalled via
# <a href='#marshal'>marshal()</a>. input parameters into a TQD-compatible format.
# Each parameter is retrieved from the 2-tuple (class descriptor, marshalled value).
# <p>
# Unmarshalling rules are:
# <p>
# <ol>
# <li>If the class descriptor is undef, the marshalled value is used as is
# <li>if the class descriptor is 'Storable', Storable::thaw() is used to recover the
#	parameter value
# <li>if the marshalled value is threads::shared, the object is simply reblessed into the class
# <li>all other classes are assumed to be
#  <a href='http://search.cpan.org/perldoc?Thread::Queue::Queueable'>Thread::Queue::Queueable</a>,
#	and the class's redeem() method is called to recover the object.
# </ol>
#
# @param $result	arrayref of marshalled parameters/results
#
# @return		arrayref of unmarshalled parameters
#*/
sub unmarshal {
	my $self = shift;
	my $result = shift;

	my $i = 0;
	my @results = ();
	my $class;
#
#	if no class, then save as is
#	else if class is 'Storable', then thaw
#	else if class is TQQ, redeem it
#	else rebless it (its a shared object)
#
	while ($i < scalar @$result) {
		$class = $result->[$i++];

		push (@results, $result->[$i++]),
		next
			unless $class;

		push(@results, thaw($result->[$i++])),
		next
			if ($class eq 'Storable');

		my $obj = $result->[$i++];
		push(@results, bless $obj, $class),
		next
			if ($class ne 'Thread::Apartment::Closure') &&
				threads::shared::is_shared($obj);
#
#	SORRY NO CAN DO!!!
#	At least, not until Perl gets its shit together...
#
#		if ($class eq 'GLOB') {
#			my $fd;
#			open($fd, $result->[$i++]);
#			push @results, $fd;
#			next;
#		}
#
#	we need to chain classes for IO::Handle descendents
#
#		elsif ($class eq 'IO::Handle') {
#			$class = $result->[$i++];
#
#	NOTE: we assume this must be successful, since we managed
#	to load it in the first place
#
#			eval "require $class;";
#			push @results, ${class}->fdopen($result->[$i], $result->[$i+1]);
#			$i += 2;
#		}
#		else {
#
# check for a closure:
#	NOTE: this has multiple arguments after the class name
#
		push(@results, ${class}->redeem($obj, $result->[$i++], $result->[$i++])),
#		print "Unmarhsalled a closure\n" and
		next
			if ($class eq 'Thread::Apartment::Closure');
#
# better be TQQ!!
#	NOTE: we assume this must be successful, since we managed
#	to load it in the first place
#
#		print "Unmarshalled a nonshared $class\n";
		eval "require $class;";
		push @results, ${class}->redeem($obj);
	}

    return \@results;
}

1;
