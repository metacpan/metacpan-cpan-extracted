package Travel::Status::DE::EFA::Info;

use strict;
use warnings;
use 5.010;

use parent 'Class::Accessor';

our $VERSION = '3.04';

Travel::Status::DE::EFA::Info->mk_ro_accessors(
	qw(link_url link_text subject content subtitle additional_text));

sub new {
	my ( $obj, %opt ) = @_;

	my $json = $opt{json};

	my $ref = {
		param           => {},
		link_url        => $json->{infoLinkURL},
		link_text       => $json->{infoLinkText},
		subject         => $json->{infoText}{subject},
		content         => $json->{infoText}{content},
		subtitle        => $json->{infoText}{subtitle},
		additional_text => $json->{infoText}{additionalText},
	};

	for my $param ( @{ $json->{paramList} // [] } ) {
		$ref->{param}{ $param->{name} } = $param->{value};
	}

	return bless( $ref, $obj );
}

sub TO_JSON {
	my ($self) = @_;

	return { %{$self} };
}

1;

__END__

=head1 NAME

Travel::Status::DE::EFA::Info - Information about a public transit stop

=head1 SYNOPSIS

    if ( $info->subject and $info->subtitle ne $info->subject ) {
        printf( "# %s\n%s\n", $info->subtitle, $info->subject );
    }
    else {
        printf( "# %s\n", $info->subtitle );
    }

=head1 VERSION

version 3.04

=head1 DESCRIPTION

Travel::Status::DE::EFA::Info holds a single information message related to
a specific public transit stop.

=head1 ACCESSORS

All accessors may return undef.
Individual accessors may return identical strings.
Strings may contain HTML elements.

=over

=item $info->additional_text

=item $info->content

=item $info->link_url

URL to a site related to this information message.
The site may or may not hold additional data.

=item $info->link_text

Text for linking to link_url.

=item $info->param

Hashref of parameters, e.g. C<< incidentDateTime >> (string describing the
date/time range during which this message is valid).

=item $info->subject

=item $info->subtitle

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item Class::Accessor(3pm)

=back

=head1 BUGS AND LIMITATIONS

This module is a Work in Progress.
Its API may change between minor versions.

=head1 SEE ALSO

Travel::Status::DE::EFA(3pm).

=head1 AUTHOR

Copyright (C) 2024 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
