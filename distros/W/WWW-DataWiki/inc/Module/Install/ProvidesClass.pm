#line 1
package Module::Install::ProvidesClass;

use strict;
use warnings;
use Module::Install::Base;


BEGIN {
  our @ISA = qw(Module::Install::Base);
  our $ISCORE  = 1;
  our $VERSION = '1.000000';
}

sub _get_no_index {
  my ($self) = @_;

  my $meta;
  {
    # dump_meta does stupid munging/defaults of the Meta values >_<
    no warnings 'redefine';
    local *YAML::Tiny::Dump = sub {
      $meta = shift;
    };
    $self->admin->dump_meta;
  }
  return $meta->{no_index} || { };
}

sub _get_dir {
  $_[0]->_top->{base};
}

sub auto_provides_class {
  my ($self, @keywords) = @_;

  return $self unless $self->is_admin;

  @keywords = ('class','role') unless @keywords;

  require Class::Discover;

  my $no_index = $self->_get_no_index;

  my $dir = $self->_get_dir;

  my $classes = Class::Discover->discover_classes({
    no_index => $no_index,
    dir => $dir,
    keywords => \@keywords
  });

  for (@$classes) {
    my ($class,$info) = each (%$_);
    delete $info->{type};
    $self->provides( $class => $info ) 
  }
}

1;

