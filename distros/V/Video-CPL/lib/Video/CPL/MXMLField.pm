package Video::CPL::MXMLField;

use warnings;
use strict;
use XML::Writer;
use Carp;

=head1 NAME

Video::CPL::MXMLField - Video::CPL::MXMLField object.

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';
my @FIELDS = qw(click color data dataProfider editable fontSize fontWidth height horizontalCenter horizontalScrollPolicy id item label leading scaleContent source source text verticalCenter verticalScrollPolicy width x y);
my @KINDS = qw(mx:CheckBox mx:ComboBox mx:RadioButton mx:Button mx:Image mx:Label mx:TextInput mx:Text);

=head1 SYNOPSIS

    This is mostly an internal package for CPL.pm. You can use it directly, but it is recommended to use the cue point creation routines in CPL.pm.

    use Video::CPL::MXMLField;
    my $foo = Video::CPL::MXMLField->new();

=head1 METHODS/METHODS

=cut

=head2 new($kind,%parms)

    Create a new Video::CPL::MXMLField object.

=cut 

sub new {
    my $pkg = shift;
    my $kind = shift;
    my %parms = @_;
    my $ret = {};
    bless $ret,$pkg;

    $ret->{kind} = $kind;
    foreach my $x (@FIELDS){
        if (defined($parms{$x})){
	    $ret->{$x} = $parms{$x};
	}
    }
    #check
    foreach my $x (keys %parms){
        confess("Parameter ('$x') value ($parms{$x}) given to Video::CPL::MXMLField::new, but not understood\n") if defined($parms{$x}) && !defined($ret->{$x});
    }
    return $ret;
}

=head2 xmlo
  
    Given an XML::Writer object, add the xml information for this Layout.

=cut

sub xmlo {
    my $obj = shift;
    my $xo = shift;
    my $kind = $obj->{kind};
    my %p;
    foreach my $x (@FIELDS){
        $p{$x} = $obj->{$x} if defined $obj->{$x};
    }
    $xo->emptyTag($kind,%p);
}

=head2 xml()

    Return the xml format of a Video::CPL::MXMLField object.

=cut

sub xml {
    my $obj = shift;
    my $a;
    my $xo = new XML::Writer(OUTPUT=>\$a);
    $obj->xmlo($xo);
    $xo->end();
    return $a;
}

=head2 fromxml(\%hash)

    Return a Video::CPL::MXMLField object given that part of the parse tree from XML::Simple::XMLin.

=cut

sub fromxml {
    my $s = shift;
    my %s = %{$s};
    my %parms;
    foreach my $q (@FIELDS){
        $parms{$q} = $s{$q} if defined($s{$q});
    }
    #how do we get our "kind"?
    return new Video::CPL::MXMLField(%parms);
}


=head1 AUTHOR

Carl Rosenberg, C<< <perl at coincident.tv> >>

=head1 BUGS

Please report any bugs or feature requests to Coincident TV.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Video::CPL::MXMLField

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

1; # End of Video::CPL::MXMLField
