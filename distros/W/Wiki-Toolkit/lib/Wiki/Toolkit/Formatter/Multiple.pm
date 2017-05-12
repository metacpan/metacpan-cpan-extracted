package Wiki::Toolkit::Formatter::Multiple;
use strict;

use vars qw( $VERSION );
$VERSION = '0.02';

=head1 NAME

Wiki::Toolkit::Formatter::Multiple - Allows a Wiki::Toolkit wiki to use more than one formatter.

=head1 DESCRIPTION

A "dummy" formatter for L<Wiki::Toolkit>.  Passes methods through to other
Wiki::Toolkit formatters, depending on supplied metadata.

=head1 SYNOPSIS

  use Wiki::Toolkit::Formatter::Multiple;
  use Wiki::Toolkit::Formatter::Pod;
  use Wiki::Toolkit::Formatter::UseMod;

  my $pod_fmtr = Wiki::Toolkit::Formatter::Pod->new(
      node_prefix => "wiki.cgi?node=",
  );

  my $usemod_fmtr = Wiki::Toolkit::Formatter::UseMod->new(
      node_prefix    => "wiki.cgi?node=",
      extended_links => 1,
      allowed_tags   => [ qw( p b i div br ) ],
  );

  my $formatter = Wiki::Toolkit::Formatter::Multiple->new(
      documentation => $pod_fmtr,
      discussion    => $usemod_fmtr,
      _DEFAULT      => $usemod_fmtr,
  );

  my $wiki = Wiki::Toolkit->new( store     => ...,
                                 formatter => $formatter );
  my $output = $wiki->format( "This is some discussion.",
                              { formatter => "discussion" } );
  
=head1 METHODS

=over

=item B<new>

  my $formatter = Wiki::Toolkit::Formatter::Multiple->new(
      label_1  => Formatter1->new( ... ),
      label_2  => Formatter2->new( ... ),
      _DEFAULT => Wiki::Toolkit::Formatter::Default->new,
  );

You may supply as many formatter objects as you wish.  They don't have
to be of different classes; you may just wish to, for example, permit
different HTML tags to be used on different types of pages.

The "labels" supplied as the keys of the parameter hash should be
unique.  When you write a node, you should store a key-value pair in
its metadata where the key is C<formatter> and the value is the label
of the formatter that should be used to render that node.

The C<_DEFAULT> label is special - it defines the formatter that will
be used for any node that does not have a C<formatter> stored in its
metadata.  The C<_DEFAULT> formatter, if not supplied to C<< ->new >>,
will default to the very basic L<Wiki::Toolkit::Formatter::Default>.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    unless ( $args{_DEFAULT} ) {
        require Wiki::Toolkit::Formatter::Default;
        $args{_DEFAULT} = Wiki::Toolkit::Formatter::Default->new;
    }
    $self->{formatters} = \%args;
    return $self;
}

=item B<format( $raw, \%metadata )>

    my $output = $formatter->format( "Here is some text.", undef,
                                     { formatter => "discussion" } );

Uses the value of C<formatter> given in the metadata to decide which
of the formatter objects passed on instantiation to use, then uses it
to format the provided rawwikitext.

The C<undef> second element of the parameter array in the example is
there because when this is called from a L<Wiki::Toolkit> object, the wiki
object passes itself in as the second parameter.

=cut

sub format {
    my ($self, $raw, $wiki, $metadata) = @_;
    return $self->_formatter($metadata)->format($raw, $wiki);
}

=item B<find_internal_links( $raw, $metadata )>

=cut

sub find_internal_links {
    my ($self, $raw, $metadata) = @_;
    return () unless $self->_formatter($metadata);
    return () unless $self->_formatter($metadata)->can("find_internal_links");
    return $self->_formatter($metadata)->find_internal_links($raw, $metadata);
}

# internal method to return the correct formatter for the current
# page.

sub _formatter {
    my $self = shift;
    my $metadata = shift;
    my $label = $metadata->{formatter} || "_DEFAULT";
    $label = $label->[0] if ref($label);
    return $self->{formatters}{$label} || $self->{formatters}{_DEFAULT};
}

=back

=head1 SEE ALSO

L<Wiki::Toolkit>

=head1 AUTHOR

Kake Pugh <kake@earth.li>

=head1 SUPPORT

Bug reports, questions and feature requests should go to cgi-wiki-dev@earth.li

=head1 COPYRIGHT

     Copyright (C) 2003-4 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
