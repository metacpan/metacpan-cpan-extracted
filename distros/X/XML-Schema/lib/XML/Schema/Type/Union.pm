#============================================================= -*-perl-*-
#
# XML::Schema::Type::Union
#
# DESCRIPTION
#   Module implementing the XML Schema union datatype.
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
#   $Id: Union.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Type::Union;

use strict;
use XML::Schema::Type::Simple;
use base qw( XML::Schema::Type::Simple );
use vars qw( $VERSION $DEBUG $ERROR @MANDATORY );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@MANDATORY = qw( memberTypes );

sub init {
    my ($self, $config) = @_;
    $self->SUPER::init($config)
	|| return;
    $self->{ _VARIETY } = 'union';
    return $self;
}

sub validate_instance {
    my ($self, $infoset) = @_;

    $self->SUPER::validate_instance($infoset) 
	|| return;

    my $value = $infoset->{ text };
    my ($newval, @errors);

    my $members = $self->{ memberTypes }
	|| return $self->error('union has no memberTypes');

    foreach my $member (@$members) {
	$newval = $member->instance($value);
	if ($newval) {
	    $infoset->{ value } = $newval;
	    return 1;
	}
	push(@errors, $member->name() . ': ' . $member->error());
    }
    return $self->error("invalid union: ", join(', ', @errors));
}

1;

__END__

=head1 NAME

XML::Schema::Type::Union - union type for XML Schema datatypes

=head1 SYNOPSIS

    # declare some simple types
    my $int   = XML::Schema::Type::int->new();
    my $time  = XML::Schema::Type::time->new();
    my $float = XML::Schema::Type::float->new();

    # declare a union
    my $union = XML::Schema::Type::Union->new(
	memberTypes => [ $int, $time, $float ],
    );

    # instantiate a validated member of the union
    my $i = $union->instance('14');	    # ok - int
    my $t = $union->instance('11:23:36');   # ok - time
    my $f = $union->instance('1.23');	    # ok - float

=head1 DESCRIPTION

This module implements the XML Schema union type.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.1.1.1 $ of the XML::Schema::Type::Union,
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<XML::Schema> and L<XML::Schema::Type::Simple>.


