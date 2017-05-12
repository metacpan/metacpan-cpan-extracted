# BW::XML::Out.pm
# Simple XML output
#
# by Bill Weinman - http://bw.org/
# Copyright (c) 1995-2010 The BearHeart Group, LLC
#
# See POD for History
#
package BW::XML::Out;
use strict;
use warnings;

use BW::Constants;
use base qw( BW::Base );

our $VERSION = "1.4";
sub version { $VERSION }

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);

    $self->indent_mul(2) unless $self->{indent_mul};  # default to 2 spaces of indentation

    return SUCCESS;
}

# _setter_getter entry points
sub indent_mul   { BW::Base::_setter_getter(@_); }
sub indent_level { BW::Base::_setter_getter(@_); }

sub element
{
    my $sn = 'element';
    my ( $self, $element, $content, $options ) = @_;
    my $a            = '';
    my $attribs      = '';
    my $flags        = {};
    my $indent_level = $self->indent_level() || 0;

    $options = {} unless $options;

    $content = '' unless defined $content;
    $content = $self->xml_escape($content) if ( $content and not $options->{xmlContent} );

    if ($options) {
        if ( $options->{indentLevel} ) {
            $indent_level = $options->{indentLevel};
        }
        if ( $options->{indent} ) {
            ++$indent_level;
        }
        if ( $options->{startTag} ) {
            $flags->{start} = TRUE;
        } elsif ( $options->{endTag} ) {
            $flags->{end} = TRUE;
            --$indent_level;
        } elsif ( $options->{emptyTag} ) {
            $flags->{empty} = TRUE;
        }

        if ( $options->{attribs} ) {
            my @ats = @{ $options->{attribs} };
            foreach my $att (@ats) {
                my @att  = %$att;
                my $a_lh = $self->xml_escape( $att[0] );
                my $a_rh = $self->xml_escape( $att[1] );
                $attribs .= qq{ ${a_lh}="${a_rh}"};
            }
        }
    }

    # create the indent
    $a .= ' ' x ( $indent_level * $self->indent_mul() );

    if ( $flags->{empty} ) {
        $a .= qq{<${element}${attribs} />};
    } elsif ( $flags->{start} ) {
        $a .= qq{<${element}${attribs}>};
    } elsif ( $flags->{end} ) {
        $a .= qq{</${element}>};
    } else {
        $a .= qq{<${element}${attribs}>${content}</${element}>};
    }

    # terminate the element with a newline
    $a .= "\n" unless $options->{noNewline};

    if ( $options->{startTag} ) {
        ++$indent_level;
    }

    # keep the indent level
    $self->indent_level($indent_level);

    return $a;
}

sub xml_escape
{
    my ( $self, $c ) = @_;
    return '' unless defined $c;
    $c =~ s/&/&amp;/gsm;
    $c =~ s/</&lt;/gsm;
    $c =~ s/>/&gt;/gsm;
    $c =~ s/"/&quot;/g;

    return $c;
}

# set the error string and return FAILURE
sub _error
{
    my $self = shift;
    $self->{error} = "$self->{me}: " . ( shift || 'unknown error' );
    return FAILURE;
}

# get and clear error string
sub error
{
    my $self   = shift;
    my $errstr = $self->{error};
    $self->{error} = VOID;
    return $errstr;
}

1;

__END__

=head1 NAME

BW::XML::Out - Simple XML output

=head1 SYNOPSIS

  use BW::XML::Out;
  my $errstr;

  my $x = BW::XML::Out->new;
  error($errstr) if (($errstr = $x->error));

=head1 METHODS

=over 4

=item B<new>

Constructs a new object . . . 

=item B<element>( element, content, options )

Returns an XML element. Can be a start-tag, an end-tag, an empty tag, or 
a container with or without content. 

Returns a string with the XML element. Sets the error string (and returns 
FAILURE) if there's a problem. 

Possible options include:

B<startTag> -- A start-tag, has no content. 

B<endTag> -- An end-tag, has no content;

B<xmlContent> -- Do not escape the content;

B<emptyTag> -- An empty tag, has not content, formatted like:

    <element />

B<attribs> -- An array ref of hash refs, like this: 

    $out = $x->('element', undef, {
      startTag => TRUE,
      attribs => [
       { Att1 => 'one' },
       { Att2 => 'two }
      ]
    } );

... will return this:

    <element Att1="one" Att2="two">

=item B<indent_mul>

Setter-getter for the B<indent_mul> property.

=item B<indent_level>

Setter-getter for the B<indent_level> property.

=item B<error>

Returns and clears the object error message. 

=back

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>.

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

    2010-03-11 bw 1.6.0 -- released to CPAN as part of BW-Lib
    2009-11-04 bw 1.5   -- documentation update - option xmlContent
    2008-04-23 bw 1.4   -- added noNewline option
    2008-03-30 bw 1.3   -- added some options to element
    2008-03-26 bw 1.2   -- miscellaneous cleanup
    2007-08-13 bw 1.1   -- fixed a zero-vs-defined bug
    2007-07-20 bw 1.0   -- initial release as a BW::* module

=cut

