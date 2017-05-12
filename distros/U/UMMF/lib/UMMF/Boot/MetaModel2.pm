package UMMF::UML::MetaModel;

use 5.6.1;
use strict;
use warnings;

our $AUTHOR = q{ ks.perl@kurtstephens.com 2003/04/06 };
our $VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::UML::MetaModel - An implementation of UML 1.5 Meta-model (M1).

=head1 SYNOPSIS

  use UMMF::UML::MetaModel;
  use UMMF::UML::Export::XMI;
  use UMMF::UML::Export::Perl;
  my $f = UMMF::UML::MetaModel->factory;
  my $model = $f->create('Model');
  my $cls = $f->create('Class', 
                       'name' => 'AClass',
                       'namespace' => $root,
		       );
  my $attr = $f->create('Attribute',
	 	        'type' => $cls,
		        'name' => 'foobar',
		        'visibility' => 'public',
		        'owner' => $cls,
		        );

  # Generate XMI for the model.
  UMMF::UML::Export::XMI->new()->export_Model($model);
  # Generate Perl code of the model.
  UMMF::UML::Export::Perl->new('packagePrefix' => 'My::Package')->export_Model($model);


  # Generate XMI for the UML meta-model itself!!!
  my $metamodel = UMMF::UML::MetaModel->model;
  UMMF::UML::Export::XMI->new()->export_Model($metamodel);


=head1 DESCRIPTION

This package allow UML models to be represented and queried from within perl.
It implements both the UML meta-meta-model and meta-model.

=head1 USAGE

=head1 PATTERNS

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, ks.perl@kurtstephens.com 2003/04/06

=head1 SEE ALSO

L<UMMF::UML::MetaMetaModel|UMMF::UML::MetaMetaModel>

=head1 VERSION

$Revision: 1.10 $

=head1 METHODS

=cut

####################################################################################

use UMMF::UML::MetaMetaModel::Util qw(:all);

####################################################################################

use UMMF::UML::MetaModel1;

####################################################################################

my $model;
sub model
{
  my ($self, $desc) = @_;

  unless ( $model ) {
    $model = UMMF::UML::MetaModel1->model;
  }

  $model;
}


sub factory_map
{
  UMMF::UML::MetaModel1->factory_map;
}


sub factory
{
  UMMF::UML::MetaModel1->factory;
}


####################################################################################


1;

####################################################################################


### Keep these comments at end of file: ks.perl@kurtstephens.com 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

