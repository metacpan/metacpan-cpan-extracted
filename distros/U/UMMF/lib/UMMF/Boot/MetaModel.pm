package UMMF::Boot::MetaModel;

use 5.6.1;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/05/03 };
our $VERSION = do { my @r = (q$Revision: 1.16 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Boot::MetaModel - Bootstrapping implementation of UML meta-model M1.

=head1 SYNOPSIS

  use UMMF::Boot::MetaModel;

  my $f = UMMF::Boot::MetaModel->factory;
  my $metamodel = UMMF::Boot::MetaModel->model;
  UMMF::Export::XMI->new()->export_Model($metamodel);

=head1 DESCRIPTION


=head1 USAGE

=head1 PATTERNS

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/05/03

=head1 SEE ALSO

L<UMMF::Core::MetaModel|UMMF::Core::MetaModel>

=head1 VERSION

$Revision: 1.16 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::Core::MetaModel);

#######################################################################

use UMMF::Core::Util qw(:all);
use Carp qw(confess);

#######################################################################

sub metamodel_spec
{
  my ($self, %opts) = @_;

  my $model_name = $opts{'model_name'} || confess("No model name specified");
  my $version = $opts{'version'} || confess("No $model_name version specified");
  qq{[% PROCESS "${model_name}-${version}.ummfmodel" %]};
}

#######################################################################

our $model_name ||= 'UML';
our $model_version ||= '1.5';

my %model;
sub model
{
  my ($self, %opts) = @_;

  my $model_name = $opts{'model_name'} ||= $model_name;
  my $version = $opts{'version'} ||= $model_version;
  my $pure = $opts{'pure'} ||= '';

  my $x = \$model{$model_name}{$version}{$pure};
  unless ( $$x ) {
    my $desc = $opts{'desc'};

    $desc ||= $self->metamodel_spec(%opts);
    # $DB::single = 1;
    
    use UMMF::Import::UMMFModel;
      
    # $DB::single = 1;
    my $factory = $opts{'factory'};
    delete $opts{'factory'};
    $factory = $self->factory unless $factory;

    # $DB::single = 1;

    my $importer = new UMMF::Import::UMMFModel(
					       'factory' => $factory,
					       'version' => $version,
					       'pure' => $pure,
					       );

    $$x = $importer->import_input($desc);

    if ( 0 ) {
      #local $UMMF::Core::Util::namespace_trace = 1;
      my (@ac) = Namespace_ownedElement_match($model{$version}, 'isaAssociationClass', 1);
      $DB::single = 1;
      
      print STDERR "AC: ", join(', ', map($_->name, @ac)), "\n";
    }

    # $DB::single = 1;
  }

  $$x;
}


my $factory;
sub factory
{
  my ($self) = @_;

  unless ( $factory ) {
    $factory = 'UMMF::Boot::Factory';
    # confess("factory not specified") unless $factory;
    unless ( ref($factory) ) {
      eval "use $factory;"; die $@ if $@;
      $factory = $factory->new('classMap' => $factory);
    }
  }

  $factory;
}



#######################################################################


1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

