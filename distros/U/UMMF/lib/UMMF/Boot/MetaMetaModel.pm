package UMMF::UML::MetaMetaModel;

use 5.6.1;
use strict;
#use warnings; # no warnings, too much hassle to make them go away.


our $AUTHOR = q{ kstephens@sourceforge.net 2004/04/06 };
our $VERSION = do { my @r = (q$Revision: 1.18 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::UML::MetaMetaModel - An implementation of the UML Meta-Meta-Model (M3).

=head1 SYNOPSIS

  use UMMF::UML::MetaMetaModel;
  my $factory = UMMF::UML::MetaMetaModel->factory;
  my $model = $factory->create('Model');
  $factory->create('Class', 'name' => 'Foo', 'namespace' => $model);
  ...

=head1 DESCRIPTION

This package implements a meta-meta-model (M3) for generating the UML metamodel (M2).

UMMF::UML::MetaMetaModel is not an implementation of the MOF; It is actually a subset of the 
1.5 Meta-model, as described in UML Spec. 1.5., p.2-13, but with a flattened package 
namespace.

It is the "Backbone" for generating the meta-model.

The UML 1.5 Meta-model is described in UMMF::UML::MetaModel package, in the ad-hoc language
imported by UMMF::UML::Import::MetaMetaModel.

This meta-model is then used to generate the Perl (or Java) code for the classes in
UMMF::UML::MetaModel::*.

The same exporters and importers can be used to process M* layers.

Thus, one description of the meta-model can generate multiple implementations.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@sourceforge.net 2003/04/06

=head1 SEE ALSO

L<UMMF::UML::MetaModel|UMMF::UML::MetaModel>

=head1 VERSION

$Revision: 1.18 $

=head1 METHODS

=cut

#######################################################################

# use UMMF::UML::MetaMetaModel::Util qw(:all);
use UMMF::UML::MetaMetaModel::FactoryBoot;
use UMMF::UML::MetaModel1;

#######################################################################

my $model;
sub model
{
  unless ( $model ) {
    $model = UMMF::UML::MetaModel1->model('factory' => 'UMMF::UML::MetaMetaModel::FactoryBoot', @_);
  }
  $model;
}


my $factory_map;
sub factory_map
{
  unless ( $factory_map ) {
    model();

    $factory_map = UMMF::UML::MetaMetaModel::FactoryBoot->factory_map;
  }

  $factory_map;
}


sub factory
{
  UMMF::UML::MetaMetaModel::FactoryBoot->factory;
}


1;

#######################################################################


### Keep these comments at end of file: kstephens@sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

