package XML::Ant::BuildFile::Task::Java;

#pod =head1 DESCRIPTION
#pod
#pod This is an incomplete class for Ant Java tasks in a
#pod L<build file project|XML::Ant::BuildFile::Project>.
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use XML::Ant::BuildFile::Project;
#pod     my $project = XML::Ant::BuildFile::Project->new( file => 'build.xml' );
#pod     my @foo_java = $project->target('foo')->tasks('java');
#pod     for my $java (@foo_java) {
#pod         print $java->classname || "$java->jar";
#pod         print "\n";
#pod     }
#pod
#pod =cut

# ABSTRACT: Java task node in an Ant build file

use utf8;
use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

our $VERSION = '0.217';     # VERSION
use Carp;
use English '-no_match_vars';
use Modern::Perl;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(ArrayRef Str);
use MooseX::Types::Path::Class 'File';
use Path::Class;
use XML::Ant::Properties;
use namespace::autoclean;
with 'XML::Ant::BuildFile::Task';

my %xpath_attr = (
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)

    #pod =attr classname
    #pod
    #pod A string representing the Java class that's executed.
    #pod
    #pod =cut

    classname  => './@classname',
    _jar       => './@jar',
    _args_attr => './@args',
);

while ( my ( $attr, $xpath ) = each %xpath_attr ) {
    has $attr => ( ro,
        isa         => Str,
        traits      => ['XPathValue'],
        xpath_query => $xpath,
    );
}

#pod =attr jar
#pod
#pod A L<Path::Class::File|Path::Class::File> for the jar file being executed.
#pod
#pod =cut

has jar => ( ro, lazy,
    isa     => File,
    default => sub { file( XML::Ant::Properties->apply( $_[0]->_jar ) ) },
);

has _args => ( ro,
    isa         => 'ArrayRef[XML::Ant::BuildFile::Element::Arg]',
    traits      => [qw(XPathObjectList Array)],
    xpath_query => './arg',

    #pod =method args
    #pod
    #pod Returns a list of all arguments passed to the Java class.
    #pod
    #pod =cut

    handles => { args => [ map => sub { $_->args } ] },
);

no Moose;

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

XML::Ant::BuildFile::Task::Java - Java task node in an Ant build file

=head1 VERSION

version 0.217

=head1 SYNOPSIS

    use XML::Ant::BuildFile::Project;
    my $project = XML::Ant::BuildFile::Project->new( file => 'build.xml' );
    my @foo_java = $project->target('foo')->tasks('java');
    for my $java (@foo_java) {
        print $java->classname || "$java->jar";
        print "\n";
    }

=head1 DESCRIPTION

This is an incomplete class for Ant Java tasks in a
L<build file project|XML::Ant::BuildFile::Project>.

=head1 ATTRIBUTES

=head2 classname

A string representing the Java class that's executed.

=head2 jar

A L<Path::Class::File|Path::Class::File> for the jar file being executed.

=head1 METHODS

=head2 args

Returns a list of all arguments passed to the Java class.

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
