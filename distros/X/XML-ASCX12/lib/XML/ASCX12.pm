#
# $Id: ASCX12.pm,v 1.17 2004/09/28 14:59:34 brian.kaney Exp $
#
# XML::ASCX12
#
# Copyright (c) Vermonster LLC <http://www.vermonster.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# For questions, comments, contributions and/or commercial support
# please contact:
#
#    Vermonster LLC <http://www.vermonster.com>
#    312 Stuart St.  2nd Floor
#    Boston, MA 02116  US
#
# vim: set expandtab tabstop=4 shiftwidth=4
#

=head1 NAME

XML::ASCX12 - ASCX12 EDI to XML Module

=head1 SYNOPSIS

    use XML::ASCX12;
    
    my $ascx12 = new XML::ASCX12();
    $ascx12->convertfile("/path/to/edi_input", "/path/to/xml_output");

=head1 INFORMATION

=head2 Module Description

XML::ASCX12 started as a project to process X12 EDI files from shipping
vendors (i.e. transaction sets 110, 820 and 997).  However, this module can be
extended to support any valid transaction set (catalog).

=head2 Why are you doing this?

If you've ever taken a look at an ASCX12 document you'll see why.  The EDI format is
very compact, which makes is great for transmission.  However this comes at a cost.

The main challenge when dealing with EDI data is parsing through the structure.
Here we find loops within loops within loops.  In this non-extensible, flat format,
human parsing is nearly impossible and machine parsing is a task at best.

A quick background of how a typical EDI is formed:


        +---->  ISA - Interchange Control Header
        |          GS - Functional Group Header       <--------+
        |              ST - Transaction Set Header             |
    Envelope              [transaction set specific]  Functional Group
        |              SE - Transaction Set Trailer            |
        |          GE - Functional Group Trailer      <--------+
        +---->  ISE - Interchange Control Trailer



The Transmission Envelope can have one or more Functional Group.  A Functional Group
can have one or more Transaction Set.  Then each specific catalog (transaction set)
can have it's own hierarchical rules.

This sort of structure really lends itself to XML.  So using the power of Perl,
this module was created to make accessing EDI information easier.

To learn more, the official ASC X12 group has a website L<http://www.x12.org>.

=head2 Module Limitations

This is a new module and has a few limitations.

=over 4

=item * EDI -> XML

This module converts from EDI to XML.  If you want to go in the other direction, suggest
creating an XSL stylesheet and use L<XML::XSLT|XML::XSLT> or similar to preform a transformation.

=item * Adding Transaction Sets

Adding new catalogs is a manual process.  The L<XML::ASCX12::Segments|XML::ASCX12::Segments> and
the L<XML::ASCX12::Catalogs|XML::ASCX12::Catalogs> need to be manually updated.  A future development effort
could store this information in dbm files with an import script if demand exists.

=back

=head2 Style Guide

You will (hopefully) find consistent coding style throughout this module.
Any private variable or method if prefixed with an underscore (C<_>).  Any
static method or variable is named in C<ALL_CAPS>.

The tabs are set at 4 spaces and the POD is physically close to the stuff it
is describing to promote fantastic ongoing documentation.

=cut
package XML::ASCX12;

use 5.008004;
use strict;
use warnings;

no warnings 'utf8';
use bytes;

our $VERSION = '0.03';

=head1 REQUIREMENTS

We use the L<Carp|Carp> module to handle errors.  Some day there may be a better
error handler and maybe an error object to reference, but for now it croaks
when there is a problem.

L<XML::ASCX12::Catalogs|XML::ASCX12::Catalogs> module is required and probably part of this package,
as is the L<XML::ASCX12::Segments|XML::ASCX12::Segments>.

=cut
use Carp qw(croak);

use XML::ASCX12::Catalogs qw($LOOPNEST load_catalog);
use XML::ASCX12::Segments qw($SEGMENTS $ELEMENTS);

=head1 VARIABLE AND METHODS

=head2 Private Variables

These variables are not exported and not intended to be accessed externally.
They are listed here for documentation purposes only.

=over 4

=item C<@_LOOPS>

Dynamic and keeps track of which loop we are on.

=item C<%_XMLREP>

Static variable used to lookup bad XML characters.

=item C<$_XMLHEAD>

Static variable containing the XML header for the output.

=back

=cut
use vars qw(@_LOOPS %_XMLREP $_XMLHEAD);

%_XMLREP = (
     '&' => '&amp;'
    ,'<' => '&lt;'
    ,'>' => '&gt;'
    ,'"' => '&quot;'
);

$_XMLHEAD = qq|<?xml version="1.0"?><ascx:message xmlns:ascx="http://www.vermonster.com/LIB/xml-ascx12-01/ascx.rdf" xmlns:loop="http://www.vermonster.com/LIB/xml-ascx12-01/loop.rdf">|;

=head2 Public Methods

=over 4

=item object = new([$segment_terminator], [$data_element_separator], [$subelement_separator])


The new method is the OO constructor.  The default for the segment terminator
is ASCII C<85> hex. The default for the data element separator is ASCII C<1D> hex.  The default
for the sub-element separator is ASCII C<1F> hex.

    my $xmlrpc = new XML::ASCX12();

The defaults can be overridden by passing them into the constructor.

    my $xmlrpc = new XML::ASCX12('\x0D', '\x2A', '\x3A');

The object that returns is now ready to transform EDI files.

=cut
sub new
{
    my ($name, $st, $des, $sbs) = @_;

    $st = '\x85' unless $st;
    $des = '\x1D' unless $des;
    $sbs = '\x1F' unless $sbs;

    my $class = ref($name) || $name;
    my $self = { ST=>$st, DES=>$des, SBS=>$sbs };

    bless ($self, $class);
    return $self;
}

=item boolean = $obj->convertfile($input, $output)


This method will transform and EDI file to XML using the configuration information
passed in from the constructor.

    my $xmlrpc = new XML::ASCX12();
    $xmlrpc->convertfile('/path/to/EDI.dat', '/path/to/EDI.xml');

You may also pass filehandles (or references to filehandles):

    $xmlrpc->convertfile(\*INFILE, \*OUTFILE);

=cut
sub convertfile
{
    my ($self, $in, $out) = @_;
    my ($inhandle, $outhandle);
    my ($bisinfile, $bisoutfile);

    $self->_unload_catalog();

    if (ref($out) eq "GLOB" or ref(\$out) eq "GLOB"
            or ref($out) eq 'FileHandle' or ref($out) eq 'IO::Handle')
    {
        $outhandle = $out;
    }
    else
    {
        local(*XMLOUT);
        open (XMLOUT, "> $out") || croak "Cannot open file \"$out\" for writing: $!";
        $outhandle = *XMLOUT;
        $bisoutfile = 1;
    }

    my $st_check=0;
    my $des_check=0;

    print {$outhandle} $XML::ASCX12::_XMLHEAD;
    {
        if (ref($in) eq "GLOB" or ref(\$in) eq "GLOB"
                or ref($in) eq 'FileHandle' or ref($in) eq 'IO::Handle')
        {
            $inhandle = $in;
        }
        else
        {
            local(*EDIIN);
            open (EDIIN, "< $in") || croak "Cannot open file \"$in\" file for reading: $!";
            $inhandle = *EDIIN;
            $bisinfile = 1;
        }
        binmode($inhandle);

        (my $eos = $self->{ST}) =~ s/^\\/0/;
        local $/ = pack("C*", oct($eos));

        # Looping per-segment for processing
        while (<$inhandle>)
        {
            if (!$st_check) { $st_check = 1 if m/$self->{ST}/; }
            if (!$des_check) { $des_check = 1 if m/$self->{DES}/; }

            chomp;
            print {$outhandle} $self->_proc_segment($_);
        }
        # This is done to close any open loops
        # XXX Is there a better way to "run on more time"?
        print {$outhandle} $self->_proc_segment('');
    }
    print {$outhandle} '</ascx:message>';

    (close($inhandle) || croak "Cannot close output file \"$out\": $!") if $bisinfile;
    (close($outhandle)|| croak "Cannot close input file \"$in\": $!") if $bisoutfile;

    croak "EDI Parsing Error:  Segment Terminator \"$self->{ST}\" not found" unless $st_check;
    croak "EDI Parsing Error:  Data Element Seperator \"$self->{DES}\" not found" unless $des_check;

    return 1;
}

=item string = $obj->convertdata($input)


This method will transform an EDI data stream, returning wellformed XML.

    my $xmlrpc = new XML::ASCX12();
    my $xml = $xmlrpc->convertdata($binary_edi_data);


=cut
sub convertdata
{
    my ($self, $in) = @_;

    croak "EDI Parsing Error:  Segment Terminator \"$self->{ST}\" not found" unless ($in =~ m/$self->{ST}/);
    croak "EDI Parsing Error:  Data Element Seperator \"$self->{DES}\" not found" unless ($in =~ m/$self->{DES}/);

    my $out = $XML::ASCX12::_XMLHEAD;
    (my $eos = $self->{ST}) =~ s/^\\/0/;
    my @data = split(pack("C*", oct($eos)), $in);
    foreach(@data)
    {
        $out .= $self->_proc_segment($_);
    }
    $out .= $self->_proc_segment('');

   return $out;
}

=item string = XMLENC($string)


Static public method used to encode and return data suitable for ASCII XML CDATA

    $xml_ready_string = XML::ASCX12::XMLENC($raw_data);

=cut
sub XMLENC
{
    my $str = $_[0];
    if ($str)
    {
      $str =~ s/([&<>"])/$_XMLREP{$1}/ge;    # relace any &<>" characters
      $str =~ s/[\x80-\xff]//ge;             # get rid on any non-ASCII characters
      $str =~ s/[\x01-\x1f]//ge;             # get rid on any non-ASCII characters
    }
    return $str;
}

=back

=head2 Private Methods

=over 4

=item string = _proc_segment($segment_data);


This is an internal private method that processes a segment. It is called by
C<_proc_transaction()> while looping per-segment.

=cut
sub _proc_segment
{
    my ($self, $segment) = @_;
    $segment =~ s/\n//g;
    if ($segment =~ m/[0-9A-Za-z]*/)
    {   
        my ($segcode, @elements) = split(/$self->{DES}/, $segment);
        if ($segcode and $segcode eq "ST")
        {
            $self->_unload_catalog();
            $self->load_catalog($elements[0]);
        }

        # check to see if we need to close a loop
        my $curloop = $XML::ASCX12::Segments::SEGMENTS->{$segcode}[3] if $segcode;
        my $xml = '';
        if (my $tmp = $self->_closeloop($curloop, $self->{lastloop}, $segcode)) { $xml .= $tmp; }
        if (@elements)
        {
            # check to see if we need to open a loop
            if (my $tmp = $self->_openloop($curloop, $self->{lastloop})) { $xml .= $tmp; }

            # now the standard segment (and elements)
            $xml .= '<segm code="'.XML::ASCX12::XMLENC($segcode).'"';
            $xml .= ' desc="'.XML::ASCX12::XMLENC($XML::ASCX12::Segments::SEGMENTS->{$segcode}[0]).'"' if $XML::ASCX12::Segments::SEGMENTS->{$segcode};
            $xml .= '>';
            
            # make our elements
            $xml .= $self->_proc_element($segcode, @elements);
            
            # close the segment
            $xml .= '</segm>';

            # keep track
            $self->{lastloop} = $curloop;
        }
        return $xml;
    }
}

=item string = _proc_element($segment_code, @elements)


This is a private method called by C<_proc_segment()>.  Each segment consists of
elements, this is where they are processed.

=cut
sub _proc_element
{
    my ($self, $segcode, @elements) = @_;
    my $i = 1;
    my $xml = '';
    foreach (@elements)
    {
        if ($_ =~ /[0-9A-Za-z]/)
        {
            my $elename;
            $elename = $segcode.$i if $i >= 10;
            $elename = $segcode.'0'.$i if $i < 10;
            $xml .= '<elem code="'.XML::ASCX12::XMLENC($elename).'"';
            $xml .= ' desc="'.XML::ASCX12::XMLENC($XML::ASCX12::Segments::ELEMENTS->{$elename}[0]).'"' if $XML::ASCX12::Segments::ELEMENTS->{$elename};
            $xml .= '>'.XML::ASCX12::XMLENC($_).'</elem>';
        }
        $i++;
    }
    return $xml;
}


=item string = _openloop($loop_to_open, $last_opened_loop)


This is an internal private method.  It will either open a loop if we can
or return nothing.

=cut
sub _openloop
{
    my ($self, $newloop, $lastloop) = @_;
    if (XML::ASCX12::_CANHAVE($lastloop, $newloop))
    {
        push (@_LOOPS, $newloop);
        return '<loop:'.XML::ASCX12::XMLENC($newloop).'>';
    }
    return;
}

=item void = _closeloop($loop_to_close, $last_opened_loop, $current_segment, $trigger)


This routine is a private method.  It will recurse to close any open loops.

=cut
sub _closeloop
{
    my ($self, $newloop, $lastloop, $currentseg, $once) = @_;
    $once = 0 unless $once;
    my $xml;
    # Case when there are two consecutive loops
    if ($newloop and $lastloop and $currentseg eq $lastloop and ($currentseg ne ""))
    {
        $xml = $self->_execclose($lastloop);
        return $xml;
    }
    # "Standard Case"
    elsif (XML::ASCX12::_CANHAVE($newloop, $lastloop))
    {
        $xml = $self->_execclose($lastloop);
        return $xml;
    }
    # Recusrively close loops
    else
    {
        my @parent_loops_to_close = ();
        if (@_LOOPS)
        {
            foreach my $testloop (reverse @_LOOPS) #Close in reverse order
            {
                # found a loop, see which ones we ough to close
                if ($testloop eq $newloop)
                {
                    if (@parent_loops_to_close)
                    {
                        foreach my $closeme (@parent_loops_to_close)
                        {
                            $xml .= $self->_execclose($closeme) if $closeme;
                        }
                        # See if the current loop ought to be closed
                        if ($once != 1)
                        {
                            if (my $tmp = $self->_closeloop($newloop, $self->{lastloop}, $currentseg, 1))
                            {
                                $xml .= $tmp;
                            }
                        }
                        return $xml;
                    }
                }
                # Push into the loops to close
                else
                {
                    if ($testloop) { push (@parent_loops_to_close, $testloop); }
                }
            }
        }
    }
    return;
}

=item string = _execclose($loop_to_close)


Private internal method to actually return the XML that signifies a closed
loop.  It is called by C<_closeloop()>.

=cut
sub _execclose
{
    my ($self, $loop) = @_;
    return unless $loop;
    if ($loop =~ /[A-Za-z0-9]*/)
    {
        pop @_LOOPS;
        $self->{lastloop} = $_LOOPS[-1];
        return '</loop:'.XML::ASCX12::XMLENC($loop).'>' if XML::ASCX12::XMLENC($loop);
    }
}

=item void = _unload_catalog()


Private method that clears out catalog data and loads standard ASCX12 structure.

=cut
sub _unload_catalog
{
    my $self = shift;
    $XML::ASCX12::Catalogs::LOOPNEST = ();
    $self->load_catalog(0);
}

=item boolean = _CANHAVE($parent_loop, $child_loop)


This is a private static method.  It uses the rules in the L<XML::ASCX12::Catalogs|XML::ASCX12::Catalogs>
to determine if a parent is allowed to have the child loop. Returns C<0> or C<1>.

=cut

sub _CANHAVE
{
    my ($parent, $child) = @_;
    if (!$parent) { return 1; } # root-level can have anything
    return 0 unless $child;
    foreach (@{$XML::ASCX12::Catalogs::LOOPNEST->{$parent}}) { if ($_ eq $child) { return 1; } }
    return 0;
}

=back

=head1 TODO

Here are some things that would make this module even better.  They are in no particular order:

=over 4

=item * Error Handling

Maybe throw in an error object to keep track of things

=item * Encoding Support

Anyone that could review to make sure we are using the correct encodings
We basically read in the EDI file in binary and use the ASCII HEX-equivalent for the
separators.  Many EDI-producing systems use EBCDIC and not UTF-8 so be careful when
specifying the values.

=item * B<Live> Transaction Set (Catalog) Library

Make a live repository of transaction set data (catalogs).  I'd really like use XML to describe
each catalog and import them to local dbm files or tied hashes during install and via an update
script.  This project will be driven if there is adaquate demand.

According to the ASC X12 website (L<http://www.x12.org>), there are 315 transaction sets.  This module has 3, so
there are 312 that could be added.

=item * XML Documentation

Create a DTD and maybe even an XML Schema for the XML output.  There ought to be better
documentation here.

=back


=head1 AUTHORS

Brian Kaney <F<brian@vermonster.com>>, Jay Powers <F<jpowers@cpan.org>>

L<http://www.vermonster.com/>

Copyright (c) 2004 Vermonster LLC.  All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

Basically you may use this library in commercial or non-commercial applications.
However, If you make any changes directly to any files in this library, you are
obligated to submit your modifications back to the authors and/or copyright holder.
If the modification is suitable, it will be added to the library and released to
the back to public.  This way we can all benefit from each other's hard work!

If you have any questions, comments or suggestions please contact the author.

=head1 SEE ALSO

L<Carp>, L<XML::ASCX12::Catalogs> and L<XML::ASCX12::Segments>

=cut
1;
