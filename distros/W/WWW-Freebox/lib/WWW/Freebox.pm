package WWW::Freebox;

use 5.006;
use strict;
use warnings;
use LWP;
use LWP::Simple;
use HTTP::Request;
use HTTP::Request::Common;
use JSON;
use Digest::HMAC_SHA1 qw(hmac_sha1_hex);

=head1 NAME

WWW::Freebox - Access to FreeboxOS API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Before using this module in your script(s) you need to acquire a token and a ID.

    use WWW::Freebox;
    
    my $fbx = WWW::Freebox->new("mafreebox.freebox.fr");
    
    my $app_id = "perl.helloworld";
    my $app_name = "Perl script";
    my $app_version = "1.0";
    my $device_name = "John's computer";
    
    # You have to launch this method only once because a unique token and a unique ID are required per application.
    my ($app_token, $track_id) = $fbx->authorize($app_id, $app_name, $app_version, $device_name);
    # You need to store $app_token and $track_id (in a config file for example)
    # You will have to grant access to your application (a message will be displayed on LCD screen of the Freebox Server)

Once you've got the token and the ID you will be able to use the module as follow : 
    
    use WWW::Freebox;
    
    my $fbx = WWW::Freebox->new("mafreebox.freebox.fr");
    
    $fbx->login("perl.helloworld", $app_token, $track_id);
    
    if($fbx->{permissions}{downloader}){
    	# Doing a request to FreeboxOS API
    	my $content = [download_dir => 'path', download_file => ['file.torrent']];
    	my $jsonResponse = $fbx->request("downloads/add", 1, $content);
    }
    
You can find more informations at L<http://dev.freebox.fr/sdk/os/>.
    
=head1 METHODS

=head2 new(freebox)

    my $fbx = WWW::Freebox->new("mafreebox.freebox.fr");
    
=cut

sub new {
	my $class = shift;
	my $self = {
		freebox => shift
	};
	
	my $content = decode_json(get("http://".$self->{freebox}."/api_version") or die("Can't access to http://".$self->{freebox}."/api_version.\n"));
	$self->{uid} = $content->{"uid"};
	$self->{device_name} = $content->{"device_name"};
	$self->{device_name} =~ s/\\\//\//g;
	$self->{api_version} = $content->{"api_version"};
	$self->{api_base_url} = $content->{"api_base_url"};
	$self->{api_base_url} =~ s/\\\//\//g;
	$self->{device_type} = $content->{"device_type"};
	$self->{device_type} =~ s/\\\//\//g;
	
	$self->{api_version} =~ m/^([0-9]+)/;
	$self->{base_url} = "http://".$self->{freebox}."/api/v".$1."/";
	
	bless $self, $class;
	
	return $self;
}

=head2 $fbx->authorize(app_id, app_name, app_version, device_name)

    my ($app_token, $track_id) = $fbx->authorize("perl.helloworld", "Perl script", "1.0", "John's computer");
    
=cut

sub authorize {
	my $self = shift;
	my %authorize = (
		'app_id' => shift,
		'app_name' => shift,
		'app_version' => shift,
		'device_name' => shift,
	);
	my $content = decode_json($self->request('login/authorize/', 1, encode_json(\%authorize)));
	unless($content->{success}) {
		die("Error: ".$content->{msg}."\n");
	}
	return ($content->{result}{app_token}, $content->{result}{track_id});
}

=head2 $fbx->login($app_id, $app_token, $track_id)

    $fbx->login("perl.helloworld", $app_token, $track_id);
    
=cut

sub login {
	my $self = shift;
	$self->{app_id} = shift;
	$self->{app_token} = shift;
	$self->{track_id} = shift;
	
	my $content = decode_json(get($self->{base_url}."login/authorize/".$self->{track_id}) or die("Can't access to ".$self->{base_url}."login/authorize/".$self->{track_id}."\n"));
	if($content->{'result'}{'status'} eq "pending") {
		die("you have to grant access for this application (a message has been displayed on the LCD screen of the Freebox).\n");
	}
	unless($content->{'result'}{'status'} eq "granted") {
		die("The freebox has returned the following status: ".$content->{'result'}{'status'}.'. You should maybe try to get another app token with the function authorize($app_id, $app_name, $app_version, $device_name)'."\n");
	}
	my $challenge = $content->{'result'}{'challenge'};
	my $password_salt = $content->{'result'}{'password_salt'};
	my $password = hmac_sha1_hex($challenge, $self->{app_token});
	my %session_login = (
		'app_id' => $self->{app_id},
		'password' => $password,
	);
	my $result = decode_json($self->request('login/session/', 1, encode_json(\%session_login)));
	if($result->{'success'}){
		$self->{session_token} = $result->{'result'}{'session_token'};
		$self->{permissions} = $result->{'result'}{'permissions'};
		return 1;
	}
	else {
		print "Error: ".$result->{'msg'}."\n";
		return 0;
	}
}

=head2 $fbx->request($url, $method [, $content/@content])

    # Possible values for the second parameter (method):
    # 0: GET
    # 1: POST
    # 2: PUT
    # 3: DELETE
    
    my $jsonResponse = $fbx->request("downloads/", 0);
    
    my $content = '{"io_priority": "high","status": "stopped"}';
    my $jsonResponse = $fbx->request("downloads/16", 2, $content);
    
    my @content = [download_dir => 'path', download_file => ['file.torrent']];
    my $jsonResponse = $fbx->request("downloads/add", 1, @content);
    
=cut

sub request {
	my $self = $_[0];
	my $url = $self->{base_url}.$_[1];
	my $method = $_[2];
	my $req;
	my $content_type;
	my $content;
	
	if(defined $_[3]){
		$content = $_[3];
		if(ref($_[3]) eq "ARRAY") {
			$content_type = "form-data";
		}
		else {
			$content_type = "application/json";
		}
	}
	if($method == 0){
		$req = GET($url);
	}
	elsif($method == 1) {
		$req = POST($url, Content_Type => $content_type, Content => $content);
	}
	elsif($method == 2) {
		$req = PUT($url, Content_Type => $content_type, Content => $content);
	}
	elsif($method == 3) {
		$req = DELETE($url);
	}
	if(defined $self->{session_token}) {
		$req->header("X-Fbx-App-Auth" => $self->{session_token});
	}
	
	my $lwp = LWP::UserAgent->new;
	my $response = $lwp->request($req);
	my $json  = $response->decoded_content();
	return $json;
}

=head2 $fbx->logout()
    
    $fbx->logout();
    
=cut

sub logout {
	my $self = shift;
	$self->request("login/logout/", 1);
	undef $self->{app_id};
	undef $self->{app_token};
	undef $self->{track_id};
	undef $self->{session_token};
	undef $self->{permissions};
	return 1;
}

=head2 $fbx->close()
    
    $fbx->close();
    
=cut

sub close {
	my $self = shift;
	undef $self;
	return 1;
}

=head1 AUTHOR

Alexandre van Beurden, C<< <alexandre.vanbeurden.dev(at)gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-freebox at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Freebox>.
You can also open an issue at L<https://github.com/KiLlOrBe/PM-Freebox>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Freebox


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Freebox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Freebox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Freebox>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Freebox/>

=back

If you need help or you have any question about this module feel free to email me.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Alexandre van Beurden.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1; # End of WWW::Freebox
