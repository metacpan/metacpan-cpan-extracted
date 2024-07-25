package URI::PackageURL;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp                  ();
use Exporter              qw(import);
use URI::PackageURL::Util qw(purl_to_urls purl_components_normalize);

use constant DEBUG => $ENV{PURL_DEBUG};

use overload '""' => 'to_string', fallback => 1;

our $VERSION = '2.21';
our @EXPORT  = qw(encode_purl decode_purl);

my $PURL_REGEXP = qr{^pkg:[A-Za-z\\.\\-\\+][A-Za-z0-9\\.\\-\\+]*/.+};

sub new {

    my ($class, %params) = @_;

    my $scheme     = delete $params{scheme} // 'pkg';
    my $type       = delete $params{type} or Carp::croak "Invalid Package URL: 'type' component is required";
    my $namespace  = delete $params{namespace};
    my $name       = delete $params{name} or Carp::croak "Invalid Package URL: 'name' component is required";
    my $version    = delete $params{version};
    my $qualifiers = delete $params{qualifiers} // {};
    my $subpath    = delete $params{subpath};

    return bless purl_components_normalize(
        scheme     => $scheme,
        type       => $type,
        namespace  => $namespace,
        name       => $name,
        version    => $version,
        qualifiers => $qualifiers,
        subpath    => $subpath
    ), $class;

}

sub scheme     { shift->{scheme} }
sub type       { shift->{type} }
sub namespace  { shift->{namespace} }
sub name       { shift->{name} }
sub version    { shift->{version} }
sub qualifiers { shift->{qualifiers} }
sub subpath    { shift->{subpath} }

sub encode_purl { __PACKAGE__->new(@_)->to_string }
sub decode_purl { __PACKAGE__->from_string(shift) }

sub from_string {

    my ($class, $string) = @_;

    # Strip slash / after scheme
    while ($string =~ m|^pkg:/|) {
        $string =~ s|^pkg:/|pkg:|;
    }

    if ($string !~ /$PURL_REGEXP/) {
        Carp::croak 'Malformed Package URL string';
    }

    my %components = ();


    # Split the purl string once from right on '#'
    #     The left side is the remainder
    #     Strip the right side from leading and trailing '/'
    #     Split this on '/'
    #     Discard any empty string segment from that split
    #     Discard any '.' or '..' segment from that split
    #     Percent-decode each segment
    #     UTF-8-decode each segment if needed in your programming language
    #     Join segments back with a '/'
    #     This is the subpath

    my @s1 = split('#', $string);

    if ($s1[1]) {
        $s1[1] =~ s/(^\/|\/$)//;
        my @subpath = map { _url_decode($_) } grep { $_ ne '' && $_ ne '.' && $_ ne '..' } split /\//, $s1[1];
        $components{subpath} = join '/', @subpath;
    }

    # Split the remainder once from right on '?'
    #     The left side is the remainder
    #     The right side is the qualifiers string
    #     Split the qualifiers on '&'. Each part is a key=value pair
    #     For each pair, split the key=value once from left on '=':
    #         The key is the lowercase left side
    #         The value is the percent-decoded right side
    #         UTF-8-decode the value if needed in your programming language
    #         Discard any key/value pairs where the value is empty
    #         If the key is checksums, split the value on ',' to create a list of checksums
    #     This list of key/value is the qualifiers object

    my @s2 = split(/\?/, $s1[0]);

    if ($s2[1]) {

        my @qualifiers = split('&', $s2[1]);

        foreach my $qualifier (@qualifiers) {

            my ($key, $value) = split('=', $qualifier);
            $value = _url_decode($value);

            if ($key eq 'checksums') {
                $value = [split(',', $value)];
            }

            $components{qualifiers}->{lc $key} = $value;

        }

    }


    # Split the remainder once from left on ':'
    #     The left side lowercased is the scheme
    #     The right side is the remainder

    my @s3 = split(':', $s2[0], 2);
    $components{scheme} = lc $s3[0];


    # Strip the remainder from leading and trailing '/'
    #     Split this once from left on '/'
    #     The left side lowercased is the type
    #     The right side is the remainder

    $s3[1] =~ s/(^\/|\/$)//;
    my @s4 = split('/', $s3[1], 2);
    $components{type} = lc $s4[0];


    # Split the remainder once from right on '@'
    #     The left side is the remainder
    #     Percent-decode the right side. This is the version.
    #     UTF-8-decode the version if needed in your programming language
    #     This is the version

    my @s5 = split('@', $s4[1]);
    $components{version} = _url_decode($s5[1]) if ($s5[1]);


    # Split the remainder once from right on '/'
    #     The left side is the remainder
    #     Percent-decode the right side. This is the name
    #     UTF-8-decode this name if needed in your programming language
    #     Apply type-specific normalization to the name if needed
    #     This is the name

    my @s6 = split('/', $s5[0], -1);
    $components{name} = _url_decode(pop @s6);


    # Split the remainder on '/'
    #     Discard any empty segment from that split
    #     Percent-decode each segment
    #     UTF-8-decode the each segment if needed in your programming language
    #     Apply type-specific normalization to each segment if needed
    #     Join segments back with a '/'
    #     This is the namespace

    if (@s6) {
        $components{namespace} = join '/', map { _url_decode($_) } @s6;
    }

    if (DEBUG) {
        say STDERR "-- S1: @s1";
        say STDERR "-- S2: @s2";
        say STDERR "-- S3: @s3";
        say STDERR "-- S4: @s4";
        say STDERR "-- S5: @s5";
        say STDERR "-- S6: @s6";
    }

    return $class->new(%components);

}

sub to_string {

    my $self = shift;

    my @purl = ('pkg', ':', $self->type, '/');

    # Namespace
    if ($self->namespace) {

        my @ns = map { _url_encode($_) } split(/\//, $self->namespace);
        push @purl, (join('/', @ns), '/');

    }

    # Name
    push @purl, _url_encode($self->name);

    # Version
    push @purl, ('@', _url_encode($self->version)) if ($self->version);

    # Qualifiers
    if (my $qualifiers = $self->qualifiers) {

        my @qualifiers = map { sprintf('%s=%s', lc $_, _url_encode($qualifiers->{$_})) }
            grep { $qualifiers->{$_} } sort keys %{$qualifiers};

        push @purl, ('?', join('&', @qualifiers)) if (@qualifiers);

    }

    # Subpath
    if ($self->subpath) {
        my @subpath = map { _url_encode($_) } split '/', $self->subpath;
        push @purl, ('#', join('/', @subpath));
    }

    return join '', @purl;

}

sub to_urls {
    purl_to_urls(shift);
}

sub TO_JSON {

    my $self = shift;

    return {
        type       => $self->type,
        name       => $self->name,
        version    => $self->version,
        namespace  => $self->namespace,
        qualifiers => $self->qualifiers,
        subpath    => $self->subpath,
    };

}

sub _url_encode {

    my $string = shift;

    # RFC-3986 (but exclude "/" and ":")
    $string =~ s/([^A-Za-z0-9\-._~\/:])/sprintf '%%%02X', ord $1/ge;
    return $string;

}

sub _url_decode {

    my $string = shift;
    return unless $string;

    $string =~ s/%([0-9a-fA-F]{2})/chr hex $1/ge;
    return $string;

}

1;

__END__
=head1 NAME

URI::PackageURL - Perl extension for Package URL (aka "purl")

=head1 SYNOPSIS

  use URI::PackageURL;

  # OO-interface
  
  # Encode components in Package URL string
  $purl = URI::PackageURL->new(
    type      => cpan,
    namespace => 'GDT',
    name      => 'URI-PackageURL',
    version   => '2.21'
  );
  
  say $purl; # pkg:cpan/GDT/URI-PackageURL@2.20

  # Parse Package URL string
  $purl = URI::PackageURL->from_string('pkg:cpan/GDT/URI-PackageURL@2.20');

  # exported functions

  $purl = decode_purl('pkg:cpan/GDT/URI-PackageURL@2.20');
  say $purl->type;  # cpan

  $purl_string = encode_purl(type => cpan, name => 'URI::PackageURL', version => '2.21');
  say $purl_string; # pkg:cpan/URI::PackageURL@2.20

=head1 DESCRIPTION

This module converts Package URL components to "purl" string and vice versa.

A Package URL (aka "purl") is a URL string used to identify and locate a software
package in a mostly universal and uniform way across programing languages,
package managers, packaging conventions, tools, APIs and databases.

L<https://github.com/package-url/purl-spec>

A purl is a URL composed of seven components:

    scheme:type/namespace/name@version?qualifiers#subpath

Components are separated by a specific character for unambiguous parsing.

The definition for each components is:

=over

=item * "scheme": this is the URL scheme with the constant value of "pkg".
One of the primary reason for this single scheme is to facilitate the future
official registration of the "pkg" scheme for package URLs. Required.

=item * "type": the package "type" or package "protocol" such as cpan, maven, npm,
nuget, gem, pypi, etc. Required.

=item * "namespace": some name prefix such as a Maven groupid, a Docker image
owner, a GitHub user or organization. Optional and type-specific.

=item * "name": the name of the package. Required.

=item * "version": the version of the package. Optional.

=item * "qualifiers": extra qualifying data for a package such as an OS,
architecture, a distro, etc. Optional and type-specific.

=item * "subpath": extra subpath within a package, relative to the package root.
Optional.

=back

=head2 CPAN PURL TYPE

C<cpan> is an official "purl" type (L<https://github.com/package-url/purl-spec/blob/master/PURL-TYPES.rst>)

=over

=item * The default repository is C<https://www.cpan.org/>.

=item * The C<namespace>:

=over

=item * To refer to a CPAN distribution name, the C<namespace> MUST be present.
In this case, the namespace is the CPAN id of the author/publisher.
It MUST be written uppercase, followed by the distribution name in the name component.
A distribution name MUST NOT contain the string C<::>.

=item * To refer to a CPAN module, the C<namespace> MUST be absent.
The module name MAY contain zero or more C<::> strings, and the module name MUST NOT contain a C<->

=back

=item * The C<name> is the module or distribution name and is case sensitive.

=item * The C<version> is the module or distribution version.

=item * Optional qualifiers may include:

=over

=item * C<repository_url>: CPAN/MetaCPAN/BackPAN/DarkPAN repository base URL (default is https://www.cpan.org)

=item * C<download_url>: URL of package or distribution

=item * C<vcs_url>: extra URL for a package version control system

=item * C<ext>: file extension (default is tar.gz)

=back

=back

=head3 Examples

    pkg:cpan/Perl::Version@1.013
    pkg:cpan/DROLSKY/DateTime@1.55
    pkg:cpan/DateTime@1.55
    pkg:cpan/GDT/URI-PackageURL
    pkg:cpan/LWP::UserAgent
    pkg:cpan/OALDERS/libwww-perl@6.76
    pkg:cpan/URI


=head2 FUNCTIONAL INTERFACE

They are exported by default:

=over

=item $purl_string = encode_purl(%purl_components)

Converts the given Package URL components to "purl" string. Croaks on error.

This function call is functionally identical to:

    $purl_string = URI::PackageURL->new(%purl_components)->to_string;

=item $purl_components = decode_purl($purl_string)

Converts the given "purl" string to Package URL components. Croaks on error.

This function call is functionally identical to:

    $purl = URI::PackageURL->from_string($purl_string);

=back

=head2 OBJECT-ORIENTED INTERFACE

=over

=item $purl = URI::PackageURL->new(%components)

Create new B<URI::PackageURL> instance using provided Package URL components
(type, name, version ,etc).

=item $purl->type

The package "type" or package "protocol" such as cpan, maven, npm, nuget, gem, pypi, etc.

=item $purl->namespace

Some name prefix such as a Maven groupid, a Docker image owner, a GitHub user or
organization. Optional and type-specific.

=item $purl->name

The "name" of the package.

=item $purl->version

The "version" of the package.

=item $purl->qualifiers

Extra qualifying data for a package such as an OS, architecture, a distro, etc.

=item $purl->subpath

Extra subpath within a package, relative to the package root.

=item $purl->to_string

Stringify Package URL components.

=item $purl->to_urls

Return B<download> and/or B<repository> URLs.

=item $purl->TO_JSON

Helper method for JSON modules (L<JSON>, L<JSON::PP>, L<JSON::XS>, L<Mojo::JSON>, etc).

    use Mojo::JSON qw(encode_json);

    say encode_json($purl);  # {"name":"URI-PackageURL","namespace":"GDT","qualifiers":null,"subpath":null,"type":"cpan","version":"2.20"}

=item $purl = URI::PackageURL->from_string($purl_string);

Converts the given "purl" string to Package URL components. Croaks on error.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-URI-PackageURL/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-URI-PackageURL>

    git clone https://github.com/giterlizzi/perl-URI-PackageURL.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
