package Win32::Filenames;

use warnings;
use strict;

use Exporter 'import';
our @EXPORT_OK = qw(&sanitize &validate $ERR_CHAR);

use Carp;

our $VERSION = '0.01';

our $ERR_CHAR = '';

my @_INVALIDS = ( '\\','/', '|', ':', '<', '>', '"', '?', '*' );

# remove any of the following invalid characters:
#   \ / | : ? * " < >
sub sanitize {
	my $str  = shift;
	my $char = $_[0] || '-';
	
	croak "Invalid character cannot be used in sanitize function. [$char]\n" if
		( grep { $char =~ /\Q$_\E/g } @_INVALIDS);
	$str =~ s/\\|\/|:|\*|\?|"|<|>|\|/$char/g;
	return $str;
}

sub validate {
	local $_;
	$_ = shift;
	
	if (/\\|\/|:|\*|\?|"|<|>|\|/) {
		$ERR_CHAR = $&;
		return undef;
	}else{
		return 1;
	}
}

=head1 NAME

Win32::Filenames - The great new Win32::Filenames!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module can be used to validate if a given filename is a valid Windows filename and if it is not valid can fix the filename by replacing the invalid characters. 

Perhaps a little code snippet.

    use Win32::Filenames qw(validate sanitize);
    
    my @filenames = ( 'file1.txt', '(file;;2.doc)', 'file::.doc?', 'file6',
                      'file7>>.txt' );
    my $test;
    foreach $test (@tests) {
      print "checking filename: [$test] ...";
      
      if ( validate($test) ) {
      	print "Filename is ok.\n";
      }else{
        print "Filename is bad. **\n";
	print "\tTRY: ";
	print sanitize($test), "\n";
      }
    }

=head1 EXPORT

Nothing is exported by default. 

The following are allowed to be exported:

=over

=item *
  sanitize() --> fix filename.

=item *
  validate() --> check filename.

=item *
  $ERR_CHAR --> what character was invalid in last filename check.

=back 

=head1 FUNCTIONS

=head2 validate($filename);

This function is passed a filename which is searched for any invalid characters.
If there are no invalid characters then the function returns true. If the filename does contain invalid characters, the invalid character encountered is stored in the GLOBAL variable $ERR_CHAR and the function returns undef.

=head2 sanitize($filename, [ $replace_str ]);

This function is passed a filename to convert to a valid Windows filename. The function is also optionaly passed a string or character to be used to replace invalid characters with. If no replacement character is passed to the function, it defaults to use '-' to replace invalid characters. 

If the replacement character passed to the function is itself an invalid character, then the function croaks. Otherwise, the filename is searched for any 
invalid characters, and string is returned with the invalid characters replaced.

=head1 AUTHOR

Brent Hostetler, C<< <brent@the-hostetlers.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-win32-filenames@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Filenames>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

I would like to acknowledge myself! :P

=head1 COPYRIGHT & LICENSE

Copyright 2005 Brent Hostetler, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Win32::Filenames
