# Copyright (C) 2004 Identity Commons.  All Rights Reserved.
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>, <fen@comedia.com>
#   with a tip-of-the-cap to parse.py written by Gabe Wachob

# TODO:
#      fix FIXME sections
#      add UNICODE support

package XRI::Parse;

our $VERSION = 0.1;

use Text::Balanced qw( extract_bracketed );
use URI::Escape;

our @SEPARATORS = qw( / * : );
our @GCS_CHARS  = qw( @ = + $ * );


sub new {
    my $self = shift;
    my $xri = shift;
    $xri =~ s/^xri://i;
#    $xri = stripComments( $xri );
    my $this = { token=>undef,
                 remainder=>undef,
                 authority=>undef,
                 xri=>$xri };
    bless $this, $self;
}


# escapes an XRI (including relative XRIs) for inclusion in an HTTP request
# FIXME: currently handles xrefs identically to sub-segments
#
sub escapeURI {
    my $this = shift;
    my $result;
    while (my $seg = $this->nextSegment) {
        $result = shift @$seg;     # always one of qw( @ // /. /: )
        foreach my $subseg ( @$seg ) {
            if ($subseg =~ m|^\(|) {            # xref
                $result .= uri_escape($subseg, "^A-Za-z0-9\\\-\_\.\!\~\*\'");
            }
            else {                              # sub-segment
                $result .= uri_escape($subseg, "^A-Za-z0-9\\\-\_\.\!\~\*\'");
            }
        }
    }
    return $result;
}

# if an absolute-xri, emit the array ref [ [ firstSegment ], local-path ]
# if a  relative-xri, emit the local-path or relative-path as a string
#
sub splitAuthLocal {
    my $this = shift;
    my $firstRef = $this->nextSegment;

    if ( defined $this->{'authority'} ) {
        my @auth = ();
        #
        # lowercase the authority segments
        #
        foreach my $seg (@$firstRef) {
            push @auth, lc $seg;
        }
        return [ \@auth, $this->{remainder} ];
    }
    else {
        return $this->{xri};
    }
}

# Emits a series of segments, each of which is a
#       list of (separator, part, separator...) tuples
# Segments are separated by forward slash '/'
# Emits (gcs-char, part, separator, part...)
#       for the first segment if using a gcs-char
# Separator is one of "/.", "/:", ".", or ":"
#
sub nextSegment {
    my $this = shift;
    my ( $token, @segment );

    if (defined $this->{token}) {
        @segment = ( $this->{token} );
        undef $this->{token};
    }
    else {
        if ( $token = $this->nextToken ) {
            @segment = ( $token );
        }
        else {
            return undef;
        }
    }
    while (( $token = $this->nextToken ) && $token !~ m|^\/| ) {
        push @segment, $token;
    }
    $this->{token} = $token if $token;
    return \@segment;
}

sub getCrossReference {
    my $this = shift;
    my $xri  = shift;

    # FIXME: what to do if: 'xri:(!comment1).(!comment2)' -- (is this legal?)
    # FIXME: raise error if unbalanced parens
    while (($this->{remainder} = $xri)  =~ m|^\(|) {               # cross-reference
        my $xref;
        ($xref, $xri) = extract_bracketed($xri, '()');
        next if $xref =~ m|^\(\!|;               # skip leading comments
        $this->{remainder} = $xri;
        return $xref;
    }
    return undef;
}

# return initial qw( @ = * // ) or undef
# created to better strip leading comments
# perhaps comment stripping should occur on object instantiation?
#
sub getAuthority {
    my $this = shift;
    my $xri  = $this->{xri};
    my $xref;

    if ( $xref = $this->getCrossReference( $xri )) {
        $this->{'authority'} = $xref;
        return $xref;
    }
    if ($this->{remainder} =~ m|^\/\/(.*)$|) {                # initial '//'
        $this->{'authority'} = '//';
        $this->{remainder} = $1;
        return '//';
    }
    if ($this->{remainder} =~ m|^([\@\=\*])(.*)$|) {          # gcs-char
        my ($gcs, $rem) = ($1, $2);
        $this->{remainder} = (($rem =~ m|^[\/\*\:]|)?'':'*') . $rem;
        $this->{'authority'} = $gcs;
        return $gcs;
    }
    $this->{remainder} = $xri;
    return;
}
    

# Generates a list of (separator, string) pairs
# Ignores the leading xri:
# If the first two characters (ignoring the xri:) are //, returns this *once* as the
# first token, as the // is only legal at the very beginning
# Everything within () is treated as a single token
# Yields a series of strings, one of the characters in SEPARATORS, or
# a string of characters (a sub-segment)
# FIXME: fix handling of '*'
# FIXME: add handling of '&'
# FIXME: strip comments: including multiple, before or after GCS
#
sub nextToken {
    my $this = shift;
    my $auth;

    if (!defined $this->{remainder} && ($auth = $this->getAuthority)) {
        return $auth;
    }
    return $xref if $xref = $this->getCrossReference( $this->{remainder} );

    if ($this->{remainder} =~ m|^([\/\*\:])(.*)$|) {  # initial separators
        my ($sep, $rem) = ($1, $2);
        if ($sep eq '/') {
            if ($rem =~ m|^([\*\:])(.*)$|) {
                $sep .= $1;                             # '/.' or '/:'
                $rem = $2;
            }
            else {
                $sep = '/*';
            }
        }
        $this->{remainder} = $rem;
        return $sep;
    }
    if ($this->{remainder} =~ m|^([^\/\*\:]+)(.*)$|) { # sub-segment
        $this->{remainder} = $2;
        return $1;
    }
    return undef;
}

1;
__END__
=head1 NAME

XRI::Descriptor - Parse routines for XRI

=head1 SYNOPSIS

    use XRI:Parse;
    my $XRI = XRI::Parse->new($xri);

    $escaped = $XRI->escapeURI;
    $split   = $XRI->splitAuyhLocal;

=head1 ABSTRACT

Parse routines for XRI

=head1 DESCRIPTION

This module provides utilities to parse an XRI string.

=head1 BUG

=over 4

=item *

Clean up escape code

=item *

Strip comments properly

=back

=head1 SEE ALSO

xri(3)

=head1 AUTHOR

Fen Labalme, E<lt>fen@idcommons.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Identity Commons

See LICENSE.

=cut
