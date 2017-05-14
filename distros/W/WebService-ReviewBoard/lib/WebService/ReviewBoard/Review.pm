package WebService::ReviewBoard::Review;

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl qw(:easy);

sub new {
	my $proto = shift;
	my $args  = shift;

	my $class = ref $proto || $proto;
	my $self = bless {
		id          => delete $args->{id},
		reviewers   => delete $args->{reviewers},
		bugs        => delete $args->{bugs},
		summary     => delete $args->{summary},
		description => delete $args->{description},
                groups      => delete $args->{groups},
	}, $class;

	$self->{review_board} = delete $args->{review_board}
	  or LOGCONFESS "new() missing review_board arg (WebService::ReviewBoard object)";

	return $self;
}

# this module returns review object as string
sub as_string {
	my $self = shift;

	return
	    "[REVIEW " . $self->get_id() . '] ' . $self->get_summary() . "\n"
	  . "    Description: " . $self->get_description() . "\n"
	  . "    Reviewers:   " . join( ", ", @{ $self->get_reviewers() } ) . "\n"
	  . "    Bugs:        " . join( ", ", @{ $self->get_bugs() } ) . "\n"
      . "    Groups:      " . join( ", ", @{ $self->get_groups() } ) . "\n";
}

# this is a constructor
sub create {
	my $self = new( shift, shift );
	my $args = shift;

	my $json
	  = $self->_get_rb()->api_post( $self->get_ua(), '/api/json/reviewrequests/new/', $args );
	if ( !$json->{review_request} ) {
		LOGDIE "create couldn't determine ID from this JSON that it got back from the server: "
		  . Dumper $json;
	}

	$self->{id} = $json->{review_request}->{id};

	return $self;
}

# this is a constructor
sub fetch {
	my $proto = shift;
	my $args  = shift;

	my $from_user = delete $args->{from_user};
	my $id        = $args->{id};

	my $rb = $args->{review_board};
	my $self = new( $proto, $args );

	my @reviews;
	my $json;
    
    my $create_review = sub { 
        my $rr = shift;

		return $self->new(
			{
				review_board => $rb,
				id           => $rr->{id},
				bugs         => $rr->{bugs_closed},
				reviewers    => [ map { $_->{username} } @{ $rr->{target_people} } ],
				description  => $rr->{description},
				summary      => $rr->{summary},
                groups       => [ map { $_->{name} } @{ $rr->{target_groups} } ],
			}
		  );
    };

	if ($from_user) {
		$json = $self->_get_rb()
		  ->api_get( $self->get_ua(), '/api/json/reviewrequests/from/user/' . $from_user );

        foreach my $rr ( @{ $json->{review_requests} } ) { 
            push @reviews, &$create_review( $rr );
        }
	}
	elsif ($id) {
		$json = $self->_get_rb()->api_get( $self->get_ua(), '/api/json/reviewrequests/' . $id );
		push @reviews, &$create_review( $json->{review_request} );
	}
	else {
		LOGDIE "fetch() must get either from_user or id as an argument";
	}

	# they wanted just one item, but there weren't any, so we'll return undef
	if ( !wantarray && !$reviews[0] ) {
		return;
	}

	return wantarray ? @reviews : $reviews[0];
}

# this method returns user agent for given reviewboard
sub get_ua { return shift->_get_rb()->get_ua(); }

# this method makes POST call to reviewboard and performs required action 
sub review_api_post {
	my $self   = shift;
	my $action = shift;

	return $self->_get_rb()
	  ->api_post( $self->get_ua(), "/api/json/reviewrequests/" . $self->get_id() . "/$action/",
		@_ );
}

sub _get_rb { return shift->{review_board}; }

sub get_id          { return shift->_get_field('id'); }
sub get_description { return shift->_get_field('description'); }
sub get_bugs        { return shift->_get_field('bugs'); }
sub get_summary     { return shift->_get_field('summary'); }
sub get_reviewers   { return shift->_get_field('reviewers'); }

# return groups for given review object
sub get_groups      { return shift->_get_field('groups'); }

sub _get_field {
	my $self  = shift;
	my $field = shift;

	if ( !$self->{$field} ) {
		LOGDIE "requested $field, but $field isn't set";
	}

	return $self->{$field};
}

sub set_description { return shift->_set_field( 'description', @_ ); }
sub set_summary     { return shift->_set_field( 'summary',     @_ ); }

sub set_bugs {
	my $self = shift;
	$self->{bugs} = [@_];

	return $self->_set_field( 'bugs_closed', join( ',', @{ $self->{bugs} } ) );
}

sub set_reviewers {
	my $self = shift;
	$self->{reviewers} = [@_];

	my $json = $self->_set_field( "target_people", join( ',', @{ $self->{reviewers} } ) );

#XXX parse json and return a list of reviewers actually added:
#{"stat": "ok",
#    "invalid_target_people": [],
#    "target_people": [{"username": "jaybuff", "url": "\/users \/jaybuff\/", "fullname": "Jay Buffington", "id": 1, "email": "jaybuff@foo.com"}, {"username": "jdagnall", "url": "\/users\/jdagnall\/", "fullname": "Jud Dagnall", "id": 2, "email": "jdagnall@foo .com"}]}

	return 1;
}

# sets groups for given review object
sub set_groups {
    my $self = shift;
    $self->{groups} = [@_];
    return $self->_set_field( 'target_groups', join( ',', @{ $self->{groups} } ) ); 
}

sub _set_field {
	my $self  = shift;
	my $field = shift;
	my $value = shift;

	# stick it in the object so the getters can access it later
	$self->{$field} = $value;
	return $self->review_api_post( "draft/set/$field", [ value => $value, ] );
}

sub _set_review_action {
    my $self   = shift;
    my $action = shift;
    my $ua   = $self->get_ua();
    use HTTP::Request::Common;
    my $request = POST( $self->_get_rb()->get_review_board_url() . "/r/" . $self->get_id() . "/" . $action . "/");
    DEBUG "Doing request:\n" . $request->as_string();
    my $response = $ua->request($request);
    DEBUG "Got response:\n" . $response->as_string();
    return 1;
}

# discards given review object
sub discard_review_request {
    my $self = shift;
    return $self->_set_review_action("discard", @_);
}

# set status as submit for given review object
sub submit_review_request {
    my $self = shift;
    return $self->_set_review_action("submitted", @_);
}

sub publish {
	my $self = shift;

	my $path = "/r/" . $self->get_id() . "/publish/";
	my $ua   = $self->get_ua();

	#XXX I couldn't get reviews/draft/publish from the web api to work, so I did this hack for now:
	# I asked the review-board mailing list about this.  Waiting for a response...
	use HTTP::Request::Common;

	my $request = POST( $self->_get_rb()->get_review_board_url() . $path );
	DEBUG "Doing request:\n" . $request->as_string();
	my $response = $ua->request($request);
	DEBUG "Got response:\n" . $response->as_string();

	#   $self->review_api_post(
	#		'reviews/draft/publish',
	#		[
	#			diff_revision => 1,
	#			shipit        => 0,
	#			body_top      => undef,
	#			body_bottom   => undef,
	#		]
	#	);

	return 1;
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

	$self->review_api_post( 'diff/new', Content_Type => 'form-data', Content => $args );

	return 1;
}

1;

__END__

WebService::ReviewBoard::Review - An object that represents a review on the review board system

=head1 SYNOPSIS

    use WebService::ReviewBoard;

    my $rb = WebService::ReviewBoard->new( 'http://demo.review-board.org' );
    $rb->login( 'username', 'password' );

    # there are two ways to create an object, create or fetch 
    # both these take a list of arguments, which must include 
    # a WebService::ReviewBoard object so it knows how to 
    # talk to review board.

    # the second arg is sent directly to the review board web services API
    my $review = WebService::ReviewBoard::Review->create( { review_board => $rb }, [ repository_id => 1 ] );
    $review->set_bugs( 1728212, 1723823  );
    $review->set_reviewers( qw( jdagnall gno ) );
    $review->set_summary( "this is the summary" );
    $review->set_description( "this is the description" );
    $review->set_groups('reviewboard');
    $review->add_diff( '/tmp/patch' ); 
    $review->publish();

    # alternatively, you can get existing reviews
    foreach my $review ( WebService::ReviewBoard::Review->fetch( { review_board => $rb, from_user => 'jaybuff' } ) ) { 
        print "[REVIEW " . $review->get_id() . "] " . $review->get_summary() . "\n";
    }

    # fetch uses the perl function wantarray so you can just get one review if you want:
    my $review = WebService::ReviewBoard::Review->fetch( { review_board => $rb, id => 123 } );

    # set status as submit 
    $review->submit_review_request;

    # discard review request
    $review->discard_review_request;
  
=head1 DESCRIPTION

=head1 INTERFACE 

=over

=item C<< new() >>

Do not use this constructor.  To construct a C<< WebService::ReviewBoard::Review >> object use the 
C<< create_review >> method in the C<< WebService::ReviewBoard >> class.


=item C<< create( { review_board => $rb }, $args ) >>

C<<review_board>> must be a C<<WebService::ReviewBoard>> object.  C<<$args>> is passed directly to the HTTP UserAgent when it does the request.

C<<$args>> must contain which repository to use.  Using one of these (from the ReviewBoard API documentation):

    * repository_path: The repository to create the review request against. If not specified, the DEFAULT_REPOSITORY_PATH setting will be used. If both this and repository_id are set, repository_path's value takes precedence.
    * repository_id: The ID of the repository to create the review request against. 

Example:

    my $rb = WebService::ReviewBoard->new( 'http://demo.review-board.org' );
    $rb->login( 'username', 'password' );
    my $review = WebService::ReviewBoard::Request->create( { review_board => $rb }, [ repository_id => 1 ] );

=item C<< fetch( $args_hash_ref ) >>

Fetch one or more review objects from the reviewboard server.  It uses wantarray(), so
you can fetch one or many.

Valid values in C<<$args_hash_ref>>:

    * review_board - (required) must be a WebService::ReviewBoard object.
    * from_user - the review board username of a person that submitted reviews
    * id - the id of a review request

C<<fetch>> is a constructor.

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

=item C<< get_ua() >>

returns an LWP::UserAgent that will be used to do requests.  You can overload this method to use custom user agents.

=item C<< review_api_post() >>

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

C<< WebService::ReviewBoard::Review >> requires no configuration files or environment variables.

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
