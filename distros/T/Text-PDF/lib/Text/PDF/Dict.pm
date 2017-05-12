package Text::PDF::Dict;

use strict;
use vars qw(@ISA $mincache $tempbase $cr);
# no warnings qw(uninitialized);

use Text::PDF::Objind;
@ISA = qw(Text::PDF::Objind);

$cr = '(?:\015|\012|(?:\015\012))';

use Text::PDF::Filter;

BEGIN
{
    my $temp_dir = -d '/tmp' ? '/tmp' : $ENV{TMP} || $ENV{TEMP};
    $tempbase = sprintf("%s/%d-%d-0000", $temp_dir, $$, time());
    $mincache = 32768;
}

=head1 NAME

Text::PDF::Dict - PDF Dictionaries and Streams. Inherits from L<PDF::Objind>

=head1 INSTANCE VARIABLES

There are various special instance variables which are used to look after,
particularly, streams. Each begins with a space:

=over

=item stream

Holds the stream contents for output

=item streamfile

Holds the stream contents in an external file rather than in memory. This is
not the same as a PDF file stream. The data is stored in its unfiltered form.

=item streamloc

If both ' stream' and ' streamfile' are empty, this indicates where in the
source PDF the stream starts.

=back

=head1 METHODS

=cut

sub new
{
    my ($class, @opts) = @_;
    my ($self);

    $class = ref $class if ref $class;
    $self = $class->SUPER::new(@_);
    $self->{' realised'} = 1;
    return $self;
}
    

=head2 $d->outobjdeep($fh)

Outputs the contents of the dictionary to a PDF file. This is a recursive call.

It also outputs a stream if the dictionary has a stream element. If this occurs
then this method will calculate the length of the stream and insert it into the
stream's dictionary.

=cut

sub outobjdeep
{
    my ($self, $fh, $pdf, %opts) = @_;
    my ($key, $val, $f, @filts);
    my ($loc, $str, %specs, $len);

    if (defined $self->{' stream'} or defined $self->{' streamfile'} or defined $self->{' streamloc'})
    {
        if ($self->{'Filter'} || !defined $self->{' stream'})
        {
            $self->{'Length'} = Text::PDF::Number->new(0) unless (defined $self->{'Length'});
            $pdf->new_obj($self->{'Length'}) unless ($self->{'Length'}->is_obj($pdf));
#            $pdf->out_obj($self->{'Length'});
        }
        else
        {
            $self->{'Length'} = Text::PDF::Number->new(length($self->{' stream'}) + ($self->{' stream'} =~ m/$cr$/o ? 0 : 1));
        }
    }

    $fh->print("<<\n");
    foreach ('Type', 'Subtype')
    {
        $specs{$_} = 1;
        if (defined $self->{$_})
        {
            $fh->print("/$_ ");
            $self->{$_}->outobj($fh, $pdf, %opts);
            $fh->print("\n");
        }
    }
    foreach $key (sort {$a cmp $b} keys %{$self})
    {
        next if ($key =~ m/^[\s\-]/o || $specs{$key});
        $val = $self->{$key};
        next if ($val eq '');
        $key = Text::PDF::Name::string_to_name ($key, $pdf);
        $fh->print("/$key ");
        $val->outobj($fh, $pdf, %opts);
        $fh->print("\n");
    }
    $fh->print('>>');

#now handle the stream (if any)
    if (defined $self->{' streamloc'} && !defined $self->{' stream'})
    {                                   # read a stream if infile
        $loc = $fh->tell;
        $self->read_stream;
        $fh->seek($loc, 0);
    }

    if (!$self->{' nofilt'}
            && (defined $self->{' stream'} || defined $self->{' streamfile'})
            && defined $self->{'Filter'})
    {
        my ($hasflate) = -1;
        my ($temp, $i, $temp1, @filtlist);
        
        if (ref($self->{'Filter'}) eq 'Text::PDF::Name')
        { push(@filtlist, $self->{'Filter'}->val); }
        else
        {
            for ($i = 0; $i < scalar @{$self->{'Filter'}{' val'}}; $i++)
            { push (@filtlist, $self->{'Filter'}{' val'}[$i]->val); }
        }
        foreach $temp (@filtlist)
        {
            if ($temp eq 'LZWDecode')               # hack to get around LZW patent
            {
                if ($hasflate < -1)
                {
                    $hasflate = $i;
                    next;
                }
                $temp = 'FlateDecode';
                $self->{'Filter'}{' val'}[$i]{'val'} = $temp;      # !!!
            } elsif ($temp eq 'FlateDecode')
            { $hasflate = -2; }
            $temp1 = "Text::PDF::$temp";
            push (@filts, $temp1->new);
        }
        splice(@{$self->{'Filter'}{' val'}}, $hasflate, 1) if ($hasflate > -1);
    }

    if (defined $self->{' stream'})
    {
        $fh->print("\nstream\n");
        $loc = $fh->tell;
        $str = $self->{' stream'};
        unless ($self->{' nofilt'})
        {
            foreach $f (reverse @filts)
            { $str = $f->outfilt($str, 1); }
        }
        $fh->print($str);
        if (@filts > 0)
        {
            $len = $fh->tell - $loc + 1;
            if ($self->{'Length'}{'val'} != $len)
            {
                $self->{'Length'}{'val'} = $len;
                $pdf->out_obj($self->{'Length'}) if ($self->{'Length'}->is_obj($pdf));
            }
        }
        $fh->print("\n") unless ($str =~ m/$cr$/o);
        $fh->print("endstream");
#        $self->{'Length'}->outobjdeep($fh);
    } elsif (defined $self->{' streamfile'})
    {
        open(DICTFH, $self->{' streamfile'}) || die "Unable to open $self->{' streamfile'}";
        binmode DICTFH;
        $fh->print("\nstream\n");
        $loc = $fh->tell;
        while (read(DICTFH, $str, 4096))
        {
            unless ($self->{' nofilt'})
            {
                foreach $f (reverse @filts)
                { $str = $f->outfilt($str, 0); }
            }
            $fh->print($str);
        }
        close(DICTFH);
        unless ($self->{' nofilt'})
        {
            $str = '';
            foreach $f (reverse @filts)
            { $str = $f->outfilt($str, 1); }
            $fh->print($str);
        }
        
        $len = $fh->tell - $loc + 1;
        if ($self->{'Length'}{'val'} != $len)
        {
            $self->{'Length'}{'val'} = $len;
            $pdf->out_obj($self->{'Length'}) if ($self->{'Length'}->is_obj($pdf));
        }
        
        $fh->print("\n") unless ($str =~ m/$cr$/o);
        $fh->print("endstream\n");
#        $self->{'Length'}->outobjdeep($fh);
    }
}


=head2 $d->read_stream($force_memory)

Reads in a stream from a PDF file. If the stream is greater than
C<PDF::Dict::mincache> (defaults to 32768) bytes to be stored, then
the default action is to create a file for it somewhere and to use that
file as a data cache. If $force_memory is set, this caching will not
occur and the data will all be stored in the $self->{' stream'}
variable.

=cut

sub read_stream
{
    my ($self, $force_memory) = @_;
    my ($fh) = $self->{' streamsrc'};
    my (@filts, $f, $last, $i, $dat);
    my ($len) = $self->{'Length'}->val;

    $self->{' stream'} = '';

    if (defined $self->{'Filter'})
    {
        foreach $f ($self->{'Filter'}->elementsof)
        {
            my ($temp) = "Text::PDF::" . $f->val;
            push(@filts, $temp->new());
        }
    }

    $last = 0;
    if (defined $self->{' streamfile'})
    {
        unlink ($self->{' streamfile'});
        $self->{' streamfile'} = undef;
    }
    seek ($fh, $self->{' streamloc'}, 0);
    for ($i = 0; $i < $len; $i += 4096)
    {
        if ($i + 4096 > $len)
        {
            $last = 1;
            read($fh, $dat, $len - $i);
        }
        else
        { read($fh, $dat, 4096); }

        foreach $f (@filts)
        { $dat = $f->infilt($dat, $last); }
        if (!$force_memory && !defined $self->{' streamfile'} && ((length($self->{' stream'}) * 2) > $mincache))
        {
            open (DICTFH, ">$tempbase") || next;
            binmode DICTFH;
            $self->{' streamfile'} = $tempbase;
            $tempbase =~ s/-(\d+)$/"-" . ($1 + 1)/oe;        # prepare for next use
            print DICTFH $self->{' stream'};
            undef $self->{' stream'};
        }
        if (defined $self->{' streamfile'})
        { print DICTFH $dat; }
        else
        { $self->{' stream'} .= $dat; }
    }
    
    close DICTFH if (defined $self->{' streamfile'});
    $self->{' nofilt'} = 0;
    $self;
}
        
=head2 $d->val

Returns the dictionary, which is itself.

=cut

sub val
{ $_[0]; }


=head2 $d->copy($inpdf, $res, $unique, $outpdf, %opts)

Copies an object. See Text::PDF::Objind::Copy() for details

=cut

sub copy
{
    my ($self, $inpdf, $res, $unique, $outpdf, %opts) = @_;
    my ($k, $path);

    $res = $self->SUPER::copy($inpdf, $res, $unique, $outpdf, %opts);
    $path = delete $opts{'path'};
    foreach $k (keys %$self)
    {
        next if $self->dont_copy($k);
        next if defined $res->{$k};
        if (UNIVERSAL::can($self->{$k}, "is_obj"))
        {
            if (grep {"$path/$k" =~ m|$_|} @{$opts{'clip'}})
            { $res->{$k} = $self->{$k}; }
            else
            { $res->{$k} = $self->{$k}->realise->copy($inpdf, undef, $unique ? $unique + 1 : 0,
                        $outpdf, %opts, 'path' => "$path/$k"); }
        }
        else
        { $res->{$k} = $self->{$k}; }
    }
    $res;
}

1;