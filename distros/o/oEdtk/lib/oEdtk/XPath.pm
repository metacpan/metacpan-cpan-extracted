package oEdtk::XPath;

use strict;
use warnings;

use base 'XML::XPath';
our $VERSION = 2.1126;

sub findTextValue {
	my ( $self, $path, $context ) = @_;
	my $val = $self->findvalue( $path, $context );
	return "$val";
}

1;

=head1 NAME

oEdtk::XPath - XML::XPath subclass returning plain string values

=head1 SYNOPSIS

    use oEdtk::XPath;

    my $xp = oEdtk::XPath->new(filename => 'doc.xml');
    my $v  = $xp->findTextValue('/root/child');

=head1 DESCRIPTION

A minimal subclass of C<XML::XPath> that adds a string-coercing lookup: it
runs the usual C<findvalue> and forces the result into a plain string, so a
node value can be used directly as a scalar.

=head1 METHODS

=head2 findTextValue

    my $value = $xp->findTextValue($path, $context);

Run C<findvalue> for C<$path> in C<$context> and return its result as a plain
string. The rest of the C<XML::XPath> API (C<new>, C<find>, C<findnodes>, ...)
is inherited unchanged.

=head1 AUTHOR

The oEdtk team.

=cut
