###############################################################################
#
# This file copyright (c) 2006-2008 by Randy J. Ray, all rights reserved
#
###############################################################################
#
#   $Id: DUMMY.pm 47 2008-04-06 10:12:34Z  $
#
#   Description:    This is a dummy-protocol stub that inherits from the REST
#                   protocol module, but replaces the raw_content() method that
#                   makes a HTTP request with a local file look-up instead.
#
#   Functions:      raw_request
#
#   Libraries:      WebService::ISBNDB::Agent
#                   WebService::ISBNDB::Agent::REST
#                   Class::Std
#
#   Global Consts:  $VERSION
#
###############################################################################

package WebService::ISBNDB::Agent::DUMMY;

use 5.006;
use strict;
use warnings;
no warnings 'redefine';
use vars qw($VERSION $BASEDIR %ARGMAP);
use base 'WebService::ISBNDB::Agent::REST';

use File::Basename 'dirname';
use Class::Std;

$VERSION = "0.10";

BEGIN
{
    $BASEDIR = dirname __FILE__;
    WebService::ISBNDB::Agent->add_protocol(DUMMY => __PACKAGE__);
}

###############################################################################
#
#   Sub Name:       new
#
#   Description:    Pass off to the super-class constructor, which handles
#                   the special cases for arguments.
#
###############################################################################
sub new
{
    shift->SUPER::new(@_);
}

###############################################################################
#
#   Sub Name:       raw_request
#
#   Description:    This is a dummy stub for the testing module to prevent
#                   actual calls to the isbndb.com service. It uses the type
#                   of $obj and values from $args to create a file name. It
#                   then reads the file and returns that content as the body
#                   for the request. All files must be in the same directory
#                   as this module.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $obj      in      ref       Object from the API hierarchy
#                   $args     in      hashref   Arguments to the request
#
#   Globals:        $BASEDIR
#
#   Returns:        Success:    scalar reference
#                   Failure:    throws Error::Simple
#
###############################################################################
sub raw_request : RESTRICTED
{
    my ($self, $obj, $args) = @_;

    # Resolve $obj before using it to call get_type
    $obj = $self->resolve_obj($obj);
    my $type = $obj->get_type;

    # Convert $args into a string used in the file name
    my $argstring = $self->args_to_string($args);
    throw Error::Simple('Cannot call DUMMY::raw_request without any $args')
        unless $argstring;

    # File name is the type + args. Throw an error if we can't open it.
    my $file = "$BASEDIR/xml/$type-$argstring.xml";
    throw Error::Simple("Error opening $file for reading: $!")
        unless open my $fh, "< $file";

    my $body = join('', <$fh>);
    \$body;
    # $fh closes when we exit
}

###############################################################################
#
#   Sub Name:       args_to_string
#
#   Description:    Convert the arguments in the hashref into a string. Sort
#                   all the labels from "indexX" arguments and combine with
#                   their corresponding "valueX" argument.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object (unused)
#                   $args     in      hashref   Arguments to convert
#
#   Returns:        string
#
###############################################################################
sub args_to_string : PRIVATE
{
    my ($self, $args) = @_;

    my @nums = (join(' ', grep(/^index/, keys %$args))) =~ /(\d+)/g;
    my %names = map { $_ => $args->{"index$_"} } @nums;
    if ($args->{page_number})
    {
        $names{page_number} = $args->{page_number};
        push(@nums, 'page_number');
    }

    my @parts = ();

    for (sort { $names{$a} cmp $names{$b} } @nums)
    {
        if (ref $args->{"value$_"})
        {
            push(@parts,
                 $names{$_} . '=' . join(',', sort @{$args->{"value$_"}}));
        }
        elsif ($_ eq 'page_number')
        {
            push(@parts, 'page_number=' . $args->{$_});
        }
        else
        {
            push(@parts, $names{$_} . '=' . $args->{"value$_"});
        }
    }

    join('-', @parts);
}

1;
