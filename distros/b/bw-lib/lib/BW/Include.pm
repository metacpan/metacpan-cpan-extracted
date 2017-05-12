# BW::Include.pm
# Template support for BW::* (esp BW::CGI)
# 
# by Bill Weinman - http://bw.org/
# Copyright (c) 1995-2010 The BearHeart Group, LLC
#
# See POD for History

# Important note: 
# This is a bona-fide kludge. I've been using it, or some version of it,
# for so many years that it works well for me. YMMV. 

package BW::Include;
use strict;
use warnings;

use IO::File;
use IO::Pipe;
use BW::Constants;
use base qw( BW::Base );

our $VERSION = "1.0.2";

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);

    $self->self( $ENV{SCRIPT_NAME} || EMPTY ) unless $self->{self};
    $self->{dir} = $self->{DIR} if $self->{DIR};
    $self->{filename} = $self->{FILENAME} if $self->{FILENAME};

    return SUCCESS;
}

# _setter_getter entry points
sub self     { BW::Base::_setter_getter(@_); }    # self-reference URI
sub dir      { BW::Base::_setter_getter(@_); }    # base dir -- must be absolute
sub DIR      { BW::Base::_setter_getter(@_); }    # for backward compatibility
sub filename { BW::Base::_setter_getter(@_); }    # filename for preloading
sub FILENAME { BW::Base::_setter_getter(@_); }    # for backward compatibility
sub QUIET    { BW::Base::_setter_getter(@_); }    # for quiet mode

sub version
{
    return $VERSION;
}

# set or get quiet mode
sub quiet
{
    my $self = shift;
    $self->{QUIET} = shift if @_;
    return $self->{QUIET};
}

# set and get vars
sub var
{
    my $self  = shift;
    my $name  = shift or return '';
    my $value = shift;

    if ( defined($value) ) {
        $self->{VARS}{$name} = $value;
    }

    return $self->{VARS}{$name};
}

# wrapper for print self->spf
sub pf
{
    my $self = shift;
    my $filename = shift || $self->{filename};
    return $self->_error( "pf: No filename" ) unless $filename;
    STDOUT->autoflush(1);
    print $self->spf($filename);
}

# expand from a string to a string
sub sps
{
    my ( $self, $string ) = @_;
    return $string unless $string;

    $string =~ s|\$([a-z0-9_:]+)\$|$self->var($1)|gei;
    $string =~ s|<!--#echo var="([^"]+)" -->|$self->var($1)|ge;
    return $string;
}

# main routine -- recursively builds a string from file with includes
sub spf
{
    my $self = shift;

    my $filename = shift || $self->{filename};
    return $self->_error( "No filename" ) unless $filename;

    # create the filename
    if ( substr( $filename, 1, 1 ) eq '/' and $ENV{DOCUMENT_ROOT} ) {
        $filename = $ENV{DOCUMENT_ROOT} . $filename;
    } elsif ( $self->{dir} ) {
        $filename = "$self->{dir}/$filename";
    }

    my $s = '';

    # this alows arbitrary perl code in the included file
    sub expand
    {
        my $self = shift;
        my $v    = shift;
        my $x;
        if    ( $x = $self->var($v)     or defined $x ) { $x }
        elsif ( $x = eval("\$main::$v") or defined $x ) { $x }
        elsif ( $x = eval("\$$v")       or defined $x ) { $x }
        elsif ( $x = eval("\$ENV{$v}")  or defined $x ) { $x }
        else { $self->{QUIET} ? '' : "Undefined Variable ($v)" }
    }

    # include virtual for running CGI ...
    sub runprog
    {
        my $self = shift;
        my $_qs  = '';
        my $x    = '';
        my $pn   = shift || '';

        # $pn =~ m|^/| or $pn = '/' . $pn;  # imply the leading / if missing
        my $progpath = '';
        if ( $pn =~ m|^/| ) {
            $progpath = "$ENV{DOCUMENT_ROOT}$pn";
        } else {
            if ( $ENV{SCRIPT_FILENAME} ) {    # derive the current directory if possible
                $ENV{SCRIPT_FILENAME} =~ m|(.*[\\/])|;
                $progpath = $1 || '';
            } else {
                $progpath = "./";             # a unixish guess
            }
            $progpath .= $pn;
        }

        ( $progpath, $_qs ) = split( /\?/, $progpath, 2 );
        if ( -f $progpath ) {
            if ( -x $progpath ) {             # run it as CGI
                                              # save the environment
                my $sn = $ENV{SCRIPT_NAME};
                my $qs = $ENV{QUERY_STRING};
                my $cl = $ENV{CONTENT_LENGTH} if $ENV{CONTENT_LENGTH};
                my $ct = $ENV{CONTENT_TYPE} if $ENV{CONTENT_TYPE};
                my $rm = $ENV{REQUEST_METHOD} || 'GET';

                # set up the CGI environment
                $pn =~ /(.*)\?/ and $pn = $1;    # SCRIPT_NAME has no query
                $ENV{SCRIPT_NAME} = $pn;
                $ENV{QUERY_STRING} = $_qs || '';

                # post method is always invalid for included CGI . . .
                delete $ENV{CONTENT_LENGTH} if $ENV{CONTENT_LENGTH};
                delete $ENV{CONTENT_TYPE}   if $ENV{CONTENT_TYPE};
                $ENV{REQUEST_METHOD} = 'GET';

                # make the path safe for the -T switch
                my $env_path = $ENV{PATH} || '';
                $ENV{PATH} = '';

                # makesure the progpath string is safe
                if ( $progpath =~ /^([-\/\\\@\w.]+)$/ ) {
                    $progpath = $1;

                    # run it
                    my $p = new IO::Pipe;
                    $p->reader($progpath);
                    while (<$p>) { $x .= $_ }
                    $p->close;

                    # can't use the mime header
                    $x =~ s/^content-type:.*//i if $x;
                }

                else {
                    $x = 'unsafe characters in exec';
                }

                # restore the environment
                $ENV{PATH}           = $env_path;
                $ENV{SCRIPT_NAME}    = $sn;
                $ENV{QUERY_STRING}   = $qs;
                $ENV{CONTENT_LENGTH} = $cl if $cl;
                $ENV{CONTENT_TYPE}   = $ct if $ct;
                $ENV{REQUEST_METHOD} = $rm;
                return $x;
            } else {    # display it
                return $self->spf($progpath);
            }
        } else {
            return "$progpath: $!";
        }
    }

    my $fh = IO::File->new("<$filename") or return $self->_error( "spf: cannot open $filename ($!)" );

    while (<$fh>) {
        $_ =~ s|\$([a-z0-9_:]+)\$|expand($self, $1)|gei;
        $_ =~ s|<!--#echo var="([^"]+)" -->|expand($self, $1)|ge;
        $_ =~ s|<!--#include virtual="([^"]+)" -->|runprog($self, $1)|ge;
        $s .= $_;
    }
    close $fh;

    return $s;
}

return 1;


__END__

=head1 NAME

BW::Include - Included File Processing

=head1 SYNOPSIS

  use BW::Include;

  $pf = new BW::Include;

  $pf = new BW::Include($filename);

  $pf = new BW::Include(DIR => $absolutepath)

  $pf = new BW::Include({
                   DIR => $absolutepath, 
                   FILENAME => $filename
                 })

=head1 ABSTRACT

Include perl objects in external files for processing the output of 
CGI and other perl programs. 

=head1 METHODS

=over 4

=item B<spf>

   $pf->spf;
   $pf->spf($filename);

The B<spf> method reads a file, performs the appropriate replacements, 
and returns the result. The file named in I<$filename> is used, if provided. 

=item B<pf>

   $pf->pf;
   $pf->pf($filename);

The B<pf> method calls B<spf> and sends the result to B<STDOUT>. 
The file named in I<$filename> is used, if provided. 

=item B<sps> string

Performs replacements on a string instead of a file. Returns the results as a string. 

=item B<var>

   $pf->var($name);
   $pf->var($name, $value);

The B<var> method sets or gets the value of a named variable. The variables 
are stored in a hash associated with the BW::Include object. If there is a 
value passed, the method sets the variable. The method always returns the 
value, if any. 

=back

=head1 OBJECT DATA VARIABLES

Object values can be specified in the initiation of the BW::Include object in 
several ways: 

   $pf = new BW::Include($filename);

If the new constructor is called with a single scalar argument, it is used for 
the default filename. 

   $pf = new BW::Include(DIR => $path, FILENAME => $filename);

If the new constructor is called with several arguments, they are taken to be 
hash name/value pairs. These are used as object data variables (see below).

   $pf = new BW::Include( { DIR => $path, FILENAME => $filename } );

Alternately the new constructor may be called with a hash reverence, 
which will be used for object data variables (see below). 

=over 4

=head2 

The object data variables are used as follows:

=item B<FILENAME>

The filesystem name of the file to be included. 

=item B<DIRECTORY>

An optional directory where the filename will be read from. This is useful 
for putting all of your HTML files in one place. You can specify relative 
directories from this base in your filenames. For example: 

   $pf = new BW::Include ( DIRECTORY => "/home/you/htmlfiles" );

   $pf->pf( "subdirectory/admin.html" );

That will use /home/you/htmlfiles/subdirectory/admin.html as the file to 
be included. 

=back

=head1 FILE PROCESSING

=over 4

=head2 Variable Replacement

=head2 Including External CGI Programs

=head2 mod_inclue Emulation

=head2 File Location

=back

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>.

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

    2010-03-11 bw -- 1.0.2  -- fixed small POD typo
    2010-02-02 bw -- 1.0.1  -- first CPAN version - some cleanup and documenting

=cut

