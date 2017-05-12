#
# This file is part of XML-Ant-BuildFile
#
# This software is copyright (c) 2014 by GSI Commerce.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use utf8;
use Modern::Perl;    ## no critic (UselessNoCritic,RequireExplicitPackage)

package XML::Ant::BuildFile::Role::HasProjects;
$XML::Ant::BuildFile::Role::HasProjects::VERSION = '0.216';

# ABSTRACT: Compose a collection of Ant build file projects

use strict;
use Carp;
use English '-no_match_vars';
## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
use List::Util 1.33 'any';
use Moose::Role;
use MooseX::Has::Sugar;
use MooseX::Types::Moose 'HashRef';
use MooseX::Types::Path::Class 'Dir';
use Path::Class;
use Regexp::DefaultFlags;
## no critic (RequireDotMatchAnything, RequireExtendedFormatting)
## no critic (RequireLineBoundaryMatching)
use Try::Tiny;
use XML::Ant::BuildFile::Project;
use namespace::autoclean;

has working_copy => ( rw, required, coerce,
    isa           => Dir,
    documentation => 'directory containing content',
);

has projects => ( rw,
    lazy_build,
    isa => HashRef ['XML::Ant::BuildFile::Project'],
    traits  => ['Hash'],
    handles => {
        project       => 'get',
        project_files => 'keys',
    },
);

sub _build_projects {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    my %projects;
    $self->working_copy->recurse(
        callback => _make_ant_finder_callback( \%projects ) );
    return \%projects;
}

sub _make_ant_finder_callback {
    my $projects_ref = shift;

    return sub {
        my $path = shift;

        # skip directories and non-XML files
        return if $path->is_dir or $path !~ / [.]xml \z/i;

        my @dir_list = $path->dir->dir_list;
        for ( 0 .. $#dir_list ) {    # skip symlinks
            return if -l file( @dir_list[ 0 .. $ARG ] )->stringify();
        }
        return                       # skip SCM dirs
            if any { 'CVS' eq $_ } @dir_list
            or any { '.svn' eq $_ } @dir_list;

        # look for matching XML files but only carp if parse error
        ## no critic (ValuesAndExpressions::ProhibitAccessOfPrivateData)
        $projects_ref->{"$path"} = try {
            XML::Ant::BuildFile::Project->new( file => $path );
        }
        catch { carp $_ };
        return;
    };
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

XML::Ant::BuildFile::Role::HasProjects - Compose a collection of Ant build file projects

=head1 VERSION

version 0.216

=head1 SYNOPSIS

    package My::Package;
    use Moose;
    with 'XML::Ant::BuildFile::Role::HasProjects';

    sub frobnicate_projects {
        my $self = shift;
        $self->working_copy('/dir/to/search');
        print "Found these projects:\n";
        print "$_\n" for @{$self->project_files};
    }

    1;

=head1 DESCRIPTION

This L<Moose::Role|Moose::Role> helps you compose a collection of Ant
project files found in a directory of source code.  The directory is searched
recursively for files ending in F<.xml>, skipping any symbolic links as well
as F<CVS> and Subversion F<.svn> directories.

=head1 ATTRIBUTES

=head2 working_copy

A L<Path::Class::Dir|Path::Class::Dir> to search for L</projects>.

=head2 projects

Reference to an array of
L<XML::Ant::BuildFile::Project|XML::Ant::BuildFile::Project>s in the
current C<working_copy> directory.

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

This software is copyright (c) 2014 by GSI Commerce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
