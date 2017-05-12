#
# Copyright (C) 1998 Ken MacLeod
# XML::Grove::XPointer is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: XPointer.pm,v 1.2 1999/08/17 15:01:28 kmacleod Exp $
#

use strict;

package XML::Grove::XPointer;

package XML::Grove::Document;

sub xp_child {
    goto &XML::Grove::Element::xp_child;
}

package XML::Grove::Element;

sub xp_child {
    my $self = shift;
    my $instance = shift;
    my $node_type = shift;

    my $look_for;
    if (defined($node_type) && substr($node_type, 0, 1) eq '#') {
	$node_type eq '#element' and do { $look_for = 'XML::Grove::Element' };
        $node_type eq '#pi'      and do { $look_for = 'XML::Grove::PI' };
        $node_type eq '#comment' and do { $look_for = 'XML::Grove::Comment' };
	$node_type eq '#text'    and do { $look_for = 'XML::Grove::Characters' };
	$node_type eq '#cdata'   and do { $look_for = 'XML::Grove::CData' };
	$node_type eq '#any'     and do { $node_type = undef };
    } elsif (defined($node_type)) {
	$look_for = 'element-name';
    }

    my $contents = $self->{Contents};
    my $object = undef;

    $instance--;		# 0 based

    if (!defined $node_type) {
	$object = $contents->[$instance];
    } elsif ($look_for eq 'element-name') {
	my $i_object;
	foreach $i_object (@$contents) {
	    if (ref($i_object) eq 'XML::Grove::Element'
		&& $i_object->{Name} eq $node_type
		&& $instance-- == 0) {
		$object = $i_object;
		last;
	    }
	}
    } else {
	my $i_object;
	foreach $i_object (@$contents) {
	    if (ref($i_object) eq $look_for
		&& $instance-- == 0) {
		$object = $i_object;
		last;
	    }
	}
    }

    return $object;
}

1;

__END__

=head1 NAME

XML::Grove::XPointer - deprecated module once intended for XPointer

=head1 SYNOPSIS

 THIS MODULE IS USED BY XML::Grove::Path, it does not implement any
 current version of XPointer

=head1 DESCRIPTION

This module implements a very tiny portion of an old draft of
XPointer.  XML::Grove::Path still uses this module, but both modules
will be obsolete when a real XPath and XPointer module become
available.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), XML::Grove(3), XML::Grove::Path(3)

Extensible Markup Language (XML) <http://www.w3c.org/XML>

=cut
