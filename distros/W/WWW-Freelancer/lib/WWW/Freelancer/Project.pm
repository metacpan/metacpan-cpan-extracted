package WWW::Freelancer::Project;

use warnings;
use strict;

sub get_id {
    my $self = shift;
    return $self->{'id'};
}

sub get_name {
    my $self = shift;
    return $self->{'name'};
}

sub get_url {
    my $self = shift;
    return $self->{'url'};
}

sub get_start_unixtime {
    my $self = shift;
    return $self->{'start_unixtime'};
}

sub get_start_date {
    my $self = shift;
    return $self->{'start_date'};
}

sub get_end_unixtime {
    my $self = shift;
    return $self->{'end_unixtime'};
}

sub get_end_date {
    my $self = shift;
    return $self->{'end_date'};
}

sub get_buyer {
    my $self = shift;
    return bless $self->{'buyer'}, 'WWW::Freelancer::Project::Buyer';
}

sub get_state {
    my $self = shift;
    return $self->{'state'};
}

sub get_short_description {
    my $self = shift;
    return $self->{'short_descr'};
}

sub get_options {
    my $self = shift;
    return bless $self->{'options'}, 'WWW::Freelancer::Project::Options';
}

sub get_budget {
    my $self = shift;
    return bless $self->{'budget'}, 'WWW::Freelancer::Project::Budget';
}

sub get_jobs {
    my $self = shift;
    return @{ $self->{'jobs'} };
}

sub get_bid_stats {
    my $self = shift;
    return bless $self->{'bid_stats'}, 'WWW::Freelancer::Project::BidStats';
}

package WWW::Freelancer::Project::Options;

use warnings;
use strict;

sub is_featured {
    my $self = shift;
    return $self->{'featured'};
}

sub is_nonpublic {
    my $self = shift;
    return $self->{'nonpublic'};
}

sub is_trial {
    my $self = shift;
    return $self->{'trial'};
}

sub is_fulltime {
    my $self = shift;
    return $self->{'fulltime'};
}

sub is_for_gold_members {
    my $self = shift;
    return $self->{'for_gold_members'};
}

sub is_hidden_bids {
    my $self = shift;
    return $self->{'hidden_bids'};
}

package WWW::Freelancer::Project::Buyer;

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

package WWW::Freelancer::Project::Budget;

use warnings;
use strict;

sub get_minimum {
    my $self = shift;
    return $self->{'min'};
}

sub get_maximum {
    my $self = shift;
    return $self->{'max'};
}

package WWW::Freelancer::Project::BidStats;

use warnings;
use strict;

sub get_count {
    my $self = shift;
    return $self->{'count'};
}

sub get_average {
    my $self = shift;
    return $self->{'avg'};
}

1;

__END__

=head1 NAME

WWW::Freelancer::Project - Provides methods to access information about a
specific project.

=head1 VERSION

This document describes WWW::Freelancer::Project version 0.0.1


=head1 SYNOPSIS

    use WWW::Freelancer;

    my $freelancer = WWW::Freelancer->new();
    my $project    = $freelancer->get_project(1000);

    print 'Project ID: ',   $project->get_id(),   "\n";
    print 'Project Name: ', $project->get_name(), "\n";
    print 'Project URL: ',  $project->get_url(),  "\n";


=head1 DESCRIPTION

Provides methods to access information about a specific project.


=head1 INTERFACE 

=over 4

=item C<< get_id() >>

Returns ID of the project.

=item C<< get_name() >>

Returns title of the project.

=item C<< get_url() >>

Returns URL of the project.

=item C<< get_start_unixtime() >>

Returns time when project was started in UNIXTIME format.

=item C<< get_start_date() >>

Returns time when the project was started in RFC 2822 format.

=item C<< get_end_unixtime() >>

Returns time when the project bidding period ends in UNIXTIME format.

=item C<< get_end_date() >>

Returns time when the project bidding period ends in RFC 2822 format.

=item C<< get_buyer() >>

Returns a buyer object. Methods of the object:

=over 4

=item C<< get_url() >>

Returns URL of the buyer's profile.

=item C<< get_id() >>

Returns ID of the buyer's username.

=item C<< get_username() >>

Returns username of the buyer.

=back

=item C<< get_state() >>

Returns state of the project.

=item C<< get_short_description() >>

Returns shortened text of the project's requirements.

=item C<< get_options() >>

Returns an options object. Methods of the object:

=over 4

=item C<< is_featured() >>

Returns a boolean value. 1 if project is featured, 0 for normal projects.

=item C<< is_nonpublic() >>

Returns a boolean value indicating if the project is public or not.

=item C<< is_trial() >>

Returns a boolean value indicating if the project is trial or not.

=item C<< is_fulltime() >>

Returns a boolean value indicating if the project is fulltime or not.

=item C<< is_for_gold_members() >>

Returns a boolean value indicating if the project is for gold members or not.

=item C<< is_hidden_bids() >>

Returns a boolean value indicating if bids for the project are hidden or not.

=back

=item C<< get_budget() >>

Returns a budget object. Methods of the object:

=over 4

=item C<< get_minimum() >>

Returns numeric value or empty if no minimum is specified.

=item C<< get_maximum() >>

Returns numeric value or empty if no maximum is specified.

=back

=item C<< get_jobs() >>

Returns an array of jobs.

=item C<< get_bid_stats() >>

Returns a bid stats object. Methods of the object:

=over 4

=item C<< get_count() >>

Returns number of bids or empty if bid statistics is not available.

=item C<< get_average() >>

Returns average bid amount or empty if bid statistics is not available.

=back

=back


=head1 CONFIGURATION AND ENVIRONMENT

WWW::Freelancer::Project requires no configuration files or environment variables.


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

=item * L<WWW::Freelancer::User>

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
