package URI::http::Dump;

use base 'URI::http';

use mro 'c3';
use feature ':5.10';

use Carp;
use MooseX::InsideOut;
use Moose::Util::TypeConstraints;
use YAML qw();

extends 'URI::http';

our $VERSION = '0.03';

use Sub::Exporter -setup => {
	exports => [ qw( mle ) ]
	, groups => [ default => [ qw( mle ) ] ]
};

has 'filename' => ( isa => 'Str', is => 'ro', default => 'url.txt' , lazy => 1);

sub new {
	my ( $name, $input ) = @_;

	confess 'No input provided' unless defined $input && length $input;

	my $uri;
	if ( ref $input eq 'HASH' ) {
		$uri = load( $input );
	}
	else {

		$uri = URI::http->new( $input );

		## If we don't have a uri
		unless ( defined $input and defined $uri and $uri eq $input ) {

			## If we have a file
			if ( -x $input ) {
				$uri = loadFile( $input );
			}

			else {
				confess "I need a valid means to create a uri\n"
			}

		}

	}

	my $self = bless $uri, $name;

	$self;

}

sub dump {
	my $self = shift;

	my @query = $self->query_form;
	my @query_w_hash;
	while ( my ( $k, $v ) = splice(@query, 0, 2) ) {
		push @query_w_hash, {$k => $v};
	}

	my $dump = {};
	$dump->{ '___SCHEME___' }    = $self->scheme;
	$dump->{ '___PORT___' }      = $self->port;
	$dump->{ '___HOST___' }      = $self->host;
	$dump->{ '___PATH___' }      = $self->path;
	$dump->{ '___QUERY___' }     = \@query_w_hash;
	$dump->{ '___CANONICAL_SRC___' } = "$self";

	YAML::Dump( $dump );

}

sub load {
	my $dump = shift;

	confess 'Non HashRef supplied to load'
		unless ref $dump eq 'HASH'
	;


	my $new = URI::http->new( $dump->{ '___CANONICAL_SRC___' } );
	$new->scheme( $dump->{ '___SCHEME___' } ) if exists $dump->{ '___SCHEME___' };
	$new->host(   $dump->{ '___HOST___'   } ) if exists $dump->{ '___HOST___' };
	$new->port(   $dump->{ '___PORT___'   } ) if exists $dump->{ '___PORT___' };
	$new->path(   $dump->{ '___PATH___'   } ) if exists $dump->{ '___PATH___' };

	if ( exists $dump->{ '___QUERY___' } ) {
		my @query;
		push @query, each %$_ foreach @{ $dump->{ '___QUERY___' } };
		$new->query_form( \@query );
	}

	$new;

}

sub dumpFile {
	my ( $self, $save ) = @_;
	YAML::DumpFile( $save, $self->dump ) or die $!;
}

sub loadFile {
	my $save = shift;
	my $dump = YAML::LoadFile( $save ) or die $!;
	load( $dump );
}

sub makeLifeEasy {
	my $self = shift;

	if ( not -e $self->filename ) {
		$self->dumpFile( $self->filename );
	}
	else {
		say loadFile( $self->filename );
	}

}

sub mle {
	my $uri = shift;

	my $self = new( __PACKAGE__, $uri );

	$self->makeLifeEasy;
}

no Moose;

## stupid pos package of shit.
package URI::http;
no strict;
no warnings;
use feature ':5.10';

sub default_port {
	my $self = shift;

	my $port;
	given ( $self->scheme ) {
		when ( 'http' ) { $port=80 }
		when ( 'https' ) { $port=443 }
	}

	$port;

}

1;

__END__

=head1 NAME

URI::http::Dump - A module to assist in the reverse engineering of URL parameters.

=head1 CAVEAT

B< This module is no longer officially supported by my standards -- though it should do what it does just fine. It violates the blackbox of URI. >

=head1 SYNOPSIS

	## Whatever you get the picture.
	use constant URI
		=> 'http://longassuri:obsecureport'
		. '/stupid_path/segments/probably/not/needed/but/there/for/fun/'
		. 'dumbFile.that.says.nothing.of.security'
		. '?Stupidquerry=HexencodedNonsense&Oth=er&cra=p'
	;

	use URI::http::Dump;
	URI::http::Dump->new( URI )->makeLifeEasy;

	perl -MURI::http::Dump -e'URI::http::Dump->new("uri")->makeLifeEasy';

	## Same as.
	perl -MURI::http::Dump -e'mle("http://google.com")'

	## Overview of process
	$ perl -MURI::http::Dump -e'mle("http://google.com")'
	$ vim url.txt ## change stuff
	$ perl -MURI::http::Dump -e'mle("http://google.com")'
	http://google.com/foobar.do?a=b
	
	$ firefox $( perl -MURI::http::Dump -e'mle("http://google.com")' ) && vim url.txt

=head1 DESCRIPTION

The simplicity of Unix is in the way it treats (most) everything like a file, and this is just a simplicity mechanism so you can treat URIs as a file too via YAML markup, ie, easily manipulate them with a text editor.

Say you're trying to reverse engineer a website for the purpose of automation and the URL that is causing annoyance has a shit ton of parameters with numerous different quirks: ie, base64 encoding, custom encoding, hexecoding nonsense, or maybe they just spelt everything in pig latin. Now, for reasons known to the reader, you need to make sense of this: this module will help you.

This module really has a small scope, and the route of action it takes depends entirely on the existance of the URI's file-store. On the first invocation, before the file-store exists, URI::http::Dump will decompile the URL provided to new() to its basic URI components and store it to a file.

On the second invocation, URI::http::Dump will compile the URI from the components in the file-store and output the URI to stdout. It will continue on this route for each subsequent invocation until the file-store is deleted. Then it will re-render the file from the arguments to constructor so you can begin the process again.

Because of the internal function of the URI module query segments encoded and unencoded in the respective steps, ie., the file will probably look more ledgable than the URI by default.

If you have deep voodoo you need to do to the URI in an automated fashion you can utilize a Moose I<around> method modifier on the C<-E<gt>load> or C<-E<gt>dump> functions.

B< All URIs must start with http:// >

B< The CANONICAL_SRC element in the dump *NEVER* changes. It is there for reference only >

=head1 EXPORT

=head2 ->mle( 'uri_string' );

Convenience functions calls C<-E<gt>new> with provided uri_string, and then calls C<-E<gt>makeLifeEasy>

=head1 METHODS

B< Beware C<-E<gt>load> and C<dump> are not inverses, C<load> takes a HashRef; C<dump> outputs yaml.>

=head2 ->new( $data )

The input to C<-E<gt>new> can be one of the following: a URI, the file's location with a YAML dump of the URI, or a HashRef in the format of the output of the C<-E<gt>dump> function.

=head2 ->dump

Returns a dump of the URI in the YAML format. Defaults to B<url.txt>.

=head2 ->dumpFile

Saves the dump of the URI in the YAML format to the file specified in C<-E<gt>filename>, which is by default B<url.txt>.

=head2 ->filename

Specifies the filename of the file-store.

=head1 CONVENIENCE FUNCTIONS

=head2 load( $hashRef )

Accepts a HashRef of the YAML file-store. Returns a new C<URI::http> representation of the HashRef.

=head2 loadFile( $fileLocation )

Accepts the YAML file-store location outputs a HashRef of the YAML file-store. This HashRef is processed by C<E<gt>load>. Returns a C<URI> representation of the file-store.

=head2 makeLifeEasy ( $url )

It will check to see if the file-store exists (url.txt), if it exists it will open the file construct the url form the components, and then dump the url the file-store composed into to STDOUT.

If the file doesn't exist, it will generate the file-store from the component.

=head1 AUTHOR

Evan Carroll, C<< <me at evancarroll.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-uri-http-dump at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-http-Dump>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc URI::http::Dump


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-http-Dump>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-http-Dump>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-http-Dump>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-http-Dump>

=back


=head1 ACKNOWLEDGEMENTS

Special thanks goes out to nothingmuch for providing emotional support and being an all around nice guy. I E<lt>3 YOU BUDDY.

=head1 COPYRIGHT & LICENSE

Copyright 2008 The man himself, Evan Carroll, no rights reserved -- have fun newbs.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
