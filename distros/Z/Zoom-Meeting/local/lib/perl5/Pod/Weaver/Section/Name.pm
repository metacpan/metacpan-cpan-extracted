package Pod::Weaver::Section::Name 4.019;
# ABSTRACT: add a NAME section with abstract (for your Perl module)

use Moose;
with 'Pod::Weaver::Role::Section',
     'Pod::Weaver::Role::StringFromComment';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

#pod =head1 OVERVIEW
#pod
#pod This section plugin will produce a hunk of Pod giving the name of the document
#pod as well as an abstract, like this:
#pod
#pod   =head1 NAME
#pod
#pod   Some::Document - a document for some
#pod
#pod It will determine the name and abstract by inspecting the C<ppi_document> which
#pod must be given.  It looks for comments in the form:
#pod
#pod
#pod   # ABSTRACT: a document for some
#pod   # PODNAME: Some::Package::Name
#pod
#pod If no C<PODNAME> comment is present, but a package declaration can be found,
#pod the package name will be used as the document name.
#pod
#pod =attr header
#pod
#pod The title of the header to be added.
#pod (default: "NAME")
#pod
#pod =cut

has header => (
  is      => 'ro',
  isa     => 'Str',
  default => 'NAME',
);

use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Nested;

sub _get_docname_via_statement {
  my ($self, $ppi_document) = @_;

  my $pkg_node = $ppi_document->find_first('PPI::Statement::Package');
  return unless $pkg_node;
  return $pkg_node->namespace;
}

sub _get_docname_via_comment {
  my ($self, $ppi_document) = @_;

  return $self->_extract_comment_content($ppi_document, 'PODNAME');
}

sub _get_docname {
  my ($self, $input) = @_;

  my $ppi_document = $input->{ppi_document};

  my $docname = $self->_get_docname_via_comment($ppi_document)
             || $self->_get_docname_via_statement($ppi_document);

  return $docname;
}

sub _get_abstract {
  my ($self, $input) = @_;

  my $comment = $self->_extract_comment_content($input->{ppi_document}, 'ABSTRACT');

  return $comment if $comment;

  # If that failed, fall back to searching the whole document
  my ($abstract)
    = $input->{ppi_document}->serialize =~ /^\s*#+\s*ABSTRACT:\s*(.+)$/m;

  return $abstract;
}

sub weave_section {
  my ($self, $document, $input) = @_;

  my $filename = $input->{filename} || 'file';

  my $docname  = $self->_get_docname($input);
  my $abstract = $self->_get_abstract($input);

  Carp::croak sprintf "couldn't determine document name for %s\nAdd something like this to %s:\n# PODNAME: bobby_tables.pl", $filename, $filename
    unless $docname;

  $self->log([ "couldn't find abstract in %s", $filename ]) unless $abstract;

  my $name = $docname;
  $name .= " - $abstract" if $abstract;

  $self->log_debug(qq{setting NAME to "$name"});

  my $name_para = Pod::Elemental::Element::Nested->new({
    command  => 'head1',
    content  => $self->header,
    children => [
      Pod::Elemental::Element::Pod5::Ordinary->new({ content => $name }),
    ],
  });

  push $document->children->@*, $name_para;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Name - add a NAME section with abstract (for your Perl module)

=head1 VERSION

version 4.019

=head1 OVERVIEW

This section plugin will produce a hunk of Pod giving the name of the document
as well as an abstract, like this:

  =head1 NAME

  Some::Document - a document for some

It will determine the name and abstract by inspecting the C<ppi_document> which
must be given.  It looks for comments in the form:

  # ABSTRACT: a document for some
  # PODNAME: Some::Package::Name

If no C<PODNAME> comment is present, but a package declaration can be found,
the package name will be used as the document name.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 header

The title of the header to be added.
(default: "NAME")

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
