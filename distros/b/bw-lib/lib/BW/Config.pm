# BW::Config.pm
# by Bill Weinman Support for config files
# Based upon bwConfig by Bill Weinman
#
# Copyright (c) 1995-2010 The BearHeart Group, LLC
#

package BW::Config;
use strict;
use warnings;

use IO::File;
use BW::Constants;
use base qw( BW::Base );

our $VERSION = 1.0;
sub version { $VERSION }

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);

    # arrange the room
    $self->{raw_lines} = [];
    $self->{keywords}  = [];
    $self->{values}    = {};
    $self->{arrays}    = {};
    $self->{me}        = ref($self);

    # shall we parse?
    $self->parse() if $self->{filename};

    return SUCCESS;
}

# _setter_getter entry points
sub filename { BW::Base::_setter_getter(@_); }

### getters only

# get the keywords arrayref
sub keywords
{
  my $self = shift;
  return $self->{keywords} || [];
}

# get the values hash
sub values
{
  my $self = shift;
  return $self->{values} || {};
}

# get the arrays hash
sub arrays
{
  my $self = shift;
  return $self->{arrays} || {};
}

### worker bees

# parse the file
sub parse
{
    my $sn   = 'parse';
    my $self = shift;
    my $args = shift;

    # find the filename
    my $filename = $args->{filename} || $self->filename;

    return $self->_error("$sn: No filename.") unless $filename;

    # set the filename property while opening the file
    my $fh = new IO::File( $filename, 'r' )
      or return $self->_error("$sn: Cannot open config file ($filename): $!");

    while (<$fh>) {
        s/#.*//;    # trim end-of-line comments
        $_ = $self->_trim($_);    # trim surrounding whitespace
        next if /^$/;             # skip semantically empty lines

        push @{ $self->{raw_lines} }, $_;
        my ( $lh, $rh ) = split( /=/, $_, 2 );
        $lh = $self->_trim($lh);    # trim them up
        $rh = $self->_trim($rh);
        push @{ $self->{keywords} }, $lh;
        $rh = '' unless $rh;        # avoid undef
        $self->{values}{$lh} = $rh;
        @{ $self->{arrays}{$lh} } = split( /:/, $rh );
    }
    return TRUE;
}

# trim leading/trailing space from a string
sub _trim
{
    my $self = shift;
    my $string = shift or return '';

    $string =~ /\s*(.*?)\s*$/;
    return $1;
}

1;

__END__

=pod

=head1 NAME

  BW::Config.pm

=head1 SYNOPSIS

  use BW::Config;
  my $config = BW::Config->new( { filename => $filename } );
  my $values = $config->values;

  my $config = BW::Config->new;
  $config->parse( { filename => $filename } );
  my $values = $config->values;

  my $errstr;
  if(($errstr = $config->error)) { 
    # report $errstr here
  }

=head1 DESCRIPTION

BW::Config reads and parses simple configuration files. 

=head1 METHODS

=over 4

=item version

Return the version string.

=item filename

Set or return the filename used by BW::Config->parse.

=item keywords

Return an arrayref of keywords, in the order they appear in the 
config file. 

=item values

Return a hashref of key/value pairs. 

=item arrays

Return a hashref of key/arrayref pairs for multi-item values.

=item error

Return the latest error condition. The error string is cleared when 
it is read. 

=back

=head1 FILE FORMAT

The config file format is very simple. It's a line-oriented format 
where keys and values are separated by an equals sign (=). 

  key = value

Whitespace surrounding the keys and values is ignored. 

Array values (multiple values per key) are separated by colons. 

  key = value:value:value:value

If you want the raw colon-separated value, you can get that with the 
values method. 

Lines that begin with '#' are ignored.

  # this is a comment 

anything after '#' to the end of the line is considered a comment and
is ignored.

  key = value # comment comment blah blah blah

All leading and trailing whitespace are trimed, and a key without 
a value is assumed to have a zero-length string as the value.

=head1 NOTES

=over

=item *

Values are never undef. A zero-length string is provided for null content. 

=item *

Errors are reported via the BW::Config->error method. It's a good idea to 
check this before using the values from your config file. 

  if((my $errorstring = $config->error)) {
    die $errorstring;  # or some other way of reporting the error
  }

=back

=head1 BUGS AND MISFEATURES

There is no quoting mechanism for the config file. The colon-separated 
arrays are particularly weak. There should be a way to quote a colon 
so it's not interpreted as such. 

There should also be a way to quote strings and quote marks. These may 
be features for a future version.

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>.

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

2010-02-14 bw 1.1   - initial CPAN version
2008-04-02 bw       - initial BW-Lib version

=cut

