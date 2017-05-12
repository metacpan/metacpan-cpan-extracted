package Test::RDF::DOAP::Version;

use 5.010;
use strict;
use utf8;

use RDF::Trine qw[iri variable literal blank statement];
use RDF::TrineX::Parser::Pretdsl;
use Test::More;
use URI::Escape qw[uri_escape];
use URI::file;

our $VERSION = '0.010';
our @EXPORT  = qw(doap_version_ok);
our $DOAP    = RDF::Trine::Namespace->new('http://usefulinc.com/ns/doap#');

use base qw[Exporter];

sub doap_version_ok
{
	my ($dist, $module) = @_;
	($module = $dist) =~ s{-}{::}g unless $module;
	
	eval "use $module";
	my $version  = $module->VERSION;
	my $dist_uri = iri(sprintf('http://purl.org/NET/cpan-uri/dist/%s/project', uri_escape($dist)));
	
	my $model = RDF::Trine::Model->temporary_model;
	
	my $turtle = RDF::Trine::Parser->new('Turtle');
	while (<meta/*.{ttl,turtle,nt}>)
	{
		my $iri = URI::file->new_abs($_);
		$turtle->parse_file_into_model("$iri", $_, $model);
	}
	
	my $rdfxml = RDF::Trine::Parser->new('RDFXML');
	while (<meta/*.{rdf,rdfxml,rdfx}>)
	{
		my $iri = URI::file->new_abs($_);
		$rdfxml->parse_file_into_model("$iri", $_, $model);
	}
	
	my $pretdsl = RDF::TrineX::Parser::Pretdsl->new;
	while (<meta/*.{pret,pretdsl}>)
	{
		my $iri = URI::file->new_abs($_);
		$pretdsl->parse_file_into_model("$iri", $_, $model);
	}
	
	my $pattern = RDF::Trine::Pattern->new(
		statement($dist_uri, $DOAP->release, variable('v')),
		statement(variable('v'), $DOAP->revision, literal($version, undef, 'http://www.w3.org/2001/XMLSchema#string')),
	);
	my $iter = $model->get_pattern($pattern);
	while (my $result = $iter->next)
	{
		pass('doap_version_ok');
		return 1;
	}
	
	$pattern = RDF::Trine::Pattern->new(
		statement($dist_uri, $DOAP->release, variable('v')),
		statement(variable('v'), $DOAP->revision, literal($version//'0')),
	);
	$iter = $model->get_pattern($pattern);
	while (my $result = $iter->next)
	{
		pass('doap_version_ok');
		return 1;
	}
	
	diag("${module}->VERSION = $version");
	$pattern = RDF::Trine::Pattern->new(
		statement($dist_uri, $DOAP->release, variable('v')),
		statement(variable('v'), $DOAP->revision, variable('r')),
	);
	$iter = $model->get_pattern($pattern);
	my $found = 0;
	while (my $result = $iter->next)
	{
		diag("Found metadata for: ".$result->as_string);
		$found++;
	}
	diag("Found no metadata for any versions.") unless $found;
	
	fail('doap_version_ok');
	return 0;
}

1;

__END__

=pod

=encoding utf-8

=for stopwords ver xsd:string

=head1 NAME

Test::RDF::DOAP::Version - tests 'meta/changes.ttl' is up to date

=head1 DESCRIPTION

=over

=item C<< doap_version_ok($dist, $module) >>

Reads all RDF in a distribution's "meta" directory and checks the
distribution metadata matches the pattern:

	?uri doap:release ?rel .
	?rel doap:revision ?ver .

Where ?uri is the URI C<< http://purl.org/NET/cpan-uri/dist/$dist/project >>
and ?ver is C<< $module->VERSION >>, as an xsd:string or plain literal.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Test-RDF-DOAP-Version>.

=head1 SEE ALSO

L<Module::Install::DOAPChangeSets>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

