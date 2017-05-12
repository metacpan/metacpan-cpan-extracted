# reform::implicit.pm
#
# Provides "self", "base" and "class" accessors to using classes.
# Written by Henning Koch <jaz@netalive.org>.
# Two methods stolen from Simon Cozens' rubyisms.pm.

package reform::implicit;

use strict;
use base 'Exporter';
our @EXPORT = ('self', 'base', 'class');

# Accessor to base class methods.
sub base 
{
	# $class is the package in which the method lies
	# that just called base(). This might be the grandparent
	# or grand-grandparent of self's class, so we may not
	# deduce it from self.
	my $class = (caller(0))[0];
	reform::implicit::BaseCaller->new(self(1), $class);
}

# Accessor to the current package.
sub class 
{
	my $class = self(1);
	ref $class and $class = ref $class;
	$class;
}

# Accessor to the current instance.
# Stolen from Simon Cozens' rubyisms.pm.
sub self 
{
	my($uplevel) = @_;

	my $call_pack = (caller($uplevel))[0];

	# So we're looking for the first thing that ISA $call_pack
	my $level = 1;
	while (caller($level)) 
	{
		my @their_args = DB::uplevel_args($level);
		if (ref $their_args[0]
		    and eval { $their_args[0]->isa($call_pack) }) 
		{
		    return $their_args[0];
		}
		$level++;
	}
	# Well, hey, maybe it's a class method.
	return $call_pack;
}

# Gets the arguments of a subroutine call some frames up.
# Stolen from Simon Cozens' rubyisms.pm.
package DB;
sub uplevel_args { my @foo = caller($_[0]+1); return @DB::args };


# Object on which the base accessor works.
package reform::implicit::BaseCaller;

# Pre-reform style constructor.
sub new
{
	my($class, $object, $calling_class) = @_;
	# $class is the package in which the method lies
	# that just called base().
	# We may NOT get $class from $object if we ever want to
	# use base more than one level of inheritance up.
	my $self = { object => $object,
	             class  => $calling_class };
	bless($self, $class);
	$self;
}

# Since the BaseCaller has no other methods itself, all
# method calls to the base calls should land here.
sub AUTOLOAD
{
	my $self = shift;
	our ($AUTOLOAD);
	
	my $method = $AUTOLOAD;
	   $method =~ /(\w+)$/;
	   $method = $1;
	
	return if $method eq 'DESTROY';
	
	my $object = $self->{object};
	my $class  = $self->{class};  # may be parent of $object (see above)
	
	# print "OBJECT: $object\n";
	# print "CALLING: $class\n";
	# print "\$object->$class\:\:SUPER\:\:$method(\@_)\n";
	
	my @re = eval "\$object->$class\:\:SUPER\:\:$method(\@_)";
	$@ and die "Error calling base method: $@";
	return @re;
	
}

1;
