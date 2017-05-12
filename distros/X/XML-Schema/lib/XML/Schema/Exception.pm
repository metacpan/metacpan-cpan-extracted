#============================================================= -*-perl-*-
#
# XML::Schema::Exception
#
# DESCRIPTION
#   Exception class for throwing around as errors.
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
#   $Id: Exception.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Exception;

use strict;
use vars qw( $VERSION $DEBUG $ERROR );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

use overload q|""| => "text";


sub new {
    my ($class, $type, $info) = @_;
    bless {
	type => $type,
	info => $info,
    }, $class;
}

sub type { $_[0]->{ type } }
sub info { $_[0]->{ info } }

sub text { 
    my $self = shift; 
    sprintf("[%s] %s", @$self{ qw( type info ) });
}

1;

__END__

=head1 NAME

XML::Schema::Exception - exception class for XML::Schema

=head1 SYNOPSIS

    use XML::Schema::Exception;

    my $err = XML::Schema::Exception->new('type_x', 'info_y');

    print $err->type();	    # type_x
    print $err->info();     # info_y
    print $err->text();     # [type_x] info_y
    print $err;             # [type_x] info_y

    die $err;

=head1 DESCRIPTION

This module implements an exception class for XML::Schema.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.1.1.1 $ of the XML::Schema::Base module,
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See L<XML::Schema> for general information about these modules and
their use.
