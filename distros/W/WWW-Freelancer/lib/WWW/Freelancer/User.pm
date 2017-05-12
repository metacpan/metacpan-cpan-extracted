package WWW::Freelancer::User;

use warnings;
use strict;

sub get_url {
    my $self = shift;
    return $self->{'url'};
}

sub get_id {
    my $self = shift;
    return $self->{'id'};
}

sub get_username {
    my $self = shift;
    return $self->{'username'};
}

sub get_logo_url {
    my $self = shift;
    return $self->{'logo_url'};
}

sub get_registration_unixtime {
    my $self = shift;
    return $self->{'reg_unixtime'};
}

sub get_registration_date {
    my $self = shift;
    return $self->{'reg_date'};
}

sub get_company {
    my $self = shift;
    return $self->{'company'};
}

sub is_gold {
    my $self = shift;
    return $self->{'gold'};
}

sub get_address {
    my $self = shift;
    return bless $self->{'address'}, 'WWW::Freelancer::User::Address';
}

sub get_hourlyrate {
    my $self = shift;
    return $self->{'hourlyrate'};
}

sub get_rating {
    my $self = shift;
    return bless $self->{'rating'}, 'WWW::Freelancer::User::Rating';
}

sub get_provider_rating {
    my $self = shift;
    return bless $self->{'provider_rating'},
      'WWW::Freelancer::User::ProviderRating';
}

sub get_buyer_rating {
    my $self = shift;
    return bless $self->{'buyer_rating'}, 'WWW::Freelancer::User::BuyerRating';
}

sub get_jobs {
    my $self = shift;
    return @{ $self->{'jobs'} };
}

package WWW::Freelancer::User::Address;

use warnings;
use strict;

sub get_country {
    my $self = shift;
    return $self->{'country'};
}

sub get_city {
    my $self = shift;
    return $self->{'city'};
}

package WWW::Freelancer::User::Rating;

use warnings;
use strict;

sub get_average {
    my $self = shift;
    return $self->{'avg'};
}

sub get_count {
    my $self = shift;
    return $self->{'count'};
}

package WWW::Freelancer::User::ProviderRating;

use warnings;
use strict;

sub get_average {
    my $self = shift;
    return $self->{'avg'};
}

sub get_count {
    my $self = shift;
    return $self->{'count'};
}

package WWW::Freelancer::User::BuyerRating;

use warnings;
use strict;

sub get_average {
    my $self = shift;
    return $self->{'avg'};
}

sub get_count {
    my $self = shift;
    return $self->{'count'};
}

1;

__END__

=head1 NAME

WWW::Freelancer::User - Provides methods to access information about a specific
user.

=head1 VERSION

This document describes WWW::Freelancer::User version 0.0.1


=head1 SYNOPSIS

    use WWW::Freelancer;

    my $freelancer = WWW::Freelancer->new();
    my $user       = $freelancer->get_user('alanhaggai');

    print 'User ID: ',                 $user->get_id(),                "\n";
    print 'User profile URL: ',        $user->get_url(),               "\n";
    print 'User registration date: ',  $user->get_registration_date(), "\n";


=head1 DESCRIPTION

Provides methods to access information about a specific user.


=head1 INTERFACE 

=over 4

=item C<< get_url() >>

Returns URL of user profile.

=item C<< get_id() >>

Returns ID of the user.

=item C<< get_username() >>

Returns username of the user.

=item C<< get_logo_url() >>

Returns URL of logo or empty string.

=item C<< get_registration_unixtime() >>

Returns time when the user was registered in UNIXTIME format.

=item C<< get_registration_date() >>

Returns time when the user was registered in RFC 2822 format.

=item C<< get_company() >>

Returns company name or empty string if company is not specified.

=item C<< is_gold() >>

Returns 1 if the user is a gold member currently, 0 - a non-gold member.

=item C<< get_address() >>

Returns an address object. Methods of the object:

=over 4

=item C<< get_country() >>

Returns user's country.

=item C<< get_city() >>

Returns user's city.

=back

=item C<< get_hourlyrate() >>

Returns hourly rate in US dollars.

=item C<< get_rating() >>

Returns rating object. Methods of the object:

=over 4

=item C<< get_average() >>

Returns average value of user's overall rating. Empty - if user has not got any rating yet.

=item C<< get_count() >>

Returns number of feedbacks received by user.

=back

=item C<< get_provider_rating() >>

Returns provider rating object. Methods of the object:

=over 4

=item C<< get_average() >>

Returns average value of provider's overall rating. Empty - if user has not got any rating yet.

=item C<< get_count() >>

Returns number of provider feedbacks received by user.

=back

=item C<< get_buyer_rating() >>

Returns buyer rating object. Methods of the object:

=over 4

=item C<< get_average() >>

Returns average value of buyer's overall rating. Empty - if user has not got any rating yet.

=item C<< get_count() >>

Returns number of buyer feedbacks received by user.

=back

=item C<< get_jobs() >>

Returns array of jobs.

=back


=head1 CONFIGURATION AND ENVIRONMENT

WWW::Freelancer::User requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over 4

=item L<LWP::UserAgent>

Not in CORE

=item L<JSON>

Not in CORE

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to C<bug-www-freelancer@rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Alan Haggai Alavi  C<< <haggai@cpan.org> >>


=head1 SEE ALSO

=over 4

=item * L<WWW::Freelancer>

=item * L<WWW::Freelancer::Project>

=back


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Alan Haggai Alavi C<< <haggai@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
