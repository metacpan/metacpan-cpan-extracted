#!/usr/bin/false
# ABSTRACT: Provides an object oriented interface to the NZBMatrix APIs.

=head1 NAME

WebService::NZBMatrix

=head1 VERSION

Version 0.002
    
=head1 SYNOPSIS

    use WebService::NZBMatrix;

    my $api = API::NZBMatrix->new(
        'username' => 'myuser',
        'apikey'   => 'myapikey',
    );

    my @search_results = $api->search('search term');
    
    for my $result (@search_results) {
        my $id = $result->{'NZBID'};
        
        unless ( $api->bookmark($id) ) {
            my $error = $api->error();
            warn "$error\n" if $error;
        }
    }

=head1 DESCRIPTION

Object oriented interface to the NZBMatrix APIs

=head1 ERROR HANDLING

With the exception of the constructor ( new() ), which will die if
arguments are invalid, all other methods will, if there are any issues,
set an error that is retrievable via the error() method and return undef.

For example of how to best manage error detection please see the doc for
the error() method below.
   
=head1 METHODS

=cut
package WebService::NZBMatrix;

    our $VERSION = '0.002';
    
    use strict;
    use LWP::UserAgent;
    
    # Class Vars
    my $API_HOSTNAME = 'api.nzbmatrix.com';
    my $API_VERSION  = 'v1.1';
    my $CLEAR_PROTO  = 'http://';
    my $SECURE_PROTO = 'https://';
    my $DEBUG        = 0;

=head2 new
    
    # Arguments as a list of arguments
    $api = WebService::NZBMatrix->new( 
        'username' => 'nzbmatrix_user',
        'apikey'   => 'nzbmatrix_apikey',
        'ssl'      => 1, #OPTIONAL
    );

    # Arguments as a hash ref    
    %opts_hash = (
        'username' => 'nzbmatrix_user',
        'apikey'   => 'nzbmatrix_apikey',
        'ssl'      => 1, #OPTIONAL
    );
    $api = WebService::NZBMatrix->new( 
        \%opts_hash    
    );
    
Accepts one argument which may be a hash reference or list of arguments 
arranged 'key', 'value' containing the keys 'username' being the
username for your NZBmarix login for your account, and 'apikey' being
the api key corresponding to that account. The hash ref can also contain
the key 'ssl' with any true value to enable the use of ssl/https when
communicating with the APIs.

Returns an object setup with your NZBMatric authentication details.
    
=cut
    sub new {
        my $class = ref $_[0] ? ref shift : shift;
        my %opts;
        
        if (@_ > 1){
            unless (@_ % 2) {
                %opts = @_;
            }
            else {
                die "Odd number of arguments supplied to new\n";
                return;
            }
        }
        elsif ( @_ == 1 ) {
            if (ref $_[0] eq 'HASH') {
                %opts = %{ $_[0] };
            }
            else {
                %opts = ( 'nzb_id' => $_[0], 'action' => 'add' );
            }
        }
        else {
            die "Must supply at least a username and apikey to new\n";
            return;
        }
        
        # %opts must contain 'username' and 'apikey'. 'ssl' is optional
        my $username = $opts{'username'} || die "Hash ref must include a 'username' key\n";
        my $apikey   = $opts{'apikey'}   || die "Hash ref must include an 'apikey' key\n";
        my $ssl      = $opts{'ssl'};
        
        my %self = (
            'username' => $username,
            'apikey'   => $apikey,
            'ssl'      => $ssl,
            'error'    => undef,
        );
        
        my $self = bless(\%self, $class);
        
        return $self;
    }

=head2 account

The account method takes no arguments and uses the username and 
apikey supplied during construction to retrieve some details of the
account.  Returns a hash reference or list depending on the calling
context:

    $account_details = $api->account();
    %account_details = $api->account();

The returned hash looks like:

    {
          'API_DAILY_DOWNLOAD' => '0', #Downloads via API for the day 
          'USERID' => '12345',         #Account ID
          'API_DAILY_RATE' => '28',    #API calls for the hour
          'USERNAME' => 'username'     #Username on the site.
    }

=cut

    sub account {
        my $self = shift;
        
        my $uri = $self->_create_uri('account.php');        
        my $result = $self->_fetch_api($uri) || return;
        $result = $self->_process_api_output($result) || return;
        
        return wantarray ? %{$result->[0]} : $result->[0];
    }
    
=head2 bookmark

The bookmark method allows you to add or remove bookmarks.  It 
accepts either a single scalar value which will be the ID of an NZB
or a hash ref containing the options applicable to this API function.
In the case of a hash ref, the nzb_id is mandatory, the rest is
optional.
    
    # As a single scalar
    $success = $api->bookmark('12345');
    
    # As a list of attributes
    $success = $api->bookmark(
            nzb_id => '12345',
            action => ('add'|'remove'), #defaults to 'add'
    );
    
    # Options supplied in a hash ref.
    %opts_hash = ( 'nzb_id' => '1234', 
                   'action' => ('add'|'remove'), 
                 );
    $success = $api->bookmark( \%opts_hash );

Returns true (1) if successful, undef if there is an error.

=cut    

    sub bookmark {
        my $self = shift;
        my %opts;
        
        if (@_ > 1){
            unless (@_ % 2) {
                %opts = @_;
            }
            else {
                $self->error('Odd number of arguments supplied to bookmark');
                return;
            }
        }
        elsif ( @_ == 1 ) {
            if (ref $_[0] eq 'HASH') {
                %opts = %{ $_[0] };
            }
            else {
                %opts = ( 'nzb_id' => $_[0], 'action' => 'add' );
            }
        }
        else {
            $self->error('Must supply at least an NZB ID to bookmark()');
            return;
        }

        my $uri;
        my $result;
        my %uri_options;
        
        my %actions = (
            'add'    => 1,
            'remove' => 1,
        );
        
        my %options = (
            'nzb_id' => 
                { 
                    'key'   => 'id',
                    'valid' => sub { return $_[0] =~ /^\d+$/ ? 1 : undef },
                },
            'action' => 
                {
                    'key'   => 'action',
                    'valid' => sub { return $actions{$_[0]} ? 1 : undef },
                },
        );
        
        unless ($opts{'nzb_id'}) {
            $self->error('No NZB ID supplied. ID is required');
            return;
        }

        for my $opt ( keys %opts ) {
            # Test that the option is a valid option
            unless ($options{$opt}) {
                $self->error("Invalid bookmark option $opt supplied");
                return;
            }
            
            # Test that the value for this option is valid
            unless ( $options{$opt}->{'valid'}->($opts{$opt}) ){
                $self->error("Invalid value for option $opt supplied");
                return;
            }
            
            $uri_options{ $options{$opt}->{'key'} } = $opts{$opt};
        }
            
        $uri    = $self->_create_uri('bookmarks.php', \%uri_options);
        $result = $self->_fetch_api($uri) || return;
        $result = $self->_process_api_output($result) || return;
        
        return 1;
    }
    
=head2 details

The details method retrieves the details of a specifc NZB given its
ID.  Accepts a single scalar argument being the ID of the NZB to be
queried.

Returns a hash reference or list depending on the calling
context:

    $details = $api->details('12345');
    %details = $api->details('12345');

Return hash is in the form:

    {
        'NZBID'       => '444027',                    # NZB ID On Site
        'NZBNAME'     => 'mandriva linux 2009',       # NZB Name On Site
        'LINK'        => 'nzbmatrix.com/nzb-details.php?id=444027&hit=1', # Link To NZB Details Page
        'SIZE'        => '1469988208.64',             # Size in bytes
        'INDEX_DATE'  => '2009-02-14 09:08:55',       # Indexed By Site (Date/Time GMT)
        'USENET_DATE' => '2009-02-12 2:48:47',        # Posted To Usenet (Date/Time GMT)
        'CATEGORY'    => 'TV: SD',                    # NZB Post Category
        'GROUP'       => 'alt.binaries.linux',        # Usenet Newsgroup
        'COMMENTS'    => '0',                         # Number Of Comments Posted (Broken: always 0)
        'HITS'        => '0',                         # Number Of Hits (Views) (Broken: always 0)
        'NFO'         => 'yes',                       # NFO Present
        'WEBLINK'     => 'http://linux.org',          # HTTP Link To Attached Website
        'LANGUAGE'    => 'English',                   # Language Attached From Our Index
        'IMAGE'       => 'http://linux.org/logo.gif', # HTTP Link To Attached Image
        'REGION'      => '0',                         # Region Coding
    }

=cut

    sub details {
        my $self = shift;
        my $opts = shift;
        my $uri;
        my $result;
        my %uri_options;

        unless ($opts =~ /^\d+$/) {
            $self->error($opts.' does not look like a valid NZB ID');
            return;
        }
        
        $uri_options{'id'} = $opts;
        
        $uri    = $self->_create_uri('details.php', \%uri_options);
        $result = $self->_fetch_api($uri) || return;
        $result = $self->_process_api_output($result) || return;
        
        return wantarray ? %{$result->[0]} : $result->[0];
    }

=head2 download

The details method retrieves the NZB given its ID.
Accepts a single scalar argument being the ID of the NZB to be
downloaded or a hash ref containing the keys 'nzb_id' being the ID
of the NZB to download and an optional 'file' key containing a file
name to write the NZB contents to.  In either case, if no 'file' is
supplied the NZB contents are returned as a scalar string.

If 'file' is supplied, the return values is 1/true.

    # NZB ID supplied as a scalar
    $nzb = $api->download('12345');
    
    # Options supplied as a list of arguments.
    $success = $api->download(
            'nzb_id' => '12345',
            'file'   => '/path/to/file.nzb',
    );
    
    # Options supplied in a hash ref.
    %opts_hash = ( 'nzb_id'   => '12345', 
                   'file' => '/some/file.nzb', 
                 );
    $success = $api->download( \%opts_hash );

Note that if the file already exists, an error will be set and undef
returned.
If 'file' contains a directory path (full or relative) and the 
directory doesn't exist, we won't create it here. An error will be 
set and undef returned.

=cut

    sub download {
        my $self = shift;
        my %opts;
        
        if (@_ > 1){
            unless (@_ % 2) {
                %opts = @_;
            }
            else {
                $self->error('Odd number of arguments supplied to download');
                return;
            }
        }
        elsif ( @_ == 1 ) {
            if (ref $_[0] eq 'HASH') {
                %opts = %{ $_[0] };
            }
            else {
                %opts = ( 'nzb_id' => $_[0] );
            }
        }
        else {
            $self->error('Must supply at least an NZB ID to download()');
            return;
        }

        my $uri;
        my $result;
        my %uri_options;

        my $id   = $opts{'nzb_id'};
        my $file = $opts{'file'};
        
        unless ( $id and $id =~ /\d+/ ) {
            $self->error('Invalid ID supplied or ID missing');
            return;
        }
        
        if ($file) {
            my ($dir) = $file =~ m|^(.*)/|;
            
            if (-f $file) {
                $self->error('The specified file already exists.');
                return;
            }
            
            if ($dir and not -d $dir) {
                $self->error('The directory does not exist.');
                return;
            }
        }

        $uri_options{'id'} = $id;
        
        
        $uri    = $self->_create_uri('download.php', \%uri_options);
        $result = $self->_fetch_api($uri) || return;
        
        if ($file) {
            open my $fh,'>',$file
              or ($self->error("Could not open $file to write to: $!")
                  and return);

            print $fh $result;
            close $fh;
            
            return 1;
        }
        
        return $result;
    }

=head2 search
 
The search method accepts either a single scalar that will be used 
as the search term and all other options will be the default as set
by the API or a single hash ref allowing the full compliment of 
options to be set in which case 'search_term' is mandatory, the rest
are optional.

    # Scalar supplied search term
    $search_results = $api->search('A search term');
    
    # Options supplied as a list of elements
    $search_results = $api->search( 
            'search_term'  => 'A search term',
            'category'     => 'NZBMatrix search category'
            'max_results'  => 10, # number
            'max_age'      => 10, # number of days
            'region'       => ('PAL'|'NTSC'|'FREE'),
            'news_group'   => 'Name of news group', #NOT VALIDATED
            'min_size'     => 10, # number of MB
            'max_size'     => 10, # number of MB
            'english_only' => (1|0),
            'search_field' => ('name'|'subject'|'weblink'),
    );
    
    # Options supplied in a hash ref.
    %opts_hash = ( 'search_term' => 'something', 
                   'category'    => 'Everything,
                   ... 
                 );
    $search_results = $api->search( \%opts_hash );

The API documentation also includes reference to min and max hits
however it appears that this info is not included in the API data at
this point in time and results always show 0 hits.

Returns a list of hash references each hash containing the details
of each result.  Example:

    {
        'NZBID'       => '444027',                    # NZB ID On Site
        'NZBNAME'     => 'mandriva linux 2009',       # NZB Name On Site
        'LINK'        => 'nzbmatrix.com/nzb-details.php?id=444027&hit=1', # Link To NZB Details Page
        'SIZE'        => '1469988208.64',             # Size in bytes
        'INDEX_DATE'  => '2009-02-14 09:08:55',       # Indexed By Site (Date/Time GMT)
        'USENET_DATE' => '2009-02-12 2:48:47',        # Posted To Usenet (Date/Time GMT)
        'CATEGORY'    => 'TV: SD',                    # NZB Post Category
        'GROUP'       => 'alt.binaries.linux',        # Usenet Newsgroup
        'COMMENTS'    => '0',                         # Number Of Comments Posted (Broken: always 0)
        'HITS'        => '0',                         # Number Of Hits (Views) (Broken: always 0)
        'NFO'         => 'yes',                       # NFO Present
        'WEBLINK'     => 'http://linux.org',          # HTTP Link To Attached Website
        'LANGUAGE'    => 'English',                   # Language Attached From Our Index
        'IMAGE'       => 'http://linux.org/logo.gif', # HTTP Link To Attached Image
        'REGION'      => '0',                         # Region Coding
    }

Valid categories are:

    Everything
    Movies: ALL             TV: ALL             Documentaries: ALL
    Movies: DVD             TV: DVD (Image)     Documentaries: STD 
    Movies: Divx/Xvid       TV: SD              Documentaries: HD  
    Movies: BRRip           TV: HD (x264)  
    Movies: HD (x264)       TV: HD (Image)      Anime: ALL  
    Movies: HD (Image)      TV: Sport/Ent       
    Movies: Other           TV: Other           Other: ALL
                                                Other: Audio Books  
    Games: ALL              Apps: ALL           Other: Radio  
    Games: PC               Apps: PC            Other: E-Books  
    Games: PS2              Apps: Mac           Other: Images  
    Games: PS3              Apps: Portable      Other: Android  
    Games: PSP              Apps: Linux         Other: iOS/iPhone  
    Games: Xbox             Apps: Other         Other: Other  
    Games: Xbox360                              Other: Extra Pars/Fills
    Games: Xbox360 (Other)  Music: ALL          
    Games: Wii              Music: MP3 Albums   
    Games: Wii VC           Music: MP3 Singles  
    Games: DS               Music: Lossless  
    Games: Other            Music: DVD  
                            Music: Video  
                            Music: Other
    
Valid regions are:

    PAL
    NTSC
    FREE

Valid search fields are:

    name
    subject
    weblink

=cut

    sub search {
        my $self = shift;
        my %opts;
        
        if (@_ > 1){
            unless (@_ % 2) {
                %opts = @_;
            }
            else {
                $self->error('Odd number of arguments supplied to search');
                return;
            }
        }
        elsif ( @_ == 1 ) {
            if (ref $_[0] eq 'HASH') {
                %opts = %{ $_[0] };
            }
            else {
                %opts = ( 'search_term' => $_[0] );
            }
        }
        else {
            $self->error('Must supply at least a search term for search()');
            return;
        }

        my $uri;
        my %uri_options;
        my $result;
        
        # Categories and category IDs
        my %categories = (
            'Everything'         => '0',  'Movies: DVD'             => '1',
            'Movies: Divx/Xvid'  => '2',  'Movies: BRRip'           => '54',
            'Movies: HD (x264)'  => '42', 'Movies: HD (Image)'      => '50', 
            'Movies: Other'      => '4',  'TV: DVD (Image)'         => '5',
            'TV: SD'             => '6',  'TV: HD (x264)'           => '41', 
            'TV: HD (Image)'     => '57', 'TV: Sport/Ent'           => '7',
            'TV: Other'          => '8',  'Documentaries: STD'      => '9',
            'Documentaries: HD'  => '53', 'Games: PC'               => '10', 
            'Games: PS2'         => '11', 'Games: PS3'              => '43', 
            'Games: PSP'         => '12', 'Games: Xbox'             => '13', 
            'Games: Xbox360'     => '14', 'Games: Xbox360 (Other)'  => '56', 
            'Games: Wii'         => '44', 'Games: Wii VC'           => '51', 
            'Games: DS'          => '45', 'Games: Other'            => '17', 
            'Apps: PC'           => '18', 'Apps: Mac'               => '19', 
            'Apps: Portable'     => '52', 'Apps: Linux'             => '20', 
            'Apps: Other'        => '21', 'Music: MP3 Albums'       => '22', 
            'Music: MP3 Singles' => '47', 'Music: Lossless'         => '23', 
            'Music: DVD'         => '24', 'Music: Video'            => '25', 
            'Music: Other'       => '27', 'Anime: ALL'              => '28', 
            'Other: Audio Books' => '49', 'Other: Radio'            => '26', 
            'Other: E-Books'     => '36', 'Other: Images'           => '37', 
            'Other: Android'     => '55', 'Other: iOS/iPhone'       => '38', 
            'Other: Other'       => '40', 'Other: Extra Pars/Fills' => '39',
            
            'Movies: ALL'        => 'movies-all', 'TV: ALL'    => 'tv-all',
            'Documentaries: ALL' => 'docu-all',   'Games: ALL' => 'games-all', 
            'Apps: ALL'          => 'apps-all',   'Music: ALL' => 'music-all',
            'Other: ALL'         => 'other-all',
        );
        
        # Valid Search Fields
        my %search_fields = (
            'name'    => 1,
            'subject' => 1,
            'weblink' => 1,
        );
        
        # Regions
        my %regions = (
            'PAL'  => 1,
            'NTSC' => 2,
            'FREE' => 3,
        );
        
        my %friendly_values = (
            'category' => \%categories,
            'regions'  => \%regions,
        );

        # Set up reference of options and valid values for each options
        # Options and their corresponding api uri keys
        my %options = (
            'search_term'  => 
                { 
                    'key'   => 'search',
                    'valid' => sub { return $_[0] =~ /^.+$/ ? 1 : undef },
                },
            'category'     => 
                {
                    'key'   => 'catid',
                    'valid' => sub { return $categories{$_[0]} ? 1 : undef },
                },
            'max_results'  => 
                {
                    'key'   => 'num',
                    'valid' => sub { return $_[0] =~ /^\d+$/ ? 1 : undef },
                },
            'max_age'      =>
                {
                    'key'   => 'age',
                    'valid' => sub { return $_[0] =~ /^\d+$/ ? 1 : undef },
                },
            'region'       => 
                {
                    'key'   => 'region',
                    'valid' => sub { return $regions{$_[0]} ? 1 : undef },
                },
            'news_group'   => 
                {
                    'key'   => 'group',
                    'valid' => sub { return $_[0] =~ /^.+$/ ? 1 : undef },
                },
            'min_size'     => 
                {
                    'key'   => 'larger',
                    'valid' => sub { return $_[0] =~ /^\d+$/ ? 1 : undef },
                },
            'max_size'     => 
                {
                    'key'   => 'smaller',
                    'valid' => sub { return $_[0] =~ /^\d+$/ ? 1 : undef },
                },
                
           # Hits data apparently is not available via the API atm
           # and always returns 0 hits
           #'min_hits'     => 
           #    {
           #        'key'   => 'minhits',
           #        'valid' => sub { return $_[0] =~ /^\d+$/ ? 1 : undef },
           #    },
           #'max_hits'     => 
           #    {
           #        'key'   => 'maxhits',
           #        'valid' => sub { return $_[0] =~ /^\d+$/ ? 1 : undef },
           #    },
            'english_only' => 
                {
                    'key'   => 'englishonly',
                    'valid' => sub { return $_[0] =~ /^[01]$/ ? 1 : undef },
                },
            'search_field' => 
                {
                    'key'   => 'searchin',
                    'valid' => sub { return $search_fields{$_[0]} ? 1 : undef },
                },
        );

        # Construct the api URI using all the options supplied
        # Make sure that at least a search term was supplied
        unless ($opts{'search_term'}) { 
            $self->error("No search term supplied");
            return;
        }
        
        for my $opt ( keys %opts ) {
            # Test that the option is a valid option
            unless ($options{$opt}) {
                $self->error("Invalid search option $opt supplied");
                return;
            }
            
            # Test that the value for this option is valid
            unless ( $options{$opt}->{'valid'}->($opts{$opt}) ){
                $self->error("Invalid value for option $opt supplied");
                return;
            }
            
            # Some option values are accepted in a more readable form
            # get the actual value the api expects.
            if ( $friendly_values{$opt} ) {
                $opts{$opt} = $friendly_values{$opt}->{$opts{$opt}};
            }

            $uri_options{ $options{$opt}->{'key'} } = $opts{$opt};
        }

        $uri    = $self->_create_uri('search.php', \%uri_options);
        $result = $self->_fetch_api($uri) || return;
        $result = $self->_process_api_output($result) || return;
        
        return wantarray ? @{$result} : $result;
    }

=head2 site_status

The site_status method downloads the site status page at 
http://nzbmatrix.info/ and attempts to find the status of the
various components for which they provide statuses.

The page also may have a notice of some kind that provides important
information outside of the normal components being online/offline.

The method needs no arguments and returns a scalar containing a
reference to a hash or a list depending on the calling context.

    $status = $api->site_status();
    %status = $api->site_status();

The return hash looks like:

    {
        'NZBxxx RSS'       => 'Online',
        'NZBMatrix API'    => 'Online',
        'Payment Gateways' => 'Online',
        'NZBMatrix'        => 'Online',
        'Notice'           => 'Issues on RSS and bookmark is Offline ATM',
        'NZBxxx API'       => 'Online',
        'NZBxxx'           => 'Online',
        'NZBMatrix RSS'    => 'Online'
    }
    
=cut

    sub site_status {
        my $self = shift;
        my $url = 'http://nzbmatrix.info/';
        my %statuses;

           my $html = $self->_fetch_page($url) || return;
           
           my @lines = split /\n/, $html;
           
           for my $line (@lines) {
            while (   $line =~ m{(?|
                                  <B>([\w\s]+):</B>[^<]+<font[^>]+>([^<]+)</font>| 
                                  (Notice).+<strong>(.+)</strong>
                                 )
                                }gx
            ) {
                $statuses{$1} = $2;
            }
        }
           
        return wantarray ? %statuses : \%statuses;
    }
    
=head2 error

The error method can be used to retrive the last error that occured.
All methods that fail, will set an error retrivable by this method, 
and then return undef.

Therefore it is good practice to check for a positive result for
each method call and then call error() if the result is 'false'.

Eg:

    $success = $api->bookmark('12345');
    unless ($success) {
        $error = $api->error();
        print $error if $error;
    }

Retrieving the error will clear the error meaning that a subsequent
call will return undef.

=cut
    
    sub error {
        my $self  = shift;
        my $error = shift;
        
        if ($error) {
            # set the new error
            $self->{'error'} = $error;
        }
        else {
            # Retrieve the last error and clear it from the obj
            $error = $self->{'error'};
            $self->{'error'} = undef;
        }
        
        return $error;
    }

    # ----------------- #
    # Private(ish) subs #
    # ----------------- #
    
    sub _fetch_api {
        my $self = shift;
        my $uri  = shift || return;
        my $full_url;
        
        if ( $self->{'ssl'} ) {
            $full_url = $SECURE_PROTO.$API_HOSTNAME.'/'.$API_VERSION.'/'.$uri;
        }
        else {
            $full_url = $CLEAR_PROTO.$API_HOSTNAME.'/'.$API_VERSION.'/'.$uri;
        }

        _debug($full_url);
        
        my $ua = LWP::UserAgent->new;
        $ua->agent("API-NZBMatrix/$VERSION");
        
        my $request = HTTP::Request->new(GET => $full_url);
        my $result  = $ua->request($request);
        
        if ( $result->is_success ) {
            return $result->content;
        }
        else {
            $self->error( 'API request failed: '.$result->status_line );
            return;
        }
    }
    
    sub _fetch_page {
        my $self = shift;
        my $url  = shift || return;

        my $ua = LWP::UserAgent->new;
        $ua->agent("API-NZBMatrix/$VERSION");
        
        my $request = HTTP::Request->new(GET => $url);
        my $result  = $ua->request($request);
        
        if ( $result->is_success ) {
            return $result->content;
        }
        else {
            $self->error( 'URL request failed: '.$result->status_line );
            return;
        }
    }
    
    sub _process_api_output {
        my $self       = shift;
        my $api_output = shift || return;
        my @results;
        
        for my $result ( split /\s*\|\s*/, $api_output ) {
            my %properties;
            
            $result =~ s/;$//;
            
            for my $key_val ( split /;\n/, $result ) {
                next if $key_val =~ /^\s*$/;

                my ($key, $val) = $key_val =~ /^([^:]*):(.*)$/;
                _debug($key.' => '.$val);

                if ($key eq 'error') {
                    $self->error('The API returned error: '.$val);
                    return;
                }
                
                $properties{$key} = $val;    
            }
            
            push @results, \%properties;
        }
        
        return wantarray ? @results : \@results;
    }
    
    sub _create_uri {
        my $self    = shift;
        my $handler = shift || return;
        my $opts    = shift;
        my $uri     = $handler.'?';
        
        if ( $opts ) {
            unless ( ref $opts eq 'HASH' ) {
                return;                
            }
            for my $opt ( keys %{$opts} ) {
                $uri .= $opt.'='.$opts->{$opt}.'&';
            }    
        }
        
        $uri .= 'username='.$self->{'username'};
        $uri .= '&apikey='.$self->{'apikey'};
        
        return $uri;
    }

    sub _debug {
        return unless $DEBUG;
        my $message = shift || return;
        
        print "$message\n";
        
        return 1;
    }
    
=head1 AUTHOR

Chris Portman <chrisportman@internode.net.au>

=head1 COPYRIGHT

Copyright (C) 2012 by Chris Portman.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
    
=cut
    
1;
