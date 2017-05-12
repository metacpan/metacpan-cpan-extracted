package Wight::Chart;

#ABSTRACT: Save charts to images using phantomjs

our $VERSION = '0.003'; # VERSION

use strictures 1;
use Moo;
use Wight;
use Encode;
use File::Share qw/dist_file/;
use Cwd;
use JSON::XS;

has 'output' => ( is => 'rw', default => sub { 'example.png'} );
has 'rows' => ( is => 'rw' );
has 'options' => ( is => 'rw', default => sub { {} } );
has 'columns' => ( is => 'rw' );
has 'wight' => ( is => 'lazy' );
has 'width' => ( is => 'rw', default => 900 );
has 'height' => ( is => 'rw', default => 500 );

sub _build_wight {
  my $self = shift;
  my $wight = Wight->new();
  #File::Share won't work with dzil
  #
  my $file = -e 'share/' . $self->src_html ?
    getcwd . '/share/' . $self->src_html
    :
    dist_file('Wight-Chart', $self->src_html );

  $wight->resize($self->width, $self->height);
  $wight->visit("file:///$file");
  $wight;
}



1;

__END__

=pod

=encoding utf-8

=head1 NAME

Wight::Chart - Save charts to images using phantomjs

=head1 VERSION

version 0.003

=head1 SYNOPSIS

See Tests.

=head1 NAME

Wight::Chart - Generate static charts

This is pre-release software, everything could change and there are definitely bugs.

=head1 TODO

The long term plan is to allow output to be dynamic (javascript) or static (emails) and there will be a Zoom FilterBuilder to do this.

At the moment there isn't a unified source data definition (its library dependent. this will change.

The charts are reloaded using a new instance every time. this is slow and pointless, in the future they will use the same phantom instance.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/papercreatures/wight-chart/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/papercreatures/wight-chart>

  git clone git://github.com/papercreatures/wight-chart.git

=head1 AUTHOR

Simon Elliott <simon@papercreatures.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Simon Elliott.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
