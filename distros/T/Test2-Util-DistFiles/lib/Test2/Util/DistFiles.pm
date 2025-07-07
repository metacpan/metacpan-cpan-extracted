package Test2::Util::DistFiles;

# ABSTRACT: Gather a list of files in a distribution

use v5.14;
use warnings;

use Carp                    qw( croak );
use Cwd                     qw( cwd chdir );
use Exporter 5.57           qw( import );
use ExtUtils::Manifest 1.68 qw( manifind maniread maniskip );
use File::Basename          qw( basename );
use File::Spec;
use IO::File;
use Ref::Util qw( is_plain_hashref );

# RECOMMEND PREREQ: Ref::Util::XS

our @EXPORT_OK = qw( manifest_files is_perl_file );

our $VERSION = 'v0.1.1';


sub manifest_files {

    my $options = {};
    $options = shift if is_plain_hashref( $_[0] );

    my $filter = shift;

    my $cwd;
    if ( my $dir = $options->{dir} ) {
        $cwd = cwd();
        chdir($dir) or croak "Cannot chdir to ${dir}";
    }

    my $default = sub {
        my ($file) = @_;
        my $name = basename($file);
        return
          if $file =~ m{^\.\w+/}                  # .git, .svn, .build, .mite ...
          || $file =~ m{^blib/}                   #
          || $file =~ m{^local/}                  # Carton
          || $name =~ m{^\.}                      #
          || $name =~ m{~$}
          || $name =~ m{^#.*#$}                   #
          || $name =~ m{\.(?:old|bak|backup)$}i
          || $file eq "Build";
        return 1;
    };

    $filter //= $default;

    my $found;

    my $mfile = $ExtUtils::Manifest::MANIFEST;
    if ( -e $mfile ) {
        $found = maniread($mfile);
    }
    else {
        $found = manifind;
    }

    my $skip = maniskip;

    chdir($cwd) if defined $cwd;

    my @files = grep { !$skip->($_) && $filter->($_) } sort keys %{$found};
    return File::Spec->no_upwards(@files);
}


sub is_perl_file {
    my ($file) = @_;
    my $name = basename($file);
    return   if $file =~ m{^inc/};                   # Module::Install
    return 1 if $name =~ /\.(?:PL|p[lm]|psgi|t)$/;
    return   if $name =~ /\.\w+$/ && $name !~ /\.bat$/;
    my $fh    = IO::File->new( $file, "r" ) or return;
    my $first = $fh->getline;
    return 1 if $first && ( $first =~ /^#!.*perl\b/ || $first =~ /--[*]-Perl-[*]--/ );
    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Util::DistFiles - Gather a list of files in a distribution

=head1 VERSION

version v0.1.1

=head1 SYNOPSIS

    use Test2::V0;
    use Test2::Util::DistFiles qw( manifest_files is_perl_file );

    my @perl = manifest_files( \&is_perl_file);

=head1 DESCRIPTION

This is a utility module that gathers lists files in a distribution, intended for author, or release tests for
developers.

=head1 EXPORTS

=head2 manifest_files

    my @files = manifest_files();

    my @perl  = manifest_files( \&is_perl_file );

This returns a list of files from the F<MANIFEST>, filtered by an optional function.

If there is no manifest, then it will use L<ExtUtils::Manifest> to build a list of files that would be added to the
manifest.

=head2 is_perl_file

This returns a list of Perl files in the distribution, excluding installation scaffolding like L<Module::Install> files
in F<inc>.

Note that it will include files like F<Makefile.PL> or F<Build.PL>.

=head1 SEE ALSO

L<Test::XTFiles>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Test2-Util-DistFiles>
and may be cloned from L<git://github.com/robrwo/perl-Test2-Util-DistFiles.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Test2-Util-DistFiles/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head2 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see F<SECURITY.md> for instructions how to
report security vulnerabilities

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
