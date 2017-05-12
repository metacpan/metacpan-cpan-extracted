package Web::ID::Certificate::Generator;

use 5.010;
use utf8;

BEGIN {
	$Web::ID::Certificate::Generator::AUTHORITY = 'cpan:TOBYINK';
	$Web::ID::Certificate::Generator::VERSION   = '1.927';
}

use Moose::Util qw(apply_all_roles);
use File::Temp qw();
use Path::Tiny qw(path);
use RDF::Trine qw(statement blank iri literal);
use Web::ID::Certificate;
use Web::ID::Types -types;
use Web::ID::Util;

use Moose::Role;
use namespace::sweep;

sub import
{
	apply_all_roles("Web::ID::Certificate", __PACKAGE__);
}

sub _openssl_path
{
	require Web::ID::Util::FindOpenSSL;
	path( Web::ID::Util::FindOpenSSL::find_openssl() );
}

sub generate
{
	my ($class, %options) = @_;
	
	my $openssl    = (delete $options{openssl_path}) // $class->_openssl_path;
	my $passphrase = (delete $options{passphrase})
		or confess "need to provide passphrase option";
	my $key_size   = (delete $options{key_size}) // 1024;
	my $sans       = (delete $options{subject_alt_names})
		or confess "need to provide subject_alt_names option";
	my $not_after  = (delete $options{not_after});
	my $dest       = (delete $options{cert_output})
		or confess "need to provide cert_output option";
	my $rdf_sink   = (delete $options{rdf_output})
		or confess "need to provide rdf_output option";
	
	my %subject = (
		C    => delete $options{subject_country},
		ST   => delete $options{subject_region},
		L    => delete $options{subject_locality},
		O    => delete $options{subject_org},
		CN   => delete $options{subject_cn},
	);
	
	confess "need to provide subject_cn option" unless $subject{CN};
	
	confess "unsupported options: ".(join q(, ), sort keys %options) if %options;
	
	my $days = $not_after
		? $not_after->delta_days( DateTime->coerce('now') )->days
		: 365;
	
	my $tempdir = path( File::Temp->newdir );
	$tempdir->mkpath;
	
	my $config = $tempdir->child('openssl.cnf')->openw;
	say $config $_ for
		q([req]),
		q(default_bits = 1024),
		q(default_keyfile = privkey.pem),
		q(distinguished_name = req_distinguished_name),
		q(x509_extensions = v3_ca),
		q(prompt = no),
		q(),
		q([v3_ca]);
	
	say $config
		q(subjectAltName = ) .
		join q(,),
		map {
			my $value = $_->value;
			my $type = {
				rfc822Name                => 'email',
				uniformResourceIdentifier => 'URI',
			}->{ $_->type };
			$type ? (join q(:), $type, $value) : ();
		} @$sans;
	
	say $config $_ for
		q(),
		q([req_distinguished_name]);
	
	foreach (qw(C ST L O CN))
	{
		next unless (defined $subject{$_} and length $subject{$_});
		say $config "$_ = ", $subject{$_};
	}
	
	close $config;
	
	system(
		$openssl,
		"req",
		"-newkey"  => "rsa:".$key_size,
		"-x509",
		"-days"    => $days,
		"-config"  => $tempdir->child('openssl.cnf'),
		"-out"     => $tempdir->child('cert.pem'),
		"-keyout"  => $tempdir->child('privkey.pem'),
		"-passout" => "pass:".$passphrase,
	);
	
	system(
		$openssl,
		"pkcs12",
		"-export",
		"-in"      => $tempdir->child('cert.pem'),
		"-inkey"   => $tempdir->child('privkey.pem'),
		"-out"     => $tempdir->child('cert.p12'),
		"-name"    => sprintf('%s <%s>', ($subject{CN}//'Unnamed'), $sans->[0]->value), 
		"-passin"  => "pass:".$passphrase,
		"-passout" => "pass:".$passphrase,
	);
	
	if (ref $dest eq 'SCALAR')
	{
		$$dest = $tempdir->child('cert.p12')->slurp;
	}
	elsif (ref $dest =~ m/^IO/)
	{
		my $p12 = $tempdir->child('cert.p12')->slurp;
		print $dest $p12;
	}
	else
	{
		my $p12 = $tempdir->child('cert.p12')->slurp;
		my $fh  = path($dest)->openw;
		print $fh $p12;
	}
	
	my ($on_triple, $on_done) = (sub {}, sub {});
	if (ref $rdf_sink eq 'SCALAR')
	{
		$$rdf_sink = Model->new;
		$on_triple = sub { $$rdf_sink->add_statement(statement(@_)) };
	}
	elsif (blessed($rdf_sink) and $rdf_sink->isa('RDF::Trine::Model'))
	{
		$on_triple = sub { $rdf_sink->add_statement(statement(@_)) };
	}
	else
	{
		my $model = Model->new;
		my $fh    = path($rdf_sink)->openw;
		$on_triple = sub { $model->add_statement(statement(@_)) };
		$on_done   = sub { "RDF::Trine::Serializer"->new('RDFXML')->serialize_model_to_file($fh, $model) };
	}
	
	my $pem  = $tempdir->child('cert.pem')->slurp;
	my $cert = $class->new(pem => $pem);
	
	my $hex = sub {
		(my $h = shift->as_hex) =~ s/^0x//;
		$h;
	};
	
	my $k = blank();
	$on_triple->($k, u('rdf:type'), u('cert:RSAPublicKey'));
	$on_triple->($k, u('cert:modulus'), literal($cert->modulus->$hex, undef, uu('xsd:hexBinary')));
	$on_triple->($k, u('cert:exponent'), literal($cert->exponent->bstr, undef, uu('xsd:integer')));
	foreach my $san (@$sans)
	{
		next unless $san->type eq 'uniformResourceIdentifier';
		$on_triple->(iri($san->value), u('cert:key'), $k);
	}
	$on_done->();
	
	$tempdir->remove_tree;
	
	return $cert;
}

__PACKAGE__
__END__

=head1 NAME

Web::ID::Certificate::Generator - role for Web::ID::Certificate

=head1 SYNOPSIS

 use Web::ID::Certificate::Generator;
 
 my %options = (
   cert_output       => '/home/alice/webid.p12',
   passphrase        => 's3cr3t s0urc3',
   rdf_output        => '/home/alice/public_html/foaf.rdf',
   subject_alt_names => [
     Web::ID::SAN::URI->new(
       value => 'http://example.com/~alice/foaf.rdf#me',
     ),
     Web::ID::SAN::Email->new(
       value => 'alice@example.com',
     ),
   ],
   subject_name      => 'Alice Jones',
   subject_locality  => 'Lewes',
   subject_region    => 'East Sussex',
   subject_country   => 'GB',   # ISO 3166-1 alpha-2 code
 );
 
 my $cert = Web::ID::Certificate->generate(%options);

=head1 DESCRIPTION

This is a role that may be applied to L<Web::ID::Certificate>. It is not
consumed by Web::ID::Certificate by default as I was trying to avoid
tainting the class with the horror that's found in this role.

The C<import> routine of this package applies the role to
Web::ID::Certificate, so it is sufficient to do:

 use Web::ID::Certificate::Generator;

You don't need to muck around with C<apply_all_roles> yourself.

=head2 Constructor

=over

=item C<< generate(%options) >>

Generates a brand new WebID-enabled certificate.

=back

=head2 Options

The following options can be passed to C<generator>

=over

=item * C<cert_output>

A passphrase-protected PKCS12 certificate file is generated as part of
the certificate generation process. The PKCS12 file is what you'd
typically import into a browser.

You can pass a scalar reference, in which case the PKCS12 data will be
written to that scalar; or a file handle or string file name.

This is a required option.

=item * C<passphrase>

The password for the PKCS12 file.

This is a required option.

=item * C<rdf_output>

RDF data is also generated as part of the certificate generation
process.

Again a file handle or string file name can be passed, or an
L<RDF::Trine::Model>.

This is a required option.

=item * C<subject_alt_names>

List of L<Web::ID::SAN> objects to generate the certificate's
subjectAltNames field. You want at least one L<Web::ID::SAN::URI>
in there.

This is a required option.

=item * C<subject_name>

The name of the person who will hold the certificate. (e.g. "Alice
Smith".)

This is a required option.

=item * C<subject_org>

The certificate holder's organisation.

Not required.

=item * C<subject_locality>

The locality (e.g. city) of the certificate holder's address.

Not required.

=item * C<subject_region>

The region (e.g. state or county) of the certificate holder's address.

Not required.

=item * C<subject_country>

Two letter ISO code for the country of the certificate holder's address.

Not required.

=item * C<openssl_path>

The path to the OpenSSL binary. Yes that's right, this role calls the
OpenSSL binary via C<system> calls. Defaults to automatic discovery
via L<Web::ID::Util::FindOpenSSL>.

=item * C<key_size>

Key size in bits. Defaults to 1024. Bigger keys are more secure. Keys
bigger than 2048 bits will take a ridiculously long time to generate.
Keys less than 512 bits are pretty poor.

=item * C<not_after>

Date when the certificate should expire, as a L<DateTime> object.
Defaults to 365 days.

=back

=head1 BUGS AND LIMITATIONS

Generating the private key results in shedloads of nasty crud being spewed
out on STDERR.

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-ID>.

=head1 SEE ALSO

L<Web::ID>,
L<Web::ID::Certificate>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

