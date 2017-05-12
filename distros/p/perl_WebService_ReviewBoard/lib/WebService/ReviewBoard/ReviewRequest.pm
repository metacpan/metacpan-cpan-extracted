package WebService::ReviewBoard::ReviewRequest;

use strict;
use warnings;

use base 'WebService::ReviewBoard';

use Data::Dumper;
use Log::Log4perl qw(:easy);

# this module returns review object as string
sub as_string {
	my $self = shift;

	return
	    "[REVIEW REQUEST "
	  . $self->get_id() . '] '
	  . $self->get_summary() . "\n"
	  . "    Description: "
	  . $self->get_description() . "\n"
	  . "    Reviewers:   "
	  . join( ", ", @{ $self->get_reviewers() } ) . "\n"
	  . "    Bugs:        "
	  . join( ", ", @{ $self->get_bugs() } ) . "\n"
	  . "    Groups:      "
	  . join( ", ", @{ $self->get_groups() } ) . "\n";
}

sub create {
	my $self = shift;
	my %args  = @_;

	my $json = $self->api_post( '/api/json/reviewrequests/new/', [%args] );
	if ( !$json->{review_request} ) {
		LOGDIE "create couldn't determine ID from this JSON that it got back from the server: " . Dumper $json;
	}

	$self->{rr} = $json->{review_request};

	return $self;
}

sub fetch {
	my $self = shift;
	my $id   = shift;

	my $json = $self->api_get( '/api/json/reviewrequests/' . $id );
	$self->{rr} = $json->{review_request};

	return $self;
}

sub fetch_all_from_user {
	my $self = shift;
    my $from_user = shift;

	my $json = $self->api_get( '/api/json/reviewrequests/from/user/' . $from_user );

    my @rrs;
	foreach my $request ( @{ $json->{review_requests} } ) {
		my $rr = $self->new( $self->get_review_board_url() );
		$rr->{rr} = $request;
		push @rrs, $rr;
	}

	return @rrs;

}

# this method makes POST call to reviewboard and performs required action
sub reviewrequest_api_post {
	my $self   = shift;
	my $action = shift;

	return $self->api_post( "/api/json/reviewrequests/" . $self->get_id() . "/$action/", @_ );
}

sub get_id          { return shift->_get_field('id'); }
sub get_description { return shift->_get_field('description'); }
sub get_summary     { return shift->_get_field('summary'); }
sub get_bugs        { return shift->_get_field('bugs_closed'); }

sub get_reviewers {
	my $self = shift;
	return [ map { $_->{username} } @{ $self->_get_field('target_people') } ];
}

sub get_groups {
	my $self = shift;
	return [ map { $_->{name} } @{ $self->_get_field('target_groups') } ];
}

sub get_reviews {
	my $self = shift;

	my $r = $self->reviewrequest_api_post('reviews');
	if ( ref( $r->{reviews} ) ne "ARRAY" ) {
		WARN "api post to fetch reviews didn't return { 'reviews' : [] } as expected";
	}

	return $r->{reviews};
}

sub get_ship_it_count {
	my $self = shift;

	my $ship_it_count = 0;
	my $reviews       = $self->get_reviews();

	foreach my $review ( @{$reviews} ) {
		$ship_it_count++ if $review->{ship_it};
	}

	return $ship_it_count;
}

sub _get_field {
	my $self  = shift;
	my $field = shift;

	if ( !$self->{rr} || !$self->{rr}->{$field} ) {
		LOGDIE "requested $field, but $field isn't set.  Maybe you need to call fetch first?";
	}

	return $self->{rr}->{$field};
}

sub set_description { return shift->_set_field( 'description', @_ ); }
sub set_summary     { return shift->_set_field( 'summary',     @_ ); }

sub set_bugs {
	my $self = shift;
	my @bugs = @_;

	return $self->_set_field( 'bugs_closed', join( ',', @bugs ) );
}

sub set_reviewers {
	my $self      = shift;
	my @reviewers = @_;

	return $self->_set_field( "target_people", join( ',', @reviewers ) );
}

# sets groups for given review object
sub set_groups {
	my $self   = shift;
	my @groups = @_;
	return $self->_set_field( 'target_groups', join( ',', @groups ) );
}

sub _set_field {
	my $self  = shift;
	my $field = shift;
	my $value = shift;

	# update the cache
	$self->{rr}->{$field} = $value;

    # send it to the server
	return $self->reviewrequest_api_post( "draft/set/$field", [ value => $value, ] );
}

# discards given review object
sub discard_review_request {
	my $self = shift;
	return  $self->reviewrequest_api_post( "close/discarded" );
}

# set status as submit for given review object
sub submit_review_request {
	my $self = shift;
	return  $self->reviewrequest_api_post( "close/submitted" );
}

sub publish {
	my $self = shift;

    return $self->api_post( "/api/json/reviewrequests/" . $self->get_id() . "/publish/" );
}

sub add_diff {
	my $self    = shift;
	my $file    = shift;
	my $basedir = shift;

	my $args = [ path => [$file] ];

	# base dir is used only for some SCMs (like SVN) (I think)
	if ($basedir) {
		push @{$args}, ( basedir => $basedir );
	}

	$self->reviewrequest_api_post( 'diff/new', Content_Type => 'form-data', Content => $args );

	return 1;
}

1;

__END__

WebService::ReviewBoard::ReviewRequest - An object that represents a review on the review board system

=head1 SYNOPSIS

    use WebService::ReviewBoard::ReviewRequest;

    my $rb = WebService::ReviewBoard::ReviewRequest->new( 'http://demo.review-board.org' );
    $rb->login( 'username', 'password' );

    $rb->create( repository_id => 1 );
    $rb->set_bugs( 1728212, 1723823  );
    $rb->set_reviewers( qw( jdagnall gno ) );
    $rb->set_summary( "this is the summary" );
    $rb->set_description( "this is the description" );
    $rb->set_groups('reviewboard');
    $rb->add_diff( '/tmp/patch' ); 
    $rb->publish();
 
    # get all the reviews that the user jaybuff created:
    foreach my $review_request ( $rr->fetch_all_from_user( 'jaybuff' ) ) { 
        print "[REVIEW REQUEST" . $review_request->get_id() . "] " . $review_request->get_summary() . "\n";
    }

    # get review request 123
    $rr->fetch( 123 );

    # return the number of ship its
    print "Number of ship its for review request #" . $rr->get_id() . ": " . $rr->get_ship_it_count() . "\n";

    # set status as submitted
    $rr->submit_review_request();

    # discard review request
    $rr->discard_review_request();
  
=head1 DESCRIPTION

=head1 INTERFACE 

=over

=item C<< create( %args ) >>

C<<%args>> is passed directly to the HTTP UserAgent when it does the request.

C<<%args>> must contain which repository to use.  Using one of these (from the ReviewBoard API documentation):

    * repository_path: The repository to create the review request against. If not specified, the DEFAULT_REPOSITORY_PATH setting will be used. If both this and repository_id are set, repository_path's value takes precedence.
    * repository_id: The ID of the repository to create the review request against. 

Example:

    my $rr = WebService::ReviewBoard::ReviewRequest->new( 'http://demo.review-board.org' );
    $rr->login( 'username', 'password' );
    $rr->create( repository_id => 1 );

=item C<< fetch( $id ) >>

Fetch a review request.

=item C<< fetch_all_from_user( $user ) >>

Returns an array of WebService::ReviewBoard::ReviewRequest objects

=item C<< get_id() >>

Returns the id of this review request

=item C<< get_bugs() >>

Returns an array.

=item C<< get_reviewers() >>

Returns an array.

=item C<< get_summary() >>

=item C<< get_description() >>

=item C<< get_groups() >>

=item C<< set_groups() >>

=item C<< set_bugs( @bug_ids ) >>

=item C<< set_reviewers( @review_board_users ) >>

=item C<< set_summary( $summary ) >>

=item C<< set_description( $description ) >>

=item C<< add_diff( $diff_file ) >>

C<< $diff_file >> should be a file that contains the diff that you want to be reviewed.

=item C<< publish( ) >>

Mark the review request as ready to be reviewed.  This will send out notification emails if review board 
is configured to do that. 

=item C<< discard_review_request() >>
Mark the review request as discarded. This will delete review request from review board.

=item C<< submit_review_request() >>
Mark the review request as submitted.

=item C<< as_string()  >>

returns a string that is a representation of the review request

=item C<< reviewrequest_api_post() >>

makes POST call to reviewboard and performs required action.  

=back

=head1 DIAGNOSTICS

=over

=item C<< "create couldn't determine ID from this JSON that it got back from the server: %s" >>
=item C<< "new() missing review_board arg (WebService::ReviewBoard object)" >>
=item C<< "requested id, but id isn't set" >>
=item C<< "fetch() must get either from_user or id as an argument" >>
=item C<< "no review requests matching your critera were found" >>
=item C<< "requested $field, but $field isn't set" >>

=back

=head1 CONFIGURATION AND ENVIRONMENT

C<< WebService::ReviewBoard::ReviewBoard >> requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<< WebService::ReviewBoard >>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-reviewboard@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Jay Buffington  C<< <jaybuffington@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Jay Buffington C<< <jaybuffington@gmail.com> >>. All rights reserved.

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
