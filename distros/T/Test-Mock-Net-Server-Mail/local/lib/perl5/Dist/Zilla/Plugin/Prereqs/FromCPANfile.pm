package Dist::Zilla::Plugin::Prereqs::FromCPANfile;

use strict;
our $VERSION = '0.08';

use Module::CPANfile;
use Try::Tiny;
use Moose;
with 'Dist::Zilla::Role::PrereqSource', 'Dist::Zilla::Role::MetaProvider';

has cpanfile => (is => 'ro', lazy => 1, builder => '_build_cpanfile');

sub _build_cpanfile {
    my $self = shift;

    return unless -e 'cpanfile';

    try {
        $self->log("Parsing 'cpanfile' to extract prereqs");
        Module::CPANfile->load;
    } catch {
        $self->log_fatal($_);
    };
}

sub register_prereqs {
    my $self = shift;

    my $cpanfile = $self->cpanfile or return;

    my $prereqs = $cpanfile->prereq_specs;
    for my $phase (keys %$prereqs) {
        for my $type (keys %{$prereqs->{$phase}}) {
            $self->zilla->register_prereqs(
                { type => $type, phase => $phase },
                %{$prereqs->{$phase}{$type}},
            );
        }
    }
}

sub metadata {
    my $self = shift;

    my $cpanfile = $self->cpanfile     or return {};
    my @features = $cpanfile->features or return {};

    my $features = {};

    for my $feature (@features) {
        $features->{$feature->identifier} = {
            description => $feature->description,
            prereqs => $feature->prereqs->as_string_hash,
        }
    }

    return { optional_features => $features };
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Dist::Zilla::Plugin::Prereqs::FromCPANfile - Parse cpanfile for prereqs

=head1 SYNOPSIS

  # dist.ini
  [Prereqs::FromCPANfile]

=head1 DESCRIPTION

Dist::Zilla::Plugin::Prereqs::FromCPANfile is a L<Dist::Zilla> plugin
to read I<cpanfile> to determine prerequisites for your distribution. This
does the B<opposite of> what L<Dist::Zilla::Plugin::CPANFile> does, which
is to I<create> a C<cpanfile> using the prereqs collected elsewhere.

When C<feature> DSL is used in C<cpanfile>, it will correctly be
converted to C<optional_features> in META data.

B<DO NOT USE THIS PLUGIN IN COMBINATION WITH Plugin::CPANFile>. You will
probably be complained about creating duplicate files from dzil.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2013- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Module::CPANfile>

=cut
