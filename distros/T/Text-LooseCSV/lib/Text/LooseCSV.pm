#
# $Id: LooseCSV.pm,v 1.6 2007/11/21 04:23:08 rsandberg Exp $
#

package Text::LooseCSV;

$VERSION = 1.6;

use strict;


=head1 NAME

Text::LooseCSV - Highly forgiving variable length record text parser; compare to MS Excel


=head1 SYNOPSIS

 use Text::LooseCSV;
 use IO::File;

 $fh = new IO::File $fname;
 $f = new Text::LooseCSV($fh);

 # Some optional settings
 $f->word_delimiter("\t");
 $f->line_delimiter("\n");
 $f->no_quotes(1);

 # Parse/split a line
 while ($rec = $f->next_record())
 {
     if ($rec == -1)
     {
         warn("corrupt rec: ", $f->cur_line);
         next;
     }

     # process $rec as arrayref
     ...
 }


 # Or, (vice-versa) create a variable-length record file
 $line = $f->form_record( [ 'Debbie Does Dallas','30.00','VHS','Classic' ] );

=head1 DESCRIPTION

Why another variable-length text record parser? I've had the privilege to parse some of the gnarliest data ever seen
and everything else I tried on CPAN choked (at the time I wrote this module). This module has
been munching on millions of records of the filthiest data imaginable at several production
sites so I thought I'd contribute.

This module follows somewhat loose rules (compare to MS Excel) and will handle embedded newlines, etc.
It is capable of handling large files and processes data in line-chunks. If MAX_LINEBUF is
reached, however, it will mark the current record as corrupt, return -1 and start over
again at the very next line. This will (of course) process tab-delimited data or whatever value
you set for C<word_delimiter>.

Methods are called in perl OO fashion.


WARNING this module messes with $/
C<line_delimiter> sets $/ and is always called during construction. Don't change $/ during
program execution!


=head1 METHOD DETAILS

=over 4


=item C<new (constructor)>

 $f = new Text::LooseCSV($fh);

Create a new Text::LooseCSV object for all your variable-length record needs with an optional
file handle, $fh (e.g. IO::File). Set properties using the accessor methods as needed.

If $fh is not given, you can use input_file() or input_text().

Returns a blessed Text::LooseCSV object.

=cut
sub new
{
    my ($caller,$fh) = @_;

    my $class = ref($caller) || $caller;
    
    my $self = {
        QUOTE_ESCAPE => '"',
        WORD_DELIMITER => ',',
        MAX_LINEBUF => 1000,
        RECADD => 0,
        NO_QUOTES => 0,
        ALWAYS_QUOTE => 0,
        WORD_LINE_DELIMITER_ESCAPE => undef,
        linebuf => [],
        fh => $fh,
    };
    line_delimiter($self,"\r\n");
    return bless($self,$class);
}
 
=pod

=item C<line_delimiter>

 $current_value = $f->line_delimiter("\n");

Get/set LINE_DELIMITER.
LINE_DELIMITER defines the line boundary chunks that are read into the
buffer and loosely defines the record delimiter.

For parsing, this does not strictly affect the record/field structures as fields may
have embedded newlines, etc. However, this DOES need to be set correctly.

Default = "\r\n" NOTE! The default is Windows format.

Always returns the current set value.

WARNING! line_delimiter() also sets $/ and is always called during construction.
Due to buffering, don't change $/ or LINE_DELIMITER during program execution!


=cut
sub line_delimiter
{
    my ($self,$newval) = @_;
    if (defined($newval))
    {
        return $self->{LINE_DELIMITER} = $/ = $newval;
    }
    return $self->{LINE_DELIMITER};
}

=pod

=item C<word_delimiter>

 $current_value = $f->word_delimiter("\t");

Get/set WORD_DELIMITER.
WORD_DELIMITER defines the field boundaries within the record.
WORD_DELIMITER may only be set to a single character, otherwise a warning
is generated and the new value is ignored.

Default = "," NOTE! Single character only.

Always returns the current set value.

WARNING! Due to buffering, don't change WORD_DELIMITER during program execution!


=cut
sub word_delimiter
{
    my ($self,$newval) = @_;
    if (defined($newval))
    {
        if (length($newval) != 1)
        {
            warn("WORD_DELIMITER may only be a single character, ignoring set value to [$newval]");
        }
        else
        {
            $self->{WORD_DELIMITER} = $newval;
        }
    }
    return $self->{WORD_DELIMITER};
}

=pod

=item C<quote_escape>

 $current_value = $f->quote_escape("\\");

Get/set QUOTE_ESCAPE.
For data that have fields enclosed in quotes, QUOTE_ESCAPE defines the escape character for '"'
e.g. for the default QUOTE_ESCAPE = '"', to embed a quote character in a field (MS Excel style):

"field1 ""junk"" and more, etc"

Default = '"'

Always returns the current set value.

WARNING! Due to buffering, don't change QUOTE_ESCAPE during program execution!


=cut
sub quote_escape
{
    my ($self,$newval) = @_;
    if (defined($newval))
    {
        return $self->{QUOTE_ESCAPE} = $newval;
    }
    return $self->{QUOTE_ESCAPE};
}

=pod

=item C<word_line_delimiter_escape>

 $current_value = $f->word_line_delimiter_escape("\\");

Get/set WORD_LINE_DELIMITER_ESCAPE.
Sometimes you'll encounter (or want to create) files where WORD_DELIMITER and/or
LINE_DELIMITER's are embedded in the data and the creator had the notion (courtesy?)
to escape those characters when they appeared within a field with say, '\'. If so,
you'll want to set WORD_LINE_DELIMITER_ESCAPE to that character.

If WORD_LINE_DELIMITER_ESCAPE is specified, this character must be escaped by the
same character to be included in a field.
e.g. for a tab-delimited file where WORD_LINE_DELIMITER_ESCAPE => '\'
follows is a sample record with an embedded newline:

S<meE<lt>TABE<gt>youE<lt>TABE<gt>this is a single field that contains an escaped line terminator\
an escaped tab\E<lt>TABE<gt> and an actual \\E<lt>TABE<gt>this is the next field...>

Do not use WORD_LINE_DELIMITER_ESCAPE for data with fields that are enclosed in
quotes.

WORD_LINE_DELIMITER_ESCAPE cannot be '_', will otherwise be silently ignored.

Default = undef()

Always returns the current set value.

WARNING! Due to buffering, don't change WORD_LINE_DELIMITER_ESCAPE during program execution!


=cut
sub word_line_delimiter_escape
{
    my ($self,$newval) = @_;
    if (defined($newval) && $newval ne '_')
    {
        return $self->{WORD_LINE_DELIMITER_ESCAPE} = $newval;
    }
    return $self->{WORD_LINE_DELIMITER_ESCAPE};
}

=pod

=item C<no_quotes>

 $current_value = $f->no_quotes($bool);

Get/set NO_QUOTES.
Instruct C<form_record> to strip WORD_DELIMITER and LINE_DELIMITER from fields within the record
and never to enclose fields in quotes.

By default, if, during record formation a WORD_DELIMITER or LINE_DELIMITER is encountered in a field
value, that field will be enclosed in quotes. However, if NO_QUOTES = 1 any occurence of
WORD_DELIMITER or LINE_DELIMITER will be stripped from the value and no enclosing quotes will be used.

If ALWAYS_QUOTE = 1 this attribute is ignored and quotes will always be used.

Only affects C<form_record>.

Default = 0 (by default records created with C<form_record> may have fields enclosed in quotes)

Always returns the current set value.


=cut
sub no_quotes
{
    my ($self,$newval) = @_;
    if (defined($newval))
    {
        return $self->{NO_QUOTES} = $newval;
    }
    return $self->{NO_QUOTES};
}

=pod

=item C<always_quote>

 $current_value = $f->always_quote($bool);

Get/set ALWAYS_QUOTE.
Always enclose fields in quotes when using C<form_record>. Only affects C<form_record>.
Takes precedence over C<no_quotes>.

Default = 0

Always returns the current set value.


=cut
sub always_quote
{
    my ($self,$newval) = @_;
    if (defined($newval))
    {
        return $self->{ALWAYS_QUOTE} = $newval;
    }
    return $self->{ALWAYS_QUOTE};
}

=pod

=item C<max_linebuf>

 $current_value = $f->max_linebuf($integer);

Get/set MAX_LINEBUF.
A file is read in line chunks and because newlines are allowed to be embedded in the field
values, many lines may be read and buffered before the whole record is determined.
MAX_LINEBUF sets the maximum number of lines that are used to parse a record before
the first line of that block is determined junk and -1 is returned from C<next_record>.
Processing then continues at the very next line in the file.

Default = 1000

Always returns the current set value.


=cut
sub max_linebuf
{
    my ($self,$newval) = @_;
    if (defined($newval))
    {
        return $self->{MAX_LINEBUF} = $newval;
    }
    return $self->{MAX_LINEBUF};
}

=pod

=item C<recadd>

 $current_value = $f->recadd($bool);

Get/set RECADD.
If set to true, LINE_DELIMITER (actually $/) will be added to the end of the value returned from
C<form_record>.
Only affects C<form_record>

Default = 0

Always returns the current set value.


=cut
sub recadd
{
    my ($self,$newval) = @_;
    if (defined($newval))
    {
        return $self->{RECADD} = $newval;
    }
    return $self->{RECADD};
}

=pod

=item C<input_file>

 $current_value = $f->input_file($fh);

Get/set the filehandle of the file to be parsed (e.g. IO::File object).
May also be set in the constructor.

Default = undef

Always returns the current set value.


=cut
sub input_file
{
    my ($self,$fh) = @_;
    if (defined($fh))
    {
        return $self->{fh} = $fh;
    }
    return $self->{fh};
}

=pod

=item C<input_text>

 $textbuf = $f->input_text($text_blob);

Alternative to C<input_file>, feed the entire text of a file or scalar to $f at once. Accepts scalar or scalar reference.

Returns the internal textbuf attr.


=cut
sub input_text
{
    my $self = shift;
    my $recdel = quotemeta($/);
    $self->{textbuf} = [ split(/$recdel/,(ref($_[0]) ? ${$_[0]} : $_[0])) ];
}

=pod

=item C<next_record>

 $rec = $f->next_record();

Parses and returns an arrayref of the fields of the next record.

return '' if EOF is encountered

return -1 if the next record is corrupted (incomplete, etc) or if MAX_LINEBUF is reached


WARNING! Due to buffering, don't change $/ or LINE_DELIMITER during program execution!


=cut
sub next_record
{
    my ($self) = @_;

    my @fields;
    my $linebuf_pos = -1;

    my $line = $self->next_line(\$linebuf_pos);
    return -1 if ref($line) || !defined($line);
    return $line unless $line;

    my $qe = quotemeta($self->{QUOTE_ESCAPE});
    my $wd = quotemeta($self->{WORD_DELIMITER});

    my $lde_orig = $self->{WORD_LINE_DELIMITER_ESCAPE};
    my $lde = defined($lde_orig) ? quotemeta($lde_orig) : undef;
    
    my $val;
    my $rec_err = 0;

    # If a word contains ["$qe$wd$line_delimiter] then it must be surrounded in quotes or preceded by WORD_LINE_DELIMITER_ESCAPE
    while (length($line))
    {
        my $match;
        my $val = '';
        my $delim = '';

        if (defined($lde))
        {
            $match = scalar($line =~ m/^
                      ((?:$lde$wd|[^$wd])*?)             # an unquoted text
                      (?:\Z|($wd))                       # plus EOL, or delimiter
                      ([\000-\377]*)                     # the rest
                      /xs);                              # extended layout

            if ($match)
            {
                $val = $1;
                $delim = $2;
                $line = $3;
            }
        }
        else
        {

            $match = scalar($line =~ m/^(?:(?:"        # a quote
                      ((?:$qe"|[^"])*)                 # and quoted text " is escaped by $qe
                      ")                               # followed by the same quote
                      |                                # --OR--
                      ([^$wd"]*?))                     # an unquoted text
                      (?:\Z|($wd))                     # plus EOL, or delimiter
                      ([\000-\377]*)                   # the rest
                      /xs);                            # extended layout

            if ($match)
            {
                $val = defined($1) ? $1 : $2;
                $delim = $3;
                $line = $4;
            }
        }

        my $ldedef = $lde;
        $ldedef = '' unless defined($lde);

        if ($match)
        {
            $val =~ s/$qe"/"/g;
            $val =~ s/$ldedef$wd/$self->{WORD_DELIMITER}/g;
            $val =~ s/__WORDLINETERMINATORESCAPE__/$lde_orig/g if defined($lde);
            push(@fields,$val);
            push(@fields,'') if (defined($delim) && length($delim)) && !length($line);
        }
        else
        {
            my $rs = $self->{le};
            my $nl = $self->next_line(\$linebuf_pos);
            return -1 if ref($nl);
            length("${nl}${rs}") || ($rec_err++,last);
            $line .= $rs . $nl;
        }
    }

    if ($rec_err)
    {
        $linebuf_pos = 0;
    }

    $self->{cur_line} = join('',@{$self->{linebuf}}[0..$linebuf_pos]);

    if ($#{$self->{linebuf}} >= (++$linebuf_pos))
    {
        @{$self->{linebuf}} = @{$self->{linebuf}}[$linebuf_pos..$#{$self->{linebuf}}];
    }
    else
    {
        $self->{linebuf} = [];
    }
    return -1 if $rec_err;
    return \@fields;
}

=pod

=item C<cur_line>

 $raw = $f->cur_line();

Returns the raw text line currently being processed (including a line terminator if originally present).


=cut
sub cur_line
{
    my $self = shift;
    return $self->{cur_line};
}



sub next_line
{
    my ($self,$linebuf_pos) = @_;

    $self->{le} = '';

    (warn("MAX_LINEBUF limit reached"),return undef) if ($$linebuf_pos+1) >= $self->{MAX_LINEBUF};

    my $fh = $self->{fh};

    my $lde_orig = $self->{WORD_LINE_DELIMITER_ESCAPE};
    my $lde = defined($lde_orig) ? quotemeta($lde_orig) : undef;

    unless ($$linebuf_pos < $#{$self->{linebuf}})
    {
        my $l;
        if ($fh)
        {
            no strict;
            $l = <$fh>;
            use strict;

            if (defined($lde))
            {
                (warn("Incompatible string in line: $l"),return {}) if $l =~ /__WORDLINETERMINATORESCAPE__/;
                $l =~ s/$lde{2}/__WORDLINETERMINATORESCAPE__/g;
                my $nl = $l;
                $l = '';
                while ($nl =~ s/$lde(\r?)$/$1/)
                {
                    $l .= $nl;
                    no strict;
                    $nl = <$fh>;
                    use strict;
                    (warn("Incompatible string in line: $nl"),return {}) if $nl =~ /__WORDLINETERMINATORESCAPE__/;
                    $nl =~ s/$lde{2}/__WORDLINETERMINATORESCAPE__/g;
                }
                $l .= $nl;
            }
        }
        else
        {
            $l = shift(@{$self->{textbuf}});
            $l .= $/ if @{$self->{textbuf}};

            if (defined($lde))
            {
                (warn("Incompatible string in line: $l"),return {}) if $l =~ /__WORDLINETERMINATORESCAPE__/;
                $l =~ s/$lde{2}/__WORDLINETERMINATORESCAPE__/g;
                my $nl = $l;
                $l = '';
                while ($nl =~ s/$lde(\r?)$/$1/)
                {
                    $l .= $nl;

                    $nl = shift(@{$self->{textbuf}});
                    $nl .= $/ if @{$self->{textbuf}};

                    (warn("Incompatible string in line: $nl"),return {}) if $nl =~ /__WORDLINETERMINATORESCAPE__/;
                    $nl =~ s/$lde{2}/__WORDLINETERMINATORESCAPE__/g;
                }
                $l .= $nl;
            }
        }
        length($l) || return '';
        push(@{$self->{linebuf}},$l);
    }
    my $l = $self->{linebuf}[++$$linebuf_pos];

##at these next lines would suck if defined($lde) and the last character of the last record of the file was an escaped line-terminator
    $self->{le} = $/ if chomp($l);
    if (substr($l,-1) eq "\r")
    {
        $self->{le} = chop($l) . $self->{le};
    }
    if (substr($l,-1) eq $self->{WORD_DELIMITER} && !defined($lde))
    {
        $l .= '""';
    }
    return $l;
}

=pod

=item C<form_record>

 $line = $f->form_record($array_of_fields);

Returns a WORD_DELIMITED joined text scalar variable-length record of $array_of_fields. Also see C<recadd>.

$array_of_fields may be an array or arrayref.

=cut
sub form_record
{
    my $self = shift;
    my @rec = ();
    if (ref($_[0]))
    {
        @rec = @{$_[0]};
    }
    else
    {
        @rec = @_;
    }
    my $ret = '';

    my $wd = quotemeta($self->{WORD_DELIMITER});
    my $ld = quotemeta($self->{LINE_DELIMITER});
    my $lde_orig = $self->{WORD_LINE_DELIMITER_ESCAPE};
    my $lde = defined($lde_orig) ? quotemeta($lde_orig) : undef;

    foreach my $field (@rec)
    {
        if ($self->{ALWAYS_QUOTE} || (!defined($lde) && !$self->{NO_QUOTES} && $field =~ /(?:$wd)|(?:$ld)|\"/s))
        {
            $field =~ s/"/$self->{QUOTE_ESCAPE}"/gs;
            $field = qq["$field"];
        }
        elsif (defined($lde))
        {
            $field =~ s/((?:$wd)|(?:$ld)|(?:$lde))/$lde_orig$1/gs;
        }
        elsif ($self->{NO_QUOTES})
        {
            $field =~ s/(?:$wd)|(?:$ld)//gs;
        }
        $ret .= "$field$self->{WORD_DELIMITER}";
    }
    chop($ret);
    $ret .= $/ if $self->{RECADD};
    return $ret;
}

=pod

=back

=head1 BUGS

None as yet. This code has been used at several production sites before publishing to the public.


=head1 AUTHORS

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>


=head1 COPYRIGHT

Copyright (C) 2001-2007 Reed Sandberg
All rights reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.


=cut

1;
