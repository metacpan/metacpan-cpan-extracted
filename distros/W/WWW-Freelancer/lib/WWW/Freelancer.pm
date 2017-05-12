package WWW::Freelancer;

use warnings;
use strict;

use version; our $VERSION = qv('0.0.1');

use LWP::UserAgent;
use JSON qw( from_json );
use WWW::Freelancer::Project;
use WWW::Freelancer::User;

my $user_agent = LWP::UserAgent->new( 'agent' => __PACKAGE__ . '/' . $VERSION );

sub new {
    my $class = shift;
    return bless {}, __PACKAGE__;
}

sub get_project {
    my ( $self, $id ) = @_;

    my $content = $user_agent->get("http://api.freelancer.com/Project/$id.json")
      ->decoded_content();

    return bless from_json($content)->{'project'}, 'WWW::Freelancer::Project';
}

sub get_user {
    my ( $self, $id_or_username ) = @_;

    my $query_string = "?id=$id_or_username";
    my $content
      = $user_agent->get(
        "http://api.freelancer.com/User/Properties.json$query_string")
      ->decoded_content();

    return bless from_json($content)->{'profile'}, 'WWW::Freelancer::User';
}

sub search_project {
    my ( $self, %parametres ) = @_;

    _move_key_to_api_key(
        \%parametres,
        {   'jobs'            => 'jobs[]',
            'maximum_budget'  => 'max_budget',
            'minimum_budget'  => 'min_budget',
            'order_direction' => 'order_dir',
        }
    );

    if ( defined $parametres{'order'}->{'random'} ) {
        $parametres{'order'}->{'rand'} = $parametres{'order'}->{'random'};
        delete $parametres{'order'}->{'random'};
    }

    my $query_string = _build_query_string(%parametres);
    my $content
      = $user_agent->get(
        "http://api.freelancer.com/Project/Search.json$query_string")
      ->decoded_content();
    my @projects = @{ from_json($content)->{'projects'}->{'items'} };
    map { bless $_, 'WWW::Freelancer::Project' } @projects;

    return @projects;
}

sub _move_key_to_api_key {
    my ( $parametres_ref, $keys_and_api_keys_ref ) = @_;

    for my $key ( keys %{$keys_and_api_keys_ref} ) {
        if ( defined $parametres_ref->{$key} ) {
            $parametres_ref->{ $keys_and_api_keys_ref->{$key} }
              = $parametres_ref->{$key};
            delete $parametres_ref->{$key};
        }
    }
}

sub _build_query_string {
    my %parametres = @_;
    my @query_strings;

    for my $key ( keys %parametres ) {
        if ( ref $parametres{$key} eq 'ARRAY' ) {
            for my $element ( @{ $parametres{$key} } ) {
                push @query_strings, $key . '=' . $element;
            }
        }
    }

    return '?' . join '&', @query_strings;
}

1;

__END__

=head1 NAME

WWW::Freelancer - Provides access to Freelancer.com API

=head1 VERSION

This document describes WWW::Freelancer version 0.0.1


=head1 SYNOPSIS

    use WWW::Freelancer;

    my $freelancer = WWW::Freelancer->new();
    my $project    = $freelancer->get_project(1000);
    my $user       = $freelancer->get_user('alanhaggai');

    print 'Project ID: ',   $project->get_id(),   "\n";
    print 'Project Name: ', $project->get_name(), "\n";
    print 'Project URL: ',  $project->get_url(),  "\n";
    print 'User ID: ',      $user->get_id(),      "\n";


=head1 DESCRIPTION

This module provides access to
Freelancer.com API 1.0 (L<http://apidocs.getafreelancer.com/index.html>).


=head1 INTERFACE 

=over 4

=item C<< new() >>

Returns a new Freelancer object.

=item C<< get_project( id ) >>

Accepts C<id> of a project and returns a L<project|WWW::Freelancer::Project>
object.

=item C<< get_user( id | username ) >>

Returns a L<user|WWW::Freelancer::User> object corresponding to the provided
C<id> or C<username>.

=item C<< search_project( HASH ) >>

Searches for a project and returns an array of
L<project|WWW::Freelancer::Project> objects. Accepts a HASH with the following
keys:

=over 4

=item C<< 'keyword' >>

Search keyword.

=item C<< 'owner' >>

Username of ID of project owner.

=item C<< 'winner' >>

Username of ID of project winner.

=item C<< 'jobs' >>

Names of job categories from the available list on Freelancer.com (Perl, XML,
AJAX, et cetera.). This key accepts an array reference.

For example:

    'jobs' => [
                  'Perl',
                  'XML',
                  'AJAX',
              ]

=item C<< 'featured' >>

If 1, only featured projects, else if 0, only non-featured projects.

=item C<< 'trial' >>

If 1, only trial projects, else if 0, only non-trial projects

=item C<< 'for_gold_members' >>

If 1, only 'for gold members' projects, else if 0, only 'for non-gold members'
projects.

=item C<< 'nonpublic' >>

If 1, only nonpublic projects, else if 0, only public projects.

=item C<< 'minimum_budget' >>

Only projects with budget higher or equal to C<< minimum_budget >>.

=item C<< 'maximum_budget' >>

Only projects with budget lower or equal to C<< maximum_budget >>.

=item C<< 'bidding_ends' >>

Only projects ending sooner than C<< bidding_ends >> days.

=item C<< 'order' >>

Order projects in the result output. Accepts a hash reference with keys and
values corresponding to order criteria:

=over 4

=item C<< 'id' >>

Order by project ID.

=item C<< 'submitdate' >>

Order by date when project was added (default).

=item C<< 'state' >>

Order by state of project. Active/open projects will be listed first, frozen
projects then, and at last closed projects.

=item C<< 'bid_count' >>

Order by number of bids.

=item C<< 'bid_average' >>

Order by average bid.

=item C<< 'bid_enddate' >>

Order by bidding end time.

=item C<< 'buyer' >>

Order by buyer's username.

=item C<< 'budget' >>

Order by budget.

=item C<< 'relevance' >>

Order by relevance of search by keyword. This criterion should be used with the
parameter C<< keyword >>.

=item C<< 'random' >>

Order randomly.

=back

=item C<< 'order_direction' >>

Direction of sorting. If the parameter is equal to C<< asc >>, results are ordered in
ascending way, otherwise, descending (C<< desc >>).

=back

=back


=head1 CONFIGURATION AND ENVIRONMENT

WWW::Freelancer requires no configuration files or environment variables.


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

=item * L<WWW::Freelancer::Project>

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
