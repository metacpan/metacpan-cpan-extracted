package WWW::Wikipedia::TemplateFiller::WebApp;
use base 'CGI::Application';

use WWW::Wikipedia::TemplateFiller;
use XML::Writer;
use Tie::IxHash;

=head1 NAME

WWW::Wikipedia::TemplateFiller::WebApp - Web interface to WWW::Wikipedia::TemplateFiller

=head1 SYNOSPSIS

Inside the index.cgi instance script:

  #!/usr/bin/perl
  use WWW::Wikipedia::TemplateFiller::WebApp;

  my %config = (
    template_path => '/path/to/web/templates',
    isbndb_access_key => 'access key here',
  );

  WWW::Wikipedia::TemplateFiller::WebApp->new( PARAMS => \%config )->run

=head1 DESCRIPTION

This module provides a L<CGI::Application> interface to
L<WWW::Wikipedia::TemplateFiller> so that the work of
L<http://diberri.dyndns.org/cgi-bin/templatefiller/> can be
distributed across multiple servers.

Please see the included INSTALL file for detailed installation
instructions.

=head1 METHODS

=head2 setup

Sets up the app for L<CGI::Application>.

=cut

sub setup {
  my $self = shift;
  $self->error_mode( 'display_error' );
  $self->tmpl_path( $self->param('template_path') );
  $self->mode_param('f');
  $self->start_mode('view');
  $self->run_modes(
    view => 'view_page',
  );
  $self->header_add( -charset => 'utf-8' );
}

=head2 view_page

Method corresponding to the C<view> run mode, which constructs both
the input form and the results page.

=cut

sub view_page {
  my $self = shift;
  my $q = $self->query;
  my %params = $self->query_params;

  my $type = $q->param('type');
  my $id = $q->param('id');

  my $error_message = '';
  if( $type and !$self->known_data_source($type) ) {
    $error_message = "No such template type.";
    $id = '';
  }
  
  my( $filler, $source, $template_markup );
  my $source_url = '';
  if( $type and $id ) {
    $filler = new WWW::Wikipedia::TemplateFiller( isbndb_access_key => $self->param('isbndb_access_key') );

    eval {
      $source = $filler->get( $type => $id, %config );
    };
    $error_message = $@;

    if( $source ) {
      # encode_entities=>1 so that HTML entities are escaped in the
      # wiki markup, so that the html::template template doesn't have
      # to do an escape=html. This is so things like raw endashes are
      # converted into &ndash; and output as &ndash;, and not a raw
      # endash. Recall that escape=html only does <, >, and &. But we
      # also need things like raw endashes encoded as well to prevent
      # some weird browser behavior.
      $template_markup = $source->fill(%params)->output( %params, encode_entities => 1);
    } else {
      $error_message ||= "Could not find requested source.";
    }
  }

  my $format = $q->param('format') || '';

  if( $format eq 'xml' and $id and $type ) {
    my $xml = '';
    my $writer = new XML::Writer( OUTPUT => \$xml, DATA_MODE => 1, DATA_INDENT => '  ' );
    $writer->xmlDecl('utf-8');
    $writer->startTag( 'wikitool', application => 'cite' );

    $writer->startTag( 'query' );
      $writer->startTag( 'id', type => $type );
      $writer->characters( $id );
      $writer->endTag();
    $writer->endTag();

    $writer->startTag( 'response', status => $template_markup ? 'ok' : 'error' );
    if( $template_markup ) {
      $writer->startTag('source');
      $writer->characters( $source_url );
      $writer->endTag();

      $writer->startTag( 'content', template => 'Template:'.ucfirst($source->template_name) );
      $writer->characters( $template_markup );
      $writer->endTag();

      $writer->startTag('paramlist');
      while( my( $k, $v ) = each %params ) {
        $writer->startTag( 'param', name => $k );
        $writer->characters($v);
        $writer->endTag();
      }
      $writer->endTag();
    } else {
      $writer->startTag( 'error' );
      $writer->characters( 'Citation could not be generated, perhaps because the requested reference could not be found.' );
      $writer->endTag();
    }

    $writer->endTag();
    $writer->endTag();
    $writer->end();

    return $xml;
  }

  my $data_sources = $self->data_sources;
  my $selected_type = $type || 'pubmed_id';
  foreach ( @$data_sources ) {
    $_->{selected} = ( $selected_type eq $_->{source} );
  }

  my $temp = $self->load_template( 'start.html' );
  $temp->param(
    error_message    => $error_message,
    template_markup  => $template_markup,
    data_sources     => $data_sources,
    checkbox_options => $self->checkbox_options,
    source_url       => $source_url,
    $self->query_params,
  );

  my $output = '';
  $output .= $temp->output;

  return $output;
}

=head2 load_template

Loads the specified L<HTML::Template> template.

=cut

sub load_template {
  my( $self, $file ) = @_;
  return $self->load_tmpl( $file, die_on_bad_params => 0, loop_context_vars => 1, cache => 1 );
}

=head2 known_data_source

  my $bool = $self->known_data_source( $id_name );

Returns true if C<$id_name> refers to a valid data source. For
example, returns true if C<$id_name> is C<'pubmed_id'> but returns
false if C<$id_name> is C<'something_else'>.

=cut

sub known_data_source {
  my( $self, $source ) = @_;
  return $self->_known_data_sources->{$source};
}

sub _known_data_sources {
  my $self = shift;
  return $self->{_all_known_data_sources} if $self->{_all_known_data_sources};

  my %keyed;
  foreach my $ds ( @{ $self->data_sources } ) {
    $keyed{ $ds->{source} } = $ds;
  }
  
  $self->{_all_known_data_sources} = \%keyed;
}

=head2 data_sources

Returns all data sources in an array reference.

=cut

sub data_sources {
  return [
    { name => 'DrugBank ID',       source => 'drugbank_id',        template => 'drugbox',      example_id => 'DB00328' },
    { name => 'HGNC ID',           source => 'hgnc_id',            template => 'protein',      example_id => '12403' },
    { name => 'ISBN',              source => 'isbn',               template => 'cite_book',    example_id => '0721659446' },
    { name => 'PubMed ID',         source => 'pubmed_id',          template => 'cite_journal', example_id => '123455' },
    { name => 'PubMed Central ID', source => 'pubmedcentral_id',   template => 'cite_journal', example_id => '137841' },
    { name => 'PubChem ID',        source => 'pubchem_id',         template => 'chembox',      example_id => '2244' },
    { name => 'URL',               source => 'url',                template => 'cite_web',     example_id => 'http://en.wikipedia.org' },
  ];
}

=head2 query_params

Returns all relevant query params passed in this HTTP request.

=cut

sub query_params {
  my $self = shift;
  my $q = $self->query;
  my $params = $self->params;

  return map {
    $_ => $q->param($_) || '' # was 0 instead of ''
  } keys %$params;
}

=head2 params

Returns all known parameters and their labels.

=cut

sub params {
  my $self = shift;

  tie( my %params, 'Tie::IxHash' );

  my $param_groups = $self->_params;
  foreach my $g ( @$param_groups ) {
    my $group = $g->{group};   # scalar
    my $params = $g->{params}; # arrayref
    
    for( my $i = 0; $i < @$params; $i+=2 ) {
      my( $param, $param_spec ) = ( $params->[$i], $params->[$i+1] );
      $params{$param} = $param_spec->{label};
    }
  }

  return \%params;
}

# A sensible data structure for parameters, but not particularly
# useful at present.
sub _params {
  my @param_groups = (
    {
      group => 'basic',
      params => [
        type            => { label => undef },
        id              => { label => undef },

        vertical        => { label => 'Fill vertically' },
        extended        => { label => 'Show extended fields' },
        add_param_space => { label => 'Pad parameter names and values' },
      ]
    },

    {
      group => 'pubmed_id',
      params => [
        add_ref_tag                => { label => 'Add ref tag' },
        dont_use_etal              => { label => "Don't use <i>et al.</i> for author list" },

        omit_url_if_doi_filled     => { label => 'Omit URL field if DOI field is populated (journals only)' },
        dont_strip_trailing_period => { label => "Don't strip trailing period from article title" },

        full_journal_title         => { label => 'Use full journal title' },
        link_journal               => { label => 'Link journal title' },

        add_text_url               => { label => 'Add URL (if available)' },
        add_accessdate             => { label => 'Add access date (if relevant)' },
      ]
    },
  );

  return \@param_groups;
}

=head2 checkbox_options

Same as C<params> but suitable output for L<CGI::checkbox> calls.

=cut

sub checkbox_options {
  my $self = shift;

  my $params = $self->params;
  my %qp = $self->query_params;

  my @options;
  foreach my $p ( keys %$params ) {
    push @options, { name => $p, value => 1, checked => $qp{$p}, id => $p, label => $params->{$p} };
  }

  # Remove 'type' and 'id'
  shift @options for 1..2;

  return \@options;
}

=head2 display_error

Error-catching method called by L<CGI::Application> if a run mode
fails for any reason. Displays a basic form with a styled error
message up top.

=cut

sub display_error {
  my( $self, $raw_error ) = @_;

  ( my $error = $raw_error ) =~ s{(.*?) at \S+ line \d+\.}{$1.};
  $error = ucfirst $error;

  my $tmpl = $self->load_template( 'start.html' );
  $tmpl->param(
    error_message => $error
  );

  return $tmpl->output;
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-wikipedia-templatefiller at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Wikipedia-TemplateFiller>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Wikipedia::TemplateFiller

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Wikipedia-TemplateFiller>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Wikipedia-TemplateFiller>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Wikipedia-TemplateFiller>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Wikipedia-TemplateFiller>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
