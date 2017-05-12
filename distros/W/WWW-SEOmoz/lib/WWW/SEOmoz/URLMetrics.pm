# ABSTRACT: Class to represent the URL metrics returned from the SEOmoz API.
package WWW::SEOmoz::URLMetrics;

use Moose;
use namespace::autoclean;

use Carp qw( croak );

our $VERSION = '0.03'; # VERSION


has 'title' => (
    isa      => 'Str|Undef',
    is       => 'ro',
);


has 'url' => (
    isa      => 'Str|Undef',
    is       => 'ro',
);


has 'external_links' => (
    isa      => 'Num|Undef',
    is       => 'ro',
);


has 'links' => (
    isa      => 'Num|Undef',
    is       => 'ro',
);


has 'mozrank' => (
    isa      => 'Num|Undef',
    is       => 'ro',
);


has 'mozrank_raw' => (
    isa      => 'Num|Undef',
    is       => 'ro',
);


has 'subdomain_mozrank' => (
    isa      => 'Num|Undef',
    is       => 'ro',
);


has 'subdomain_mozrank_raw' => (
    isa      => 'Num|Undef',
    is       => 'ro',
);


has 'http_status_code' => (
    isa      => 'Int|Undef',
    is       => 'ro',
);


has 'page_authority' => (
    isa      => 'Num|Undef',
    is       => 'ro',
);


has 'domain_authority' => (
    isa      => 'Num|Undef',
    is       => 'ro',
);


has 'subdomain' => (
    isa     => 'Str|Undef',
    is      => 'ro',
);


has 'rootdomain' => (
    isa     => 'Str|Undef',
    is      => 'ro',
);


has 'subdomain_external_links' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'rootdomain_external_links' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'juicepassing_links' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'subdomain_linking' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'rootdomain_linking' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'subdomain_subdomains_linking' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'rootdomain_rootdomains_linking' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'rootdomain_mozrank' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'rootdomain_mozrank_raw' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'moztrust' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'moztrust_raw' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'subdomain_moztrust' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'subdomain_moztrust_raw' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'rootdomain_moztrust' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'rootdomain_moztrust_raw' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'external_mozrank' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'external_mozrank_raw' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'subdomain_external_juice' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'subdomain_external_juice_raw' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'rootdomain_external_juice' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);

has 'rootdomain_external_juice_raw' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'subdomain_juice' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'subdomain_juice_raw' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'rootdomain_juice' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'rootdomain_juice_raw' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'links_subdomain' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'links_rootdomain' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);


has 'rootdomains_links_subdomain' => (
    isa     => 'Num|Undef',
    is      => 'ro',
);
__PACKAGE__->meta->make_immutable;


sub new_from_data {
    my $class = shift;
    my $data  = shift || croak 'Requires a hash ref of data returned from the API';

    return $class->new({
        title                   => $data->{ut},
        url                     => $data->{uu},
        external_links          => $data->{ueid},
        links                   => $data->{uid},
        mozrank_raw             => $data->{umrr},
        mozrank                 => $data->{umrp},
        subdomain_mozrank       => $data->{fmrp},
        subdomain_mozrank_raw   => $data->{fmrr},
        http_status_code        => $data->{us},
        page_authority          => $data->{upa},
        domain_authority        => $data->{pda},

        ## NON-FREE API VALUES
        subdomain                       => $data->{ufq},
        rootdomain                      => $data->{upl},
        subdomain_external_links        => $data->{feid},
        rootdomain_external_links       => $data->{peid},
        juicepassing_links              => $data->{ujid},
        subdomain_linking               => $data->{uifq},
        rootdomain_linking              => $data->{uipl},
        subdomain_subdomains_linking    => $data->{fid},
        rootdomain_rootdomains_linking  => $data->{pid},
        rootdomain_mozrank              => $data->{pmrp},
        rootdomain_mozrank_raw          => $data->{pmrr},
        moztrust                        => $data->{utrp},
        moztrust_raw                    => $data->{utrr},
        subdomain_moztrust              => $data->{ftrp},
        subdomain_moztrust_raw          => $data->{ftrr},
        rootdomain_moztrust             => $data->{ptrp},
        rootdomain_moztrust_raw         => $data->{ptrr},
        external_mozrank                => $data->{uemrp},
        external_mozrank_raw            => $data->{uemrr},
        subdomain_external_juice        => $data->{uemrp},
        subdomain_external_juice_raw    => $data->{uemrr},
        rootdomain_external_juice       => $data->{pejp},
        rootdomain_external_juice_raw   => $data->{pejr},
        subdomain_juice                 => $data->{fjp},
        subdomain_juice_raw             => $data->{fjr},
        rootdomain_juice                => $data->{pjp},
        rootdomain_juice_raw            => $data->{pjr},
        links_subdomain                 => $data->{fuid},
        links_rootdomain                => $data->{puid},
        rootdomains_links_subdomain     => $data->{fipl},
    });
}


1;

__END__
=pod

=head1 NAME

WWW::SEOmoz::URLMetrics - Class to represent the URL metrics returned from the SEOmoz API.

=head1 VERSION

version 0.03

=head1 DESCRIPTION

Class to represent the URL metrics data returned from the 'url-metrics' method
in the SEOmoz API.

=head1 ATTRIBUTES

=head2 title

=head2 url

=head2 external_links

=head2 links

=head2 mozrank

=head2 mozrank_raw

=head2 subdomain_mozrank

=head2 subdomain_mozrank_raw

=head2 http_status_code

=head2 page_authority

=head2 domain_authority

=head2 subdomain

=head2 rootdomain

=head2 subdomain_external_links

=head2 rootdomain_external_links

=head2 juicepassing_links

=head2 subdomain_linking

=head2 rootdomain_linking

=head2 subdomain_subdomains_linking

=head2 rootdomain_rootdomains_linking

=head2 rootdomain_mozrank

=head2 rootdomain_mozrank_raw

=head2 moztrust

=head2 moztrust_raw

=head2 subdomain_moztrust

=head2 subdomain_moztrust_raw

=head2 rootdomain_moztrust

=head2 rootdomain_moztrust_raw

=head2 external_mozrank

=head2 external_mozrank_raw

=head2 subdomain_external_juice

=head2 subdomain_external_juice_raw

=head2 rootdomain_external_juice

=head2 rootdomain_external_juice_raw

=head2 subdomain_juice

=head2 subdomain_juice_raw

=head2 rootdomain_juice

=head2 rootdomain_juice_raw

=head2 links_subdomain

=head2 links_rootdomain

=head2 rootdomains_links_subdomain

=head1 METHODS

=head2 new_from_data

    my $metrics = WWW::SEOmoz::URLMetrics->( $data );

Returns a new L<WWW::SEOmoz::URLMetrics> object from the data returned from the API
call.

=head1 SEE ALSO

L<WWW::SEOmoz>

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

