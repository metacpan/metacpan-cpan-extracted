package URI::VersionRange::App;

use feature ':5.10';
use strict;
use warnings;
use utf8;

use Getopt::Long qw(GetOptionsFromArray :config gnu_compat);
use Pod::Usage   qw(pod2usage);
use Carp         ();
use JSON::PP     ();
use Data::Dumper ();

use URI::VersionRange ();

our $VERSION = '2.21';

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
            help
            man
            v

            contains=s

            null|0
            format=s

            json
            human-readable|h
        )
    ) or pod2usage(-verbose => 0);

    pod2usage(-exitstatus => 0, -verbose => 2) if defined $options{man};
    pod2usage(-exitstatus => 0, -verbose => 0) if defined $options{help};

    if (defined $options{v}) {

        (my $progname = $0) =~ s/.*\///;

        say <<"VERSION";
$progname version $URI::VersionRange::VERSION

Copyright 2022-2024, Giuseppe Di Terlizzi <gdt\@cpan.org>

This program is part of the "URI-PackageURL" distribution and is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

Complete documentation for $progname can be found using 'man $progname'
or on the internet at <https://metacpan.org/dist/URI-PackageURL>.
VERSION

        return 0;

    }

    my ($vers_string) = @args;

    pod2usage(-verbose => 1) if !$vers_string;

    $options{format} = 'json'           if defined $options{json};
    $options{format} = 'human-readable' if defined $options{'human-readable'};

    my $vers = eval { URI::VersionRange->from_string($vers_string) };

    if ($@) {
        cli_error($@);
        return 1;
    }

    if (defined $options{contains}) {

        my $vers_comparator_class = join '::', 'URI::VersionRange::Version', $vers->scheme;

        if (!$vers_comparator_class->can('new')) {
            say STDERR 'WARNING: Loaded the fallback scheme class comparator.';
            say STDERR '         The comparison may not work correctly!';
        }

        my $res = eval { $vers->contains($options{contains}) };

        if ($@) {
            cli_error($@);
            return 1;
        }

        say STDERR $res ? 'TRUE' : 'FALSE';
        return $res;

    }

    if ($options{format} eq 'json') {
        print JSON::PP->new->canonical->pretty(1)->convert_blessed(1)->encode($vers);
        return 0;
    }

    if ($options{format} eq 'human-readable') {
        say $vers->scheme;
        say "- " . $_->to_human_string for (@{$vers->constraints});
        return 0;
    }

}

1;

__END__

=encoding utf-8

=head1 NAME

URI::VersionRange::App - URL::VersionRange (vers) Command Line Interface

=head1 SYNOPSIS

    use URI::VersionRange::App qw(run);

    run(\@ARGV);

=head1 DESCRIPTION

URI::VersionRange::App "Command Line Interface" helper module for C<vers-tool(1)>.

=over

=item URI::VersionRange->run(@args)

Execute the command

=item cli_error($error)

Clean error

=back

=head1 AUTHOR

L<Giuseppe Di Terlizzi|https://metacpan.org/author/gdt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2022-2024 L<Giuseppe Di Terlizzi|https://metacpan.org/author/gdt>

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
