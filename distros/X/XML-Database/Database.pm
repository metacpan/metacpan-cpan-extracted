package XML::Database;

use 5.006;
use strict;
use warnings;

require Exporter;
#use AutoLoader qw(AUTOLOAD);
use Carp;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::Database ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.
use lib "C:/Documents and Settings/isterin/Desktop";
use XML::Database::Config;
my $xmlconfig = XML::Database::Config->new();

use XML::Database::Tables;
my $xmltables = XML::Database::Tables->new();

use XML::Database::DTD;
my $xmldtd = XML::Database::DTD->new();


sub new
{
	my $self = shift;
	my %args = (@_);	
	return bless \%args, $self;	
}

sub create
{
	my $self = shift;
	my %args = (@_);
	%$self = (%$self, %args);
	
	Carp::croak("Usage: ...->create(Name => ..., Directory => ...)")
	unless(ref $self && $self->{Name} && $self->{Directory});
	
	mkdir("$self->{Directory}/$self->{Name}") || 
	Carp::croak("Error creating a database in $self->{Directory}/$self->{Name}: $!");
	
	$xmlconfig->writeMain(Database => $self);	
}

sub drop
{
	my $self = shift;
	my %args = (@_);
	%$self = (%$self, %args);
	
	Carp::croak("Usage: ...->create(DB_name, DB_dir)")
	unless(ref $self && $self->{Name} && $self->{Directory});
	
	require File::Path;
	File::Path::rmtree("$self->{Directory}/$self->{Name}") ||
	Carp::croak("Error deleting a database in $self->{Directory}/$self->{Name}: $!");
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::Database - Perl extension for blah blah blah

=head1 SYNOPSIS

  use XML::Database;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for XML::Database, created by h2xs. It looks like the
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
