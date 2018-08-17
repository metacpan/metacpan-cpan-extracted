package App::cpanlistchanges;

use strict;
use 5.008_001;
our $VERSION = '0.08';

use Algorithm::Diff;
use CPAN::DistnameInfo;
use Getopt::Long;
use IO::Handle;
use Module::Metadata;
use LWP::UserAgent;
use YAML;
use Try::Tiny;
use Pod::Usage;
use version;

sub new {
    bless {
        all => 0,
        use_pager => 1,
    }, shift;
}

sub run {
    my($self, @args) = @_;

    Getopt::Long::GetOptionsFromArray(
        \@args,
        "all|a", \$self->{all},
        "help",  sub { Pod::Usage::pod2usage(0) },
        "pager!", \$self->{use_pager},
    );

    for my $mod (@args) {
        $self->show_changes($mod);
    }
}

sub get {
    my $self = shift;

    $self->{ua} ||= do{
        my $ua = LWP::UserAgent->new(agent => "cpan-listchanges/$VERSION");
        $ua->env_proxy;
        $ua;
    };

    $self->{ua}->get(@_)->content;
}

sub show_changes {
    my($self, $mod) = @_;

    my($from, $to);
    if ($mod =~ s/\@\{?(.+)\}?$//) {
        ($from, $to) = split /\.\./, $1;
        $to = undef if $to eq 'HEAD';
    }

    my $dist = try { YAML::Load( $self->get("http://cpanmetadb.plackperl.org/v1.0/package/$mod") ) };
    unless ($dist->{distfile}) {
        warn "Couldn't find a module '$mod'. Skipping.\n";
        return;
    }

    my $meta = Module::Metadata->new_from_module($mod);
    my $info = CPAN::DistnameInfo->new($dist->{distfile});

    $from ||= $meta->{version};
    $to   ||= $info->{version};

    unless ($self->{all} or $from) {
        warn "You don't have the module '$mod' installed locally. Skipping.\n";
        return;
    }

    unless ($self->{all} or $to) {
        warn "Couldn't find the module '$mod' on CPAN MetaDB. Skipping.\n";
        return;
    }

    if (!$self->{all} and version->new($from) >= version->new($to)) {
        warn "You have the latest version of $info->{dist} ($to). Skipping.\n";
        return;
    }

    my $get_changes = sub {
        my $version = shift;
        return $self->get(
            "https://fastapi.metacpan.org/source/$info->{cpanid}/$info->{dist}-$version/Changes"
        );
    };

    my $new_changes = $get_changes->($to);
    unless ($new_changes) {
        warn "Can't find Changes for $info->{dist}-$to. Skipping.\n";
        return;
    }

    if ($self->{all}) {
        $self->print("=== Changes for $info->{dist}\n\n$new_changes\n");
        return;
    }

    my $old_changes = $get_changes->($from) || '';

    my $diff = Algorithm::Diff->new(
        [ split /\n/, $old_changes ],
        [ split /\n/, $new_changes ],
    );
    $diff->Base(1);

    my $result;
    while ($diff->Next()) {
        next if $diff->Same();
        $result .= "$_\n" for $diff->Items(2);
    }

    if ($result) {
        $self->print("=== Changes between $from and $to for $info->{dist}\n\n$result\n");
    } else {
        warn "Couldn't find changes between $from and $to for $info->{dist}\n";
    }
}

sub print {
    my $self = shift;
    $self->{pager} ||= ($self->{use_pager} and $ENV{PAGER})
        ? do {
            open my $io, "| $ENV{PAGER}" or die $!;
            $io;
        } : \*STDOUT;

    $self->{pager}->print(@_);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

App::cpanlistchanges - list changes for CPAN modules

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Tokuhiro Matsuno originally wrote the snippet to fetch Changes and
compare with Algorithm::Diff if I remember correctly.

=head1 COPYRIGHT

Copyright 2010- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<cpan-listchanges>

=cut
