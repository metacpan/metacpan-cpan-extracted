package Tk::CWidget;

use strict;
use Carp;
use Tk qw(Ev);
use Tk::CWidget::Util::Boolean qw(IsTrue);

use vars qw($VERSION);
$VERSION = "0.01";

use base qw(Tk::Frame);
Tk::Widget->Construct('CWidget');

############################################################
## Configuration Methods - support Widget creation and
## the configure method.
############################################################

sub Populate
{
   my ($cw, $args) = @_;
   $cw->SUPER::Populate($args);
   $cw->ConfigSpecs(-subwidgets => [qw/METHOD/]);
}

sub subwidgets
{
   my ($cw, $configAR) = @_;
   $cw->afterIdle(['configureSubwidgets', $cw, $configAR]);
   return;
}

############################################################
## "public" methods
############################################################

############################################################################
## Convenience method for configuring one or more Subwidgets. This
## method one or more pairs of arguments. The first item in each pair
## is expected to be either the name of one Subwidget, or an Array
## reference containing multiple Subwidgets names, and the second in
## the pair should be a Hash reference containing one or more
## configuration parameters that will be passed to the named Subwidget(s).
############################################################################
sub configureSubwidgets 
{
   my $cw = shift;
   my @args;
   if (@_ > 1) { (@args) = @_; }
   else        { (@args) = @{$_[0]}; }

   while (@args) {
      my $key   = shift @args;
      my $valHR = shift @args;
      my $type  = ref($key);

      my @widgets;
      if (!$type)              { @widgets = ($key); }
      elsif ($type eq "ARRAY") { @widgets = @{$key}; }
      else {
         carp "Invalid parameter: expected Subwidget name or ARRAY ref"; 
         return;
      }

      foreach my $w (@widgets) {
         my $sw = $cw->Subwidget($w);
	 if (defined($sw)) { $sw->configure(%$valHR); }
         else { carp "Subwidget: $w does not exist!";}
      }
   }
}

1;
