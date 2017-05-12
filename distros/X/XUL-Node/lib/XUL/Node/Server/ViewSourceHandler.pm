package XUL::Node::Server::ViewSourceHandler;

use strict;
use warnings;
use Carp;
use HTTP::Status;
use POE::Component::Server::HTTPServer::Handler;
use XUL::Node::Application;

use base 'POE::Component::Server::HTTPServer::Handler';

sub handle {
	my ($self, $context) = @_;
	my %request  = $context->{request}->uri->query_form;
	my $response = $context->{response};
	my ($content, $code);
	eval {
		my $name = $request{name};
		croak "no name given" unless $name;

		my $package = XUL::Node::Application->application_to_package($name);
		XUL::Node::Application->runtime_use($package);
		($package .= '.pm') =~ s|::|/|g;
		my $file = $INC{$package};
		croak "file not found for [$package]" unless $file;

		open F, $file or die "can't open source file [$file]: $!";
		$content = join '', <F>;
		for ($content) {
			s/\t/   /g;
			s/&/&amp;/g;
			s/</&lt;/g;
			s/>/&gt;/g;
		}
		
		close F;

		$code = RC_OK;
	};
	if ($@) {
		$content = 'cannot show source';
		$code    = RC_INTERNAL_SERVER_ERROR;
	}
	for ($response) {
		$_->code($code);
		$_->content_type('text/html');
		$_->content_encoding('UTF-8');
		$_->content("<html><pre>$content</pre></html>");
	}
	return H_FINAL;
}

1;
