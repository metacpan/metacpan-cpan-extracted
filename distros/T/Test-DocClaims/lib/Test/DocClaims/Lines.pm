package Test::DocClaims::Lines;

# Copyright (c) Scott E. Lee

use 5.008009;
use strict;
use warnings;
use Carp;

use Test::DocClaims::Line;

# Tell croak to skip over calls from here.
our @CARP_NOT = qw< Test::DocClaims >;

# Keys in the blessed hash
#   {lines}      array of Test::DocClaims::Line objects
#   {current}    the current index into {lines}
#   {paths}      list of paths and/or globs used to read the lines

=head1 NAME

Test::DocClaims::Lines - Represent lines form one of more files

=head1 SYNOPSIS

  use Test::DocClaims::Lines;
  my $lines = Test::DocClaims::Lines->new("t/Foo*.t");
  my %files;
  while ( !$lines->is_eof ) {
      my $line = $lines->current_line;
      $files{ $line->path }[ $line->lnum - 1 ] = $line->text;
      $lines->advance_line;
  }

=head1 DESCRIPTION

This holds a collection of lines from one or more files.
The file path and line number of each line is recorded as well as
other attributes of both the file and the individual lines.
For example, it records whether a file supports POD documentation
and whether each line is POD documentation or not.
Each line in the list is represented as a Test::DocClaims::Line object.

There is a concept of current line.
This can be used to step through the lines sequentially.

=head1 CONSTRUCTOR

=head2 new I<FILE_SPEC>

The I<FILE_SPEC> argument specifies a list of one or more files.
It can be one of:

  - a string which is the path to a file or a wildcard which is
    expanded by the glob built-in function.
  - a ref to a hash with these keys:
    - path:    path or wildcard (required)
    - has_pod: true if the file can have POD (optional)
  - a ref to an array, where each element is a path, wildcard or hash
    as above

If a list of files is given, those files are read in order and the
lines in each are concatenated.
If a wildcard expands to more than one file they are read in the order
returned by the glob built-in.

=cut

sub new {
    my $class     = shift;
    my $file_spec = shift;
    croak "missing arg to Test::DocClaims::Line->new" unless $file_spec;
    my $self = bless {}, ref($class) || $class;
    $self->{lines}   = [];
    $self->{current} = 0;
    $self->{paths}   = [];
    foreach my $attrs ( $self->_file_spec_to_list($file_spec) ) {
        $self->_add_file($attrs);
    }
    return $self;
}

=head1 ACCESSORS

=head2 is_eof

This returns true if the end of the lines has been reached.

=cut

sub is_eof {
    my $self = shift;
    return $self->{current} >= scalar( @{ $self->{lines} } );
}

=head2 advance_line

This advances to the next line and returns the Test::DocClaims::Line
object for that line.
If there is no next line, undef is returned.

=cut

sub advance_line {
    my $self = shift;
    $self->{current}++;
    return $self->current_line;
}

=head2 current_line

Return the current line, a Test::DocClaims::Line object.
If there is no current line because the end has been reached, undef is
returned.

=cut

sub current_line {
    my $self = shift;
    return undef if $self->is_eof;
    return $self->{lines}[ $self->{current} ];
}

=head2 paths

Return a list of strings for the paths and/or globs used to read the file
or files.

=cut

sub paths {
    my $self = shift;
    return @{ $self->{paths} };
}

# Convert a file spec arg to a list of attribute hashes representing the
# files.
sub _file_spec_to_list {
    my $self = shift;
    my $arg  = shift;
    $arg = [$arg] unless ref $arg eq "ARRAY";

    # Expand wildcards to a list of paths (or hashes), putting the results
    # into @specs.
    my @specs;
    foreach my $item (@$arg) {
        if ( ref $item eq "HASH" ) {
            croak "file spec is hash, but it has no 'path' key"
                unless length $item->{path};
            push @{ $self->{paths} }, "$item->{path}";
            my @list = _glob( $item->{path} );
            @list = sort @list;
            croak "no such file ($item->{path})" unless @list;
            foreach my $path (@list) {
                push @specs, { %$item, path => $path };
            }
        } else {
            push @{ $self->{paths} }, "$item";
            my @list = _glob($item);
            @list = sort @list;
            croak "no such file ($item)" unless @list;
            push @specs, @list;
        }
    }

    # Convert each item in the list to a hash if it isn't already and fill
    # in any missing attributes with default values.
    foreach my $item (@specs) {
        if ( ref $item eq "HASH" ) {
            my %default = $self->_attrs_of_file( $item->{path} );
            foreach my $key ( keys %default ) {
                $item->{$key} = $default{$key} unless defined $item->{$key};
            }
        } else {
            $item = { path => $item, $self->_attrs_of_file($item) };
        }
    }
    return @specs;
}

# This wrapper for the glob function can be overridden at run time (by the
# TestTester module), where the system glob can only be overridden at
# compile time.
sub _glob {
    return glob( $_[0] );
}

# Each attribute hash has at least these keys:
#   path    the path of the file
#   has_pod true if it should be parsed as POD
#   white   true if amount of white space at beginning of lines is preserved
# TODO remove white attribute
sub _attrs_of_file {
    my $self  = shift;
    my $path  = shift;
    my %attrs = (
        has_pod => 0,
        white   => 0,
    );
    if ( $path =~ /\.p[lm]$/ ) {
        $attrs{has_pod} = 1;
    } elsif ( $path =~ /\.pod$/ ) {
        $attrs{has_pod} = 1;
    } elsif ( $path =~ /\.t$/ ) {
        $attrs{has_pod} = 1;
    }
    return %attrs;
}

sub _add_file {
    my $self     = shift;
    my $attrs    = shift;
    my $lines    = _read_file( $attrs->{path} );
    my $lnum     = 0;
    my $doc_mode = !$attrs->{has_pod};
    my $code     = undef;
    my $todo     = undef;
    my $in_data = 0;    # ignore TestTester files in __DATA__ section

    foreach my $text (@$lines) {
        $in_data = 1 if $text =~ /^__(END|DATA)__$/;
        last if $in_data && $text =~ /^FILE:<.*>-/;
        my %hash = ( orig => $text, lnum => ++$lnum );
        my $this_line_doc;
        if ( $attrs->{has_pod} ) {
            if ( $text =~ /^=([a-zA-Z]\S*)(\s+(.*))?\s*$/ ) {
                my ( $cmd, $cmd_text ) = ( $1, $2 );
                $hash{is_doc} = 1;
                $doc_mode = 1;
                if ( $cmd eq "pod" ) {
                    $this_line_doc = 0;
                } elsif ( $cmd =~ /^cut/ ) {
                    my ( $format, $args ) = _parse_pod_command($cmd_text);
                    $this_line_doc = 0;
                    $doc_mode      = 0;
                } elsif ( $cmd =~ /^begin/ ) {
                    my ( $format, $args ) = _parse_pod_command($cmd_text);
                    if ( $format eq "DC_CODE" ) {
                        $this_line_doc = 0;
                        $code          = $args;
                    }
                } elsif ( $cmd =~ /^end/ ) {
                    my ( $format, $args ) = _parse_pod_command($cmd_text);
                    if ( $format eq "DC_CODE" ) {
                        $this_line_doc = 0;
                        $code          = undef;
                    }
                } elsif ( $cmd =~ /^for/ ) {
                    my ( $format, $args ) = _parse_pod_command($cmd_text);
                    if ( $format eq "DC_TODO" ) {
                        $this_line_doc = 0;
                        $todo          = $args;
                    }
                }
            }
        }
        if ( !defined $this_line_doc ) {
            $this_line_doc = 1 if $code || $doc_mode;
        }
        $hash{is_doc}  = $this_line_doc ? 1 : 0;
        $hash{has_pod} = $attrs->{has_pod};
        $hash{code}    = $code;
        $hash{todo}    = $todo;
        $todo          = undef;
        $text =~ s/\s+$//;    # remove CRLF, NL and trailing white space
        $text =~ s/^\s+/ / if !$attrs->{white};
        $hash{text} = $text;
        $hash{file} = $attrs;
        push @{ $self->{lines} }, Test::DocClaims::Line->new(%hash);
    }
    return $self;
}

sub _parse_pod_command {
    my $text = shift;
    my ( $format, %args );
    if ( $text =~ /^\s*(\S+)(\s+(.*))?$/ ) {
        $format = $1;
        %args =
            map { /^(.+?)=(.*)$/ ? ( $1 => $2 ) : ( $1 => 1 ) }
            grep { length $_ }
            split " ", $3 || "";
    } else {
        $format = "";
    }
    return ( $format, \%args );
}

sub _read_file {
    my $path = shift;
    my @lines;
    if ( open my $fh, "<", $path ) {
        @lines = <$fh>;
        close $fh;
    } else {
        die "cannot read $path: $!\n";
    }
    return \@lines;
}

=head1 COPYRIGHT

Copyright (c) Scott E. Lee

=cut

1;

