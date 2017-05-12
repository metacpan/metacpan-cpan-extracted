package UMMF::Core::MetaModel;

use 5.6.1;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/05/03 };
our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Core::MetaModel - Base class for UMMF metamodels.

=head1 SYNOPSIS

  use base qw(UMMF::Core::MetaModel);

=head1 DESCRIPTION


=head1 USAGE

=head1 PATTERNS

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/05/03

=head1 SEE ALSO

L<UMMF::Boot::MetaModel|UMMF::Boot::MetaModel>

=head1 VERSION

$Revision: 1.1 $

=head1 METHODS

=cut

#######################################################################

# use UMMF::Boot::MetaModel;
use UMMF::Core::Util qw(:all);
use Carp qw(confess);

#######################################################################

our $uml_version ||= '1.5'; # See UMMF::Boot::MetaModel

sub exporter
{
  my ($self, %opts) = @_;

  #####################################################################
  # Generate metamodel code directly into Perl or Java or ...
  #

  $opts{'version'} ||= $uml_version;

  
  #$DB::single = 1;
  #use UMMF::UML::Code;

  my $exporter = $opts{'exporter'} || 'UMMF::Export::Perl';
  delete $opts{'exporter'};

  if ( ! ref($exporter) ) {
    eval "use $exporter"; die $@ if $@;
    $exporter = $exporter->new
    (
     'output' => 'EVAL',
     %opts,
    );
  }

  $exporter;
}


sub export_Model
{
  my ($self, %opts) = @_;

  $opts{'version'} ||= $uml_version;

  my $model = $opts{'model'};
  delete $opts{'model'};

  confess("model not specified") unless $model;
  unless ( ref($model) ) {
    eval "use $model;"; die if $@;
    $model = $model->model;
  }

  $self->exporter(%opts)->export_Model($model);
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

