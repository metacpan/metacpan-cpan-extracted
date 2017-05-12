package WebShortcutUtil::Write;

use 5.006_001;
use strict;
use warnings;

our $VERSION = '0.22';

use Carp;
use File::Basename;
use Encode qw/is_utf8 encode/;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	create_desktop_shortcut_filename
	create_url_shortcut_filename
	create_webloc_shortcut_filename
	write_desktop_shortcut_file
	write_url_shortcut_file
	write_webloc_binary_shortcut_file
	write_webloc_xml_shortcut_file
    write_desktop_shortcut_handle
    write_url_shortcut_handle
    write_webloc_binary_shortcut_handle
    write_webloc_xml_shortcut_handle
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);


=head1 NAME

WebShortcutUtil::Write - Utilities for writing web shortcut files

=head1 SYNOPSIS

  use WebShortcutUtil::Write qw(
        create_desktop_shortcut_filename
        create_url_shortcut_filename
        create_webloc_shortcut_filename
        write_desktop_shortcut_file
        write_url_shortcut_file
        write_webloc_binary_shortcut_file
        write_webloc_xml_shortcut_file);

  # Helpers to create a file name (with bad characters removed).
  my $filename = create_desktop_shortcut_filename("Shortcut: Name");
  my $filename = create_url_shortcut_filename("Shortcut: Name");
  my $filename = create_webloc_shortcut_filename("Shortcut: Name");

  # Write shortcuts
  write_desktop_shortcut_file("myshortcut.desktop", "myname", "http://myurl.com/");
  write_url_shortcut_file("myshortcut.url", "myname", "http://myurl.com/");
  write_webloc_binary_shortcut_file("myshortcut_binary.webloc", "myname", "http://myurl.com/");
  write_webloc_xml_shortcut_file("myshortcut_xml.webloc", "myname", "http://myurl.com/");

=head1 DESCRIPTION

The following subroutines are provided:

=over 4

=cut


my $desktop_extension = ".desktop";
my $url_extension = ".url";
my $webloc_extension = ".webloc";
my $website_extension = ".website";


### Subroutines for generating file names

=item create_desktop_shortcut_filename( NAME [,LENGTH] )

=item create_url_shortcut_filename( NAME [,LENGTH] )

=item create_webloc_shortcut_filename( NAME [,LENGTH] )

Creates a file name based on the specified shortcut name.
The goal is to allow the file to be stored on a wide variety
of filesystems without issues.  The following rules are used:

=over 8

=item 1 An appropriate extension is added based on the shortcut type (e.g. ".url").

=item 2 Removes characters which are prohibited in some file systems (such as "?" and ":").
        Note there may still be characters left that will cause difficulty,
        such as spaces and single quotes.

=item 3 If the resulting name (after removing characters) is an empty string, the file will be named "_".

=item 4 Unicode characters are B<not changed>.  If there are unicode characters,
        they could cause problems on some file systems.  If you do not
        want unicode characters in the file name, you are responsible for
        removing them or converting them to ASCII.

=item 5 If the filename is longer than 100 characters (including the extension),
        it will be truncated.  This maximum length was chosen somewhat
        arbitrarily.  You may optionally override it by passing in a length
        parameter.

=back

The following references discuss file name restrictions:

=over 8

=item * http://en.wikipedia.org/wiki/Filename

=item * http://msdn.microsoft.com/en-us/library/windows/desktop/aa365247(v=vs.85).aspx

=item * http://support.grouplogic.com/?p=1607

=item * https://www.dropbox.com/help/145/en

=back

=cut

my $default_max_filename_length = 100;

sub _create_filename {
    my ($name, $length, $extension) = @_;
    
    if(!defined($length)) {
        $length = $default_max_filename_length;
    } else {
        my $min_length = length($extension) + 1;
        if($length < $min_length) {
            croak("Length parameter must be greater than or equal to ${min_length}")
        }
    }
    
    if(!defined($name)) {
        $name = "";
    }
    
    my $max_basename_length = $length - length($extension);

    # The valid characters are listed below in ASCII order.
    # Essentially this means we are excluding: "%*/<>?\^| (along with any control characters)
    # Note that Unicode characters are allowed in the file name.
    my $clean_name = $name;
    $clean_name =~ s/[^ !#\$&'\(\)+,\-\.,0-9;=\@A-Z\[\]_`a-z\{\}~\x{0080}-\x{FFFF}]//g;

    if($clean_name eq "") {
        $clean_name = "_";
    }

    my $filename = substr($clean_name, 0, $max_basename_length) . $extension;
    
    return $filename;
}

# $length Includes file name and extension (no path).
sub create_desktop_shortcut_filename {
	my ($name, $length) = @_;
	
	_create_filename($name, $length, $desktop_extension);
}

sub create_url_shortcut_filename {
    my ($name, $length) = @_;
    
    _create_filename($name, $length, $url_extension);
}

sub create_webloc_shortcut_filename {
    my ($name, $length) = @_;
    
    _create_filename($name, $length, $webloc_extension);
}



### The writers

sub _check_file_already_exists {
	my ( $filename ) = @_;
	
	if(-e $filename) {
        croak "File ${filename} already exists";
    }
}

=item write_desktop_shortcut_file( FILENAME, NAME, URL )

=item write_url_shortcut_file( FILENAME, NAME, URL )

=item write_webloc_binary_shortcut_file( FILENAME, NAME, URL )

=item write_webloc_xml_shortcut_file( FILENAME, NAME, URL )

These routines write shortcut files of the specified type.  The
shortcut will contain the specified name/title and URL.
Note that some shortcuts do not contain a name inside the file, in
which case the name parameter is ignored.

If your URL contains unicode characters, it is recommended that
you convert it to an ASCII-only URL
(see http://en.wikipedia.org/wiki/Internationalized_domain_name ).
That being said, write_desktop_shortcut_file and write_url_shortcut_file
will write unicode URLs.  The webloc writers should as well,
although this functionality requires more testing.

Note: The Mac::PropertyList module (http://search.cpan.org/~bdfoy/Mac-PropertyList/)
must be installed in order to write ".webloc" files.

=cut

# SEE REFERENCES IN WebShortcutUtil.pm

sub write_desktop_shortcut_file {
    my ( $filename, $name, $url ) = @_;
 
    _check_file_already_exists ( $filename );
    open (my $file, ">:encoding(UTF-8)", $filename) or die "Error opening file \"${filename}\": $!";
    
    write_desktop_shortcut_handle($file, $name, $url);
    
    close ($file);
    
    return 1;
}

sub write_url_shortcut_file {
    my ( $filename, $name, $url ) = @_;
 
    _check_file_already_exists ( $filename );
    open (my $file, ">", $filename) or die "Error opening file \"${filename}\": $!";
    
    write_url_shortcut_handle($file, $name, $url);
    
    close ($file);
    
    return 1;
}

sub write_webloc_binary_shortcut_file {
    my ( $filename, $name, $url ) = @_;
 
    _check_file_already_exists ( $filename );
    
    open (my $file, ">:encoding(UTF-8)", $filename) or die "Error opening file \"${filename}\": $!";
    binmode $file;
    write_webloc_binary_shortcut_handle($file, $name, $url);
    close ($file);
    
    return 1;
}

sub write_webloc_xml_shortcut_file {
    my ( $filename, $name, $url ) = @_;
 
    _check_file_already_exists ( $filename );
    
    open (my $file, ">:encoding(UTF-8)", $filename) or die "Error opening file \"${filename}\": $!";
    write_webloc_xml_shortcut_handle($file, $name, $url);
    close ($file);
    
    return 1;
}



sub write_desktop_shortcut_handle {
    my ( $handle, $name, $url ) = @_;
 
    # Assume all the writes will be done in UTF-8.
    print $handle "[Desktop Entry]\n";
    print $handle "Encoding=UTF-8\n";
    print $handle "Name=${name}\n";
    print $handle "Type=Link\n";
    print $handle "URL=${url}\n";
    
    close ($handle);
    
    return 1;
}

sub write_url_shortcut_handle {
    my ( $handle, $name, $url ) = @_;
 
    my $ascii_url = $url;
    # Generate a URL where non-ASCII characters are placed with a question mark
    $ascii_url =~ s/[x{0080}-\x{FFFF}]/?/g;

    print $handle "[InternetShortcut]\r\n";
    print $handle "URL=${ascii_url}\r\n";
 
    # If the url contains non-ascii characters, print the extra sections 
    if($url ne $ascii_url) {
        print $handle "[InternetShortcut.A]\r\n";
        print $handle "URL=${ascii_url}\r\n";

        print $handle "[InternetShortcut.W]\r\n";
        my $url_utf7 = encode("UTF-7", $url);
        print $handle "URL=${url_utf7}\r\n";      
    }

    close ($handle);
    
    return 1;
}

# TODO: Fix this eval to not use an expression.  This causes it to fail perlcritic.
sub _try_load_module_for_webloc {
    my ( $module, $list ) = @_;

    eval ( "use ${module} ${list}; 1" ) or
        die "Could not load ${module} module.  This module is required in order to read/write webloc files.  Error: $@";
}

sub write_webloc_binary_shortcut_handle {
    my ( $handle, $name, $url ) = @_;
 
    _try_load_module_for_webloc ( "Mac::PropertyList", "qw(:all)" );
    _try_load_module_for_webloc ( "Mac::PropertyList::WriteBinary", "" );

    my $data = new Mac::PropertyList::dict({ "URL" => $url });
    my $buf = Mac::PropertyList::WriteBinary::as_string($data);
    print $handle $buf;
    close ($handle);
    
    return 1;
}

sub write_webloc_xml_shortcut_handle {
    my ( $handle, $name, $url ) = @_;
 
    _try_load_module_for_webloc ( "Mac::PropertyList", "qw(:all)" );
    
    my $str = create_from_hash({ "URL" => $url });
    print $handle $str;
    close ($handle);
    
    return 1;
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

