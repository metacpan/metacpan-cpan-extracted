package WebService::Viddler;

use strict;
use warnings;

use HTTP::Request::Common;
use LWP::UserAgent;
use LWP::Simple;
use XML::Simple;

=head1 NAME

WebService::Viddler -  An encapsulation of the Viddler video platform in Perl

=head1 VERSION

Version 0.10

=cut

our $VERSION = "0.10";

### To Do
#
# Complete support of all API methods
# Process/Return Viddler error codes for all method calls
# Document common error codes and method specific error codes
# Validation/Error Handling of parameters/results
# Add SSL option for methods such as users_auth
#
####

=head1 SYNOPSIS

use WebService::Viddler;

my $videos = new WebService::Viddler( apiKey => $apiKey, 
                 username => $username,
                 password => $passwd,
               );

print "API Version: " .$videos->api_getInfo(). "\n";

$video->videos_upload( $title, $tags, $description, $make_public, $file, $bitrate );

$video->videos_getDetails( $video_id, $add_embed_code, $include_comments );

=head1 DESCRIPTION

This is an object-oriented library which focuses on providing Perl specific methods for accessing the Viddler video service via their API, as documented at: http://developers.viddler.com/documentation/api/

This library currently only supports version 1 of the Viddler API

Along with method specific error codes, all methods may return one of the following error codes upon failure. 

Error Codes:

1 	An internal error has occurred

2 	Bad argument format

3 	Unknown argument specified

4 	Missing required argument for this method

5 	No method specified

6 	Unknown method specified

7 	API key missing

8 	Invalid or unknown API key specified

9 	Invalid or expired sessionid

10 	Used HTTP method is not allowed for this API method. Try using HTTP POST instead of HTTP GET.

11 	Method call not allowed. Your API key security level restricts calling this method.

12 	API key disabled

=head2 Methods

=head3 new

my $video = Viddler->new( apikey => $key, username => $username, password => $passwd );

Instantiates an object which established the basic connection to the API, including requesting and setting a session id.

=cut

# The constructor of an object is called new() by convention.

sub new {

    my ( $class, %args ) = @_;
    my $new = bless {

        _apiURL       => 'http://api.viddler.com/rest/v1/',
        _sessionID    => undef,
        _record_token => undef,
        %args

    }, $class;

    # Get a sessionid
    my $result = $new->users_auth;

    if ( $result ne "1" ) {

        warn "Viddler Error: " . $result;

    }

    return $new;

}

=head3 users_auth

Gets and sets a sessionid for an authenticated Viddler account. Returned sessionid is valid for 5 minutes (may change in the future). Every method request which contains valid sessionid, renews its validity time.

$video->users_auth;

No required parameters, we use the username and password defined at object's creation

Additional options parameters include: 

* get_record_token: If set to "1" response will also include recordToken

Returns 1 ( true ) if successful and a Viddler error code if unsuccessful

Additional Error Codes:

101	Username not found.

102 	This account has been suspended.

103 	Password incorrect for this username.

=cut

sub users_auth {

    my ( $self, $get_record_token ) = @_;

    if ( ( !defined $get_record_token ) || ( $get_record_token ne "1" ) ) {

        $get_record_token = "";

    }

    my $xml = new XML::Simple;
    my $content =
        get $self->{_apiURL}
      . "?method=viddler.users.auth&api_key="
      . $self->{apiKey}
      . "&user="
      . $self->{username}
      . "&password="
      . $self->{password}
      . "&get_record_token="
      . $get_record_token;
    my $results = $xml->XMLin($content);

    if ( defined $results->{'code'} ) {

        return $results->{'code'};

    }
    else {

        $self->{_sessionID} = $results->{'sessionid'};

        if ( defined $results->{'get_record_token'} ) {

            $self->{_recordToken} = $results->{'record_token'};

        }

        if ( defined( $self->{_sessionID} ) ) {

            return 1;

        }

    }

}

=head3 users_register

Creates a Viddler account. Note: This method is restricted to only qualified API keys.

$video->users_register( $user, $email, $fname, $lname, $password, $question, $answer, $lang, $termsaccepted, $company );

Requires the following parameters:

* user: The chosen Viddler user name

* email: The email address of the user

* fname: The user's first name

* lname: The user's last name

* password: The user's password with Viddler

* question: The text of the user's secret question

* answer: The text of the answer to the secret question

* lang: The language of the user for the account

* termsaccepted: "1" indicates the user has accepted Viddler's terms and conditions

Additional options parameters include: 

* company: The user's company affiliation

Returns the created username as a string, if successful. Returns an error code if unsuccessful.

Additional Error Codes:

104	Terms of Service not accepted by user.

105	Username already in use.

106	Email address already in use.

=cut

sub users_register( $$$$$$$$$ ) {

    my (
        $self,  $user,          $email,    $fname,
        $lname, $password,      $question, $answer,
        $lang,  $termsaccepted, $company
    ) = @_;

    my $xml = new XML::Simple;

    if ( !defined $company ) {

        $company = "";

    }

    my $content =
        get $self->{_apiURL}
      . "?method=viddler.users.register&api_key="
      . $self->{apiKey}
      . "&user="
      . $user
      . "&email="
      . $email
      . "&fname="
      . $fname
      . "&lname="
      . $lname
      . "&password="
      . $password
      . "&question="
      . $question
      . "&answer="
      . $answer
      . "&lang="
      . $lang
      . "&termsaccepted="
      . $termsaccepted
      . "&company="
      . $company;
    my $results = $xml->XMLin($content);

    if ( defined $results->{'code'} ) {

        return $results->{'code'};

    }
    else {

        return $results->{'username'};

    }

}

=head3 users_getProfile

Retrieves the public parts of a user profile.

$video->users_getProfile( $user );

Requires the following parameters:

* user: The chosen Viddler user name

Additional options parameters include: 

None

Returns a hash of an array of user's public profile information

=cut

sub users_getProfile( $ ) {

    my ( $self, $user ) = @_;

    my $xml = new XML::Simple;
    my $content =
        get $self->{_apiURL}
      . "?method=viddler.users.getProfile&api_key="
      . $self->{apiKey}
      . "&user="
      . $user;
    my $results = $xml->XMLin($content);
    return $results;

}

=head3 users_setProfile

Updates authenticated user profile data

$video->users_setProfile( $first_name, $last_name, $about_me, $birthday, $gender, $company, $city );

Requires the following parameters:

None

Additional options parameters include: 

* first_name: User's first name. 20 characters max

* last_name: User's last name. 20 characters max

* about_me: About the user. No length limitation

* birthdate: User's birthday in yyyy-mm-dd format 

* gender: User's gender, either "m" for male or "f" for female 

* company: User's company. 100 characters max

* city: User's city. 250 characters max. Currently this is the only address field supported by Viddler, so you may provide more information than just city.

Note: Arguments not sent, won't update the profile. To remove any information from profile just send empty parameter value.

Returns a hash of an array of user's public profile information, including updated information

=cut

sub users_setProfile {

    my ( $self, $first_name, $last_name, $about_me, $birthday, $gender,
        $company, $city )
      = @_;

    my $xml = new XML::Simple;
    my $ua  = new LWP::UserAgent;

    my $content =
        "method=viddler.users.setProfile"
      . "&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID};

    if ( defined $first_name ) {

        $content .= "&first_name=" . $first_name;

    }

    if ( defined $last_name ) {

        $content .= "&last_name=" . $last_name;

    }

    if ( defined $about_me ) {

        $content .= "&about_me=" . $about_me;

    }

    if ( defined $birthday ) {

        $content .= "&birthday=" . $birthday;

    }

    if ( defined $gender ) {

        $content .= "&gender=" . $gender;

    }

    if ( defined $company ) {

        $content .= "&company=" . $company;

    }

    if ( defined $city ) {

        $content .= "&city=" . $city;

    }

    my $request = POST $self->{_apiURL},
      Content_Type => 'application/x-www-form-urlencoded',
      Content      => $content;

    my $results = $xml->XMLin( $ua->request($request)->content );
    return $results;

}

=head3 users_search

Search Viddler people (or Viddler users). This method can also be used to search through people that are active and also a Viddler user's friends.

$video->users_search( $type, $query, $page, $per_page );

Requires the following parameters:

* type: The type of search (e.g. "everybody", "friends", "active"

* query: What to search for (e.g. "New York City", "Paul Weinstein", or "Photographers")

Additional options parameters include: 

* page: The "page number" of results to retrieve (e.g. 1, 2, 3) 

* per_page: The number of results to retrieve per page (maximum 100). If not specified, the default value equals 20 

Returns a hash of an array of search results

=cut

sub users_search( $$ ) {

    my ( $self, $type, $query, $page, $per_page ) = @_;

    if ( !defined $page ) {

        $page = "";

    }

    if ( !defined $per_page ) {

        $per_page = "";

    }

    my $xml = new XML::Simple;
    my $content =
        get $self->{_apiURL}
      . "?method=viddler.users.search&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID}
      . "&type="
      . $type
      . "&query="
      . $query
      . "&page="
      . $page
      . "&per_page="
      . $per_page;
    my $results = $xml->XMLin($content);
    return $results;

}

=head3 users_setOptions

Sets user account options. Currently only partners options are supported. More of them later!

$video->users_setOptions( $show_account, $tagging_enabled, $commenting_enabled, $show_related_videos, $embedding_enabled, $clicking_through_enabled, $email_this_enabled, $trackbacks_enabled, $favourites_enabled, $custom_logo_enabled  );

Requires the following parameters:

None

Additional options parameters include: 

* show_account: "1", "0" - Show/hide your account in Viddler. If you set it to "0" both your account and your videos won't be visible on viddler.com site

* tagging_enabled: "1", "0" - Enable/disable tagging on all your videos

* commenting_enabled: "1", "0" - Enable/disable commenting on all your videos

* show_related_videos: "1", "0" - Show/hide related videos on all your videos

* embedding_enabled: "1", "0" - Enable/disable embedding of off all your videos

* clicking_through_enabled: "1", "0" - Enable/disable redirect to Viddler while clicking on embedded player

* email_this_enabled: "1", "0" - Enable/disable email this option on all your videos

* trackbacks_enabled: "1", "0" - Enable/disable trackbacks on all your videos

* favourites_enabled: "1", "0" - Enable/disable favorites on all your videos

* custom_logo_enabled: "1", "0" - Enable/disable custom logo on all your videos. Note: that logo itself must be send to viddler manually.

Returns an integer representing the number of options actually updated

=cut

sub users_setOptions {

    my (
        $self,                     $show_account,
        $tagging_enabled,          $commenting_enabled,
        $show_related_videos,      $embedding_enabled,
        $clicking_through_enabled, $email_this_enabled,
        $trackbacks_enabled,       $favourites_enabled,
        $custom_logo_enabled
    ) = @_;

    my $xml = new XML::Simple;

    if ( !defined $show_account ) {

        $show_account = "";

    }

    if ( !defined $tagging_enabled ) {

        $tagging_enabled = "";

    }

    if ( !defined $commenting_enabled ) {

        $commenting_enabled = "";

    }

    if ( !defined $show_related_videos ) {

        $show_related_videos = "";

    }

    if ( !defined $embedding_enabled ) {

        $embedding_enabled = "";

    }

    if ( !defined $clicking_through_enabled ) {

        $clicking_through_enabled = "";

    }

    if ( !defined $email_this_enabled ) {

        $email_this_enabled = "";

    }

    if ( !defined $trackbacks_enabled ) {

        $trackbacks_enabled = "";

    }

    if ( !defined $favourites_enabled ) {

        $favourites_enabled = "";

    }

    if ( !defined $custom_logo_enabled ) {

        $custom_logo_enabled = "";

    }

    my $content =
        get $self->{_apiURL}
      . "?method=viddler.users.setOptions&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID}
      . "&show_account="
      . $show_account
      . "&tagging_enabled="
      . $tagging_enabled
      . "&commenting_enabled"
      . $commenting_enabled
      . "&show_related_videos="
      . $show_related_videos
      . "&embedding_enabled="
      . $embedding_enabled
      . "&clicking_ithrough_enabled="
      . $clicking_through_enabled
      . "&email_this_enabled="
      . $email_this_enabled
      . "&trackbacks_enabled="
      . $trackbacks_enabled
      . "&favourites_enabled="
      . $favourites_enabled
      . "&custom_logo_enabled="
      . $custom_logo_enabled;
    my $results = $xml->XMLin($content);
    return $results->{'updated'};

}

=head3 api_getInfo

Gets and returns the current version of the Viddler API.

$video->api_getInfo;

Returns current API version as a string

=cut

sub api_getInfo {

    my ($self) = @_;

    my $xml = new XML::Simple;
    my $content =
        get $self->{_apiURL}
      . "?method=viddler.api.getInfo&api_key="
      . $self->{apiKey};
    my $results = $xml->XMLin($content);
    return $results->{'version'};

}

=head3 videos_getRecordToken

Generate token for embedded recorder

$video->videos_getRecordToken;

Returns a record token as a string

=cut

sub videos_getRecordToken {

    my ($self) = @_;

    my $xml = new XML::Simple;
    my $content =
        get $self->{_apiURL}
      . "?method=viddler.videos.getRecordToken&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID};
    my $results = $xml->XMLin($content);
    return $results->{'record_token'};

}

=head3 videos_prepareUpload

There are two possible solutions for video upload via API call. First one is regular viddler.videos.upload API call. When upload call to this method is received it scans the request and proxies it to best possible upload server. Everything is done in the background and doesn't require any additional client side interaction. Disadvantage of this solution is that the upload will go through multiple servers before reaching its final location. This may cause some slowness in certain situations (API nodes overload etc).

To prevent this you may use second (preferred) solution. Call viddler.videos.prepareUpload method which will assign the best possible upload node for you. After reading the response use "endpoint" tag value as new API endpoint for viddler.videos.upload method call instead of standard http://api.viddler.com/rest/v1/ endpoint.

This method is available since API version 1.3.0.

$video->videos_prepareUpload;

Returns a endpoint as a string for videos_upload method

=cut

sub videos_prepareUpload {

    my ($self) = @_;

    my $xml = new XML::Simple;
    my $content =
        get $self->{_apiURL}
      . "?method=viddler.videos.prepareUpload&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID};
    my $results = $xml->XMLin($content);
    return $results->{'endpoint'};

}

=head3 videos_upload

Uploads a video to a user's account on Viddler site.

Make sure "file" part is sent as the last part of a request. Your upload request will be validated before actual file will be read.

For better videos uploads performance consider using viddler.videos.prepareUpload method which will assign new, one time use API endpoint for video upload call.

$video->videos_upload( $title, $tags, $description, $make_public, $file, $bitrate );

Requires the following parameters:

* title: The video's title

* tags: Tags for the video. Separate each tag with a space. To join two words together in one tag, use double quotes.

* description: The video description.

* make_public: Use "1" for true and "0" for false to choose whether or not the video goes public when uploaded.

* file: The video file.

Additional options parameters include: 

* bitrate: (in kilobits per second) The bitrate to encode the current video at, rather than the account default. E.g. 400, 700, or 1500. Note: This option is not available for all accounts.

Returns a hash of an array of the successfully uploaded video's details

=cut

sub videos_upload( $$$$$ ) {

    my ( $self, $title, $tags, $description, $make_public, $file, $bitrate ) =
      @_;

    my $xml = new XML::Simple;
    my $ua  = new LWP::UserAgent;

    my $request = POST $self->{_apiURL},
      Content_Type => 'multipart/form-data',
      Content      => [
        method      => 'viddler.videos.upload',
        api_key     => $self->{apiKey},
        sessionid   => $self->{_sessionID},
        title       => $title,
        tags        => $tags,
        description => $description,
        make_public => $make_public,
        file        => [$file],
        bitrate     => $bitrate
      ];

    my $results = $xml->XMLin( $ua->request($request)->content );
    return $results;

}

=head3 videos_getStatus

Returns the status of a video uploaded through the API

$video->videos_getStatus( $video_id );

Requires the following parameters:

* video_id: The ID of the video to get information for. The video ID is a value that's returned by videos_upload.

Additional options parameters include: 

None

Returns a status code as a string

Status Codes:

1	Video waiting for encode

2	Video encoding

3	Video did not encoded (encoding error)

4	Video ready

5	Video deleted

=cut

sub videos_getStatus( $ ) {

    my ( $self, $video_id ) = @_;

    my $xml = new XML::Simple;
    my $content =
        get $self->{_apiURL}
      . "?method=viddler.videos.getStatus&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID}
      . "&video_id="
      . $video_id;
    my $results = $xml->XMLin($content);
    return $results->{'statuscode'};

}

=head3 videos_getDetails

Displays the details for a video

$video->videos_getDetails( $video_id, $add_embed_code, $include_comments );

Requires the following parameters:

* video_id: The ID of the video to get information for. The video ID is a value that's returned by videos_upload.

Additional options parameters include: 

* add_embed_code: Include video embed code in response ("1" or "0", default is "0")

* include_comments: Include comments in response ("1" or "0", default: "1")

Returns a hash of an array of the video's details if successful, a Viddler error code if unsuccessful

Notes: 

* All possible permission levels in result set are: public, shared_all, shared and private

* Only /video/permissions/view node may contain secreturl node

* Only shared permission level may contain user and list subnodes

Additional Error Codes:

100 	Video could not be found

=cut

sub videos_getDetails( $ ) {

    my ( $self, $video_id, $add_embed_code, $include_comments ) = @_;

    my $xml = new XML::Simple;

    if ( !defined $add_embed_code ) {

        $add_embed_code = "0";

    }

    if ( !defined $include_comments ) {

        $include_comments = "1";

    }

    my $content =
        get $self->{_apiURL}
      . "?method=viddler.videos.getDetails&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID}
      . "&video_id="
      . $video_id
      . "&add_embed_code="
      . $add_embed_code
      . "&include_comments="
      . $include_comments;
    my $results = $xml->XMLin($content);

    if ( defined $results->{'code'} ) {

        return $results->{'code'};

    }
    else {

        return $results;

    }

}

=head3 videos_getDetailsByUrl

Displays the details for a video

$video->videos_getByDetailsByUrl( $video_url );

Requires the following parameters:

* video_url: The complete Viddler video URL

Additional options parameters include: 

None

Returns a hash of an array of the video's details

Additional Error Codes:

2 	Bad argument format

100 	Video could not be found

=cut

sub videos_getDetailsByUrl( $ ) {

    my ( $self, $video_url ) = @_;

    my $xml = new XML::Simple;
    my $content =
        get $self->{_apiURL}
      . "?method=viddler.videos.getDetailsByUrl&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID} . "&url="
      . $video_url;
    my $results = $xml->XMLin($content);

    if ( defined $results->{'code'} ) {

        return $results->{'code'};

    }
    else {

        return $results;

    }

}

=head3 videos_setDetails

Updated video details

$video->videos_setByDetails( $video_id, $title, $description, $tags, $view_perm, $view_users, $view_use_secret, $embed_perm, $embed_users, $commenting_users, $tagging_perm, $tagging_users, $download_perm, $download_users );

Requires the following parameters:

* video_id: The ID of the video which you want to update

Additional options parameters include: 

* title: Video title - 500 characters max

* description: Video description

* tags: List of tags to be set on video. Setting tags will update current tags set (both timed and global video tags). To set timed tag use formattagname[timestamp_in_ms] as tagname. For example - usingtag1,tag2,tag3[2500] will set 2 global and 1 timed tag at 2.5s

* view_perm: View permission. Can be set to public, shared_all, shared or private

* view_users: List of users which may view this video if view_perm is set to shared. Only your viddler friends are allowed here. If you provide multiple usernames - non valid viddler friends usernames will be ignored.

* view_use_secret: If view_perm is set to non public value, you may activate secreturl for your video. If you want to enable or regenerate secreturl pass "1" as parameter value. If you want to disable secreturl pass "0" as parameter value.

* embed_perm: Embedding permission. Supported permission levels are the same as forview_perm. This and all permissions below cannot be less restrictive thanview_perm. You cannot set it to public if view_perm is for example shared.

* embed_users: Same as view_users. If view_perm is shared, this list cannot contain more users than view_users. Invalid usernames will be removed.

* commenting_perm: Commenting permission. Description is the same as for embed_perm

* commenting_users: Same as embed_users.

* tagging_perm: Tagging permission. Description is the same as for embed_perm

* tagging_users: Same as embed_users.

* download_perm: Download permission. Description is the same as for embed_perm

* download_users: Same as embed_users.

Note: Invalid arguments will be ignored. All lists are comma or space separated.

Returns a hash of an array of the video's details, including updated details, if successful. Returns a Viddler error code if unsuccessful.

Additional Error Codes:

100 	Video could not be found

107 	Wrong privileges

=cut

sub videos_setDetails( $ ) {

    my (
        $self,         $video_id,        $title,
        $description,  $tags,            $view_perm,
        $view_users,   $view_use_secret, $embed_perm,
        $embed_users,  $commenting_perm, $commenting_users,
        $tagging_perm, $tagging_users,   $download_perm,
        $download_users
    ) = @_;

    my $xml = new XML::Simple;
    my $ua  = new LWP::UserAgent;

    my $content =
        "method=viddler.users.setDetails"
      . "&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID}
      . "&video_id="
      . $video_id;

    if ( defined $title ) {

        $content .= "&title=" . $title;

    }

    if ( defined $description ) {

        $content .= "&description=" . $description;

    }

    if ( defined $tags ) {

        $content .= "&tags=" . $tags;

    }

    if ( defined $view_perm ) {

        $content .= "&view_perm=" . $view_perm;

    }

    if ( defined $view_users ) {

        $content .= "&view_users=" . $view_users;

    }

    if ( defined $view_use_secret ) {

        $content .= "&view_use_secret=" . $view_use_secret;

    }

    if ( defined $embed_perm ) {

        $content .= "&embed_perm=" . $embed_perm;

    }

    if ( defined $embed_users ) {

        $content .= "&embed_users=" . $embed_users;

    }

    if ( defined $commenting_perm ) {

        $content .= "&commenting_perm=" . $commenting_perm;

    }

    if ( defined $commenting_users ) {

        $content .= "&commenting_users=" . $commenting_users;

    }

    if ( defined $tagging_perm ) {

        $content .= "&tagging_perm=" . $tagging_perm;

    }

    if ( defined $tagging_users ) {

        $content .= "&tagging_users=" . $tagging_users;

    }

    if ( defined $download_perm ) {

        $content .= "&download_perm=" . $download_perm;

    }

    if ( defined $download_users ) {

        $content .= "&download_users=" . $download_users;

    }

    my $request = POST $self->{_apiURL},
      Content_Type => 'application/x-www-form-urlencoded',
      Content      => $content;

    my $results = $xml->XMLin( $ua->request($request)->content );

    if ( defined $results->{'code'} ) {

        return $results->{'code'};

    }
    else {

        return $results;

    }

}

=head3 videos_setPermalink

Set permalink on videos you own. Permalink is used by our flash player. When a user clicks on a video while it is played, he will be redirected to permalink url defined on a video.

$video->videos_setPermalink( $video_id, $permalink );

Requires the following parameters:

* video_id: The ID of the video to get information for. This is the ID that's returned by videos_upload.

* permalink: URL address to your page - max 250 characters long.

Additional options parameters include: 

None

Note: To reset a permalink back to its Viddler.com default - simply supply an empty permalink argument.

Returns 0 ( false ) if unsuccessful and 1 ( true ) if successful

=cut

sub videos_setPermalink( $$ ) {

    my ( $self, $video_id, $permalink ) = @_;

    my $xml = new XML::Simple;
    my $content =
        get $self->{_apiURL}
      . "?method=viddler.videos.setPermalink&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID}
      . "&video_id="
      . $video_id
      . "&permalink="
      . $permalink;
    my $results = $xml->XMLin($content);

    if ( defined( $results->{'success'} ) ) {

        return 1;

    }
    else {

        return 0;

    }

}

=head3 videos_setThumbnail

Choose a thumbnail based on a moment in time in a video. This feature will select the nearest keyframe to the point given and create a new thumbnail.

Due to the caching methods of Viddler's service, it will take a few minutes for the new thumbnail to propagate to our entire network.

$video->videos_setThumbnail( $video_id, $timepoint, $file );

Requires the following parameters:

* video_id: The ID of the video which you want to update

* timepoint: Time in seconds from 0 to video length (int).

* file: An image file to use as the static thumbnail. JPG, GIF, PNG supported.

Additional options parameters include: 

None

Notes: 

* Invalid arguments will be ignored

* Time point must be in seconds and be a valid integer.

* To improve thumbnail generation increase the number of keyframes in the video uploaded.

* Due to caching, a new thumbnail make take a few minutes to propagate throughout the network.

* If both timepoint and file are sent, timepoint is ignored.

* Image files should be the same dimensions as the video. Larger image files will be automatically scaled down.

* Max thumbnail size is 400 KB. Anything larger results in Error 200.

Returns a hash of an array of URL's for accessing various thumbanil image sizes

=cut

sub videos_setThumbnail( $$ ) {

    my ( $self, $video_id, $timepoint, $file ) = @_;

    my $xml = new XML::Simple;
    my $ua  = new LWP::UserAgent;

    my $request = POST $self->{_apiURL},
      Content_Type => 'multipart/form-data',
      Content      => [
        method    => 'viddler.videos.setThumbnail',
        api_key   => $self->{apiKey},
        sessionid => $self->{_sessionID},
        video_id  => $video_id,
        timepoint => $timepoint,
        file      => [$file]
      ];

    my $results = $xml->XMLin( $ua->request($request)->content );
    return $results;

}

=head3 videos_search

Gets and returns results of a search of Viddler videos and people.

$video->videos_search( $type, $query, $page, $per_page );

Requires the following parameters:

* type: The type of search (e.g. "myvideos", "friendsvideos", "allvideos", "relevant", "recent", "popular", "timedtags", "globaltags". (The "timedtags" and "globetags" sorting argument should be used in conjunction with an actual tag being given for the query argument.))

* query: What to search for (e.g. "iPhone", "Pennsylvania", or "Windows XP")

Additional options parameters include: 

* page: The "page number" of results to retrieve (e.g. 1, 2, 3).

* per_page: The number of results to retrieve per page (maximum 100). If not specified, the default value equals 20.

Returns a hash of an array of search results

=cut

sub videos_search( $$ ) {

    my ( $self, $type, $query, $page, $per_page ) = @_;

    my $xml = new XML::Simple;

    if ( !defined $page ) {

        $page = "";

    }

    if ( !defined $per_page ) {

        $per_page = "";

    }

    my $content =
        get $self->{_apiURL}
      . "?method=viddler.videos.search&api_key="
      . $self->{apiKey}
      . "&type="
      . $type
      . "&query="
      . $query
      . "&page="
      . $page
      . "&per_age="
      . $per_page
      . "&sessionid="
      . $self->{_sessionID};
    my $results = $xml->XMLin($content);
    return $results;

}

=head3 videos_getByUser

Gets and returns a lists of all videos that were uploaded by the specified user.

$video->videos_getByUser( $user, page, $per_page, $tags, $sort );

Requires the following parameters:

* user: The chosen Viddler user name. You can provide multiple coma separated Viddler usernames

Additional options parameters include: 

* page: The of results to retrieve (e.g. 1, 2, 3).

* per_page: The number of results to retrieve per page (maximum 100). If not specified, the default value equals 20.

* tags: The tags you would like to filter your query by.

* sort: How you would like to sort your query (views-asc,views-desc,uploaded-asc,uploaded-desc)

Returns a hash of an array of search results

=cut

sub videos_getByUser( $ ) {

    my ( $self, $user, $page, $per_page, $tags, $sort ) = @_;

    my $xml = new XML::Simple;

    if ( !defined $page ) {

        $page = "";

    }

    if ( !defined $per_page ) {

        $per_page = "";

    }

    if ( !defined $tags ) {

        $tags = "";

    }

    if ( !defined $sort ) {

        $sort = "";

    }

    my $content =
        get $self->{_apiURL}
      . "?method=viddler.videos.getByUser&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID}
      . "&user="
      . $user
      . "&page="
      . $page
      . "&per_age="
      . $per_page
      . "&tags="
      . $tags
      . "&sort="
      . $sort;
    my $results = $xml->XMLin($content);
    return $results;

}

=head3 videos_getByTag

Lists all videos that have the specified tag.

$video->videos_getByTag( $tag, $page, $per_page, $sort );

Requires the following parameters:

* tag The tag to search for

Additional options parameters include: 

* page: The "page number" of results to retrieve (e.g. 1, 2, 3).

* per_page: The number of results to retrieve per page (maximum 100). If not specified, the default value equals 20.

* sort: How you would like to sort your query (views-asc,views-desc,uploaded-asc,uploaded-desc)

Returns a hash of an array of details for videos with a matching tag

=cut

sub videos_getByTag( $ ) {

    my ( $self, $tag, $page, $per_page, $sort ) = @_;

    my $xml = new XML::Simple;

    if ( !defined $page ) {

        $page = "";

    }

    if ( !defined $per_page ) {

        $per_page = "";

    }

    if ( !defined $sort ) {

        $sort = "";

    }

    my $content =
        get $self->{_apiURL}
      . "?method=viddler.videos.getByTag&api_key="
      . $self->{apiKey} . "&tag="
      . $tag
      . "&page="
      . $page
      . "&per_page="
      . $per_page
      . "&sort="
      . $sort;
    my $results = $xml->XMLin($content);
    return $results;

}

=head3 videos_getFeatured

Lists currently featured videos

$video->videos_getFeatured;

Returns a hash of an array of details for videos featured by Viddler

=cut

sub videos_getFeatured( ) {

    my ($self) = @_;

    my $xml = new XML::Simple;
    my $content =
        get $self->{_apiURL}
      . "?method=viddler.videos.getFeatured&api_key="
      . $self->{apiKey};
    my $results = $xml->XMLin($content);
    return $results;

}

=head3 videos_delete

Deletes a video associated with a users account.

$video->videos_delete( $video_id );

Requires the following parameters:

* video_id: The ID of the video to get information for. This is the ID that's returned by videos_upload.

Additional options parameters include: 

None

Returns 0 ( false ) if unsuccessful and 1 ( true ) if successful

=cut

sub videos_delete( $ ) {

    my ( $self, $video_id ) = @_;

    my $xml = new XML::Simple;
    my $content =
        get $self->{_apiURL}
      . "?method=viddler.videos.delete&api_key="
      . $self->{apiKey}
      . "&sessionid="
      . $self->{_sessionID}
      . "&video_id="
      . $video_id;
    my $results = $xml->XMLin($content);

    if ( defined( $results->{'success'} ) ) {

        return 1;

    }
    else {

        return 0;

    }

}

=head1 AUTHOR

Paul Weinstein, C<< <pdw at weinstein.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-viddler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Viddler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Viddler


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Viddler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Viddler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Viddler>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Viddler/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Paul Weinstein.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of WebService::Viddler
__END__
