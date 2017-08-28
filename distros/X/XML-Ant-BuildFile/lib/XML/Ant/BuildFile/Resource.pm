package XML::Ant::BuildFile::Resource;

# ABSTRACT: Role for Ant build file resources

#pod =head1 DESCRIPTION
#pod
#pod This is a role shared by resources in an
#pod L<XML::Ant::BuildFile::Project|XML::Ant::BuildFile::Project>.
#pod
#pod =head1 SYNOPSIS
#pod
#pod     package XML::Ant::BuildFile::Resource::Foo;
#pod     use Moose;
#pod     with 'XML::Ant::BuildFile::Resource';
#pod
#pod     after BUILD => sub {
#pod         my $self = shift;
#pod         print "I'm a ", $self->resource_name, "\n";
#pod     };
#pod
#pod     1;
#pod
#pod =cut

use utf8;
use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

our $VERSION = '0.217';     # VERSION
use strict;
use English '-no_match_vars';
use Moose::Role;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(Maybe Str);
use namespace::autoclean;
with 'XML::Ant::BuildFile::Role::InProject';

#pod =attr resource_name
#pod
#pod Name of the task's XML node.
#pod
#pod =cut

has resource_name => ( ro, lazy,
    isa      => Str,
    init_arg => undef,
    default  => sub { $_[0]->node->nodeName },
);

requires qw(as_string content);

#pod =attr as_string
#pod
#pod Every role consumer must implement the C<as_string> method.
#pod
#pod =cut

around as_string => sub {
    my ( $orig, $self ) = splice @_, 0, 2;
    return $self->$orig(@_) if !$self->_refid;

    my $antecedent = $self->project->find_resource(
        sub {
            $_->resource_name eq $self->resource_name
                and $_->id eq $self->_refid;
        },
    );
    return $antecedent->as_string;
};

#pod =attr content
#pod
#pod C<XML::Ant::BuildFile::Resource> provides a
#pod default C<content> attribute, but it only returns C<undef>.  Consumers should
#pod use the C<around> method modifier to return something else in order to
#pod support resources with C<refid> attributes
#pod
#pod =cut

has content => ( ro, lazy, builder => '_build_content', isa => Maybe );

around content => sub {
    my ( $orig, $self ) = splice @_, 0, 2;
    return $self->$orig(@_) if !$self->_refid;

    my $antecedent = $self->project->find_resource(
        sub {
            $_->resource_name eq $self->resource_name
                and $_->id eq $self->_refid;
        },
    );
    return $antecedent->content;
};

#pod =method BUILD
#pod
#pod After a resource is constructed, it adds its L<id|/id> and
#pod L<string representation|/as_string> to the
#pod L<XML::Ant::Properties|XML::Ant::Properties> singleton with C<toString:>
#pod prepended to the C<id>.
#pod
#pod =cut

sub BUILD {
    my $self = shift;
    if ( $self->id ) {
        XML::Ant::Properties->set(
            'toString:' . $self->id => $self->as_string );
    }
    return;
}

## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)

#pod =attr id
#pod
#pod C<id> attribute of this resource.
#pod
#pod =cut

has id =>
    ( ro, isa => Str, traits => ['XPathValue'], xpath_query => './@id' );
has _refid => ( ro,
    isa         => Str,
    traits      => ['XPathValue'],
    xpath_query => './@refid',
);

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

XML::Ant::BuildFile::Resource - Role for Ant build file resources

=head1 VERSION

version 0.217

=head1 SYNOPSIS

    package XML::Ant::BuildFile::Resource::Foo;
    use Moose;
    with 'XML::Ant::BuildFile::Resource';

    after BUILD => sub {
        my $self = shift;
        print "I'm a ", $self->resource_name, "\n";
    };

    1;

=head1 DESCRIPTION

This is a role shared by resources in an
L<XML::Ant::BuildFile::Project|XML::Ant::BuildFile::Project>.

=head1 ATTRIBUTES

=head2 resource_name

Name of the task's XML node.

=head2 as_string

Every role consumer must implement the C<as_string> method.

=head2 content

C<XML::Ant::BuildFile::Resource> provides a
default C<content> attribute, but it only returns C<undef>.  Consumers should
use the C<around> method modifier to return something else in order to
support resources with C<refid> attributes

=head2 id

C<id> attribute of this resource.

=head1 METHODS

=head2 BUILD

After a resource is constructed, it adds its L<id|/id> and
L<string representation|/as_string> to the
L<XML::Ant::Properties|XML::Ant::Properties> singleton with C<toString:>
prepended to the C<id>.

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
