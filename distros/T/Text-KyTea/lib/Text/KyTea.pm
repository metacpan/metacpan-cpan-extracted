package Text::KyTea;

use 5.008_001;
use strict;
use warnings;

use Carp ();

our $VERSION = '0.44';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);


sub _options
{
    return {
        # analysis options
        model   => '/usr/local/share/kytea/model.bin',
        nows    => 0,
        notags  => 0,
        notag   => [],
        nounk   => 0,
        unkbeam => 50,

        # I/O options
        tagmax  => 3,
        deftag  => 'UNK',
        unktag  => '',

        # advanced I/O options
        wordbound => ' ',
        tagbound  => '/',
        elembound => '&',
        unkbound  => ' ',
        skipbound => '?',
        nobound   => '-',
        hasbound  => '|',

        # Text::KyTea options
        prontag_num => 1,
    };
}

sub new
{
    my $class = shift;
    my %args  = (ref $_[0] eq 'HASH' ? %{$_[0]} : @_);

    my $options = $class->_options;

    for my $key (keys %args)
    {
        if ( ! exists $options->{$key} ) { Carp::croak "Unknown option: '$key'";  }
        else                             { $options->{$key} = $args{$key};        }
    }

    Carp::croak 'model file not found' unless -e $options->{model};

    return _init_text_kytea($class, $options);
}

1;

__END__

=encoding utf8

=head1 NAME

Text::KyTea - Perl wrapper for KyTea

=for test_synopsis
my ($text, %config);

=head1 SYNOPSIS

  use Text::KyTea;

  my $kytea   = Text::KyTea->new(%config);
  my $results = $kytea->parse($text);

  for my $result (@{$results})
  {
      print $result->{surface};

      for my $tags (@{$result->{tags}})
      {
          print "\t";

          for my $tag (@{$tags})
          {
              print " ", $tag->{feature}, "/", $tag->{score};
          }
      }

      print "\n";
  }


=head1 DESCRIPTION

KyTea is a general toolkit developed for analyzing text,
with a focus on Japanese, Chinese and other languages
requiring word or morpheme segmentation.

This module works under KyTea Ver.0.4.2 and later.
Under the old versions of KyTea, this module does not work!

If you've changed the default install directory of KyTea,
please install Text::KyTea in interactive mode
(e.g., cpanm --interactive or cpanm -v).

For more information about KyTea, please see the "SEE ALSO" section of this page.


=head1 METHODS

=head2 $kytea = Text::KyTea->new(%config)

Creates a new Text::KyTea instance.

  my $kytea = Text::KyTea->new(
      model       => 'model.bin', # default is "$INSTALL_DIRECTORY/share/kytea/model.bin"
      notag       => [1,2],       # default is []
      nounk       => 0,           # default is 0 (Estimates the pronunciation of unkown words.)
      unkbeam     => 50,          # default is 50
      tagmax      => 3,           # default is 3
      deftag      => 'UNK',       # default is 'UNK'
      unktag      => '',          # default is ''
      prontag_num => 1,           # default is 1 (Normally no need to change the default value.)
  );


=head2 $results_arrayref = $kytea->parse($text)

Parses the given text via KyTea, and returns the results.
The results are returned as an array reference.


=head2 $pron = $kytea->pron( $text [, $replacement ] )

Returns the estimated pronunciation of the given text.
Unknown pronunciations are replaced with $replacement.

If $replacement is not specified, unknown pronunciations
are replaced with the original characters.

This is the mere shortcut method.


=head2 $kytea->read_model($path)

Reads the given model file.
Model files should be read by new(model => $path) method.

Model files are available at L<http://www.phontron.com/kytea/model.html>.


=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

L<http://www.phontron.com/kytea/>

=head1 LICENSE

Copyright (C) pawa All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
