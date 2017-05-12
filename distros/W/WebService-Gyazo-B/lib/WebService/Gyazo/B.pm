package WebService::Gyazo::B;

use strict;
use warnings;

use WebService::Gyazo::B::Image;

use LWP::UserAgent;
use LWP::Protocol::socks;
use HTTP::Request::Common;
use URI::Simple;

our $VERSION = '0.0405';

my %PROXY_PROTOCOLS = (map { $_ => 1 } qw(http https socks socks4));

sub new {
	my ($self, %args) = @_;
	$self = bless(\%args, $self);

	return $self;
}

# Get/set error message
sub error {
	return shift->{error} || 'N/A';
}

sub _error {
	my ( $self, $error_str ) = @_;
	if ( $error_str ) {
		$self->{error} = $error_str;
	}

	return $self->{error};
}

sub isError {
	return shift->{error} ? 1 : 0;
}

# Set proxy
sub setProxy {
	my ($self, $proxyStr) = @_;

	if ( !$proxyStr ) {
		$self->_error('Undefined proxy value!');
		return 0;
	}

	# If $proxyStr was passed, get protocol, ip and port from it
	my $proxyUrl = URI::Simple->new($proxyStr);

	# Check if we have protocol and host/ip from proxy string
	if ( !$proxyUrl->protocol || !$proxyUrl->host ) {
		$self->_error('Wrong proxy protocol or hostname!');
		return 0;
	}

	# Check if protocol is correct
	if ( ! exists($PROXY_PROTOCOLS{$proxyUrl->protocol})) {
		$self->_error('Wrong protocol type: ' . $proxyUrl->protocol);
		return 0;
	}

	# Check if port is correct
	if ( $proxyUrl->port && $proxyUrl->port > 65535 ) {
		$self->_error('Wrong proxy port!');
		return 0;
	}

	$self->{proxy} = sprintf("%s://%s:%s", $proxyUrl->protocol, $proxyUrl->host, $proxyUrl->port || 80);

	return 1;
}

# Assign ID
sub setId {
	my ($self, $id) = @_;

	# Check the length of ID
	if ( ! defined $id || $id !~ m#^\w{1,14}$# ) {
		$self->_error('Wrong id syntax!');
		return 0;
	}

	$self->{id} = $id;

	return 1;
}

# Upload file
sub uploadFile {
	my ($self, $filename) = @_;

	# Assign ID unless already assigned
	$self->{id} ||= time();

	# Check if file path was passed
	if ( ! defined $filename ) {
		$self->_error('File parameter was not specified or is undef!');
		return 0;
	}

	# Check if it is a file
	if ( ! -f $filename ) {
		$self->_error('File parameter to uploadFile() was not found!');
		return 0;
	}

	# Check if file is readable
	if ( ! -r $filename) {
		$self->error('The file parameter to uploadFile() is not readable!');
		return 0;
	}

	# Create user agent object
	$self->{ua} = LWP::UserAgent->new('agent' => 'Gyazo/'.$VERSION) unless (defined $self->{ua});

	# Assign proxy if it was passed
	$self->{ua}->proxy(['http'], $self->{proxy}.'/') if ($self->{proxy});

	# Create object for POST-request
	my $req = POST('https://gyazo.com/upload.cgi',
		'Content_Type' => 'form-data',
		'Content' => [
			'id' => $self->{id},
			'imagedata' => [$filename],
		]
	);

	# Send POST-request and check the response
	my $res = $self->{ua}->request($req);
	if ( my ($id) = ($res->content) =~ m#https://gyazo.com/(\w+)#is ) {
		return WebService::Gyazo::B::Image->new(id => $id);
	} else {
		$self->_error("Cannot parsed URL in the:\n".$res->as_string."\n");
		return 0;
	}
}

1;

__END__

=pod

=head1 NAME

WebService::Gyazo::B - a Perl image upload library for gyazo.com

=head1 VERSION

version 0.0405

=head1 SYNOPSIS

	use WebService::Gyazo::B;

	my $newUserId = time();

	my $upAgent = WebService::Gyazo::B->new(id => $newUserId);
	print "Set user id [".$newUserId."]\n";

	my $image = $upAgent->uploadFile('1.jpg');

	unless ($upAgent->isError) {
		print "Image uploaded [".$image->getImageUrl()."]\n";
	} else {
		print "Error:\n".$upAgent->error()."\n\n";
	}

=head1 DESCRIPTION

B<WebService::Gyazo::B> helps you to upload images to gyazo.com (via regular expressions and LWP).

It is a fork of L<WebService::Gyazo> by Shlomi Fish, which was done to make
the deployment of some code he has written for a commission easier.

=head1 METHODS

=head2 C<new>

	my $userID = time();
	my $wsd = WebService::Gyazo::B->new(id => $userID);

Constructs a new C<WebService::Gyazo::B> object.
Parameter id is optional, if the parameter is not passed, it will take the value of the time() function.

=head2 C<setProxy>

	my $proxy = 'http://1.2.3.4:8080';
	if ($wsd->setProxy($proxy)) {
		print "The proxy [$proxy] was set!";
	} else {
		print "The proxy was not set! Error [".$wsd->error."]";
	}

Set the proxy C<1.2.3.4:8080> and the protocol http for the C<LWP::UserAgent>
object.

=head2 C<error>

	print "Error [".$wsd->error."]" if ($wsd->isError);

This method return text of last error.

=head2 C<isError>

	print "Error [".$wsd->error."]" if ($wsd->isError);

This method return 1 if $wsd->{error} not undef, else return 0.

=head2 C<setId>

	my $newUserId = time();
	if ($wsd->setId($newUserId)) {
		print "User id [".$newUserId."] seted!";
	} else {
		print "User id not seted! Error [".$wsd->error."]";
	}

This method set new gyazo user id.

=head2 C<uploadFile>

	my $result = $upAgent->uploadFile('1.jpg');

	if (defined($result) and !$upAgent->isError) {
		print "Returned result[".$result->getImageUrl()."]\n";
	} else {
		print "Error:\n".$upAgent->error()."\n\n";
	}

This metod return object WebService::Gyazo::B::Image.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Gyazo::B

=head1 SEE ALSO

L<WebService::Gyazo::B::Image>, L<LWP::UserAgent>.

=head1 AUTHOR

Modified by Shlomi Fish, 2015 (L<http://www.shlomifish.org/>) while
disclaiming all rights.

SHok, <shok at cpan.org> (L<http://nig.org.ua/>)

=head1 COPYRIGHT

Copyright 2013-2014 by SHok

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by SHok.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Gyazo-B or by email to
bug-webservice-gyazo-b@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc WebService::Gyazo::B

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/WebService-Gyazo-B>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/WebService-Gyazo-B>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WebService-Gyazo-B>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/WebService-Gyazo-B>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/WebService-Gyazo-B>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/WebService-Gyazo-B>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/WebService-Gyazo-B>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/W/WebService-Gyazo-B>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=WebService-Gyazo-B>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=WebService::Gyazo::B>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-webservice-gyazo-b at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=WebService-Gyazo-B>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/WebService--Gyazo>

  git clone https://github.com/shlomif/WebService--Gyazo.git

=cut
