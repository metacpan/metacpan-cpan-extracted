package Tk::ChildNotification;

BEGIN
   {
    $Tk::ChildNotification::DerivedInitObject = \&Tk::Derived::InitObject;
    $Tk::ChildNotification::WidgetInitObject = \&Tk::Widget::InitObject;
   }

use vars qw ($VERSION);
use strict;
use Tk;

use Tk::Derived;
use Tk::Widget;

$VERSION = '0.01';

sub Tk::Derived::InitObject
   {
    my $l_Return = &{$Tk::ChildNotification::DerivedInitObject} (@_);
    $_[0]->parent()->ChildNotification (@_) if (defined ($_[0]->parent()));
    return $l_Return;
   }

sub Tk::Widget::InitObject
   {
    my $l_Return = &{$Tk::ChildNotification::WidgetInitObject} (@_);
    $_[0]->parent()->ChildNotification (@_) if (defined ($_[0]->parent()));
    return $l_Return;
   }

#
# Override this method when you want to know when a child has been
# created for you. Don't globally override it (leave out the 'Tk::Widget::'
# part).
#
sub Tk::Widget::ChildNotification
   {
    my ($this, $p_Child) = (shift, @_);
   }

1;

__END__
