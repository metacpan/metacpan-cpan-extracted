# $Id$
package Youri::Package::RPM::URPM;

=head1 NAME

Youri::Package::RPM::URPM - URPM-based rpm package implementation

=head1 DESCRIPTION

This is an URPM-based L<Youri::Package> implementation for rpm.

It is merely a wrapper over URPM::Package class, with a more structured
interface.

=cut

use strict;
use warnings;
use base 'Youri::Package::RPM';
use overload
    '""'     => 'as_string',
    '0+'     => '_to_number',
    fallback => 1;

use Carp;
use English qw(-no_match_vars);
use Expect;
use File::Spec;
use Scalar::Util qw/refaddr blessed/;
use URPM;

use Youri::Package::Change;
use Youri::Package::File;
use Youri::Package::Relationship;

my $relationship_pattern = qr/^
    ([^\s*]+)      # name: everything BUT space and * characters
    (?:\[\*\])   ? # optional scriptlet flag
    (?:\[(.+)\]) ? # optional version suffix
    $/x;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Package::RPM::URPM object.

Specific parameters:

=over

=item file $file

Path of file to use for creating this package.

=item header $header

L<URPM::Package> object to use for creating this package.

=back

=cut

sub _init {
    my ($self, %options) = @_;

    my $header;
    HEADER: {
        if (exists $options{header}) {
            croak "undefined header"
                unless $options{header};
            croak "invalid header"
                unless $options{header}->isa('URPM::Package');
            $header = $options{header};
            last HEADER;
        }

        if (exists $options{file}) {
            croak "undefined file"
                unless $options{file};
            croak "non-existing file $options{file}"
                unless -f $options{file};
            croak "non-readable file $options{file}"
                unless -r $options{file};
            my $urpm = URPM->new();
            $urpm->parse_rpm($options{file}, keep_all_tags => 1);
            $header = $urpm->{depslist}->[0];
            croak "non-rpm file $options{file}" unless $header;
            last HEADER;
        }

        croak "no way to extract header from arguments";
    }

    $self->{_header} = $header;
    $self->{_file}   = File::Spec->rel2abs($options{file});
}

sub compare_revisions {
    my ($class, $revision1, $revision2) = @_;

    return URPM::rpmvercmp($revision1, $revision2);
}

sub check_ranges_compatibility {
    my ($class, $range1, $range2) = @_;

    return URPM::ranges_overlap($range1, $range2);
}

sub get_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->name();
}

sub get_version {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->version();
}

sub get_release {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->release();
}

sub get_revision {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->queryformat('%|EPOCH?{%{EPOCH}:}:{}|%{VERSION}-%{RELEASE}');
}

sub get_file_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->filename();
}

sub get_arch {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->arch();
}

sub get_url {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->url();
}

sub get_summary {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->summary();
}

sub get_description {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->description();
}

sub get_packager {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->packager();
}

sub is_source {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->arch() eq 'src';
}

sub is_binary {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->arch() ne 'src';
}

sub get_type {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return
        $self->{_header}->arch() eq 'src' ?
        "source" :
        "binary";
}

sub get_age {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->buildtime();
}

sub get_source_package {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->sourcerpm();
}

sub get_canonical_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    if ($self->{_header}->arch() eq 'src') {
       return $self->{_header}->name();
    } else {
       $self->{_header}->sourcerpm() =~ /^(\S+)-[^-]+-[^-]+\.src\.rpm$/;
       return $1;
    }
}

sub get_canonical_revision {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    if ($self->{_header}->arch() eq 'src') {
       return $self->{_header}->get_revision();
    } else {
       $self->{_header}->sourcerpm() =~ /^\S+-([^-]+-[^-]+)\.src\.rpm$/;
       return $1;
    }
}

sub get_tag {
    my ($self, $tag) = @_;
    croak "Not a class method" unless ref $self;
    croak "invalid tag $tag" unless $self->{_header}->can($tag);
    return $self->{_header}->$tag();
}

sub get_requires {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return map {
        $_ =~ $relationship_pattern;
        Youri::Package::Relationship->new($1, $2)
    } $self->{_header}->requires();
}

sub get_provides {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return map {
        $_ =~ $relationship_pattern;
        Youri::Package::Relationship->new($1, $2)
    } $self->{_header}->provides();
}

sub get_obsoletes {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return map {
        $_ =~ $relationship_pattern;
        Youri::Package::Relationship->new($1, $2)
    } $self->{_header}->obsoletes();
}

sub get_conflicts {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return map {
        $_ =~ $relationship_pattern;
        Youri::Package::Relationship->new($1, $2)
    } return $self->{_header}->conflicts();
}

sub get_files {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my @modes   = $self->{_header}->files_mode();
    my @md5sums = $self->{_header}->files_md5sum();

    return map {
        Youri::Package::File->new($_, shift @modes, shift @md5sums)
    } $self->{_header}->files();
}

sub get_gpg_key {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    
    my $signature = $self->{_header}->queryformat('%{SIGGPG:pgpsig}');
    return if $signature eq '(not a blob)';
    my $key_id = (split(/\s+/, $signature))[-1];
    return substr($key_id, 8);
}

sub get_changes {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my @times = $self->{_header}->changelog_time();
    my @texts = $self->{_header}->changelog_text();

    return map {
        Youri::Package::Change->new($_, shift @times, shift @texts)
    } $self->{_header}->changelog_name();
}

sub get_last_change {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my $text = ($self->{_header}->changelog_text())[0];
    my $name = ($self->{_header}->changelog_name())[0];
    my $time = ($self->{_header}->changelog_time())[0];

    return $text ?
        Youri::Package::Change->new($name, $time, $text) :
        undef;
}

sub as_string {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->fullname();
}

sub as_formated_string {
    my ($self, $format) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->queryformat($format);
}

sub _to_number {
    return refaddr($_[0]);
}

sub compare {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;
    croak "Not a __PACKAGE__ object" unless
        blessed $package && $package->isa(__PACKAGE__);

    return $self->{_header}->compare_pkg($package->{_header});
}

sub satisfy_range {
    my ($self, $range) = @_;
    croak "Not a class method" unless ref $self;

    return $self->check_ranges_compatibility(
        '== ' . $self->get_revision(),
        $range
    );
}

sub sign {
    my ($self, $name, $path, $passphrase) = @_;
    croak "Not a class method" unless ref $self;

    # check if parent directory is writable
    my $parent = (File::Spec->splitpath($self->{_file}))[1];
    croak "Unsignable package, parent directory is read-only"
        unless -w $parent;

    my $command =
        'LC_ALL=C rpm --resign ' . $self->{_file} .
        ' --define "_signature gpg"' .
        ' --define "_gpg_name ' . $name . '"' .
        ' --define "_gpg_path ' . $path . '"';
    my $expect = Expect->spawn($command)
        or croak "Couldn't spawn command $command: $ERRNO\n";
    my @log;
    $expect->log_stdout(0);
    $expect->log_file(sub { push(@log, $_[0]); });
    $expect->expect(10, 'Enter pass phrase:')
        or croak "Unexpected output: $log[-1]\n";
    $expect->send("$passphrase\n");

    $expect->soft_close();

    croak "Signature error: " . $log[-1] if $expect->exitstatus();
}

sub extract {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    system("rpm2cpio $self->{_file} | cpio -id >/dev/null 2>&1");
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
