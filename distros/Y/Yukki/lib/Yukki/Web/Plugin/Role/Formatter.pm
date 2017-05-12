package Yukki::Web::Plugin::Role::Formatter;
{
  $Yukki::Web::Plugin::Role::Formatter::VERSION = '0.140290';
}
use 5.12.1;
use Moose::Role;

# ABSTRACT: interface for HTML formatters


requires qw( html_formatters );


sub has_format {
    my ($self, $media_type) = @_;
    return unless defined $media_type;
    return defined $self->html_formatters->{$media_type};
}


sub format {
    my ($self, $params) = @_;

    my $media_type = $params->{file}->media_type;
    return unless $self->has_format($media_type);

    my $format = $self->html_formatters->{$media_type};
    return $self->$format($params);
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::Plugin::Role::Formatter - interface for HTML formatters

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  package MyPlugins::SimpleText;
  use 5.12.1;
  use Moose;

  extends 'Yukki::Web::Plugin';

  has html_formatters => (
      is          => 'ro',
      isa         => 'HashRef[Str]',
      default     => sub { +{
          'text/simple' => 'format_simple',
        } },
  );

  with 'Yukki::Web::Plugin::Role::Formatter;

  sub format_simple {
      my ($self, $file) = @_;

      my $html = $file->fetch;
      $html =~ s/$/<br>/g;
      
      return [ { title => 'Simple' }, $html ];
  }

=head1 DESCRIPTION

This role defines the interface for file formatters. The first formatter matching the MIME type for a file will be used to format a page's contents as HTML.

=head1 REQUIRED METHODS

=head2 html_formatters

This must return a reference to a hash mapping MIME-types to method names.

The methods will be called with a hashref parameter containing the following:

=over

=item context

The current L<Yukki::Web::Context> object.

=item repository

The name of the repository this file is in.

=item page

The full path to the name of the file being formatted.

=item media_type

This is the media type that Yukki has detected for the file.

=item content

The body of the page as a string.

=back

The method should return an HTML document.

=head1 METHOD

=head2 has_format

  my $yes_or_no = $formatter->has_format($media_type);

Returns true if this formatter plugin has a formatter for the named media type.

=head2 format

  my $html = $self->format({
      context    => $ctx,
      repository => $repository,
      page       => $full_path,
      media_type => $media_type,
      content    => $content,
  });

Renders the text as HTML. If this plugin cannot format this media type, it
returns C<undef>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
