# Copyrights 2007-2014 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

use warnings;
use strict;

package XML::Compile::Dumper;
our $VERSION = '0.14';


use Log::Report 'xml-compile', syntax => 'SHORT';
use Data::Dump::Streamer;
use POSIX     qw/asctime/;
use IO::File;

# I have no idea why the next is needed, but without it, the
# tests are failing.
use XML::Compile::Schema;


sub new(@)
{   my ($class, %opts) = @_;
    (bless {}, $class)->init(\%opts);
}

sub init($)
{   my ($self, $opts) = @_;

    my $fh      = $opts->{filehandle};
    unless($fh)
    {   my $fn  = $opts->{filename}
            or error __x"either filename or filehandle required";

        $fh     = IO::File->new($fn, '>:utf8')
            or fault __x"cannot write to {filename}", filename => $fn;
    }
    $self->{XCD_fh} = $fh;

    my $package = $opts->{package}
        or error __x"package name required";

    $self->header($fh, $package);
    $self;
}


sub close()
{   my $self = shift;
    my $fh = $self->file or return 1;

    $self->footer($fh);
    delete $self->{XCD_fh};
    $fh->close;
}

sub DESTROY()
{   my $self = shift;
    $self->close;
}


sub file() {shift->{XCD_fh}}


sub header($$)
{   my ($self, $fh, $package) = @_;
    my $date = asctime localtime;
    $date =~ s/\n.*//;

    my $xc_version = $XML::Compile::VERSION || '(devel)';

    $fh->print( <<__HEADER );
#crash
# This module has been generated using
#    XML::Compile         $xc_version
#    Data::Dump::Streamer $Data::Dump::Streamer::VERSION
# Created with a script
#    named $0
#    on    $date

use warnings;
no  warnings 'once';
no  strict;   # sorry

package $package;
use base 'Exporter';

use XML::LibXML   ();
use Log::Report;
use Data::Dump::Streamer ':undump';

our \@EXPORT;

 # We will need these modules
 { package XML::Compile::Translate::Reader;
   use Log::Report;

 ; package XML::Compile::Translate::Writer;
   use Log::Report;

 ; package XML::Compile::Transport::SOAPHTTP;
   use Log::Report;

 ; package XML::Compile::Transport;
   use Log::Report;
 }

__HEADER
}


sub freeze(@)
{   my $self = shift;

    error "freeze needs PAIRS or a HASH"
        if (@_==1 && ref $_[0] ne 'HASH') || @_ % 2;

    error "freeze can only be called once"
        if $self->{XCD_freeze}++;

    my (@names, @data);
    if(@_==1)   # Hash
    {   my $h  = shift;
        @names = keys %$h;
        @data  = values %$h;
    }
    else        # Pairs
    {   while(@_)
        {   push @names, shift;
            push @data, shift;
        }
    }

    my $fh = $self->file;
    my $export = join "\n    ", sort @names;
    $fh->print("push \@EXPORT, qw/\n    $export/;\n\n");

    Data::Dump::Streamer->new->To($fh)->Data(@data)->Out;

    for(my $i = 0; $i < @names; $i++)
    {   ref $data[$i] eq 'CODE'
            or error __x"value with '{label}' is not a code reference"
                   , label => $names[$i];

        my $code  = '$CODE'.($i+1);
        $fh->print("*${names[$i]} = $code;\n");
    }
}


sub footer($)
{   my ($self, $fh) = @_;
    $fh->print( "\n1;\n" );
}

1;
