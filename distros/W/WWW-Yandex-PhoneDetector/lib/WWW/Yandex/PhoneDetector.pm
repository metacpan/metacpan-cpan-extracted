package WWW::Yandex::PhoneDetector;
use strict;
use LWP::UserAgent;
use URI::Escape;
use XML::LibXML;

# Version
use vars qw($VERSION);
$VERSION = '1.07';

# Constants
use constant PHD_HOST=>'http://phd.yandex.net/detect';


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless($self, $class);
	$self->{'ua'} = LWP::UserAgent->new();
	$self->{'ua'}->agent('Mozilla/5.0 (compatible; WWW::Yandex::PhoneDetector/'+$VERSION+'; +http://search.cpan.org/~kostya/WWW-Yandex-PhoneDetector/lib/WWW/Yandex/PhoneDetector.pm)');
	$self->{'params'} = [];
	$self->{'is_error'} = '';
	$self->{'is_phone'} = '';
	$self->{'details'} = {};
	return $self;
}


sub lwp_user_agent {
	my $self = shift;
	my $agent = shift || 'Mozilla/5.0 (compatible; WWW::Yandex::PhoneDetector/'+$VERSION+'; +http://search.cpan.org/~kostya/WWW-Yandex-PhoneDetector/lib/WWW/Yandex/PhoneDetector.pm)';
	$self->{'ua'}->agent($agent);
}

sub lwp_timeout {
	my $self = shift;
	my $timeout = shift || 10;
	$self->{'ua'}->timeout($timeout);
}

sub profile {
	my $self = shift;
	my $data = shift;
	if($data){
		$data = uri_escape($data);
		push(@{$self->{'params'}}, "profile=$data");
	}
}

sub wap_profile {
	my $self = shift;
	my $data = shift;
	if($data){
		$data = uri_escape($data);
		push(@{$self->{'params'}}, "wap-profile=$data");
	}
}

sub x_wap_profile {
	my $self = shift;
	my $data = shift;
	if($data){
		$data = uri_escape($data);
		push(@{$self->{'params'}}, "x-wap-profile=$data");
	}
}

sub user_agent {
	my $self = shift;
	my $data = shift;
	if($data){
		$data = uri_escape($data);
		push(@{$self->{'params'}}, "user-agent=$data");
	}
}

sub x_operamini_phone_ua {
	my $self = shift;
	my $data = shift;
	if($data){
		$data = uri_escape($data);
		push(@{$self->{'params'}}, "x-operamini-phone-ua=$data");
	}
}

sub is_phone {
	my $self = shift;
	return $self->{'is_phone'};
}

sub is_error {
	my $self = shift;
	return $self->{'is_error'};
}

sub details {
	my $self = shift;
	return $self->{'details'};
}

sub flush {
	my $self = shift;
	$self->{'params'} = [];
	$self->{'is_error'} = '';
	$self->{'is_phone'} = '';
	$self->{'details'} = {};
	return;
}


sub get {
	my $self = shift;
	my $data = shift;
	my $uri = join("&",@{$self->{'params'}});
	my %hash;

	if($uri){
		my $request = HTTP::Request->new(GET=>PHD_HOST.'?'.$uri);
		my $response = $self->{'ua'}->request($request);

		if($response->status_line ne '200 OK'){
			$self->{'is_error'} = 'Server Status '.$response->status_line;
			return;
		}

		my $xml = $response->content if($response->is_success);
		my $dom = XML::LibXML->load_xml(string=>$xml);

		foreach my $node (@{$dom->getElementsByTagName('yandex-mobile-info-error')}){
			$self->{'is_error'} = $node->textContent;
			return;
		}

		foreach my $node (@{$dom->getElementsByTagName('yandex-mobile-info')}){
			$self->{'is_phone'} = 1;

			foreach my $node (@{$node->childNodes()}){
				if($node->nodeType == 1 and !($node->nodeName eq 'java')){
					$hash{$node->nodeName} = $node->textContent if($node->textContent);
				}

				if($node->nodeName eq 'java'){
					foreach my $node (@{$node->childNodes()}){
						if($node->nodeType == 1){
							$hash{'java'}{$node->nodeName} = $node->textContent if($node->textContent);
						}
					}
				}
			}
		}
		$self->{'details'} = \%hash;
		return;
	}
	else{
		$self->{'is_error'} = 'Invalid URL!';
	}

	return;
}


1;
__END__



=head1 NAME

WWW::Yandex::PhoneDetector - Detector mobile phone

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict;
	use WWW::Yandex::PhoneDetector;
	use Data::Dumper;

	my $phone_detector = WWW::Yandex::PhoneDetector->new();
	$phone_detector->user_agent('BlackBerry9700/5.0.0.351 Profile/MIDP-2.1 Configuration/CLDC-1.1 VendorID/123');
	$phone_detector->get();

	if($phone_detector->is_error){
		print $phone_detector->is_error();
		$phone_detector->flush();
		exit;
	}

	if($phone_detector->is_phone){
		print "yes mobile phone!\n"
		print "details mobile phone!\n"
		print Dumper $phone_detector->details();
		$phone_detector->flush();
	}


=head1 METHODS

=head2 C<user_agent>

	$phone_detector->user_agent('BlackBerry9700/5.0.0.351 Profile/MIDP-2.1 Configuration/CLDC-1.1 VendorID/123');

UserAgent your customers


=head2 C<get>

	$phone_detector->get();

Requires data from server


=head2 C<is_phone>

	$phone_detector->is_phone();

Returns 1 if a mobile phone


=head2 C<is_error>

	$phone_detector->is_error()

Returns the string with an error


=head2 C<flush>

	$phone_detector->flush()

Cleans internal buffer


=head2 C<details>

	$phone_detector->details();

Returns the hash detail phone


=head2 C<profile>

	$phone_detector->profile('');

If the http header is present "profile" send it with help of this method


=head2 C<wap_profile>

	$phone_detector->wap_profile('');

If the http header is present "wap-profile" send it with help of this method


=head2 C<x_wap_profile>

	$phone_detector->x_wap_profile('');

If the http header is present "x-wap-profile" send it with help of this method


=head2 C<x_operamini_phone_ua>

	$phone_detector->x_operamini_phone_ua('');

Additional title passed to the browser Opera Mini. Usually contains the full-browser version of mobile device.


=head1 AUTHOR

Kostya Ten, E<lt>kostya@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Kostya Ten

=cut
