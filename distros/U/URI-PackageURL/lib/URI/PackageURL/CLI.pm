package URI::PackageURL::CLI;

use strict;
use warnings;
use utf8;

use Getopt::Long qw( GetOptionsFromArray :config gnu_compat pass_through );
use Pod::Usage;
use Carp;
use URI::PackageURL;

use JSON qw(encode_json);
use Data::Dumper;

sub cli_error {
    my ($error) = @_;
    $error =~ s/ at .* line \d+.*//;
    print STDERR "ERROR: $error\n";
}

sub run {

    my ($class, @args) = @_;

    my %options = (format => 'json');

    GetOptionsFromArray(
        \@args, \%options, qw(
            help|h
            man
            version

            download-url
            repository-url

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

    if (defined $options{version}) {
        print "PackageURL CLI v$URI::PackageURL::VERSION\n";
        return 0;
    }

    my ($purl_string) = @args;

    pod2usage(-verbose => 1) if !$purl_string;

    $options{format} = 'json'   if defined $options{json};
    $options{format} = 'yaml'   if defined $options{yaml};
    $options{format} = 'dumper' if defined $options{dumper};
    $options{format} = 'env'    if defined $options{env};

    my $purl = eval { URI::PackageURL->from_string($purl_string) };

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

        exit(2) unless defined $purl_urls->{repository};

        print $purl_urls->{repository} . ($options{null} ? "\0" : "\n");
        return 0;
    }

    if ($options{format} eq 'json') {
        print JSON->new->canonical->pretty(1)->convert_blessed(1)->encode($purl);
        return 0;
    }

    if ($options{format} eq 'dumper') {
        print Data::Dumper->new([$purl])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump;
        return 0;
    }

    if ($options{format} eq 'yaml') {

        if (eval { require YAML::XS }) {
            print YAML::XS::Dump($purl);
            return 0;
        }
        if (eval { require YAML }) {
            print YAML::Dump($purl);
            return 0;
        }

        cli_error 'YAML or YAML::XS module are missing';
        return 255;

    }

    if ($options{format} eq 'env') {

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

}

1;

__END__

=encoding utf-8

=head1 NAME

URI::PackageURL::CLI - URL::PackageURL (purl) Command Line Interface

=head1 SYNOPSIS

    use URI::PackageURL::CLI qw(run);

    run(\@ARGV);

=head1 DESCRIPTION

URI::PackageURL::CLI "Command Line Interface" helper module for C<purl-tool(1)>.

=head1 AUTHOR

L<Giuseppe Di Terlizzi|https://metacpan.org/author/gdt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2022-2023 L<Giuseppe Di Terlizzi|https://metacpan.org/author/gdt>

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
