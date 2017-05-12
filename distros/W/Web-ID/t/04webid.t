=head1 PURPOSE

Performs as close to an end-to-end test as possible without an actual
HTTPS server.

Generates certificates for five dummy identities using
L<Web::ID::Certificate::Generator>; creates FOAF profiles for them
(using a mixture of Turtle and RDF/XML) and checks that their
certificates can be validated against their profiles.

Destroys one of the FOAF profiles and checks that the corresponding
certificate no longer validates.

Alters one of the FOAF profiles and checks that the corresponding
certificate no longer validates.

Tries its very best to clean up after itself.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.010;
use strict;

use lib 'lib';
use lib 't/lib';

use File::Temp qw();
use Path::Tiny qw();
use Test::More;
use Web::ID;
use Web::ID::Certificate::Generator;

# Attempt to silence openssl during test cases
sub capture_merged (&;@);
BEGIN {
	*capture_merged = eval { require Capture::Tiny }
		? \&Capture::Tiny::capture_merged
		: sub (&;@) { my $code = shift; $code->() }
}

require Web::ID::Util::FindOpenSSL;
-x Web::ID::Util::FindOpenSSL::find_openssl()
	or plan skip_all => "Cannot find an executable OpenSSL binary";

# They're unlikely to have /usr/bin/openssl anyway, but...
$^O eq 'MSWin32'
	and plan skip_all => "This test will not run on MSWin32";

our @PEOPLE = qw(alice bob carol david eve);
our %Certificates;

my $tmpdir = "Path::Tiny"->tempdir;
$tmpdir->mkpath;

sub tmpfile
{
	return $tmpdir->child(@_) if @_;
	return $tmpdir;
}

{
	package Test::HTTP::Server::Request;
	no strict 'refs';
	for my $p (@::PEOPLE)
	{
		*$p = sub {
			if (-e main::tmpfile($p))
			{
				shift->{out_headers}{content_type} =
					$p eq 'david' ? 'text/turtle' : 'application/rdf+xml';
				scalar main::tmpfile($p)->slurp;
			}
			else
			{
				my $server = shift;
				$server->{out_code} = '404 Not Found';
				$server->{out_headers}{content_type} = 'text/plain';
				'Not Found';
			}
		}
	}
}

eval { require Test::HTTP::Server; 1; }
        or plan skip_all => "Could not use Test::HTTP::Server: $@";

plan tests => 12;
		  
my $server  = Test::HTTP::Server->new();
my $baseuri = $server->uri;

for my $p (@PEOPLE)
{
	my $discard;
	my $rdf;
	my @captured = capture_merged {
		$Certificates{$p} = 'Web::ID::Certificate'->generate(
			passphrase        => 'secret',
			subject_alt_names => [
				Web::ID::SAN::URI->new(value => $baseuri.$p),
			],
			subject_cn        => ucfirst($p),
			rdf_output        => \$rdf,
			cert_output       => \$discard,
		)->pem
	};
	
	isa_ok($rdf, 'RDF::Trine::Model', tmpfile($p).' $rdf');
	
	RDF::Trine::Serializer
		-> new($p eq 'david' ? 'Turtle' : 'RDFXML')
		-> serialize_model_to_file(tmpfile($p)->openw, $rdf);
}

for my $p (@PEOPLE)
{
	my $webid = Web::ID->new(certificate => $Certificates{$p});
	ok($webid->valid, $webid->uri);
}

tmpfile('carol')->remove;  # bye, bye

my $carol = Web::ID->new(certificate => $Certificates{carol});
ok(!$carol->valid, 'bye, bye carol!');

do {
	(my $data = tmpfile('eve')->slurp)
		=~ s/exponent/component/g;
	my $fh = tmpfile('eve')->openw;
	print $fh $data;
};

my $eve = Web::ID->new(certificate => $Certificates{eve});
ok(!$eve->valid, 'eve is evil!');

tmpfile()->remove_tree;
