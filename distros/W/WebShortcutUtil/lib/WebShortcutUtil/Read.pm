package WebShortcutUtil::Read;


use 5.006_001;

use strict;
use warnings;

our $VERSION = '0.22';

use Carp;
use File::Basename;
use Encode qw/decode/;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    shortcut_has_valid_extension
    get_shortcut_name_from_filename
    read_shortcut_file
    read_shortcut_file_url
	read_desktop_shortcut_file
	read_url_shortcut_file
	read_webloc_shortcut_file
	read_website_shortcut_file
	get_handle_reader_for_file
	read_desktop_shortcut_handle
    read_url_shortcut_handle
    read_webloc_shortcut_handle
    read_website_shortcut_handle
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

=head1 NAME

WebShortcutUtil::Read - Utilities for reading web shortcut files

=head1 SYNOPSIS

  use WebShortcutUtil::Read qw(
        shortcut_has_valid_extension
        read_shortcut_file
        read_shortcut_file_url);

  # If the file does not have a valid shortcut extension, the reads will fail.
  if(!shortcut_has_valid_extension($filename)) {
  	  die "File is not a shortcut!";
  }

  # Read name and URL
  my $results = read_shortcut_file($filename);
  my $name = $results->{"name"};
  my $url = $results->{"url"};

  # Just get URL
  my $url = read_shortcut_file_url($filename);

=head1 DESCRIPTION

The following subroutines are provided:

=over 4

=cut

my %_shortcut_file_readers = (
	".desktop", \&read_desktop_shortcut_file,
	".url", \&read_url_shortcut_file,
	".webloc", \&read_webloc_shortcut_file,
	".website", \&read_website_shortcut_file,
);

my %_shortcut_handle_readers = (
    ".desktop", \&read_desktop_shortcut_handle,
    ".url", \&read_url_shortcut_handle,
    ".webloc", \&read_webloc_shortcut_handle,
    ".website", \&read_website_shortcut_handle,
);



### Routines that deal with file names

sub _fileparse_any_extension {
    my ( $filename ) = @_;

    my @pieces = split(m/[\\\/]/, $filename);
    my $filename_without_path = pop(@pieces);
    my ($name, $path, $suffix) = fileparse($filename_without_path,  qr/\.[^.]*/);
    return ($name, $suffix);
}

sub get_shortcut_name_from_filename {
	my ( $filename ) = @_;
	my ($name, $suffix) = _fileparse_any_extension($filename);
	return $name;
}


=item shortcut_file_has_valid_extension( FILENAME )

Checks the specified file name and returns true if
its extension matches one of the supported types.

=cut

sub shortcut_has_valid_extension {
	my ( $filename ) = @_;
	
	my ($name, $suffix) = _fileparse_any_extension($filename);
	
	return exists $_shortcut_file_readers{lc ($suffix)};
}


=item read_shortcut_file( FILENAME )

Reads the specified file and extracts the contents.  The type of
shortcut file is determined by the file extension.  A hash will be returned
containing two keys: "name" and "url".  The name is the name/title of
the shortcut.  A hash will always be returned - if there is an error
reading the file, the routine will die with an appropriate error message.

For ".desktop" and ".url" files, the reader can handle unicode characters
in the name and URL.  ".webloc" files may contain unicode characters as well,
although this functionality still requires more testing.

The name returned by the readers is a guess.  Many shortcut files
do not contain a name/title embedded in the file.  ".desktop" shortcuts
may contain several embedded names with different encodings.  Unfortunately,
these names are not necessarily updated when the shortcut is renamed.
It is difficult, if not impossible, to determine which is the correct name.
As of right now, the reader will always return the name of the file as the
name of the shortcut, although this may change in the future.

Note: The Mac::PropertyList module (http://search.cpan.org/~bdfoy/Mac-PropertyList/)
must be installed in order to read ".webloc" files.

=cut

sub read_shortcut_file {
    my ( $filename ) = @_;

    my ($name, $suffix) = _fileparse_any_extension($filename);
    
    if (!exists($_shortcut_file_readers{lc ($suffix)})) {
    	croak ( "Shortcut file does not have a recognized extension!" );
    }
    my $reader_sub = $_shortcut_file_readers{lc ($suffix)};
    &$reader_sub($filename);
}


=item read_shortcut_file_url( FILENAME )

The same as read_shortcut_file, but only returns a string containing the URL.

=cut

sub read_shortcut_file_url {
    return read_shortcut_file(@_)->{"url"};
}



### Routines used by the readers to parse lines

# Note that the dollar sign at the end of the regular
# expression matches the new line at the end of the
# string.

sub _is_group_header {
    my ( $line, $group_name ) = @_;

    return $line =~ m/^\s*\[${group_name}\]\s*$/;
}

sub _get_key_value_pair {
    my ( $line ) = @_;
    if($line =~ m/^\s*([A-Za-z0-9-]*)(\[([^\[\]]*)\])?\s*=\s*([^\n\r]*?)\s*$/) {
        return ($1, $3, $4);
    } else {
        return (undef, undef, undef);
    }
}

sub _desktop_entry_is_blank_or_comment_line {
    my ( $line ) = @_;

    return $line =~ m/^\s*(#.*)?$/;
}

sub _url_is_blank_or_comment_line {
    my ( $line ) = @_;

    my $elimination_line = $line;
    $elimination_line =~ s/(;.*)//;
    $elimination_line =~ s/\s*//;

    # Account for other separators as well.
    return $elimination_line eq "";
}




### The readers

sub _ensure_file_exists {
    my ( $filename ) = @_;
    
    unless(-e $filename) {
        croak "File ${filename} does not exist!";
    }
}

=item read_desktop_shortcut_file( FILENAME )

=item read_url_shortcut_file( FILENAME )

=item read_website_shortcut_file( FILENAME )

=item read_webloc_shortcut_file( FILENAME )

These routines operate essentially the same way as read_shortcut_file.
However, they force the file to be parsed as a particular type,
regardless of the file extension.  These should be used sparingly.
You should use read_shortcut_file unless you have a good
reason not to.

=cut

# SEE REFERENCES IN WebShortcutUtil.pm

sub read_desktop_shortcut_file {
    my ( $filename ) = @_;
   
    _ensure_file_exists($filename);
    open (my $file, "<:encoding(UTF-8)", $filename) or croak ( "Error opening file ${filename}: $!" );
    
    my $url = read_desktop_shortcut_handle($file);
    
    close ($file);
    
    my $name = get_shortcut_name_from_filename($filename);

    return {
        "name", $name,
        "url", $url};
}



sub read_url_shortcut_file {
    my ( $filename ) = @_;
    
    _ensure_file_exists($filename);
    open (my $file, "<", $filename) or croak ( "Error opening file ${filename}: $!" );
    
    my $url = read_url_shortcut_handle($file);

    close ($file);
    
    my $name = get_shortcut_name_from_filename($filename);

    return {
        "name", $name,
        "url", $url};
}


sub read_website_shortcut_file {
    read_url_shortcut_file(@_);
}



sub read_webloc_shortcut_file
{
    my ( $filename ) = @_;
    
    open (my $file, "<", $filename) or croak ( "Error opening file ${filename}: $!" );
    binmode($file);
    
    my $url = read_webloc_shortcut_handle( $file );
    
    close ($file);
    
    my $name = get_shortcut_name_from_filename($filename);

    return {
        "name", $name,
        "url", $url};
}





=item read_desktop_shortcut_handle( HANDLE )

=item read_url_shortcut_handle( HANDLE )

=item read_website_shortcut_handle( HANDLE )

=item read_webloc_shortcut_handle( HANDLE )

These routines operate essentially the same way as read_shortcut_file.
However, they force the file to be parsed as a particular type,
regardless of the file extension.  These should be used sparingly.
You should use read_shortcut_file unless you have a good
reason not to.
=cut

sub read_desktop_shortcut_handle {
    my ( $file ) = @_;
    
    # Make sure that we are using line feed as the separator
    local $/ = "\n";
    
    # Read to the "Desktop Entry"" group - this should be the first entry, but comments and blank lines are allowed before it.
    # Should handle desktop entries at different positions not just in first spot....
    my $desktop_entry_found = 0;
    while(1) {
    	my $next_line = <$file>;
    	if(not $next_line) {
    		# End of file
    		last;
        # Per the Desktop Entry specifications, [KDE Desktop Entry] was used at one time...
    	} elsif(_is_group_header($next_line, "(KDE )?Desktop Entry")) {
    		$desktop_entry_found = 1;
    		last;
    	} elsif(_desktop_entry_is_blank_or_comment_line($next_line)) {
    		# Ignore this line
    	} else {
    		# When we find a line that does not match the above criteria, stop looping.  This should never happen.
            last;
    	}
    }
    
    if (not $desktop_entry_found) {
    	die "Desktop Entry group not found in desktop file.";
    }
    
    my $type = undef;
    my $url = undef;
    while(1) {
    	my $next_line = <$file>;
    	if(not $next_line) {
            last;
    	} elsif(_is_group_header($next_line, ".*")) {
    		last;
    	} elsif(_desktop_entry_is_blank_or_comment_line($next_line)) {
    		# Ignore this line
    	} else {
    		my ($key, $locale, $value) = _get_key_value_pair($next_line);
    		if(defined($key)) {
    			if($key eq "Type") {
    				$type = $value;
    			} elsif($key eq "URL") {
    				$url = $value;
    			}
    		} else {
    			warn "Warning: Found a line in the file with no valid key/value pair: ${next_line}";
    		}
    	}
    }
    
    # Show a warning if the Type key is not right, but still continue.
    if(!defined($type)) {
    	warn "Warning: Type not found in desktop file";
    } elsif($type ne "Link") {
    	warn "Warning: Invalid type ${type} in desktop file";
    }
    
    if(not defined($url)) {
        die "URL not found in file";
    }

    return $url;
}


use constant {
	NO_SECTION => 0,
    INTERNET_SHORTCUT_SECTION   => 1,
    INTERNET_SHORTCUT_W_SECTION   => 2,
    OTHER_SECTION => 3,
};

sub read_url_shortcut_handle {
    my ( $file ) = @_;

    # Make sure that we are using line feed as the separator.
    # Windows uses \r\n as the terminator, but should be safest always to use \n since it
    # handles both end-of-line cases.
    local $/ = "\n";
        
    # Read to the desktop file entry group - this should be the first entry, but comments and blank lines are allowed before it.
    my $curr_section = NO_SECTION;
    my $parsed_url = undef;
    my $parsed_urlw = undef;
    while(1) {
        my $next_line = <$file>;
        if(not $next_line) {
            last;
            # use a constant instead of indicvidual bools.
        } elsif(_is_group_header($next_line, "InternetShortcut")) {
           $curr_section = INTERNET_SHORTCUT_SECTION;
        } elsif(_is_group_header($next_line, "InternetShortcut.W")) {
           $curr_section = INTERNET_SHORTCUT_W_SECTION
        } elsif(_is_group_header($next_line, ".*")) {
           $curr_section = OTHER_SECTION;
        } elsif(_url_is_blank_or_comment_line($next_line)) {
            # Ignore this line
        } else {
            my ($key, $locale, $value) = _get_key_value_pair($next_line);
            if(defined($key)) {
            	if($key eq "URL") {
                    if($curr_section == INTERNET_SHORTCUT_SECTION) {
                       $parsed_url = $value;
                    } elsif($curr_section == INTERNET_SHORTCUT_W_SECTION) {
                       $parsed_urlw = decode("UTF-7", $value);
                    }
                }
            } else {
                warn "Warning: Found a line in the file with no valid key/value pair: ${next_line}";
            }
        }
    }

    my $url;
    if(defined($parsed_urlw)) {
    	$url = $parsed_urlw;
    } elsif(defined($parsed_url)) {
    	$url = $parsed_url;
    } else {
    	die "URL not found in file";
    }

  	return $url;

}


sub read_website_shortcut_handle {
    read_url_shortcut_handle(@_);
}

# TODO: Fix this eval to not use an expression.  This causes it to fail perlcritic.
sub _try_load_module_for_webloc {
    my ( $module, $list ) = @_;

    eval ( "use ${module} ${list}; 1" ) or
        die "Could not load ${module} module.  This module is required in order to read/write webloc files.  Error: $@";
}



sub read_webloc_shortcut_handle
{
    my ( $file ) = @_;

    _try_load_module_for_webloc ( "Mac::PropertyList", "qw(:all)" );

    my $data = parse_plist_fh( $file );
    
    if (ref($data) ne "Mac::PropertyList::dict") {
    	die "Webloc plist file does not contain a dictionary!";
    } elsif(!exists($data->{ 'URL' })) {
    	die "Webloc plist file does not contain a URL!";
    }
    
    my $url_object = $data->{ 'URL' };
    my $url = $url_object->value;

    return $url;
}

=item get_handle_reader_for_file( FILENAME )

These routines operate essentially the same way as read_shortcut_file.
However, they force the file to be parsed as a particular type,
regardless of the file extension.  These should be used sparingly.
You should use read_shortcut_file unless you have a good
reason not to.
=cut

sub get_handle_reader_for_file
{
    my ( $filename ) = @_;
    
    my ($name, $suffix) = _fileparse_any_extension($filename);
    
    if (!exists($_shortcut_handle_readers{lc ($suffix)})) {
        croak ( "Shortcut file does not have a recognized extension!" );
    }
    my $reader_sub = $_shortcut_handle_readers{lc ($suffix)};
    return $reader_sub;
}



1;
__END__

=back

=head1 SEE ALSO

http://search.cpan.org/~beckus/WebShortcutUtil/lib/WebShortcutUtil.pm

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Andre Beckus

This library is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language itself.

=cut
