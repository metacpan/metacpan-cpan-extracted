#!/ford/thishost/unix/div/ap/bin/perl -w
#!../xperl -w

use blib;

use strict;
use X11::Motif;
#use X11::Xbae;
#use X11::XRT;

my %listing_by_type = ();
my %listing_by_class = ();

foreach my $widget_class (keys %X::Toolkit::Widget::resource_registry) {
    my $registry = $X::Toolkit::Widget::resource_registry{$widget_class};
    foreach my $name (keys %{$registry}) {
	my $class = $registry->{$name}[0];
	my $type = $registry->{$name}[1];
	my $size = $registry->{$name}[2];

	if (!exists $listing_by_type{$type}) {
	    $listing_by_type{$type} = [ { $class => 1 },  $size ];
	}
	else {
	    $listing_by_type{$type}[0]{$class} = 1;
	    if ($listing_by_type{$type}[1] != $size) {
		print "warning: resource $name uses different size for same type\n";
	    }
	}

	if (!exists $listing_by_class{$class}) {
	    $listing_by_class{$class} = { $name => 1 };
	}
	else {
	    $listing_by_class{$class}{$name} = 1;
	}
    }
}

my $sep = "\n" . (' ' x 45);

print "\nWidget Class Listing:\n\n";

foreach my $class (sort keys %X::Toolkit::Widget::resource_registry) {
    print "    $class\n";
}

print "\nResource Class Listing By Type:\n\n";

foreach my $type (sort keys %listing_by_type) {
    print sprintf("%3d %-40s ", $listing_by_type{$type}[1], $type), join($sep, sort keys %{$listing_by_type{$type}[0]}), "\n";
}

print "\n\nResource Name Listing By Class:\n\n";

foreach my $class (sort keys %listing_by_class) {
    print sprintf("    %-40s ", $class), join($sep, sort keys %{$listing_by_class{$class}}), "\n";
}
