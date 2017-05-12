package XML::Database::DTD;

use 5.006;
use strict;
use warnings;

require Exporter;
#use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::Database::DTD ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.

sub new
{
	my $self = shift;
	my %args = (@_);
	return bless \%args, $self;
}

sub attach
{
	my $self = shift;
	my %args = (@_);
	%$self = (%$self, %args);
	
	require File::Copy;
	File::Copy::copy($self->{DTDFile}, 
	"$self->{Table}->{Database}->{Directory}/$self->{Table}->{Database}->{Name}/$self->{Table}->{TableName}/$self->{Table}->{TableName}.dtd");
	
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::Database::DTD - Perl extension for blah blah blah

=head1 SYNOPSIS

  use XML::Database::DTD;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for XML::Database::DTD, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 SEE ALSO

L<perl>.

=cut
