package Tk::ECWarning;

$VERSION='0.00';

use Tk qw(Ev);
use strict;
use Carp;
use base qw(Tk::Derived Tk::Toplevel);
use Tk::widgets qw(Button Label Frame);

Construct Tk::Widget 'ECWarning';

sub Cancel {
  my ($w) = @_;
  $w -> {Configure}{-response} = 'Cancel';
}

sub Ok {
    my ($w) = @_;
    $w -> {Configure}{-response} = 'Ok';
}

sub Populate {
    my ($w, $args) = @_;
    $w->SUPER::Populate($args);

    $w->ConfigSpecs(
        -font => ['CHILDREN',undef,undef,'*-helvetica-medium-r-*-*-12-*'],
	-message => ['PASSIVE', undef, undef, ''],
	-response => ['PASSIVE', undef, undef, '']
    );

    $w -> configure (-title => 'Warning');

    my $l = $w -> Component( Label => 'entry_label',
	     -textvariable => \$w->{Configure}{-message});
    $l -> grid( -column => 2, -row => 1, -padx => 5, -pady => 5,
		-columnspan => 3);

    $b = $w -> Button(-text => 'Ok', -command => ['Ok', $w],
		      -width => 10 );
    $b->grid(-column=>2,-row=>2,-padx=>5,-pady=>5,-sticky=>'nsew');


    $b = $w->Button( -text => 'Cancel', -command => ['Cancel', $w],
		     -width => 10);
    $b->grid( -column => 4, -row => 2, -padx => 5, -pady => 5,
	    -sticky => 'nsew' );
    $w -> withdraw;
    return $w;
}

sub Show {
    my ($w, @args) = @_;
    $w -> Popup(@args);
    $w -> waitVariable (\$w->{Configure}{-response});
    $w -> withdraw;
    return $w->{Configure}{-response};
}

1;
