use strict;
use warnings;
use ExtUtils::MakeMaker;

check_wx_version();

WriteMakefile(
    NAME                => 'Wx::Perl::PodEditor',
    AUTHOR              => 'Renee Baecker <module@renee-baecker.de>',
    VERSION_FROM        => 'lib/Wx/Perl/PodEditor.pm',
    ABSTRACT_FROM       => 'lib/Wx/Perl/PodEditor.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Data::Dumper'         => 2.121,
        'Exporter'             => 5.58,
        'File::Basename'       => 2.74,
        'File::Spec'           => 0.87,
        'Pod::Simple::Methody' => 2.02,
        'Test::More'           => 0,
        'Wx'                   => 0.87,
        'XML::Twig'            => 3.26,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Wx::Perl::PodEditor-*' },
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ?
      (LICENSE        => 'perl') : ()),
);

sub check_wx_version {
     # Missing Wx should be dealt by the standard prereq system
     eval { require Wx };
     return if $@;

     my $version = Wx::wxVERSION_STRING();
     nono("Could not find Wx::wxVERSION_STRING") if not defined $version;

     print "Found $version\n";
     print "Found Wx.pm     $Wx::VERSION\n";
     $version =~ s/wxWidgets\s+//;
     nono("Sorry we don't known this wxWidgets version format: '$version'")
             if $version !~ /^\d+\.\d+(\.\d+)?$/;
     my ($major, $minor, $way_too_minor) = split /\./, $version;
     nono("Wx::Perl::PodEditor needs at least version 2.8.x of wxWidgets. this is version $version")
             if $major < 2 or $minor < 8;

     return;
}

sub nono {
    my $msg = shift;
    print STDERR "$msg\n";
    exit 0;
}