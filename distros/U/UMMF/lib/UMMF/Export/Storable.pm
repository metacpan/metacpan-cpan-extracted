package UMMF::Export::Storable;

use 5.6.0;
use strict;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/08/18 };
our $VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Export::Storable - A code generator for Storable.

=head1 SYNOPSIS

  my $d = UMMF::Export::Storable->new('output' => *STDOUT);
  my $d->export_Model($model);

OR
  
  ummf -e Storable your_uml.xmi

=head1 DESCRIPTION

This package allow UML models to be represented as Storable output.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@sourceforge.net 2003/09/07

=head1 SEE ALSO

L<Storable|Storable>, L<UMMF::Export::DataDumper|UMMF::Export::DataDumper>

=head1 VERSION

$Revision: 1.5 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::Export);

use Storable;

#######################################################################


sub initialize
{
  my ($self) = @_;

  # $DB::single = 1;

  $self->SUPER::initialize;

  $self;
}


#######################################################################

sub export_Model
{
  my ($self, $model) = @_;
  
  $DB::single = 1;

  Storable::store_fd($model, $self->{'output'});

  $self;
}


#######################################################################

sub Set::Object::STORABLE_freeze
{
  my ($self, $cloning) = @_;
  return if $cloning;

  # print STDERR "STORABLE_freeze: $self\n";

  ("", $self->members());
}


sub Set::Object::STORABLE_thaw
{
  my ($self, $cloning, $serialized, @members) = @_;
  return if $cloning;

  print STDERR "STORABLE_thaw: $self\n";

  $self->clear();
  $self->insert(@members);
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

