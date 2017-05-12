package Video::CPL::MXML;

use warnings;
use strict;

=head1 NAME

Video::CPL::MXML

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';


=head1 SYNOPSIS

Holding object for MXML objects.

=head1 SUBROUTINES/METHODS

=cut

my @FIELDS = qw(pauseOnOverlay xmlns:mx width height);

=head2 new(%parms)

=cut

sub new {
    #given hash with parameters.
    #fieldList is either an array of MXMLField objects or a single one.
    my $pkg = shift;
    my %parms = @_;
    my $ret = {};
    bless $ret,$pkg;

    foreach my $x (@FIELDS){
	$ret->{$x} = $parms{$x} if defined $parms{$x};
    }
    #if (defined $x->{fieldList}){
    #    if (isa($x->{fieldList},'ARRAY')){
#	} else {
#	}
#    }
    foreach my $x (keys %parms){
        confess("Parameter ('$x') given to Video::CPL::MXML::new, but not understood\n") if !defined $ret->{$x};
    }

    return $ret;
}

sub fromxml {
    my $parent = shift;
    my $name = shift;
    my $s = shift;
    my %s = %{$s};
    my %p;
    foreach my $k (@FIELDS){
        $p{$k} = $s{$k} if defined($s{$k});
    }
    #don't fully understand how this will show up in XML
    #foreach (mxfields){
    #    $f = Video::CPL::MXMLField::fromxml();
    #    push @f;
    #}
    #$p{fieldList} = \@f;
    return new Video::CPL::MXML(%p);
} 

      #<mxmlInCPL pauseOnOverlay="true">
      #  <mx:MXML xmlns:mx="http://www.adobe.com/2006/mxml">
      #    <mx:Canvas width="720" height="508">
sub xmlo {
    my $obj = shift;
    my $xo = shift;
    my %p;
    $p{pauseOnOverlay} = $obj->{pauseOnOverlay} if defined $obj->{pauseOnOverlay};
    $xo->startTag("mxmlInCPL",%p);
    %p = undef;
    $p{"xmlns:mx"} = $obj->{"xmlns:mx"} if defined $obj->{"xmlns:mx"};
    $xo->startTag("mx:MXML",%p);
    %p = undef;
    $p{width} = $obj->{width} if defined $obj->{width};
    $p{height} = $obj->{height} if defined $obj->{height};
    if ($obj->{fieldList}){
	foreach my $c (@{$obj->{fieldList}}){
	    $c->xmlo($xo);
	}
    }
    $xo->startTag("mx:Canvas",%p);
    $xo->endTag("mx:Canvas");
    $xo->endTag("mx:MXML");
    $xo->endTag("mxmlInCPL");
}

=head2 xml()

=cut

sub xml {
    my $obj = shift;
    my $a = "";
    my $xo = new XML::Writer(OUTPUT=>\$a);
    $obj->xmlo($xo);
    $xo->end;
    return $a;
}

#can only have
#    Canvas,Image,Text,TextInput,Radiobutton fields. 
#    in linear non-nested order. Suggest they simply be routines within here.
=head1 AUTHOR

Carl Rosenberg, C<< <perl at coincident.tv> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-video-cpl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Video-CPL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Video::CPL::MXML


=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Coincident TV

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
