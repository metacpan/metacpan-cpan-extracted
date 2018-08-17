package XML::SemanticDiff::BasicHandler;

use strict;
use warnings;

our $VERSION = '1.0006';

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = \%args;
    bless ($self, $class);
    return $self;
}

sub rogue_element {
    my $self = shift;
    my ($element, $properties) = @_;
    my ($element_name, $parent) = parent_and_name($element);
    my $info = {context => $parent,
                message => "Rogue element '$element_name' in element '$parent'."};

    if ($self->{keeplinenums}) {
        $info->{startline} = $properties->{TagStart};
        $info->{endline}   = $properties->{TagEnd};
    }

    if ($self->{keepdata}) {
        $info->{new_value} = $properties->{CData};
    }
    return $info;
}

sub missing_element {
    my $self = shift;
    my ($element, $properties) = @_;
    my ($element_name, $parent) = parent_and_name($element);
    my $info = {context => $parent,
                message => "Child element '$element_name' missing from element '$parent'."};

    if ($self->{keeplinenums}) {
        $info->{startline} = $properties->{TagStart};
        $info->{endline}   = $properties->{TagEnd};
    }
    if ($self->{keepdata}) {
        $info->{old_value} = $properties->{CData};
    }
    return $info;
}

sub element_value {
    my $self = shift;
    my ($element, $new_properties, $old_properties) = @_;
    my ($element_name, $parent) = parent_and_name($element);

    my $info = {context => $element,
                message => "Character differences in element '$element_name'."};

    if ($self->{keeplinenums}) {
        $info->{startline} = $new_properties->{TagStart};
        $info->{endline}   = $new_properties->{TagEnd};
    }

    if ($self->{keepdata}) {
        $info->{old_value} = $old_properties->{CData};
        $info->{new_value} = $new_properties->{CData};
    }

    return $info;
}

sub rogue_attribute {
    my $self = shift;
    my ($attr, $element, $properties) = @_;
    my ($element_name, $parent) = parent_and_name($element);
    my $info = {context  => $element,
                message  => "Rogue attribute '$attr' in element '$element_name'."};

    if ($self->{keeplinenums}) {
        $info->{startline} = $properties->{TagStart};
        $info->{endline}   = $properties->{TagEnd};
    }

    if ($self->{keepdata}) {
        $info->{new_value} = $properties->{Attributes}->{$attr};
    }
    return $info;
}

sub missing_attribute {
    my $self = shift;
    my ($attr, $element, $new_properties, $old_properties) = @_;
    my ($element_name, $parent) = parent_and_name($element);
    my $info = {context  => $element,
                message  => "Attribute '$attr' missing from element '$element_name'."};

    if ($self->{keeplinenums}) {
        $info->{startline} = $new_properties->{TagStart};
        $info->{endline}   = $new_properties->{TagEnd};
    }

    if ($self->{keepdata}) {
        $info->{old_value} = $old_properties->{Attributes}->{$attr};
    }
    return $info;
}

sub attribute_value {
    my $self = shift;
    my ($attr, $element, $new_properties, $old_properties) = @_;
    my ($element_name, $parent) = parent_and_name($element);
    my $info = {context  => $element,
                message  => "Attribute '$attr' has different value in element '$element_name'."};

    if ($self->{keeplinenums}) {
        $info->{startline} = $new_properties->{TagStart};
        $info->{endline}   = $new_properties->{TagEnd};
    }

    if ($self->{keepdata}) {
        $info->{old_value} = $old_properties->{Attributes}->{$attr};
        $info->{new_value} = $new_properties->{Attributes}->{$attr};
    }
    return $info;
}

sub namespace_uri {
    my $self = shift;
    my ($element, $new_properties, $old_properties) = @_;
    my ($element_name, $parent) = parent_and_name($element);
    my $info = {context  => $element,
                message  => "Element '$element_name' within different namespace."};

    if ($self->{keeplinenums}) {
        $info->{startline} = $new_properties->{TagStart};
        $info->{endline}   = $new_properties->{TagEnd};
    }

    if ($self->{keepdata}) {
        $info->{old_value} = $old_properties->{NamspaceURI};
        $info->{new_value} = $new_properties->{NamspaceURI};
    }
    return $info;
}

sub parent_and_name {
    my $element = shift;
    my @steps = split('/', $element);
    my $element_name = pop (@steps);
    my $parent = join '/', @steps;
    $element_name =~ s/\[\d+\]$//;
    return ($element_name, $parent);
}

1;

__END__

=pod

=head1 NAME

XML::SemanticDiff::BasicHandler - Default handler class for XML::SemanticDiff

=head1 VERSION

version 1.0007

=head1 SYNOPSIS

  use XML::SemanticDiff;
  my $diff = XML::SemanticDiff->new();

  foreach my $change ($diff->compare($file, $file2)) {
      print "$change->{message} in context $change->{context}\n";
  }

=head1 DESCRIPTION

This is the default event handler for XML::SemanticDiff. It implements nothing useful apart from the parent class and should
never be used directly.

Please run perldoc XML::SemanticDiff for more information.

=head1 VERSION

version 1.0007

=head1 IMPLEMENTED METHODS (FOR INTERNAL USE)

=head2 new
=head2 rogue_element
=head2 missing_element
=head2 element_value
=head2 rogue_attribute
=head2 missing_attribute
=head2 attribute_value
=head2 namespace_uri
=head2 parent_and_name

=head1 AUTHOR

Kip Hampton khampton@totalcinema.com

=head1 COPYRIGHT

Copyright (c) 2000 Kip Hampton. All rights reserved. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

XML::SemanticDiff

=head1 AUTHORS

=over 4

=item *

Shlomi Fish <shlomif@cpan.org>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by Kip Hampton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-XML-SemanticDiff/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::SemanticDiff::BasicHandler

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-SemanticDiff>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-SemanticDiff>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-SemanticDiff>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-SemanticDiff>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-SemanticDiff>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-SemanticDiff>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-SemanticDiff>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-SemanticDiff>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::SemanticDiff>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-semanticdiff at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-SemanticDiff>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-XML-SemanticDiff>

  git clone git://github.com/shlomif/perl-XML-SemanticDiff.git

=cut
