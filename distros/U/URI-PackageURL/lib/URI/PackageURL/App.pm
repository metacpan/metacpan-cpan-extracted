package URI::PackageURL::App;

use feature ':5.10';
use strict;
use warnings;
use utf8;

use Carp         ();
use Data::Dumper ();
use Getopt::Long qw(GetOptionsFromArray :config gnu_compat);
use JSON::PP     ();
use Pod::Text    ();
use Pod::Usage   qw(pod2usage);

use URI::PackageURL       ();
use URI::PackageURL::Type ();
use URI::PackageURL::Util qw(purl_types);

our $VERSION = '2.25';

sub cli_error {
    my ($error) = @_;
    $error =~ s/ at .* line \d+.*//;
    say STDERR "ERROR: $error";
}

sub run {

    my ($class, @args) = @_;

    my %options = (format => 'json');

    GetOptionsFromArray(
        \@args, \%options, qw(
            help|h
            man
            v

            download-url
            repository-url

            validate
            quiet|q
            info=s
            list

            type=s
            namespace=s
            name=s
            version=s
            qualifiers|qualifier=s%
            subpath=s

            null|0
            format=s

            json
            yaml
            dumper
            env
        )
    ) or pod2usage(-verbose => 0);

    pod2usage(-exitstatus => 0, -verbose => 2) if defined $options{man};
    pod2usage(-exitstatus => 0, -verbose => 0) if defined $options{help};

    if (defined $options{v}) {

        (my $progname = $0) =~ s/.*\///;

        say <<"VERSION";
$progname version $URI::PackageURL::VERSION

Copyright 2022-2026, Giuseppe Di Terlizzi <gdt\@cpan.org>

This program is part of the "URI-PackageURL" distribution and is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

Complete documentation for $progname can be found using 'man $progname'
or on the internet at <https://metacpan.org/dist/URI-PackageURL>.
VERSION

        return 0;

    }

    if (defined $options{info}) {
        return _definition_help(lc $options{info});
    }

    if (defined $options{list}) {
        return _purl_list();
    }

    if (defined $options{type}) {

        my $purl = eval {
            URI::PackageURL->new(
                type       => $options{type},
                namespace  => $options{namespace},
                name       => $options{name},
                version    => $options{version},
                qualifiers => $options{qualifiers},
                subpath    => $options{subpath},
            );
        };

        if ($@) {
            cli_error($@);
            return 1;
        }

        print "$purl" . (defined $options{null} ? "\0" : "\n");
        return 0;

    }

    my ($purl_string) = @args;

    pod2usage(-verbose => 1) if !$purl_string;

    $options{format} = 'json'   if defined $options{json};
    $options{format} = 'yaml'   if defined $options{yaml};
    $options{format} = 'dumper' if defined $options{dumper};
    $options{format} = 'env'    if defined $options{env};

    my $purl = eval { URI::PackageURL->from_string($purl_string) };

    if ($options{validate}) {

        unless ($options{quiet}) {
            say STDERR $purl ? 'true' : 'false';
        }

        return $purl ? 0 : 1;

    }

    if ($@) {
        cli_error($@);
        return 1;
    }

    my $purl_urls = $purl->to_urls;

    if ($options{'download-url'}) {

        return 2 unless defined $purl_urls->{download};

        print $purl_urls->{download} . (defined $options{null} ? "\0" : "\n");
        return 0;

    }

    if ($options{'repository-url'}) {

        return 2 unless defined $purl_urls->{repository};

        print $purl_urls->{repository} . ($options{null} ? "\0" : "\n");
        return 0;
    }

    if ($options{format} eq 'json') {
        print JSON::PP->new->canonical->pretty(1)->convert_blessed(1)->encode($purl);
        return 0;
    }

    if ($options{format} eq 'dumper') {
        print Data::Dumper->new([$purl->to_hash])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump;
        return 0;
    }

    if ($options{format} eq 'yaml') {

        if (eval { require YAML::XS }) {
            print YAML::XS::Dump($purl->to_hash);
            return 0;
        }
        if (eval { require YAML }) {
            print YAML::Dump($purl->to_hash);
            return 0;
        }

        cli_error 'YAML or YAML::XS module are missing';
        return 255;

    }

    if ($options{format} eq 'env') {
        return _purl_env($purl);
    }

}

sub _md_to_pod {

    my $text = shift;

    $text =~ s/(``([^``]*)``)/C<$2>/gm;
    $text =~ s/(`([^`]*)`)/C<$2>/gm;

    return $text;

}

sub _purl_env {

    my $purl = shift;

    my $purl_urls = $purl->to_urls;

    my %PURL_ENVS = (
        PURL            => $purl->to_string,
        PURL_TYPE       => $purl->type,
        PURL_NAMESPACE  => $purl->namespace,
        PURL_NAME       => $purl->name,
        PURL_VERSION    => $purl->version,
        PURL_SUBPATH    => $purl->subpath,
        PURL_QUALIFIERS => (join ' ', sort keys %{$purl->qualifiers}),
    );

    # Preserve order
    my @PURL_ENVS = qw(PURL PURL_TYPE PURL_NAMESPACE PURL_NAME PURL_VERSION PURL_SUBPATH PURL_QUALIFIERS);

    my $qualifiers = $purl->qualifiers;

    foreach my $qualifier (sort keys %{$qualifiers}) {
        my $key = "PURL_QUALIFIER_$qualifier";
        push @PURL_ENVS, $key;
        $PURL_ENVS{$key} = $qualifiers->{$qualifier};
    }

    if ($purl_urls) {
        if (defined $purl_urls->{download}) {
            push @PURL_ENVS, 'PURL_DOWNLOAD_URL';
            $PURL_ENVS{PURL_DOWNLOAD_URL} = $purl_urls->{download};
        }
        if (defined $purl_urls->{repository}) {
            push @PURL_ENVS, 'PURL_REPOSITORY_URL';
            $PURL_ENVS{PURL_REPOSITORY_URL} = $purl_urls->{repository};
        }
    }

    foreach my $key (@PURL_ENVS) {
        print sprintf qq{%s="%s"\n}, $key, $PURL_ENVS{$key} || q{};
    }

    return 0;

}

sub _purl_list {

    my @types = purl_types();

    my $pattern = "%15s | %10s | %10s | %10s | %10s | %s";

    say sprintf $pattern, 'TYPE', 'NAMESPACE', 'NAME', 'VERSION', 'SUBPATH', 'QUALIFIERS';

    say sprintf "%s-|-%s-|-%s-|-%s-|-%s-|-%s", '-' x 15, '-' x 10, '-' x 10, '-' x 10, '-' x 10, '-' x 10;

    for my $type (@types) {

        my $definition = URI::PackageURL::Type->new($type);

        my $namespace  = '-';
        my $name       = '-';
        my $version    = '-';
        my $subpath    = '-';
        my $qualifiers = '-';

        if ($definition->component_have_definition('namespace')) {
            $namespace = $definition->component_requirement('namespace') // '-';
        }

        if ($definition->component_have_definition('name')) {
            $name = $definition->component_requirement('name') // '-';
        }

        if ($definition->component_have_definition('version')) {
            $version = $definition->component_requirement('version') // '-';
        }

        if ($definition->component_have_definition('subpath')) {
            $subpath = $definition->component_requirement('subpath') // '-';
        }

        if (@{$definition->qualifiers_definition}) {
            $qualifiers = join ", ", map { $_->{key} } @{$definition->qualifiers_definition};
        }

        say sprintf $pattern, $type, $namespace, $name, $version, $subpath, $qualifiers;

    }

    return 0;

}


sub _definition_help {

    my $type = shift;

    my $definition = URI::PackageURL::Type->new($type);

    unless (%{$definition->definition}) {
        say "No known PURL type definition for '$type'";
        exit 1;
    }

    my $type_name      = $definition->type_name;
    my $description    = $definition->description;
    my $reference_urls = $definition->reference_urls;
    my $examples       = $definition->examples;
    my $note           = $definition->note;
    my $repository     = $definition->repository;
    my $schema_id      = $definition->schema_id;

    my $qualifiers_definition = $definition->qualifiers_definition;

    my $have_ns = ($definition->component_is_required('namespace') || $definition->component_is_optional('namespace'));

    my $purl_syntax = "pkg:$type";
    $purl_syntax .= '/E<lt>namespaceE<gt>' if $have_ns;
    $purl_syntax .= '/E<lt>nameE<gt>@E<lt>versionE<gt>?E<lt>qualifiersE<gt>#E<lt>subpathE<gt>';

    my $man = <<"MAN";
=head1 NAME

$type - $type_name

=head1 DESCRIPTION

$description

=head1 SYNTAX

The structure of a PURL for this package type is:

C<$purl_syntax>

MAN

    foreach my $component (qw[namespace name version subpath]) {

        next unless $definition->component_have_definition($component);

        my $requirement          = $definition->component_requirement($component);
        my $permitted_characters = $definition->component_permitted_characters($component);
        my $normalization_rules  = $definition->component_normalization_rules($component);
        my $case_sensitive       = $definition->component_case_sensitive($component);
        my $native_name          = $definition->component_native_name($component);
        my $note                 = $definition->component_note($component);

        $man .= sprintf "=head2 %s\n\n", ucfirst $component;
        $man .= "=over 2\n\n";

        if ($requirement) {
            $man .= sprintf "=item B<Requirement>: %s\n\n", ucfirst($requirement);
        }

        if ($permitted_characters) {
            $man .= sprintf "=item B<Permitted Characters>: %s\n\n", ucfirst($permitted_characters);
        }

        if ($case_sensitive) {
            $man .= sprintf "=item B<Is Case Sensitive>: %s\n\n", ($case_sensitive ? 'Yes' : 'No');
        }

        if (@{$normalization_rules}) {

            $man .= "=item B<Normalization Rules>:\n\n";
            $man .= "=over 2\n\n";

            foreach (@{$normalization_rules}) {
                $man .= sprintf "=item * %s\n\n", $_;
            }

            $man .= "=back\n\n";

        }

        if ($native_name) {
            $man .= "=item B<Native Label>: $native_name\n\n";
        }

        $man .= "=back\n\n";

        if ($note) {
            $man .= sprintf "%s\n\n", _md_to_pod($note);
        }
    }

    if (@{$qualifiers_definition}) {

        $man .= "=head2 Qualifiers\n\n";
        $man .= "=over 2\n\n";

        foreach my $qualifier (@{$qualifiers_definition}) {

            $man .= sprintf "=item C<%s>\n\n", $qualifier->{key};

            if (my $requirement = $qualifier->{requirement}) {
                $man .= sprintf "Requirement: %s\n\n", ucfirst($requirement);
            }

            if (my $native_name = $qualifier->{native_name}) {
                $man .= sprintf "Native name: %s\n\n", $native_name;
            }

            if (my $default_value = $qualifier->{default_value}) {
                $man .= sprintf "Default value: %s\n\n", $default_value;
            }

            $man .= sprintf "%s\n\n", _md_to_pod($qualifier->{description});

        }

        $man .= "=back\n\n";

    }

    if ($repository) {

        my $use_repository         = $repository->{use_repository} ? 'Yes' : 'No';
        my $default_repository_url = $repository->{default_repository_url};

        $man .= "=head1 REPOSITORY\n\n";
        $man .= "=over\n\n";
        $man .= sprintf "=item B<Use repository>: %s\n\n",         $repository->{use_repository} ? 'Yes' : 'No';
        $man .= sprintf "=item B<Default repository URL>: %s\n\n", $repository->{default_repository_url} || '(none)';
        $man .= "=back\n\n";

        if (my $note = $repository->{note}) {
            $man .= sprintf "%s\n\n", _md_to_pod($note);
        }

    }

    if (@{$examples}) {

        $man .= "=head1 EXAMPLES\n\n";
        $man .= "=over 2\n\n";

        foreach (@{$examples}) {
            $man .= sprintf "=item * %s\n\n", $_;
        }

        $man .= "=back\n\n";

    }

    if ($note) {
        $man .= "=head1 NOTES\n\n";
        $man .= sprintf "$note\n\n";
    }

    $man .= "=head1 REFERENCES\n\n";
    $man .= "=over 2\n\n";

    $man .= sprintf "=item * %s schema ID, L<%s>\n\n", $type_name, $schema_id;

    foreach (@{$reference_urls}) {
        $man .= sprintf "=item * %s reference, L<%s>\n\n", $type_name, $_;
    }

    $man .= "=item * PURL specification, L<https://github.com/package-url/purl-spec>\n\n";
    $man .= "=item * VERS specification, L<https://github.com/package-url/vers-spec>\n\n";

    $man .= "=back\n\n";

    Pod::Text->new->parse_string_document($man, \my $output);

    exit;

}

1;

__END__

=encoding utf-8

=head1 NAME

URI::PackageURL::App - URI::PackageURL (PURL) Command Line Interface

=head1 SYNOPSIS

    use URI::PackageURL::App qw(run);

    run(\@ARGV);

=head1 DESCRIPTION

URI::PackageURL::App "Command Line Interface" helper module for C<purl-tool(1)>.

=over

=item URI::PackageURL->run(@args)

Execute the command

=item cli_error($error)

Clean error

=back

=head1 AUTHOR

L<Giuseppe Di Terlizzi|https://metacpan.org/author/gdt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2022-2026 L<Giuseppe Di Terlizzi|https://metacpan.org/author/gdt>

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
