package sBNC::User::Summary;

use 5.006;

use Carp;
use Moose;

use vars qw/$VERSION/;

$VERSION = 1.01;

################################################################################

has users => (is => 'ro', isa => 'ArrayRef', required => 1);
has dir   => (is => 'ro', isa => 'Str',      required => 1);

has conf_files => (is => 'ro', isa => 'HashRef', lazy_build => 1);
has chan_files => (is => 'ro', isa => 'HashRef', lazy_build => 1);
has config     => (is => 'ro', isa => 'HashRef', lazy_build => 1);

################################################################################

sub _file_contents {
    my $self     = shift;
    my $filename = shift;
    my $type     = shift; # conf, chan

    my $content = $type eq 'conf'
        ? $self->_conf_file($filename)
        : $self->_chan_file($filename);

    return $content;
}

sub _conf_file {
    my $self     = shift;
    my $filename = shift;

    my %content;

    if (open (my $fh, '<', $filename)) {
        while (my $row = <$fh>) {
            chomp $row;

            my ($handle, $key, $value) = $row =~ /^(\w+)\.(\w+)=(.+)/;

            $content{$key} = $value if $key;
        }

        close $fh;
    } else {
        warn sprintf("No such channel file %s\n", $filename);
    }

    return \%content;
}

sub _chan_file {
    my $self     = shift;
    my $filename = shift;

    my %content;

    if (open (my $fh, '<', $filename)) {
        while (my $row = <$fh>) {
            chomp $row;

            my ($name, $modes) = $row =~ /^channel add (#\w+) \{\ (.+)\ \}$/;
            my %options;

            if ($modes) {
                while ($modes =~ /(\w+) (\w+)+/g) {
                    $options{$1} = $2;
                }
            }

            $content{$name} = \%options if $name;
        }

        close $fh;
    } else {
        warn sprintf("No such channel file %s\n", $filename);
    }

    return \%content;
}

sub _filename {
    my $self = shift;
    my $user = shift;
    my $type = shift; # conf, chan

    return sprintf("%s/%s.%s", $self->dir, $user, $type);
}

sub _file_builder {
    my $self = shift;
    my $type = shift;

    my %files;

    foreach my $user (@{$self->users}) {
        my $filename = $self->_filename($user, $type);

        $files{$user} = $self->_file_contents($filename, $type);
    }

    return \%files;
}

################################################################################

sub _build_config {
    my $self = shift;

    my %config;

    foreach my $user (@{$self->users}) {
        my $out = $self->conf_files->{$user};

        $out->{channels} = $self->chan_files->{$user};
        $config{$user}   = $out;
    }

    return \%config;
}

sub _build_conf_files {
    my $self = shift;

    return $self->_file_builder('conf');
}

sub _build_chan_files {
    my $self = shift;

    return $self->_file_builder('chan');
}

################################################################################

no Moose;
1;
__END__

=head1 NAME

sBNC::User::Summary - Translate sBNC user files into usable objects.

=head1 DESCRIPTION

Takes input of sBNC's config flatfiles (.conf, .chan) for users and translates
them into a Perl-friendly format.

=head1 VERSION

Version 1.01

=head2 USAGE

    my $users = sBNC::User->new({
        users => [ 'Mike', 'Dave' ],
        dir   => '/absolute/path/to/sBNC/users/',
    });

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

=head1 LICENSE

Copyright (c) Mike Jones 2016


