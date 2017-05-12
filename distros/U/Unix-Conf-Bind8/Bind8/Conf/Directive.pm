# Base class for all directives. 
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf::Directive - Base class for all classes representing
various directives in a Bind8 configuration file. 

=head1 DESCRIPTION

This class is also used directly for representing dummy directives, i.e. ones
that represent comments, whitespace etc.. between two directives.

=cut

package Unix::Conf::Bind8::Conf::Directive;

use strict;
use warnings;

use Unix::Conf;

=over 4

=item new ()

Class method.
Returns a Unix::Conf::Bind8::Conf::Directive object.

=cut

sub new 
{
	my $class = shift ();
	my %args = @_;
	my ($new, $ret);

	return (Unix::Conf->_err ('new', "not an object constructor"))
		if (ref ($class));
	$args{PARENT} || return (Unix::Conf->_err ('new', "PARENT not specified"));
	$new = bless ({}, $class);
	$ret = $new->_parent ($args{PARENT}) or return ($ret);
	$args{WHERE} = 'LAST' unless ($args{WHERE});
	$ret = Unix::Conf::Bind8::Conf::_insert_in_list ($new, $args{WHERE}, $args{WARG})
		or return ($ret);
	return ($new);
}

sub DESTROY
{
	my $self = $_[0];
	# all directive types are hash
	# delete hash
	undef (%$self);
}

=item dirty ()

 Arguments
 0/1,   # optional

Object method.
If argument is passed its value is set as the dirty flag. 0 for false, 1 for
true. Sets the object as dirty. If argument is not passed returns the value
of the dirty flag, which can be evaluted in a boolean context.

=cut

sub dirty 
{
	if (defined ($_[1])) {
		$_[0]->{DIRTY} = $_[1];
		$_[0]->{PARENT}{DIRTY} = $_[1];
		return (1)
	}
	return ($_[0]->{DIRTY});
}

=item delete ()

Object method.
Deletes the directive.

=cut

sub delete
{
	no strict 'refs';
	my $self = $_[0];
	my $ret;

	# Get the class of the invocant
	my $type = ref ($self);
	$type =~ s/^.+::(.+)$/$1/;
	$type = lc ($type);
	my $meth = "Unix::Conf::Bind8::Conf::_del_$type";
	$ret = &$meth ($self) or return ($ret);
	$ret = Unix::Conf::Bind8::Conf::_delete_from_list ($self) 
		or return ($ret);
	$self->dirty (1);
	return (1);
}

sub _parent
{
	my ($self, $parent) = @_;

	if ($parent) {
		# do not allow resetting as PARENT is used to register/update ouself in 
		# the PARENT specific hashes and doubly linked list.
		return (Unix::Conf->_err ('_parent', "PARENT already defined. Cannot reset"))
			if ($self->{PARENT});
		$self->{PARENT} = $parent;
		return (1);
	}
	return (
		defined ($self->{PARENT}) ? $self->{PARENT} : 
			Unix::Conf->_err ('_parent', "`PARENT' not defined")
	)
}

# get/set method.
# if argument passed it sets the rendered string for the directive. else
# returns the directive rendered as a string.
sub _rstring
{
	my ($self, $string, $arg) = @_;

	if (defined ($string)) {
		$self->{RENDERED} = ref ($string) ? $string : \$string;
		$self->dirty (0);
		return (1);
	}
	# make sure we render before returning IF dirty
	if ($self->dirty ()) {
		$self->__render ($arg);
		$self->dirty (0);
	}
	return ($self->{RENDERED});
}

# set method.
sub _tws
{
	my ($self, $string) = @_;

	if (defined ($string)) {
		$self->{TWS} = ref ($string) ? $string : \$string;
		return (1);
	}
	return ($self->{TWS});
}

1;
__END__
