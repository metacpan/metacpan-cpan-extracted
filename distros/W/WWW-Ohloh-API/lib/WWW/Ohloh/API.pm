package WWW::Ohloh::API;

use warnings;
use strict;
use Carp;

use Object::InsideOut;

use LWP::UserAgent;
use Readonly;
use XML::LibXML;
use Params::Validate qw(:all);

use WWW::Ohloh::API::Account;
use WWW::Ohloh::API::Analysis;
use WWW::Ohloh::API::Project;
use WWW::Ohloh::API::Projects;
use WWW::Ohloh::API::Languages;
use WWW::Ohloh::API::ActivityFact;
use WWW::Ohloh::API::ActivityFacts;
use WWW::Ohloh::API::Kudos;
use WWW::Ohloh::API::ContributorLanguageFact;
use WWW::Ohloh::API::Enlistments;
use WWW::Ohloh::API::Factoid;
use WWW::Ohloh::API::SizeFact;
use WWW::Ohloh::API::Stack;

use Digest::MD5 qw/ md5_hex /;

our $VERSION = '0.3.2';

Readonly our $OHLOH_URL => 'http://www.ohloh.net/';

our $useragent_signature = "WWW-Ohloh-API/$VERSION";

my @api_key_of : Field : Std(api_key) : Arg(api_key);
my @api_version_of : Field : Default(1);    # for now, there's only v1

my @user_agent_of : Field;

my @debugging : Field : Arg(debug) : Default(0) : Std(debug);

my @parser_of : Field;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub fetch_messages {
    my $self = shift;

    require WWW::Ohloh::API::Messages;

    return WWW::Ohloh::API::Messages->new( ohloh => $self, @_ );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_account_stack {
    my $self = shift;

    my $id = shift;

    $id = md5_hex($id) if -1 < index $id, '@';    # it's an email

    my ( $url, $xml ) =
      $self->_query_server("accounts/$id/stacks/default.xml");

    return WWW::Ohloh::API::Stack->new(
        ohloh       => $self,
        request_url => $url,
        xml         => $xml->findnodes('stack[1]'),
    );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_project_stacks {
    my $self = shift;

    my $project = shift;

    my ( $url, $xml ) = $self->_query_server("projects/$project/stacks.xml");

    return map {
        WWW::Ohloh::API::Stack->new(
            ohloh       => $self,
            request_url => $url,
            xml         => $_,
          )
    } $xml->findnodes('//result/stack');
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_size_facts {
    my $self = shift;

    my ( $project_id, $analysis_id ) =
      validate_pos( @_, 1, { default => 'latest' }, );

    my ( $url, $xml ) = $self->_query_server(
        "projects/$project_id/analyses/$analysis_id/size_facts.xml");

    return map {
        WWW::Ohloh::API::SizeFact->new(
            ohloh       => $self,
            request_url => $url,
            xml         => $_
          )
    } $xml->findnodes('//size_fact');

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_account {
    my $self = shift;

    my ( $type, $id ) = @_;

    $type eq 'id'
      or $type eq 'email'
      or croak "first argument must be 'id' or 'email'";

    $id = md5_hex($id) if $type eq 'email';

    my ( $url, $xml ) = $self->_query_server("accounts/$id.xml");

    return WWW::Ohloh::API::Account->new(
        ohloh       => $self,
        request_url => $url,
        xml         => $xml->findnodes('account[1]'),
    );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_enlistments {
    my $self = shift;
    my %arg  = @_;

    return WWW::Ohloh::API::Enlistments->new(
        ohloh      => $self,
        project_id => $arg{project_id},
        ( sort => $arg{sort} ) x !!$arg{sort},
    );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_factoids {
    my $self = shift;

    my $project_id = shift;

    my ( $url, $xml ) =
      $self->_query_server("projects/$project_id/factoids.xml");

    return map {
        WWW::Ohloh::API::Factoid->new(
            ohloh       => $self,
            request_url => $url,
            xml         => $_
          )
    } $xml->findnodes('//factoid');
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_contributor_language_facts {
    my $self = shift;

    my %param = validate(
        @_,
        {   project_id     => 1,
            contributor_id => 1,
        } );

    my ( $url, $xml ) = $self->_query_server(
        "projects/$param{project_id}/contributors/$param{contributor_id}.xml"
    );

    return map {
        WWW::Ohloh::API::ContributorLanguageFact->new(
            ohloh       => $self,
            request_url => $url,
            xml         => $_
          )
    } $xml->findnodes('//contributor_language_fact');

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_kudos {
    my $self = shift;
    my ( $type, $id ) = @_;

    $type eq 'id'
      or $type eq 'email'
      or croak "first argument must be 'id' or 'email'";

    $id = md5_hex($id) if $type eq 'email';

    return WWW::Ohloh::API::Kudos->new(
        ohloh => $self,
        id    => $id,
    );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_project {
    my $self = shift;
    my $id   = shift;

    my ( $url, $xml ) = $self->_query_server("projects/$id.xml");

    return WWW::Ohloh::API::Project->new(
        ohloh       => $self,
        request_url => $url,
        xml         => $xml->findnodes('project[1]'),
    );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_projects {
    my $self = shift;
    my %arg = validate( @_, { query => 0, sort => 0, max => 0 } );

    return WWW::Ohloh::API::Projects->new(
        ohloh => $self,
        query => $arg{query},
        sort  => $arg{sort},
        max   => $arg{max},
    );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_analysis {
    my $self    = shift;
    my $project = shift;

    $_[0] ||= 'latest';

    my ( $url, $xml ) =
      $self->_query_server("projects/$project/analyses/$_[0].xml");

    my $analysis = WWW::Ohloh::API::Analysis->new(
        request_url => $url,
        xml         => $xml->findnodes('analysis[1]'),
    );

    unless ( $analysis->project_id == $project ) {
        croak "analysis $_[0] doesn't apply to project $project";
    }

    return $analysis;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_languages {
    my $self = shift;
    my %arg  = @_;

    return WWW::Ohloh::API::Languages->new(
        ohloh => $self,
        ( sort => $arg{sort} ) x !!$arg{sort},
    );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_language {
    my $self = shift;
    my $id   = shift;

    my ( $url, $xml ) = $self->_query_server("languages/$id.xml");

    return WWW::Ohloh::API::Language->new(
        request_url => $url,
        xml         => $xml->findnodes('language[1]'),
    );

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_activity_facts {
    my $self = shift;
    my ( $project, $analysis ) =
      validate_pos( @_, 1, { default => 'latest' }, );

    return WWW::Ohloh::API::ActivityFacts->new(
        ohloh    => $self,
        project  => $project,
        analysis => $analysis,
    );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _ua {
    my $self = shift;
    my $ua;
    unless ( $ua = $user_agent_of[$$self] ) {
        $ua = $user_agent_of[$$self] = LWP::UserAgent->new;
        $ua->agent($useragent_signature);
    }
    return $ua;
}

sub _parser {
    my $self = shift;
    return $parser_of[$$self] ||= XML::LibXML->new;
}

sub _query_server {
    my $self  = shift;
    my $url   = shift;
    my %param = $_[0] ? %{ $_[0] } : ();

    $param{api_key} = $self->get_api_key
      or croak "api key not configured";

    $param{v} = $api_version_of[$$self];

    $url = $OHLOH_URL . $url;

    $url .= '?' . join '&', map { "$_=$param{$_}" } keys %param;

    warn "querying ohloh server with $url" if $debugging[$$self];

    # TODO: beef up here for failures
    my $request = HTTP::Request->new( GET => $url );
    my $response = $self->_ua->request($request);

    unless ( $response->is_success ) {
        croak "http query to Ohloh server failed: " . $response->status_line;
    }

    my $result = $response->content;

    my $dom = eval { $self->_parser->parse_string($result) }
      or croak "server didn't feed back valid xml: $@";

    if ( $dom->findvalue('/response/status/text()') ne 'success' ) {
        croak "query to Ohloh server failed: ",
          $dom->findvalue('/response/status/text()');
    }

    return $url, $dom->findnodes('/response/result[1]');
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

WWW::Ohloh::API - Ohloh API implementation

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $account $ohloh->get_account( id => 12933 );

    print $account->name;

=head1 DESCRIPTION

This module is a Perl interface to the Ohloh API as defined at
http://www.ohloh.net/api/getting_started. 

=head1 METHODS 

=head2 new( [ api_key => $api_key ] )

Create a new WWW::Ohloh::API object. To be able to retrieve information
from the Ohloh server, an api key must be either passed to the constructor 
or set via the L<set_api_key> method.

    my $ohloh = WWW::Ohloh::API->new( api_key => $your_key );

=head2 get_account( [ id | email ] => $account_id )

Return the account associated with the $account_id as a 
L<WWW::Ohloh::API::Account>
object. If no such account exists, an error is thrown.
The $accound_id can either be specified as the Ohloh id number, 
or the email address associated with the account.

    my $account = $ohloh->get_account( id => 12933 );
    my $other_accound = $ohloh->get_account( email => 'foo@bar.com' );


=head2 get_project( $id )

Return the project having the Ohloh id I<$id> as a
L<WWW::Ohloh::API::Project>.  If no such project exists, 
an error is thrown.

    my $project = $ohloh->get_project( 1234) ;
    print $project->name;

=head2 get_projects( query => $query, sort => $sorting_order, max => $nbr )

Return a set of projects as a L<WWW::Ohloh::API::Projects> object. 

=head3 Parameters

=over

=item query

If provided, only the projects matching the query string are returned.
A project matches the query string is any of its name, description
or tags does.

=item sort

If provided, the projects will be returned according to the specified 
sorting order.  Valid values are 
'created_at', 'description', 'id', 'name', 'stack_count',
'updated_at', 'created_at_reverse',
'description_reverse', 'id_reverse', 'name_reverse',
'stack_count_reverse' or 'updated_at_reverse'.  If no sorting order
is explicitly given, 'id' is the default.

=item max

If given, the project set will returns at most I<$nbr> projects.

    # get top ten stacked projects
    my @top = $ohloh->get_projects( max => 10, sort => 'stack_count' )->all;

=back

=head2 get_languages( sort => $order )

Return the languages known to Ohloh a set of L<WWW::Ohloh::API::Language>
objects. 

An optional I<sort> parameter can be passed to the method. The valid
I<$order>s it accepts are
C<total>, C<code>, C<projects>, C<comment_ratio>, 
C<contributors>, C<commits> and C<name>. If I<sort> is not explicitly called,
projects are returned in alphabetical order of C<name>s.

=head2 get_activity_facts( $project_id, $analysis )

Return a set of activity facts computed out of the project associated
with the I<$project_id> as a L<WWW::Ohloh::API::ActivityFacts> object. 

The optional argument I<$analysis> can be either an Ohloh analysis id 
(which must be an analysis associated to the project) or the keyword
'latest'. By default the latest analysis will be queried.

=head2 get_contributor_language_facts( project_id => $p_id,  contributor_id => $c_id )

    my @facts = $ohloh->get_contributor_language_facts(
        project_id     => 1234,
        contributor_id => 5678
    );

Return the list of contributor language facts associated to the 
contributor I<$c_id> for the project I<$p_id>.

=head2 get_enlistments( project_id => $id )

Returns the list of enlistements pertaining to the
given project as an L<WWW::Ohloh::API::Enlistment> object.

    my $enlistments = $ohloh->get_enlistments( project_id => 1234 );

    while ( my $enlistment = $enlistments->next ) {
        # do stuff with $enlistment...
    }

=head2 get_size_facts( $project_id, $analysis_id )

Return the list of L<WWW::Ohloh::API::SizeFact> objects pertaining to the
given project and analysis. If I<$analysis_id> is not provided, it defaults
to the latest analysis done on the project.

=head2 get_project_stacks( $project_id ) 

Return the list of stacks containing the project as 
L<WWW::Ohloh::API::Stack>
objects.

=head2 get_account_stack( $account_id )

Return the stack associated with the account as an 
L<WWW::Ohloh::API::Stack> object.

=head2 fetch_messages( [ account | project ] => I<$id> )

Returns the messages associated to the given account or project
as a L<WWW::Ohloh::API::Messages> object.

=head1 SEE ALSO

=over

=item *

L<WWW::Ohloh::API::Project>, 
L<WWW::Ohloh::API::Projects>, 
L<WWW::Ohloh::API::Account>, 
L<WWW::Ohloh::API::KudoScore>,
L<WWW::Ohloh::API::Languages>,
L<WWW::Ohloh::API::Language>.

=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

How to obtain an Ohloh API key: http://www.ohloh.net/api_keys/new

=back

=head1 VERSION

This document describes WWW::Ohloh::API version 0.3.2

=head1 BUGS AND LIMITATIONS

WWW::Ohloh::API is very extremely alpha quality. It'll improve,
but till then: I<Caveat emptor>.

Please report any bugs or feature requests to
C<bug-www-ohloh-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Yanick Champoux  C<< <yanick@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Yanick Champoux C<< <yanick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

