use strict;
use warnings;
package inc::MakeMaker;
use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

# custom sharedir installation to delete the directory first
# (otherwise we might have old/broken tests lingering from the last installation)
around _build_share_dir_block => sub {
  my $orig = shift;
  my $self = shift;
  my $blocks = $self->$orig(@_);

  my @pre_lines = split /\n/, $blocks->[0];
  splice @pre_lines, -1, 0, ($pre_lines[-1] =~ s/install_share/delete_share/r);
  [ join("\n", @pre_lines), $blocks->[1] ];
};

1;
