#!perl -w
#
# Tk Transaction Manager.
# Action Bar widget - Set of data objects
#
# makarow, demed
#

package Tk::TM::wgActionBar;
require 5.000;
use strict;
use Tk;
use Tk::TM::wgMenu;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.50';
@ISA = ('Tk::TM::wgMenu');

Tk::Widget->Construct('tmActionBar'); 

sub Populate {
 my ($self, $args) = (shift,shift);
 $args->{-mdmnu}='';
 $self->SUPER::Populate($args,@_)
}
