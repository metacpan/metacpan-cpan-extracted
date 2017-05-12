package Xcruciate::Utils;

use Exporter;
@ISA    = ('Exporter');
@EXPORT = qw();
our $VERSION = 0.21;

use strict;
use warnings;
use Time::gmtime;
use Carp;
use XML::LibXML;
use XML::LibXSLT;

=head1 NAME

Xcruciate::Utils - Utilities for Xcruciate

=head1 SYNOPSIS

check_path('A very nice path',$path,'rw');

=head1 DESCRIPTION

Provides utility functions Xcruciate ( F<http://www.xcruciate.co.uk>).

=head1 AUTHOR

Mark Howe, E<lt>melonman@cpan.orgE<gt>

=head2 EXPORT

None

=head1 FUNCTIONS

=head2 check_path(option,path,permissions[,non_fatal])

Checks that the path exists, and that it has the appropriate
permissions, where permissions contains some combination of r, w and x. If not, and if non_fatal is perlishly false,
it dies, using the value of option to produce a semi-intelligable error message. If non_fatal is perlishly true it returns the error or an empty string.

=cut

sub check_path {
    my $option      = shift;
    my $path        = shift;
    my $permissions = shift;
    my $non_fatal   = 0;
    $non_fatal = 1 if $_[0];
    my $error = "";
    if ( not( -e $path ) ) {
        $error = "No file corresponding to path for '$option'";
    }
    elsif ( $permissions =~ /r/ and ( not -r $path ) ) {
        $error = "File '$path' for '$option' option is not readable";
    }
    elsif ( $permissions =~ /w/ and ( not -w $path ) ) {
        $error = "File '$path' for '$option' option is not writable";
    }
    elsif ( $permissions =~ /x/ and ( not -x $path ) ) {
        $error = "File '$path' for '$option' option is not executable";
    }
    if ($non_fatal) {
        return $error;
    }
    else {
        croak $error;
    }
}

=head2 check_absolute_path(option,path,permissions[,non_fatal])

A lot like &check_path (which it calls), but also checks that the path is
absolute (ie is starts with a /).

=cut

sub check_absolute_path {
    my $option      = shift;
    my $path        = shift;
    my $permissions = shift;
    my $non_fatal   = 0;
    $non_fatal = 1 if defined $_[0];
    if ( $path !~ m!^/! and $non_fatal ) {
        return "Path for '$option' must be absolute";
    }
    elsif ( $path !~ m!^/! ) {
        croak "Path for '$option' must be absolute";
    }
    else {
        check_path( $option, $path, $permissions, $non_fatal );
    }
}

=head2 type_check(path,name,value,record)

Returns errors on typechecking value against record. Name is provided for error messages. Path is from config file.

=cut

sub type_check {
    my $path   = shift;
    my $name   = shift;
    my $value  = shift;
    my $record = shift;
    $value =~ s/^\s*(.*?)\s*$/$1/s;
    my @errors    = ();
    my $list_name = '';
    $list_name = "Item $_[0] of" if defined $_[0];
    my $datatype = $record->[2];

    if ( $datatype eq 'integer' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be an integer", $name )
          unless $value =~ /^\d+$/;
        push @errors,
          sprintf(
"$list_name Entry called %s is less than minimum permitted value of $record->[3]",
            $name )
          if (  $value =~ /^\d+$/
            and ( defined $record->[3] )
            and ( $record->[3] > $value ) );
        push @errors,
          sprintf(
"$list_name Entry called %s exceeds permitted value of $record->[4]",
            $name )
          if (  $value =~ /^\d+$/
            and ( defined $record->[4] )
            and ( $record->[4] < $value ) );
    }
    elsif ( $datatype eq 'float' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be a number", $name )
          unless $value =~ /^-?\d+(\.\d+)?$/;
        push @errors,
          sprintf(
"$list_name Entry called %s is less than minimum permitted value of $record->[3]",
            $name )
          if (  $value =~ /^-?\d+(\.\d+)$/
            and ( defined $record->[3] )
            and ( $record->[3] > $value ) );
        push @errors,
          sprintf(
"$list_name Entry called %s exceeds permitted value of $record->[4]",
            $name )
          if (  $value =~ /^-?\d+(\.\d+)$/
            and ( defined $record->[4] )
            and ( $record->[4] < $value ) );
    }
    elsif ( $datatype eq 'ip' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be an ip address", $name )
          unless $value =~ /^\d\d?\d?\.\d\d?\d?\.\d\d?\d?\.\d\d?\d?$/;
    }
    elsif ( $datatype eq 'cidr' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be a CIDR ip range",
            $name )
          unless $value =~ m!^\d\d?\d?\.\d\d?\d?\.\d\d?\d?\.\d\d?\d?/\d\d?$!;
    }
    elsif ( $datatype eq 'yes_no' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be 'yes' or 'no'", $name )
          unless $value =~ /^(yes)|(no)$/;
    }
    elsif ( $datatype eq 'duration' ) {
        push @errors,
          sprintf(
"$list_name Entry called %s should be a duration (eg PT2H30M, P15DT12H)",
            $name )
          unless $value =~ /^-?P(\d+D)?(T(\d+H)?(\d+M)?(\d+(\.\d+)?S)?)?$/;
    }
    elsif ( $datatype eq 'word' ) {
        push @errors,
          sprintf(
            "$list_name Entry called %s should be a word (ie no whitespace)",
            $name )
          unless $value =~ /^\S+$/;
    }
    elsif ( $datatype eq 'hexbyte' ) {
        push @errors,
          sprintf(
            "$list_name Entry called %s should be a hexidecimal byte (00 - FF)",
            $name )
          unless $value =~ /^[0-9A-F][0-9A-F]$/;
    }
    elsif ( $datatype eq 'captchastyle' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be a captcha style",
            $name )
          unless $value =~ /^rect|default|circle|ellipse|ec|box|blank$/;
    }
    elsif ( $datatype eq 'language' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be a language code",
            $name )
          unless $value =~ /^[a-z][a-z]$/;
    }
    elsif ( $datatype eq 'function_name' ) {
        push @errors,
          sprintf(
            "$list_name Entry called %s should be an xpath function name",
            $name )
          unless $value =~ /^[^\s:]+(:\S+)?$/;
    }
    elsif ( $datatype eq 'path' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be a path", $name )
          unless $value =~ /^\S+$/;
    }
    elsif ( $datatype eq 'url' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be a url", $name )
          unless $value =~ /^(\/)|(http)/;
    }
    elsif ( $datatype eq 'imagesize' ) {
        push @errors,
          sprintf(
            "$list_name Entry called %s should be an image size (123x456)",
            $name )
          unless $value =~ /^\d+x\d+$/;
    }
    elsif ( $datatype eq 'dateformat' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be a time format", $name )
          unless $value =~ /\S/;
    }
    elsif ( $datatype eq 'timeoffset' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be a time zone offset",
            $name )
          unless $value =~ /^(-1[01])|(1[012])|(-?[1-9])|0$/;
    }
    elsif ( $datatype eq 'email' ) {
        push @errors,
          sprintf( "$list_name Entry called %s should be an email address",
            $name )
          unless $value =~ /^[^\s@]+\@[^\s@]+$/;
    }
    elsif ( ( $datatype eq 'abs_file' ) or ( $datatype eq 'abs_dir' ) ) {
        $value = "$path/$value" if ( $path and $value !~ /^\// );
        push @errors,
          sprintf(
"$list_name Entry called %s should be absolute (ie it should start with /)",
            $name )
          unless $value =~ /^\//;
        push @errors,
          sprintf(
"No file or directory corresponds to $list_name entry called %s ('%s')",
            $name, $value )
          unless -e $value;
        if ( -e $value ) {
            push @errors,
              sprintf(
                "$list_name Entry called %s should be a file, not a directory",
                $name )
              if ( ( -d $value ) and ( $datatype eq 'abs_file' ) );
            push @errors,
              sprintf(
                "$list_name Entry called %s should be a directory, not a file",
                $name )
              if ( ( -f $value ) and ( $datatype eq 'abs_dir' ) );
            push @errors,
              sprintf( "$list_name Entry called %s must be readable", $name )
              if ( $record->[3] =~ /r/ and not -r $value );
            push @errors,
              sprintf( "$list_name Entry called %s must be writable", $name )
              if ( $record->[3] =~ /w/ and not -w $value );
            push @errors,
              sprintf( "$list_name Entry called %s must be executable", $name )
              if ( $record->[3] =~ /x/ and not -x $value );
            push @errors, check_file_content( $name, $value, $record->[4] )
              if ( ( -f $value ) and $record->[4] );
        }
    }
    elsif ( $datatype eq 'abs_create' ) {
        $value = "$path/$value" if ( $path and $value !~ /^\// );
        $value =~ m!^(.*/)?([^/]+$)!;
        my $dir = $1;
        push @errors,
          sprintf(
"$list_name Entry called %s should be absolute (ie it should start with /)",
            $name )
          unless $value =~ /^\//;
        push @errors,
          sprintf(
"$list_name No file or directory corresponds to entry called %s, and insufficient rights to create one",
            $name )
          if (
            ( not -e $value )
            and (  ( not $dir )
                or ( -d $dir )
                and ( ( not -r $dir ) or ( not -w $dir ) or ( not -x $dir ) ) )
          );
        push @errors,
          sprintf( "$list_name Entry called %s must be readable", $name )
          if ( $record->[3] =~ /r/ and -e $value and not -r $value );
        push @errors,
          sprintf( "$list_name Entry called %s must be writable", $name )
          if ( $record->[3] =~ /w/ and -e $value and not -w $value );
        push @errors,
          sprintf( "$list_name Entry called %s must be executable", $name )
          if ( $record->[3] =~ /x/ and -e $value and not -x $value );
    }
    elsif ( $datatype eq 'debug_list' ) {
        if ( $value !~ /,/ ) {
            push @errors,
              sprintf( "$list_name Entry called %s cannot include '%s'",
                $name, $value )
              unless $value =~
/^((none)|(all)|(timer-io)|(non-timer-io)|(io)|(show-wrappers)|(connections)|(doc-cache)|(doc-write)|(channels)|(stack)|(update)|(verbose)|(result)|(backup))$/;
        }
        else {
            foreach my $v ( split /\s*,\s*/, $value ) {
                push @errors,
                  sprintf(
"$list_name Entry called %s cannot include 'all' or 'none' in a comma-separated list",
                    $name )
                  if $v =~ /^((none)|(all))$/;
                push @errors,
                  sprintf( "$list_name Entry called %s cannot include '%s'",
                    $name, $v )
                  unless $v =~
/^((none)|(all)|(timer-io)|(non-timer-io)|(io)|(show-wrappers)|(connections)|(doc-cache)|(channels)|(stack)|(update)|(verbose)|(result)|(backup))$/;
            }
        }
    }
    else {
        croak sprintf( "ERROR: Unknown unit config datatype %s", $datatype );
    }
    return @errors;
}

=head2 check_file_content

Check an XML or XSLT file

=cut

sub check_file_content {
    my $name     = shift;
    my $filename = shift;
    my $type     = shift;
    my @ret      = ();
    if ( $type !~ /^((xsl)|(xml))$/ ) {
        push @ret, "Unknown file content type '$type'";
    }
    else {
        my $parser = XML::LibXML->new();
        eval { my $xml_parser = $parser->parse_file($filename) };
        push @ret,
          "Could not parse file for entry '$name' ('$filename') as XML: $@"
          if $@;
    }
    return @ret;
}

=head2 parse_xslt(file_path)

Attempts to parse a file as XSLT 1.0 and returns an error in case of failure (ie false means 'no error').

=cut

sub parse_xslt {
    my $filename = shift;
    my $ret      = '';
    my $parser   = XML::LibXML->new();
    my $xml_parser;
    eval { $xml_parser = $parser->parse_file($filename) };
    if ($@) {
        my $errormsg = $@;
        $errormsg =~ s/ at .*?$//gs;
        $ret = "Could not parse '$filename' as XML: $errormsg";
    }
    else {
        my $xslt_parser = XML::LibXSLT->new();
        eval { my $stylesheet = $xslt_parser->parse_stylesheet($xml_parser) };
        if ($@) {
            my $errormsg = $@;
            $errormsg =~ s/ at .*?$//gs;
            $ret = "Could not parse '$filename' as XSLT: $errormsg";
        }
    }
    return $ret;
}

=head2 apache_time(epoch_time)

Produces an apache-style timestamp from an epoch time.

=cut

sub apache_time {
    my $epoch_time = shift;
    my $time       = gmtime($epoch_time);
    my @days       = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @months     = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    return sprintf(
        "%s, %02d %s %04d %02d:%02d:%02d GMT",
        $days[ $time->wday ],
        $time->mday,
        $months[ $time->mon ],
        $time->year + 1900,
        $time->hour, $time->min, $time->sec
    );
}

=head2 datetime(epoch_time)

Converts GMT epoch time to the format expected by XSLT date functions.

=cut

sub datetime
{    #Converts GMT epoch time to the format expected by XSLT date functions
    my $epoch_time = shift;
    my $time       = gmtime($epoch_time);
    return sprintf(
        "%04d-%02d-%02dT%02d:%02d:%02d+00:00",
        $time->year + 1900,
        $time->mon + 1,
        $time->mday, $time->hour, $time->min, $time->sec
    );
}

=head2 duration_in_seconds(schemaduration)

Converts an XML Schema duration into seconds (Month and Year must be zero or absent for compatibility with EXSLT's date:seconds().

=cut

sub duration_in_seconds {
    my $schema_duration = shift;
    my $epoch_duration  = 0;
    my ( $minus, $date, $time_plus_t, $time ) =
      $schema_duration =~ /^(-)?P([0-9D]+)?(T([0-9.HMS]+))?$/;
    if ( ( not defined $date ) and ( not defined $time ) ) {
        return undef;
    }
    else {
        if ( defined $date ) {
            $date =~ /^((\d+)D)$/;
            $epoch_duration += $2 * 86400 if $2;
        }
        if ( defined $time ) {
            $time =~ /^(((\d+)H)?)(((\d+)M)?)(((\d+(\.\d+)?)S))?$/;

            #print "Values $3:$6:$9";
            $epoch_duration += $3 * 3600 if $3;
            $epoch_duration += $6 * 60   if $6;
            $epoch_duration += $9        if $9;
        }
        $epoch_duration = 0 - $epoch_duration if $minus;
        return $epoch_duration;
    }
}

=head2 index_docroot($docroot_path,$mimetypes_hash)

Returns XML describing the contents of $docroot_path.

=cut

sub index_docroot {
    my $docroot   = shift;
    my $mimetypes = shift;
    my $ndirs     = 0;
    my $nfiles    = 0;

    my $dir_xml;
    my $dir_writer = XML::Writer->new( OUTPUT => \$dir_xml );
    $dir_writer->startTag("directories");

    opendir( DIR, $docroot ) or croak "Cannot opendir '$docroot': $!";
    while ( defined( my $file = readdir(DIR) ) ) {
        next unless $file =~ /^[^.\s]+$/;
        next unless -d "$docroot/$file";
        $ndirs++;
        $dir_writer->startTag(
            "directory",
            "url_path"   => $file,
            "local_path" => $file
        );
        opendir( DIR2, "$docroot/$file" )
          or croak "Cannot opendir '$docroot/$file': $!";
        while ( defined( my $file2 = readdir(DIR2) ) ) {
            next unless $file2 =~ /^[^.\s]+\.([^.\s~%]+)$/;
            my $suffix = $1;
            next unless -f "$docroot/$file/$file2";
            $nfiles++;
            $dir_writer->emptyTag(
                "file",
                "url_name"   => $file2,
                "local_name" => $file2,
                "size"       => ( -s "$docroot/$file/$file2" ),
                "utime"      => Xcruciate::Utils::datetime(
                    ( stat("$docroot/$file/$file2") )[9]
                ),
                "document_type" => ( $mimetypes->{$suffix} || 'text/plain' )
            );
        }
        closedir(DIR2);
        $dir_writer->endTag;
    }
    closedir(DIR);

    $dir_writer->endTag;
    $dir_writer->end;

    return $dir_xml;
}

=head1 BUGS

The best way to report bugs is via the Xcruciate bugzilla site (F<http://www.xcruciate.co.uk/bugzilla>).

=head1 PREVIOUS VERSIONS

B<0.01>: First upload

B<0.03>: First upload containing module

B<0.04>: Changed minimum perl version to 5.8.8

B<0.05>: Added debug_list data type, fixed uninitialised variable error when numbers aren't.

B<0.07>: Attempt to put all Xcruciate modules in one PAUSE tarball.

B<0.08>: Added index_docroot (previously inline code in xcruciate script)

B<0.09>: Fixed typo in error message. Use Carp for errors. Non-fatal option for check_path()

B<0.10>: Prepend path entry to relative paths

B<0.12>: Resolve modifiable file paths, attempt to parse XML and XSLT files

B<0.13>: Do not attempt to parse XSLT as part of config file validation (because modifiable XSLT files
will not be in place for a clean install). Add explicit function to test XSLT later.

B<0.14>: Add doc-write to permissible debug options.

B<0.15>: Dot optional in number data type. Remove last line of XSLT parse errors.

B<0.16>: Integers acceptable where float requested. Added duration data type.

B<0.17>: use warnings.

B<0.18>: dateformat, url and timeoffset data types.

B<0.19>: duration_in_seconds(). Better duration type checking.

B<0.20>: Example durations in error message now legal durations. Added hexbyte, captchastyle and imagesize types.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 - 2009 by SARL Cyberporte/Menteith Consulting

This library is distributed under BSD licence (F<http://www.xcruciate.co.uk/licence-code>).

=cut

1;
