#!/usr/bin/env perl

# Save WSDL and XSD files from the network into the current directory, with
# subdirectories created for the protocol (http or https), host name(s), and
# paths to the loaded documents.
#
# example usage:
#
#     $ perl save_wsdl_schema.pl <URLs of WSDL and XSD files...>

use Modern::Perl '2010';
use LWP::UserAgent;
use Path::Tiny 0.018;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::CompileX::Schema::Loader;

# create a user agent that will save content to the filesystem
my $user_agent = LWP::UserAgent->new;
$user_agent->set_my_handler( response_done => \&response_done_handler );
my $transport
    = XML::Compile::Transport::SOAPHTTP->new( user_agent => $user_agent );

# use XML::CompileX::Schema::Loader to collect WSDL and XSD files from URIs
# on the command line
my $wsdl   = XML::Compile::WSDL11->new;
my $loader = XML::CompileX::Schema::Loader->new(
    uris       => \@ARGV,
    user_agent => $user_agent,
    wsdl       => $wsdl,
);
$loader->collect_imports;

# make sure all calls compile
$wsdl->compileCalls( transport => $transport );

# LWP handler that saves content based on its path on the server
sub response_done_handler {
    my ( $response, $ua, $h ) = @_;

    my $uri  = $response->base->canonical;
    my $path = Path::Tiny->cwd->child(
        grep    {$_}
            map { $uri->abs($uri)->$_ }
            qw(scheme authority path_segments query fragment),
    );

    print STDERR 'Saving ', $response->base, " to $path...";
    $path->parent->mkpath;
    $path->spew( $response->decoded_content );
    say STDERR 'done';

    return;
}
