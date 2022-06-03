# $Id$
package Youri::Package::RPM::RPM4;

=head1 NAME

Youri::Package::RPM::RPM4 - RPM4-based rpm package implementation

=head1 DESCRIPTION

This is an RPM4-based L<Youri::Package> implementation for rpm.

=cut

use strict;
use warnings;
use base 'Youri::Package::RPM';
use overload
    '""'     => 'as_string',
    '0+'     => '_to_number',
    fallback => 1;

use Carp;
use File::Spec;
use RPM4;
use RPM4::Header;
use RPM4::Sign;
use Scalar::Util qw/refaddr blessed/;

use Youri::Package::Relationship;
use Youri::Package::File;
use Youri::Package::Change;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Package::RPM::RPM4 object.

Specific parameters:

=over

=item file $file

Path of file to use for creating this package.

=item header $header

L<RPM4::Header> object to use for creating this package.

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
                unless $options{header}->isa('RPM4::Header');
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
            $header = RPM4::Header->new($options{file});
            croak "Can't get header from file $options{file}" if (!$header); 

            last HEADER;
        }

        croak "no way to extract header from arguments";
    }

    $self->{_header} = $header;
    $self->{_file}   = File::Spec->rel2abs($options{file});
}

sub compare_revisions {
    my ($class, $revision1, $revision2) = @_;

    return RPM4::rpmvercmp($revision1, $revision2);
}

sub _depsense2flag {
    my ($string) = @_;
    my @flags = 0;
    push(@flags, 'EQUAL') if ($string =~ /=/);
    push(@flags, 'LESS') if ($string =~ /</);
    push(@flags, 'GREATER') if ($string =~ />/);
    return \@flags;
}

sub check_ranges_compatibility {
    my ($class, $range1, $range2) = @_;
    my @deps1 = ('', split(/ /, $range1));
    my @deps2 = ('', split(/ /, $range2));
    $deps1[1] = _depsense2flag($range1); 
    $deps2[1] = _depsense2flag($range2); 
    my $dep1 = RPM4::Header::Dependencies->new(
        "PROVIDENAME",
        \@deps1,
    );
    my $dep2 = RPM4::Header::Dependencies->new(
        "PROVIDENAME",
        \@deps2,
    );

    return $dep1->overlap($dep2);
}

sub set_verbosity {
    return RPM4::setverbosity($_[1])
}

sub install_srpm {
    return RPM4::installsrpm($_[1]);
}

sub add_macro {
    return RPM4::add_macro($_[1]);
}

sub expand_macro {
    return RPM4::expand($_[1]);
}

sub new_header {
    shift @_;
    return RPM4::Header->new(@_);
}

sub new_spec {
    shift @_;
    return RPM4::Spec->new(@_);
}

sub new_transaction {
    shift @_;
    return RPM4::Transaction->new(@_);
}

sub get_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->tag('name');
}

sub get_version {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->tag('version');
}

sub get_release {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->tag('release');
}

sub get_revision {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->queryformat('%|EPOCH?{%{EPOCH}:}:{}|%{VERSION}-%{RELEASE}');
}

sub get_file_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->queryformat('%{NAME}-%{VERSION}-%{RELEASE}.%|SOURCERPM?{%{ARCH}}:{src}|.rpm');
}


sub get_arch {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->queryformat('%|SOURCERPM?{%{ARCH}}:{src}|');
}

sub get_url {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->tag('url');
}

sub get_summary {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->tag('summary');
}

sub get_description {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->tag('description');
}

sub get_packager {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->tag('packager');
}

sub is_source {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->issrc();
}

sub is_binary {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return !$self->{_header}->issrc();
}

sub get_type {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return
        $self->{_header}->issrc() ?
        "source" :
        "binary";
}

sub get_age {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->tag('buildtime');
}

sub get_source_package {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_header}->tag('sourcerpm');
}

sub get_canonical_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    $self->{_header}->sourcerpmname() =~ /^(\S+)-[^-]+-[^-]+\.src\.rpm$/;
    return $1;
}

sub get_canonical_revision {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    $self->{_header}->sourcerpmname() =~ /^\S+-([^-]+-[^-])+\.src\.rpm$/;
    return $1;
}

sub get_tag {
    my ($self, $tag) = @_;
    croak "Not a class method" unless ref $self;
    #croak "invalid tag $tag" unless $self->{_header}->can($tag);
    return $self->{_header}->tag($tag);
}


sub _get_dependencies {
    my ($self, $type) = @_;
    my $deps = $self->{_header}->dep($type);
    my @depslist;
    if ($deps) {
        $deps->init();
        while ($deps->next() >= 0) {
            my (undef, $name, $operator, $revision) = $deps->info();
            next if $name =~ m/^rpmlib\(/;       # internal rpmlib dep
            $operator = '==' if $operator eq '='; # rpm to URPM syntax
            push(@depslist, Youri::Package::Relationship->new(
                $name,
                $revision ? $operator . ' ' . $revision : undef
            ));
        }
    }
    return @depslist
}

sub get_requires {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->_get_dependencies('REQUIRENAME');
}

sub get_provides {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->_get_dependencies('PROVIDENAME');
}

sub get_obsoletes {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
   
    return $self->_get_dependencies('OBSOLETENAME');
}

sub get_conflicts {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->_get_dependencies('CONFLICTNAME');
}

sub get_files {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my $files = $self->{_header}->files();
    my @fileslist;
    if ($files) {
        $files->init();
        while ($files->next() >= 0) {
            # convert signed int to unsigned int
            my $smode = $files->mode();
            my $umode;
            for my $i (0..15) {
                $umode |= $smode & (1 << $i); ## no critic (ProhibitBitwise)
            }
            my $md5 = $files->md5();
            $md5 = '' if !$md5 || $md5 eq '00000000000000000000000000000000';
            push(@fileslist, Youri::Package::File->new(
                $files->filename(),
                $umode,
                $md5
            ));
        }
    }
    return @fileslist
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

    my @times = $self->{_header}->tag('changelogtime');
    my @texts = $self->{_header}->tag('changelogtext');

    return map {
        Youri::Package::Change->new($_, shift @times, shift @texts)
    } $self->{_header}->tag('changelogname');
}

sub get_last_change {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my $text = ($self->{_header}->tag('changelogtext'))[0];
    my $name = ($self->{_header}->tag('changelogname'))[0];
    my $time = ($self->{_header}->tag('changelogtime'))[0];

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

    return $self->{_header}->compare($package->{_header});
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

    my $sign = RPM4::Sign->new(
        name => $name,
        path => $path,
    );
    $sign->{passphrase} = $passphrase;

    # RPM4 sux, there is no error handling available here
    $sign->rpmssign($self->{_file});
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
