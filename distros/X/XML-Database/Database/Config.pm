package XML::Database::Config;

use 5.006;
use strict;
use warnings;

require Exporter;
#use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::Database::Config ':all';
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

sub writeMain
{
	my $self = shift;
	my %args = (@_);
	%$self = (%$self, %args);
	
	open MAINCONF, ">$self->{Database}->{Directory}/$self->{Database}->{Name}/.conf";
	print MAINCONF "test";
	close MAINCONF;
	
}

sub appendMain
{
	my $self = shift;
	my %args = (@_);
	%$self = (%$self, %args);
	
	
	
}

sub readMain
{
	my $self = shift;
	my %args = (@_);
	%$self = (%$self, %args);	
	
	

}

sub updateMain
{
	my $self = shift;
	my %args = (@_);
	%$self = (%$self, %args);
	
	
}



# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::Database::Config - Perl extension for blah blah blah

=head1 SYNOPSIS

  use XML::Database::Config;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for XML::Database::Config, created by h2xs. It looks like the
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
