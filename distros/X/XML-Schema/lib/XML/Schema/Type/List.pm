#============================================================= -*-perl-*-
#
# XML::Schema::Type::List
#
# DESCRIPTION
#   Module implementing the XML Schema list datatype.
#
# AUTHOR
#   Andy Wardley <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2001 Canon Research Centre Europe Ltd.
#   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: List.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Type::List;

use strict;
use XML::Schema::Type::Simple;
use base qw( XML::Schema::Type::Simple );
use vars qw( $VERSION $DEBUG $ERROR @MANDATORY @FACETS );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@MANDATORY = qw( itemType );
@FACETS = (
    whiteSpace  => 'collapse',
    sub { $_[1]->split($_[0]) },
);

sub split {
    my ($self, $instance) = @_;
    my $base = $self->{ itemType }
	|| return $self->error('list has no itemType');
    my $i = 0;

    $instance->{ value } = [ 
	map {
	    $base->instance($_)
		|| return $self->error("list item $i: " . $base->error());
	    $i++;
	} split(/\s+/, $instance->{ value }) 
    ];

    return 1;
}

sub init {
    my ($self, $config) = @_;
    $self->SUPER::init($config)
	|| return;
    $self->{ _VARIETY } = 'list';
    return $self;
}


__END__

=head1 NAME

XML::Schema::Type::List - list type for XML Schema datatypes

=head1 SYNOPSIS

    # an object to represent the base type
    my $float = XML::Schema::Type::float->new();

    # create a list type of the base type
    my $list = XML::Schema::Type::List->new( itemType => $float );

    # instantiate a validated list
    my $items = $list->instance('3.14  2.718');

    # add constraints to list
    $list->constrain( maxLength => 4 );		# max 3 items

    $item = $list->instance('1.2 3.4 5.6');	# OK
    $item = $list->instance('1.2 3.4 5.6 7.8'); # not OK - 4 items
    $item = $list->instance('hello');		# not OK - not a float

=head1 DESCRIPTION

This module implements the XML Schema list type.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.1.1.1 $ of the XML::Schema::Type::List,
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<XML::Schema> and L<XML::Schema::Type::Simple>.


