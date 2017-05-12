package WebService::Futu;

use warnings;
use strict;

use LWP::UserAgent;
use JSON::XS;
use HTTP::Status qw(:constants :is status_message);
use HTTP::Cookies;

use Data::Dumper;

=head1 NAME

WebService::Futu - Perl interface to the Futu API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

 use WebService::Futu;
 
 my $ws = WebService::Futu->new(     user => 'username',
                                     pass => 'password'    );

 my $body = $ws->perform_get('/api/personal');

 my $trans = {
	date => {
		day => 12,
		month => 10,
		year => 2010
	},
	amount => 100,
	tags => {
		dir => 'out',
		how => 'platba v hotovosti',
		regularity => "b\x{11b}\x{17e}n\x{e1}",
		what => "Jidlo",
		whom => "Tesco",
		who => "",
		product => "cash",
		card => ""
	},
	note => 'Something to eat.'
 };

 $ws->perform_post('/api/transaction/', $trans));

=head1 DESCRIPTION

Library for comuniccation with Futu API.

=head1 METHODS

=over 4

=item new( [user => $username|id => $futuid], pass => $password, url => $url )

Call new() to create a new Futu object.
You have to pass username or futu id and password.

It is possible to pass base url for API queries with parameter url. (default 'http://www.futu.cz')

Example:

 my $bc = WebService::Futu->new( user => $username, 
                                     pass => $password );
=cut

sub new {
    my $class = shift;
    my %hash = @_;
	
    unless ( (defined($hash{'user'}) or defined($hash{'id'})) && defined($hash{'pass'}) ) {
        die "Must define user and pass to initialise object";
    }
	my $self;
	$self->{_user} = $hash{'user'} if exists $hash{'user'};
	$self->{_id} = $hash{'id'} if exists $hash{'id'};
	$self->{_pass} = $hash{'pass'};
	$self->{_url} = exists $hash{'url'} ? $hash{'url'} : 'https://www.futu.cz';
	
    return bless($self, $class);
}

### ERROR MESSAGES
=pod

=item error()

Returns any error messages as a string.

=cut

sub error {
    return shift->{'_error'};
}

=pod

=item perform_get()

Perform request on the server.
Automatically request authentication token.

 my $personal = $self->perform_get('/api/personal');
 
=cut

sub perform_get {
    my ($self, @other) = @_;
	return $self->_perform_auth('GET', @other);
}

=pod

=item perform_post($content)

Perform post on the server.
Automatically request authentication token.
$content is used for sending content.

 my $personal = $self->perform_post('/api/transaction/', $content);
 
=cut

sub perform_post {
    my ($self, @other) = @_;
	return $self->_perform_auth('POST', @other);
}

=pod

=item perform_put($content)

Perform put on the server.
Automatically request authentication token.
$content is used for sending content.

 my $personal = $self->perform_put('/api/transaction/123', $content);
 
=cut

sub perform_put {
    my ($self, @other) = @_;
	return $self->_perform_auth('PUT', @other);
}

=item perform_delete($content)

Perform delete on the server.
Automatically request authentication token.
$content is used for sending content.

 my $personal = $self->perform_delete('/api/transaction/123', $content);
 
=cut

sub perform_delete {
    my ($self, @other) = @_;
	return $self->_perform_auth('DELETE', @other);
}

sub _perform_auth {
    my ($self, $method, $query, $content) = @_;

	my $json_content = encode_json($content) if $content;
	my $max = 10;

	for (my $i = 0; $i < $max; $i++){
	
		my $body = $self->_perform($method, $query, $json_content); 

		# run command
    	if ($body->code eq HTTP_OK) {
        	if ($body->content){
				return decode_json($body->content)
			}else{
				return {};
			};
    	} elsif ($body->code eq HTTP_UNAUTHORIZED) {
				# make auth content
				my $auth_content = { password => $self->{_pass} };
				if ( $self->{_user} ){
					$auth_content->{email} = $self->{_user};
				}elsif( $self->{_id} ){
					$auth_content->{id} = $self->{_id};				
				}
				# auth request
				my $auth_body = $self->_perform('POST','/auth/', encode_json($auth_content));

				if ( $auth_body->code eq HTTP_OK ){
					next;
				}else{
		        	$self->{'_error'} = $body->status_line;
					return 0;
				}
		}else{
	        	$self->{'_error'} = $body->status_line;
				return 0
		}
	}

	return 0;
}

sub _perform {
    my $self    = shift;
    my $method  = shift;
    my $query   = shift;
	my $content = shift;

    my $url = $self->{'_url'}.$query;

	# user agent initialization
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new($method => $url);
	
	my $cookie_jar = HTTP::Cookies->new(
		file => "/tmp/futu_cookies.dat",
		autosave => 1,
		ignore_discard => 1
	);

	$ua->cookie_jar( $cookie_jar );
  
	# http params
    $req->header('Accept' => 'application/json');
    $req->content_type('application/json');
	if ($content){
		$req->content_length(length($content));
	    $req->content($content);
	}

    my $body = $ua->request($req);
	#print STDERR Dumper($body);

	return $body;
}



=back

=head1 AUTHOR

Vaclav Dovrtel, C<< <vaclav.dovrtel at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-futu at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Futu>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Futu


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Futu>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Futu>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Futu>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Futu/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Vaclav Dovrtel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WebService::Futu
