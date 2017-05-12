package UMMF::Export::DataDumper;

use 5.6.1;
use strict;

our $AUTHOR = q{ kstephens@sourceforge.net 2003/08/18 };
our $VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Export::DataDumper - A code generator for Data::Dumper.

=head1 SYNOPSIS

  my $d = UMMF::Export::DataDumper->new('output' => *STDOUT);
  my $d->export_Model($model);

=head1 DESCRIPTION

This package allow UML models to be represented as Data::Dumper output.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@sourceforge.net 2003/08/18

=head1 SEE ALSO

L<UMMF::UML::MetaModel|UMMF::UML::MetaModel>

=head1 VERSION

$Revision: 1.3 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::Export);

use UMMF::Core::Util qw(:all);
use Data::Dumper;

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

  $self->{'output'}
    ->print(
	    Data::Dumper->new([ $model ], [ qw($model) ])
	    ->Indent(1)
	    ->Purity(1)
	    ->Useqq(1)
	    ->Quotekeys(1)
	    ->Dump(),
	    "\n;\n",
	   );

  $self;
}


#######################################################################

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

