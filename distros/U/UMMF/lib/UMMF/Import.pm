package UMMF::Import;

use 5.6.1;
use strict;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/04/15 };
our $VERSION = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Import - Base class for (meta-)model importers.

=head1 SYNOPSIS

  use base qw(UMMF::Import);

=head1 DESCRIPTION

This base class provides support and interfaces for specific importers, like UMMF::Import::XML and UMMF::Import::MetaMetaModel.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/04/15

=head1 SEE ALSO

L<UMMF|UMMF>

=head1 VERSION

$Revision: 1.9 $

=head1 METHODS

=cut


#######################################################################

use base qw(UMMF::Core::Object);

use Carp qw(confess);

#######################################################################

sub initialize
{
  my ($self) = @_;
  
  # $DB::single = 1;

  # confess("factory not specified") unless $self->{'factory'};
  
  $self->SUPER::initialize;
}


#######################################################################

sub import_input_string
{
  confess("import_input_string: not implemented");
}

#######################################################################

sub import_input
{
  my ($self, $input) = @_;

  # $DB::single = 1;

  if ( UNIVERSAL::isa($input, 'IO::Handle') ) {
    $input = join('', <$input>);
  }

  $_[1] = undef; # Help Devel::StackTrace.

  $self->import_input_string($input);
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

