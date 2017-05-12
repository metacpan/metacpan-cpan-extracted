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

package XML::Ant::BuildFile::Project;
$XML::Ant::BuildFile::Project::VERSION = '0.216';

# ABSTRACT: consume Ant build files

use English '-no_match_vars';
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Has::Sugar::Minimal;
use MooseX::Types::Moose qw(ArrayRef HashRef Str);
use MooseX::Types::Path::Class 'File';
use Path::Class;
use Readonly;
use Regexp::DefaultFlags;
## no critic (RequireDotMatchAnything, RequireExtendedFormatting)
## no critic (RequireLineBoundaryMatching)
extends 'XML::Ant::BuildFile::ResourceContainer';
with 'XML::Rabbit::RootNode';

subtype 'FileStr', as Str;
coerce 'FileStr', from File, via {"$ARG"};
has '+_file' => ( isa => 'FileStr', coerce => 1 );

{
## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)

    has name => (
        isa         => Str,
        traits      => ['XPathValue'],
        xpath_query => '/project/@name',
    );

    has _properties => (
        lazy        => 1,
        isa         => HashRef [Str],
        traits      => ['XPathValueMap'],
        xpath_query => '//property[@name and @value]',
        xpath_key   => './@name',
        xpath_value => './@value',
        default     => sub { {} },
    );

    has _filelists => (
        isa         => 'ArrayRef[XML::Ant::BuildFile::Resource::FileList]',
        traits      => [qw(XPathObjectList Array)],
        xpath_query => '//filelist[@id]',
        handles     => {
            filelists        => 'elements',
            filelist         => 'get',
            map_filelists    => 'map',
            filter_filelists => 'grep',
            find_filelist    => 'first',
            num_filelists    => 'count',
        },
    );

    has paths => (
        auto_deref  => 1,
        isa         => 'HashRef[XML::Ant::BuildFile::Resource::Path]',
        traits      => [qw(XPathObjectMap Hash)],
        xpath_query => '//classpath[@id]|//path[@id]',
        xpath_key   => './@id',
        handles     => { path => 'get', path_pairs => 'kv' },
    );

    has targets => (
        auto_deref  => 1,
        isa         => 'HashRef[XML::Ant::BuildFile::Target]',
        traits      => [qw(XPathObjectMap Hash)],
        xpath_query => '/project/target[@name]',
        xpath_key   => './@name',
        handles     => {
            target       => 'get',
            all_targets  => 'values',
            target_names => 'keys',
            has_target   => 'exists',
            num_targets  => 'count',
        },
    );
}

sub BUILD {
    my $self = shift;

    my %ant_property = (
        'os.name'          => $OSNAME,
        'basedir'          => file( $self->_file )->dir->stringify(),
        'ant.file'         => $self->_file,
        'ant.project.name' => $self->name,
    );
    for my $property (
        grep { not XML::Ant::Properties->exists($ARG) }
        keys %ant_property
        )
    {
        XML::Ant::Properties->set( $property => $ant_property{$property} );
    }
    if ( keys %{ $self->_properties } ) {
        XML::Ant::Properties->set( %{ $self->_properties } );
    }

    for my $attr ( $self->meta->get_all_attributes() ) {
        next if !$attr->has_type_constraint;
        if ( $attr->type_constraint->name
            =~ /XML::Ant::BuildFile::Resource::/ )
        {
            my $attr_name = $attr->name;
            $attr_name = $self->$attr_name;
        }
    }
    return;
}

no Moose::Util::TypeConstraints;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

XML::Ant::BuildFile::Project - consume Ant build files

=head1 VERSION

version 0.216

=head1 SYNOPSIS

    use XML::Ant::BuildFile::Project;

    my $project = XML::Ant::BuildFile::Project->new( file => 'build.xml' );
    print 'Project name: ', $project->name, "\n";
    print "File lists:\n";
    for my $list_ref (@{$project->file_lists}) {
        print 'id: ', $list_ref->id, "\n";
        print join "\n", @{$list_ref->files};
        print "\n\n";
    }

=head1 DESCRIPTION

This class uses L<XML::Rabbit|XML::Rabbit> to consume Ant build files using
a L<Moose|Moose> object-oriented interface.  It is a work in progress and in no
way a complete implementation of all Ant syntax.

=head1 ATTRIBUTES

=head2 file

On top of L<XML::Rabbit|XML::Rabbit>'s normal behavior, this class will also
coerce L<Path::Class::File|Path::Class::File> objects to the strings expected
by L<XML::Rabbit::Role::Document|XML::Rabbit::Role::Document>.

=head2 name

Name of the Ant project.

=head2 paths

Hash of
L<XML::Ant::BuildFile::Resource::Path|XML::Ant::BuildFile::Resource::Path>s
from the build file.  The keys are the path C<id>s.

=head2 targets

Hash of L<XML::Ant::BuildFile::Target|XML::Ant::BuildFile::Target>s
from the build file.  The keys are the target names.

=head1 METHODS

=head2 filelists

Returns an array of all L<filelist|XML::Ant::BuildFile::Resource::FileList>s
in the project.

=head2 filelist

Given an index number returns that C<filelist> from the project.
You can also use negative numbers to count from the end.
Returns C<undef> if the specified C<filelist> does not exist.

=head2 map_filelists

Given a code reference, transforms every C<filelist> element into a new
array.

=head2 filter_filelists

Given a code reference, returns an array with every C<filelist> element
for which that code returns C<true>.

=head2 find_filelist

Given a code reference, returns the first C<filelist> for which the code
returns C<true>.

=head2 num_filelists

Returns a count of all C<filelist>s in the project.

=head2 path

Given a list of one or more C<id> strings, returns a list of
L<XML::Ant::BuildFile::Resource::Path|XML::Ant::BuildFile::Resource::Path>s
for C<< <classpath/> >>s and C<< <path/> >>s in the project.

=head2 target

Given a list of target names, return the corresponding
L<XML::Ant::BuildFile::Target|XML::Ant::BuildFile::Target>
objects.  In scalar context return only the last target specified.

=head2 all_targets

Returns a list of all targets as
L<XML::Ant::BuildFile::Target|XML::Ant::BuildFile::Target>
objects.

=head2 target_names

Returns a list of the target names from the build file.

=head2 has_target

Given a target name, returns true or false if the target exists.

=head2 num_targets

Returns a count of the number of targets in the build file.

=head2 BUILD

After construction, the app-wide L<XML::Ant::Properties|XML::Ant::Properties>
singleton stores any C<< <property/> >> name/value pairs set by the build file,
as well as any resource string expansions handled by
L<XML::Ant::BuildFile::Resource|XML::Ant::BuildFile::Resource> plugins.
It also contains the following predefined properties as per the Ant
documentation:

=over

=item os.name

=item basedir

=item ant.file

=item ant.project.name

=back

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
