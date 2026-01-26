package URI::PackageURL::Type;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp           ();
use File::Basename qw(dirname);
use File::Spec;
use JSON::PP   qw(decode_json);
use List::Util qw(first);

use constant DEBUG => $ENV{PURL_DEBUG};

our $VERSION = '2.24';


my %ALGO_LENGTH = ('md5' => 32, 'sha1' => 40, 'sha256' => 64, 'sha384' => 96, 'sha512' => 128);

my %CACHE = ();

sub new {

    my ($class, $type) = @_;

    Carp::croak 'Missing PURL type' unless $type;

    $type = lc $type;

    my $self = {type => $type, definition => _load_definition($type) || {}};

    return bless $self, $class;

}

sub definition_dir { File::Spec->catfile(dirname(__FILE__), 'types') }

sub _file_content {

    my $path = shift;

    return unless -e $path;

    open my $fh, '<', $path or Carp::croak "Can't open file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    return $content;

}

sub _load_definition {

    my $purl_type = shift;

    return $CACHE{$purl_type} if defined $CACHE{$purl_type};

    my $content = _file_content(File::Spec->catfile(definition_dir, "$purl_type-definition.json"));
    return unless $content;

    DEBUG and say STDERR "-- Loaded '$purl_type' definition schema";

    my $data = eval { decode_json($content) };
    Carp::croak "Failed to decode '$purl_type' PURL type definition: $@" if $@;

    $CACHE{$purl_type} = $data;
    return $data;

}

sub definition { shift->{definition} }

sub _property {

    my ($self, $property, $sub_property) = @_;

    return unless $self->definition;

    return $self->definition->{$property} unless defined $sub_property;
    return $self->definition->{$property}->{$sub_property};

}

sub schema_id              { shift->_property('$id') }
sub type_name              { shift->_property('type_name') }
sub description            { shift->_property('description') }
sub default_repository_url { shift->_property('repository', 'default_repository_url') }
sub examples               { shift->_property('examples') || [] }
sub repository             { shift->_property('repository') }
sub note                   { shift->_property('note') }
sub reference_urls         { shift->_property('reference_urls') }

sub namespace_definition  { shift->component_definition('namespace') }
sub name_definition       { shift->component_definition('name') }
sub version_definition    { shift->component_definition('version') }
sub qualifiers_definition { shift->component_definition('qualifiers') || [] }
sub subpath_definition    { shift->component_definition('subpath') }

sub component_have_definition      { defined shift->component_definition(shift) }
sub component_definition           { shift->_property(shift . '_definition') }
sub component_case_sensitive       { shift->_property(shift . '_definition', 'case_sensitive') }
sub component_is_case_sensitive    { shift->component_case_sensitive(shift) == 1 }
sub component_is_optional          { shift->component_requirement(shift) eq 'optional' }
sub component_is_prohibited        { shift->component_requirement(shift) eq 'prohibited' }
sub component_is_required          { shift->component_requirement(shift) eq 'required' }
sub component_native_name          { shift->_property(shift . '_definition', 'native_name') }
sub component_normalization_rules  { shift->_property(shift . '_definition', 'normalization_rules') || [] }
sub component_note                 { shift->_property(shift . '_definition', 'note') }
sub component_permitted_characters { shift->_property(shift . '_definition', 'permitted_characters') }
sub component_requirement          { shift->_property(shift . '_definition', 'requirement') }

sub normalize {

    my $self = shift;

    my %components = (
        type       => undef,
        namespace  => undef,
        name       => undef,
        version    => undef,
        version    => undef,
        qualifiers => {},
        subpath    => undef,
        @_
    );

    # Common normalizations
    $components{type} = lc $components{type};

    if (grep { $_ eq $components{type} } qw(alpm apk bitbucket composer deb github gitlab hex npm oci pypi)) {
        $components{name} = lc $components{name};
    }

    if (defined $components{namespace}) {

        if (grep { $_ eq $components{type} } qw(alpm apk bitbucket composer deb github gitlab golang hex rpm)) {
            $components{namespace} = lc $components{namespace};
        }

        # The namespace is the CPAN id of the author/publisher. It MUST be written uppercase and is required.

        if ($components{type} eq 'cpan') {
            $components{namespace} = uc $components{namespace};
        }

    }

    # Force checksum into ARRAY
    if (defined $components{qualifiers}->{checksum} and ref $components{qualifiers}->{checksum} ne 'ARRAY') {
        $components{qualifiers}->{checksum} = [$components{qualifiers}->{checksum}];
    }

    # PURL type specific normalization
TYPE: for ($components{type}) {

        if (/huggingface/) {

            # The version is the model revision Git commit hash. It is case insensitive and
            # must be lowercased in the package URL.

            $components{version} = lc $components{version};
            last TYPE;
        }

        if (/mlflow/) {

            # The "name" case sensitivity depends on the server implementation:
            #   - Azure ML: it is case sensitive and must be kept as-is in the package URL.
            #   - Databricks: it is case insensitive and must be lowercased in the package URL.

            last TYPE unless $components{qualifiers}->{repository_url};

            if ($components{qualifiers}->{repository_url} =~ /azuredatabricks/) {
                $components{name} = lc $components{name};
            }
            last TYPE;
        }

        if (/pypi/) {

            # A PyPI package name must be lowercased and underscore "_" replaced with a dash "-".
            $components{name} =~ s/_/-/g;
            last TYPE;
        }

        if (/cpan/) {
            if (defined $components{qualifiers}->{author}) {
                # CPAN ID. It MUST be written uppercase.
                $components{qualifiers}->{author} = uc $components{qualifiers}->{author};
            }
            last TYPE;
        }

    }

    return wantarray ? %components : \%components;

}

sub validate {

    my $self = shift;

    my %components = (
        type       => undef,
        namespace  => undef,
        name       => undef,
        version    => undef,
        version    => undef,
        qualifiers => {},
        subpath    => undef,
        @_
    );

    my $purl_type = $components{type};


    # Check PURL components requirements

    Carp::croak "Invalid PURL: '$components{scheme}' is not a valid scheme" unless ($components{scheme} eq 'pkg');

    foreach my $qualifier (keys %{$components{qualifiers}}) {
        Carp::croak "Invalid PURL: '$qualifier' is not a valid qualifier" if ($qualifier =~ /(\s|\%)/);
    }

    # Check checksum qualifier
    if (defined $components{qualifiers}->{checksum} and ref $components{qualifiers}->{checksum} eq 'ARRAY') {

        foreach (@{$components{qualifiers}->{checksum}}) {

            my ($algo, $checksum) = split ':', $_;

            if (defined $ALGO_LENGTH{$algo}) {

                if (length($checksum) != $ALGO_LENGTH{$algo}) {
                    DEBUG and say STDERR "-- Malformed '$algo' checksum qualifier (invalid length)";
                }

                if ($checksum !~ m/^[0-9a-f]+$/) {
                    DEBUG and say STDERR "-- Malformed '$algo' checksum qualifier (invalid characters)";
                }

            }

            # Fallback
            elsif ($checksum !~ /^[0-9a-f]{32,}$/) {
                DEBUG and say STDERR "-- Malformed '$algo' checksum qualifier (invalid characters or length)";
            }

        }

    }

    # PURL type definition validation
    if (%{$self->definition}) {

        # Check components using PURL type definition

        for my $component (qw[namespace name version subpath]) {

            next unless $self->component_have_definition($component);

            my $requirement = $self->component_requirement($component);
            next unless $requirement;

            DEBUG and say STDERR "-- Validation - $component is $requirement";

            if (defined $components{$component} && $self->component_is_prohibited($component)) {
                Carp::croak sprintf("Invalid PURL: '%s' is prohibited for '%s' PURL type", $component, $purl_type);
            }

            if (!defined $components{$component} && $self->component_is_required($component)) {
                Carp::croak sprintf("Invalid PURL: '%s' is required for '%s' PURL type", $component, $purl_type);
            }

        }

        # Default known qualifiers
        # TODO: "checksums" legacy qualifier
        my @known_qualifiers = (qw[
            vers
            repository_url
            download_url
            vcs_url
            file_name
            checksum
            checksums
        ]);

        foreach my $rule (@{$self->qualifiers_definition}) {

            my $key = $rule->{key};
            push @known_qualifiers, $key;

            my $requirement = $rule->{requirement};
            next unless $requirement;

            DEBUG and say STDERR "-- Validation - '$key' qualifier is $requirement";

            if (defined $components{qualifiers}->{$key} and $requirement eq 'prohibited') {
                Carp::croak sprintf("Invalid PURL: '%s' qualifier is prohibited for '%s' PURL type", $key, $purl_type);
            }

            if (not defined $components{qualifiers}->{$key} and $requirement eq 'required') {
                Carp::croak sprintf("Invalid PURL: '%s' qualifier is required for '%s' PURL type", $key, $purl_type);
            }

        }

        # Check unknown qualifiers
        foreach my $key (keys %{$components{qualifiers}}) {
            DEBUG and say STDERR "-- '$key' is known qualifier for '$purl_type' PURL type"
                unless (first { $key eq $_ } @known_qualifiers);
        }

    }


    # PURL type specific validation

TYPE: for ($purl_type) {

        if (/conan/) {
            if (!$components{namespace} && defined $components{qualifiers}->{channel}) {
                Carp::croak "Invalid PURL: Conan 'channel' qualifier without 'namespace'";
            }
            last TYPE;
        }

        if (/cpan/) {

            # Use legacy CPAN PURL type SPEC
            if ($ENV{PURL_LEGACY_CPAN_TYPE}) {

                if ((defined $components{namespace} && defined $components{name}) && $components{namespace} =~ /\:/) {
                    Carp::croak "Invalid PURL: CPAN 'namespace' component must have the distribution author";
                }

                if ((defined $components{namespace} && defined $components{name}) && $components{name} =~ /\:/) {
                    Carp::croak "Invalid PURL: CPAN 'name' component must have the distribution name";
                }

                if (!defined $components{namespace} && $components{name} =~ /\-/) {
                    Carp::croak "Invalid PURL: CPAN 'name' component must have the module name";
                }

                last TYPE;

            }

            if ($components{name} =~ /\:/) {
                Carp::croak "Invalid PURL: The CPAN 'name' component must have the distribution name";
            }

            last TYPE;

        }

        if (/cran/) {
            Carp::croak "Invalid PURL: Cran 'version' is required" unless defined $components{version};
            last TYPE;
        }

        if (/swift/) {

            # TODO remove after spec FIX
            Carp::croak "Invalid PURL: Swift 'version' is required" unless defined $components{version};

            if (defined $components{namespace}) {
                my ($source, $user_org) = split '/', $components{namespace};
                Carp::croak "Invalid PURL: Swift user/organization is required in 'namespace'" unless $user_org;
            }

            last TYPE;

        }

    }


    return 1;

}

1;

__END__
=head1 NAME

URI::PackageURL::Type - PURL type definition class for URI::PackageURL

=head1 SYNOPSIS

  use URI::PackageURL::Type;

  # Load 'cpan' PURL type definition
  $type = URI::PackageURL::Type->new('cpan');

  say $type->definition->{description};


=head1 DESCRIPTION

L<URL::PackageURL::Type> is the PURL type definition helper for URL::PackageURL.

=over

=item $purl_type = URI::PackageURL::Type->new($purl_type)

Create new B<URI::PackageURL::Type> instance and load PURL type definition for
normalization and validation.

    $type = URI::PackageURL::Type->new('cpan');

=item $purl_type->normalize(%components)

Perform PURL components normalization:

    %components = $purl_type->normalize(
        type      => 'CPAN',
        namespace => 'gdt',
        name      => 'URI-PackageURL'
    );

    say Dumper(\%components);

    # {
    #   type      => 'cpan',
    #   namespace => 'GDT',
    #   name      => 'URI-PackageURL'
    # }

=item $purl_type->validate(%components)

Perform PURL components validation:

    $purl_type->validate(
        type => 'CPAN',
        name => 'URI-PackageURL'
    );

=back


=head2 Definition

=over

=item $purl_type->schema_id

=item $purl_type->type_name

=item $purl_type->description

=item $purl_type->default_repository_url

=item $purl_type->examples

=item $purl_type->repository

=item $purl_type->note

=item $purl_type->reference_urls

=back


=head3 Component definition

=over

=item $purl_type->namespace_definition

=item $purl_type->name_definition

=item $purl_type->version_definition

=item $purl_type->qualifiers_definition

=item $purl_type->subpath_definition

=back


=head3 Helpers

=over

=item $purl_type->component_have_definition($component)

=item $purl_type->component_definition($component)

=item $purl_type->component_case_sensitive($component)

=item $purl_type->component_is_case_sensitive($component)

=item $purl_type->component_is_optional($component)

=item $purl_type->component_is_prohibited($component)

=item $purl_type->component_is_required($component)

=item $purl_type->component_native_name($component)

=item $purl_type->component_normalization_rules($component)

=item $purl_type->component_note($component)

=item $purl_type->component_permitted_characters($component)

=item $purl_type->component_requirement($component)

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

=over

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
