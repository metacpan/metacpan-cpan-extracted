#
# Package Definition
#

package Text::UberText::Dispatch;

#
# Compiler Directives
#

use strict;
use warnings;

#
# Global Variables
#

use vars qw/$VERSION /;

$VERSION=0.95;

#
# Methods
#

sub new
{
my ($class)=shift;
my ($object);
$object={};
bless ($object,$class);
$object->_init(@_);
return $object;
}

sub main
{
my ($self)=shift;
if (@_)
{
	$self->{main}=shift;
}
if ($self->{main})
{
	$self->{log}=$self->{main}->log();
	print("Dispatch log set to $self->{log}\n");
}
return $self->{main};
}

sub extend
{
my ($self)=shift;
if (@_)
{
        my ($object,$space)=@_;
        my ($newobj,$defspace,$table);
        # Determine if $object is a package name or a class
        unless (ref($object))
        {
                unless ($object->VERSION)
                {
                        eval " require $object; ";
                        if ($@)
                        {
				$self->{log}->write("Dispatch",
					"Import of $object failed ($@)",
					undef,"ERROR");
                                return;
                        }
                } else {
			$self->{log}->write("Dispatch",
				"Object $object already imported",
				undef,"NOTICE");
                }
        }
        # Run the "uberText" method to get data on recommended namespace,
        # dispatch table, and object to run methods against
        eval { $object->uberText() };
        if ($@)
        {
		$self->{log}->write("Dispatch",
			"Object $object does not support uberText method",
			undef,"ERROR");
                return;
        } else {
                ($newobj,$defspace,$table)=$object->uberText();
                $space=$defspace unless ($space);
		$self->{log}->write("Dispatch","Object $object loaded",
			undef,"NOTICE");
        }
        unless ($newobj->VERSION)
        {
		$self->{log}->write("Dispatch",
			"Object $newobj did not return VERSION",
			undef,"NOTICE");
                # Either there's no VERSION, or this object
                # isn't working
        }
        if ($self->{table}->{$space})
        {
                # Something else is already using this space
		$self->{log}->write("Dispatch",
			"Another object is already using namespace $space",
			undef,"ERROR");
                return undef;
        } else {
		$self->{log}->write("Dispatch",
			"Object loaded in dispatch table",undef,"DEBUG");
                $self->{table}->{$space}->{object}=$newobj;
                $self->{table}->{$space}->{dispatch}=$table;
        }
}
return;
}

sub involke
{
my ($self)=shift;
if (@_)
{
	my ($node,$namespace,$command,$object,$method,$output);
	$node=shift;
	$namespace=$node->namespace();
	($command)=$node->command();
	$command="_default" unless ($command);
	$object=$self->{table}->{$namespace}->{object};
	$method=$self->{table}->{$namespace}->{dispatch}->{$command};
	if ($object && $method)
	{
		$output=$object->$method($node);
		return $output;
	} else {
		$self->{log}->write("Dispatch",
			"No object or method available for $namespace/$command",
			undef,"ERROR");
	}
}
return;
}

sub fetch
{
my ($self)=shift;
if (@_)
{
	my ($namespace)=shift;
	return $self->{table}->{$namespace}->{object};
}
return;
}

#
# Hidden Methods
#

sub _init
{
my ($self)=shift;
my ($a);
while (@_)
{
	($a)=shift;
	if ($a eq "-main")
	{
		$self->main(shift);
	}
}
$self->{table}={};
return;
}


#
# Exit Block
#
1;

#
# POD Documentation
#

=head1 NAME

Text::UberText::Dispatch - UberText Code Dispatcher

=head1 DESCRIPTION

Text::UberText::Dispatch keeps track of loaded code modules that extend 
the UberText template language.  A Dispatch object is automatically 
created for new Text::UberText objects.

=head1 EXTENDING UBERTEXT

If you write a module that integrates with an UberText template, the UberText 
object needs to be aware of it.

$uber=Text::UberText->new();

$uber->extend($myObject);

$uber->extend(MyClass);

The UberText module passes the object or class name to the 
Text::UberText::Dispatch object.  The Dispatch object then calls the 
C<uberText> method of the module it was passed.

The C<uberText> method will need to return 3 variables.  The first is the 
object that the dispatch table will need to use when it encounters 
your custom namesapce.  The second variable is the preferred namespace 
the object will use, and the third is an anonymous hash containing the 
dispatch table matching UberText tags and Perl code.

=head1 EXAMPLE

=head2 Custom Module

 package Automobile;

 $Dispatch={
 	"make" => \&make,
 	"model" => \&model,
 	"color" => \&color,
	"odometer' => \&mileage,
 };

 sub uberText
 {
 my ($self)=shift;
 return ($self,"my.automobile",$Dispatch);
 }

 sub make
 {
 my ($self)=shift;
 return ($self->{color});
 }

 sub mileage
 {
 my ($self,$node)=@_;
 my ($value);
 if ($node->commandValue() eq "trip")
 {
       $value=$self->{odometer}->{trip};
 } else {
       $value=$self->{odometer}->{basic};
 }
 if ($node->getOptValue("units") eq "metric")
 {
        # convert miles to kilometers
        $value=$value*1.61;
 }
 return $value;
 }

=head2 UberText File

 The manufacturer of my car is [my.automobile make ]
 It is described as a [my.automobile color ] [my.automobile model ].
 My last trip was [my.automobile odometer:(trip) units:(metric) ] kilometers.


=head1 METHODS

=over 4

=item $dispatch->extend($module)

When a class name is passed to the Dispatch object, the module is loaded, 
and the uberText() method is called.  When a blessed object is passed, the 
loading isn't necessary, so only the uberText() method is called.

Based on the data returned from UberText, the data returned from the 
uberText() method is saved in the internal dispatch table.

=item $dispatch->involke($node);

Takes the internal data from a Command node, and then runs the command 
associated with the namespace.

=item $dispatch->fetch($namespace);

Returns the object in the dispatch table assigned to a particular UberText 
namespace.

=back

=head1 AUTHOR

Chris Josephes E<lt>cpj1@visi.comE<gt>     

=head1 SEE ALSO

L<Text::UberText>

=head1 COPYRIGHT

Copyright 2002, Chris Josephes.  All rights reserved.
This module is free software.  It may be used, redistributed, 
and/or modified under the same terms as Perl itself.
~
