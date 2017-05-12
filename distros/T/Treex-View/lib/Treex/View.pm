package Treex::View;
our $AUTHORITY = 'cpan:MICHALS';
$Treex::View::VERSION = '1.0.0';
# ABSTRACT: Converts Treex::Core::Document to JSON

use Moose;
use Treex::Core::Document;
use Treex::Core::TredView;
use Treex::Core::TredView::Labels;
use Treex::PML::Factory;
use Treex::View::TreeLayout;
use Treex::View::Node;
use JSON;

use File::Basename 'dirname';
use File::Spec ();
use File::ShareDir 'dist_dir';

use namespace::autoclean;

has 'tree_layout' => (
  is => 'ro',
  isa => 'Treex::View::TreeLayout',
  default => sub { Treex::View::TreeLayout->new },
);

has 'static_dir' => (
  is => 'ro',
  default => sub {
    my $package_name = __PACKAGE__;
    $package_name =~ s/::/-/;
    my $shared_dir = eval { dist_dir($package_name) };

    # Assume installation
    unless ($shared_dir) {
      my $updir = File::Spec->updir();
      $shared_dir = File::Spec->catdir(dirname(__FILE__), $updir, $updir, 'share');
    }

    File::Spec->catdir($shared_dir, 'static')
  }
);

# fake TredMacro package so that TMT TrEd macros can be used directly
{
  package # ignore this package
    TredMacro;
  use List::Util qw(first);
  use vars qw($this $root $grp @EXPORT);
  @EXPORT=qw($this $root $grp FS first GetStyles AddStyle ListV);
  use Exporter 'import';
  sub FS { $grp->{FSFile}->FS } # used by TectoMT_TredMacros.mak
  sub GetStyles {               # used by TectoMT_TredMacros.mak
    my ($styles,$style,$feature)=@_;
    my $s = $styles->{$style} || return;
    if (defined $feature) {
      return $s->{ $feature };
    } else {
      return %$s;
    }
  }

  sub AddStyle {
    my ($styles,$style,%s)=@_;
    if (exists($styles->{$style})) {
      $styles->{$style}{$_}=$s{$_} for keys %s;
    } else {
      $styles->{$style}=\%s;
    }
  }

  sub ListV {
    UNIVERSAL::DOES::does($_[0], 'Treex::PML::List') ? @{$_[0]} : ()
  }

  # maybe more will be needed for drawing arrows, need example
}

sub convert {
  my ($self, $doc, $pretty) = @_;

  $self->tree_layout->treex_doc($doc);
  my $labels = Treex::Core::TredView::Labels->new( _treex_doc => $doc );

  my @bundles;
  foreach my $bundle ($doc->get_bundles) {
    my %bundle;
    my %zones;
    $bundle{zones} = \%zones;
    foreach my $zone ( $bundle->get_all_zones ) {
      my %trees;
      foreach my $tree ( $zone->get_all_trees ) {
        my $tree_label = $self->tree_layout->get_tree_label($tree);
        my @nodes = (map { Treex::View::Node->new(node => $_, labels => $labels) }
                         $self->tree_layout->get_nodes($tree));
        $trees{$tree_label} = {
          nodes => \@nodes,
          language => $tree->language,
          layer => $tree->get_layer,
        };
      }
      $zones{$self->tree_layout->get_zone_label($zone)} = {
        trees => \%trees,
        sentence => $zone->sentence
      };
    }
    $bundle{desc} = $self->tree_layout->value_line($bundle);
    push @bundles, \%bundle;
  }

  my $json = JSON->new->allow_nonref->allow_blessed->convert_blessed;
  $json = $json->pretty if $pretty;

  return $json->encode(\@bundles);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 AUTHOR

Michal Sedlak E<lt>sedlak@ufal.mff.cuni.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Michal Sedlak

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
