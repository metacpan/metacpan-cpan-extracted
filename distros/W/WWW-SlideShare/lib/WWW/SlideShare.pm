package WWW::SlideShare;

use strict;
use Digest::SHA1 qw(sha1_hex);
use LWP::UserAgent;
use WWW::SlideShare::Object;
use XML::Parser;
use Carp qw(confess);

our $AUTOLOAD;
our $VERSION='1.01';

use constant {
		TIMEOUT => 10,
		BASE_URL => 'http://www.slideshare.net/api/2/',
		URL => 0,
		OBJECT_TYPE => 1,	
};

{
my $ua = LWP::UserAgent->new;
$ua->timeout(TIMEOUT);
$ua->env_proxy;

my %conf = (
		'_get_slideshow'	   => [ 'get_slideshow', 'Slideshow' ],
		'get_slideshows_by_tag'	   => [ 'get_slideshows_by_tag', 'Slideshow' ],
		'get_slideshows_by_group'  => [ 'get_slideshows_by_group', 'Slideshow' ],
		'get_slideshows_by_user'   => [ 'get_slideshows_by_user', 'Slideshow' ],
		'search_slideshows'	   => [ 'search_slideshows', 'Slideshow' ],
		'get_user_groups'	   => [ 'get_user_groups', 'Group' ],
		'get_user_contacts'   	   => [ 'get_user_contacts', 'Contact' ],
		'get_user_tags'		   => [ 'get_user_tags', 'Tag' ],
	   );

sub new {
	my ($class, %params) = @_;

	my $self = {
			'_objs' => [],
			'_objtype' => '',
		   };

	$self->{'_api_key'} = $params{'api_key'};
	$self->{'_ts'} = time;
	$self->{'_hash'} = lc(sha1_hex($params{'secret'},$self->{'_ts'}));
	$self->{'_params'} = "?api_key=$self->{'_api_key'}&ts=$self->{'_ts'}&hash=$self->{'_hash'}";

	bless $self, $class;
}

sub AUTOLOAD {
	my ($self, $params) = @_;

	my $name = $AUTOLOAD;
	$name =~ s/.*://;

	confess "Method $name not found" unless $conf{$name};
	
	my $query_string = join('&', map { "$_=$params->{$_}" } keys %$params);

	my $url = BASE_URL.$conf{$name}->[URL].$self->{'_params'}.'&'.$query_string;
        my $response = $ua->get($url);

	if ($response->is_success) {
		my $content = $response->content;
		my $ref = $self->_parseResponse($content, $conf{$name}->[OBJECT_TYPE]);
		return $ref;
	}
	else {
		confess "Web Service Error for $url";
	}
}

sub get_slideshow {
	my ($self, $params) = @_;
	
	my $ref = $self->_get_slideshow($params);
	return $ref->[0];
}

sub _parseResponse {
	my ($self, $xml, $objtype) = @_;

	if ($xml =~ /serviceerror/i) {
		confess "SlideShare Service Error $xml";		
	}

	$self->{'_objs'} = [];
	$self->{'_objtype'} = $objtype;

	my %fields = ();
	my $last_tag = undef;

	my $st_sub_ref  = sub { 
		my ($obj, $tag) = @_;

		if ($tag eq $self->{'_objtype'}) {
			%fields = ();
		}
	
		$last_tag = $tag;
	};

	my $text_handler_ref = sub { 
		$fields{$last_tag} .= $_[1];
	};

	my $end_sub_ref = sub {
		my ($obj, $tag) = @_;
	
		$fields{$last_tag} =~ s/^\s+//g;
		delete $fields{''};

		while (my ($k, $v) = each %fields) {
			delete $fields{$k} if ($v eq '');
		}

		if ($tag eq $self->{'_objtype'}) {
			push @{$self->{'_objs'}}, WWW::SlideShare::Object->new({ %fields });
		}
	};

	my $p2 = new XML::Parser(Handlers => {
			 			Start  => $st_sub_ref, 
						Char   => $text_handler_ref, 
						End    => $end_sub_ref, 
				             });
        $p2->parse($xml);

	return $self->{'_objs'};
}

sub DESTROY { }
}

1;

__END__

=head1 NAME 

WWW::SlideShare

=head1 ABSTRACT

A perl interface to the Slideshare Web Service API

=head1 SYNPOSIS

The usage of the API is demonstrated here -

	my $ss = WWW::SlideShare->new('api_key' => $api_key, 'secret' => $secret);
	ok (ref $ss, "Object creation");

	my $slide =  $ss->get_slideshow({ 'slideshow_id' => 4383743 });
	ok($slide->[0]->ID == 4383743, "get_slideshow() by id");

=head1 DESCRIPTION

This an object-oriented module and supports most of the SlideShare Web Services API documented at http://www.slideshare.net/developers/documentation 

All parameters are passed as key-value pairs in a hash reference.

=head2  new

 	Creates a SlideShare object, taking two parameters - API key and secret
 
	my $obj = new ({ 'api_key' => $api_key, 'secret' => $secret })

=head2  get_slideshow
	
	This can be called in one of two ways, by providing slideshow_id or slideshow_url. It always returns a slideshow object.

	$slideshow = get_slideshow({ slideshow_id => $id })
	
	$slideshow = get_slideshow({ slideshow_url => $url })

=head2  get_slideshows_by_tag

	This accepts a tag and other optional key-value pairs supported by the API, returning a reference to an array of slideshow objects.

	$slideshows = get_slideshow_by_tag({ tag => $tag, ... })

=head2  get_slideshows_by_user

	This accepts username of user whose slideshows are to be accessed and returns a reference to an array of slideshow objects.
	detailed is an optional parameter

	$slideshows = get_slideshows_by_user({ 'username_for' => $user, 'detailed' => 0 });

=head2  search_slideshows

	This accepts the keyword/phrase contained in slideshows and returns a reference to an array of slideshow objects.

	$slideshows = search_slideshows({ 'q' => $keyword, ... });

=head2  get_user_groups
		
	This accepts a username and returns a reference to an array of SlideShare group objects corresponding to that user.

	$gps = $ss->get_user_groups({ 'username_for' => $user, ... });

=head2  get_user_contacts

	This accepts a username and returns a reference to an array of SlideShare contact objects corresponding to that user.

	$contacts = $ss->get_user_contacts({ 'username_for' => $user, ... });

=head2  get_user_tags

	This accepts a username and returns a reference to an array of SlideShare tag objects corresponding to that user.

	$tags = $ss->get_user_tags({ 'username_for' => $user, ... });

=head1 ERROR HANDLING

If any Web Service error is encountered, then it dies with a stack backtrace and displays the error message returned. The errors may be  -

- Network connectivity errors
- API key/secret incorrect
- User/Slide not found on the system

Example error message:

SlideShare Service Error <?xml version="1.0" encoding="UTF-8"?>
<SlideShareServiceError>
  <Message ID="2">Failed User authentication</Message>
</SlideShareServiceError>

=head1 FUTURE WORK

The campaign related methods and edit/delete/upload slideshow methods are currently not supported and will be provided in future releases.

=head1 AUTHOR 

Ashish Mukherjee (ashish.mukherjee@gmail.com)

=head1 BUGS 

No known ones

=head1 COPYRIGHT

This is distributed under the same licence as the perl source code.

=head1 CREATION DATE

June 3, 2010
