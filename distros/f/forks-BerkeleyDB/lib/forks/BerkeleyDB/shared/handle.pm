package forks::BerkeleyDB::shared::handle;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = 0.060;
use strict;
use warnings;

our $AUTOLOAD;

# Need to implement all subs except TIEHANDLE with the command:
#	my @result = _command( '_tied',$self->{'ordinal'},$sub,@_ );
# where $sub is a threads::shared:: qualified command.  AUTOLOAD might work.
#hey! I don't even have to do this...it's already handled by threads::shared

*_command = \&threads::_command;

#---------------------------------------------------------------------------
sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	my $self = {};
	return bless($self, $class);
}

# standard Perl features
#	TIEHANDLE
#	WRITE, PRINT, PRINTF
#	READ, READLINE, GETC
#	CLOSE
#	BINMODE, OPEN, EOF, FILENO, SEEK, TELL
#	UNTIE, DESTROY

#---------------------------------------------------------------------------
*TIEHANDLE = *TIEHANDLE = \&new;

#---------------------------------------------------------------------------
sub AUTOLOAD {	#use forks::shared default method for everything!
    my $self = shift;
    (my $sub = $AUTOLOAD) =~ s#^.*::#$self->{'module'}::#;
    my @result = _command( '_tied',$self->{'ordinal'},$sub,@_ );
    wantarray ? @result : $result[0];
}

#---------------------------------------------------------------------------
1;

__END__
=pod

=head1 NAME

forks::BerkeleyDB::shared::handle - class for tie-ing handles to threads with forks

=head1 DESCRIPTION

Helper class for L<forks::BerkeleyDB::shared>.  See documentation there.

=head1 AUTHOR

Eric Rybski <rybskej@yahoo.com>.

=head1 COPYRIGHT

Copyright (c) 2006-2009 Eric Rybski <rybskej@yahoo.com>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<forks::BerkeleyDB::shared>, L<forks::shared>.

=cut
