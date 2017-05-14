# $Id: xml_space.pm,v 1.1 2011/11/20 18:18:46 pfeiffer Exp $
use strict;
package Mpp::Signature::xml_space;

use Mpp::Signature::xml;

our @ISA = qw(Mpp::Signature::xml); # This one does all the work for us.

our $xml_space = bless \@ISA;	# Make the singleton object.
