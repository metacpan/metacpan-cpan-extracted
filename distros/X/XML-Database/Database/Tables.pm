package XML::Database::Tables;

use 5.006;
use strict;
use warnings;

require Exporter;
#use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::Database::Tables ':all';
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

sub tables
{
	my $self = shift;
	my %args = (@_);
	%$self = (%$self, %args);
	
	Carp::croak("The {Name} and/or directory properties are not set.  Set them using XML::Database->new(...) method")
	unless($self->{Database}->{Name} && $self->{Database}->{Directory});
		
	my @files;
	my $file;
	opendir(DB, "$self->{Database}->{Directory}/$self->{Database}->{Name}");
	while (defined ($file = readdir(DB)))
	{
		push(@files, $file) unless $file =~ /(\.config)|(\.)|(\.\.)|(\.dtd)/;
	}
	
	return @files;
}

sub create
{
	my $self = shift;
	my %args = (@_);
	%$self = (%$self, %args);
	
	#Carp::croak("Usage: ...->create(XML::Database->new(), [key => value])")
	#unless(ref $db && $self->{TableName});
			
	Carp::croak("The {Name} and/or directory properties are not set.  Set them using XML::Database->new(...) method")
	unless($self->{Database}->{Name} && $self->{Database}->{Directory});
	
	## Create the directory needed by the table
	mkdir("$self->{Database}->{Directory}/$self->{Database}->{Name}/$self->{TableName}");
	
	## Create the config file(s) needed by the table
	
	
	## Attach a DTD to the table
	require XML::Database::DTD;
	my $xmldtd = XML::Database::DTD->new(Table => $self);
	$xmldtd->attach(DTDFile => $self->{DTDFile}) if $self->{DTDFile};
	$self->{DTDFile} = '';  ### Clear the DTDFile so that it won't attach to next table
}

sub drop
{
	my $self = shift;
	my %args = (@_);
	%$self = (%$self, %args);
	
	#Carp::croak("Usage: ...->drop(XML::Database->new(), [key => value])")
	#unless(ref $db && $self->{tableName});
			
	Carp::croak("The {Name} and/or directory properties are not set.  Set them using XML::Database->new(...) method")
	unless($self->{Database}->{Name} && $self->{Database}->{Directory});
	
	## Create the directory needed by the table
	require File::Path;
	File::Path::rmtree("$self->{Database}->{Directory}/$self->{Database}->{Name}/$self->{TableName}") ||
	Carp::croak("Error deleting a table in $self->{Database}->{Directory}/$self->{Database}->{Name}/$self->{tableName}: $!");
	
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::Database::Tables - Perl extension for blah blah blah

=head1 SYNOPSIS

  use XML::Database::Tables;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for XML::Database::Tables, created by h2xs. It looks like the
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
