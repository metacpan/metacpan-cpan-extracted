package XML::Ant::BuildFile::Resource::FileList;

# ABSTRACT: file list node within an Ant build file

#pod =head1 DESCRIPTION
#pod
#pod See L<XML::Ant::BuildFile::Project|XML::Ant::BuildFile::Project> for a complete
#pod description.
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use XML::Ant::BuildFile::Project;
#pod
#pod     my $project = XML::Ant::BuildFile::Project->new( file => 'build.xml' );
#pod     for my $list_ref (@{$project->file_lists}) {
#pod         print 'id: ', $list_ref->id, "\n";
#pod         print join "\n", @{$list_ref->files};
#pod         print "\n\n";
#pod     }
#pod
#pod =cut

use utf8;
use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

our $VERSION = '0.217';     # VERSION
use Modern::Perl;
use English '-no_match_vars';
use Path::Class;
use Regexp::DefaultFlags;
## no critic (RequireDotMatchAnything, RequireExtendedFormatting)
## no critic (RequireLineBoundaryMatching)
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(ArrayRef HashRef Str);
use MooseX::Types::Path::Class qw(Dir File);
use XML::Ant::Properties;
use namespace::autoclean;

#pod =attr directory
#pod
#pod L<Path::Class::Dir|Path::Class::Dir> indicated by the C<< <filelist> >>
#pod element's C<dir> attribute with all property substitutions applied.
#pod
#pod =cut

has directory => ( ro, required, lazy,
    builder  => '_build_directory',
    isa      => Dir,
    init_arg => undef,
);

sub _build_directory {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self      = shift;
    my $directory = $self->_dir_attr;

    if ( not state $recursion_guard) {
        $recursion_guard = 1;
        $directory       = XML::Ant::Properties->apply($directory);
        undef $recursion_guard;
    }
    return dir($directory);
}

has _files => ( ro, lazy,
    builder  => '_build__files',
    isa      => ArrayRef [File],
    traits   => ['Array'],
    init_arg => undef,
    handles  => {

       #pod =method files
       #pod
       #pod Returns an array of L<Path::Class::File|Path::Class::File>s within
       #pod this file list with all property substitutions applied.
       #pod
       #pod =cut

        files        => 'elements',
        map_files    => 'map',
        filter_files => 'grep',
        find_file    => 'first',
        file         => 'get',
        num_files    => 'count',
        as_string    => [ join => q{ } ],
    },
);

sub _build__files
{    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    my @file_names;

    if ( defined $self->_file_names ) {
        push @file_names, @{ $self->_file_names };
    }
    if ( defined $self->_files_attr_names ) {
        push @file_names, split / [,\s]* /, $self->_files_attr_names;
    }

    if ( not state $recursion_guard) {
        $recursion_guard = 1;
        @file_names = map { XML::Ant::Properties->apply($_) } @file_names;
        undef $recursion_guard;
    }

    return [ map { $self->_prepend_dir($_) } @file_names ];
}

sub _prepend_dir {
    my ( $self, $file_name ) = @_;
    return $self->directory->subsumes( file($file_name) )
        ? file($file_name)
        : $self->directory->file($file_name);
}

has content =>
    ( ro, lazy, isa => ArrayRef [File], default => sub { $_[0]->_files } );

with 'XML::Ant::BuildFile::Resource';

## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)

has _dir_attr => ( ro, required,
    isa         => Str,
    traits      => ['XPathValue'],
    xpath_query => './@dir',
);

has _file_names => ( ro,
    isa => ArrayRef [Str],
    traits      => ['XPathValueList'],
    xpath_query => './file/@name',
);

has _files_attr_names => ( ro,
    isa         => Str,
    traits      => ['XPathValue'],
    xpath_query => './@files',
);

no Moose;

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

XML::Ant::BuildFile::Resource::FileList - file list node within an Ant build file

=head1 VERSION

version 0.217

=head1 SYNOPSIS

    use XML::Ant::BuildFile::Project;

    my $project = XML::Ant::BuildFile::Project->new( file => 'build.xml' );
    for my $list_ref (@{$project->file_lists}) {
        print 'id: ', $list_ref->id, "\n";
        print join "\n", @{$list_ref->files};
        print "\n\n";
    }

=head1 DESCRIPTION

See L<XML::Ant::BuildFile::Project|XML::Ant::BuildFile::Project> for a complete
description.

=head1 ATTRIBUTES

=head2 directory

L<Path::Class::Dir|Path::Class::Dir> indicated by the C<< <filelist> >>
element's C<dir> attribute with all property substitutions applied.

=head1 METHODS

=head2 files

Returns an array of L<Path::Class::File|Path::Class::File>s within
this file list with all property substitutions applied.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::Ant::BuildFile::Project

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/XML-Ant-BuildFile>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-Ant-BuildFile>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Ant-BuildFile>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-Ant-BuildFile>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-Ant-BuildFile>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/XML-Ant-BuildFile>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-Ant-BuildFile>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Ant-BuildFile>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Ant-BuildFile>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Ant::BuildFile::Project>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/xml-ant-buildfile/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/xml-ant-buildfile>

  git clone git://github.com/mjgardner/xml-ant-buildfile.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by GSI Commerce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
