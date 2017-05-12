package Video::CPL::AnnotationList;

use warnings;
use strict;
use Carp;
use Data::Dumper;
use XML::Writer;

use Video::CPL::Annotation;

=head1 NAME

Video::CPL::AnnotationList - Manages a list of Annotation objects. Generally invoked by other Video::CPL modules.

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    Video::CPL::AnnotationList is normally called by Video::CPL.pm. If need be it can be 
    called directly to create or modify Video::CPL::AnnotationList objects.

=head1 METHODS

=cut

our @FIELDS = qw(target);

=head2 target([@targetarray])

    Accessor function to get or set the target array.

=cut

sub target { 
    my $obj = shift; 
    if (@_){
        my @a = @_;
	delete $obj->{target};
        foreach my $x (@a){
	    $obj->pusht($x);
	}
    }
    return () if !exists($obj->{target});
    return @{$obj->{target}};
}

=head2 new([target=>$targetarray])

    Create a new AnnotationList object.

=cut 

sub new {
    my $pkg = shift;
    my %parms = @_;
    my $ret = {};
    bless $ret,$pkg;

    foreach my $x (@FIELDS){
	$ret->{$x} = $parms{$x} if defined $parms{$x};
    }
    foreach my $x (keys %parms){
        confess("Parameter ('$x') given to Video::CPL::AnnotationList::new, but not understood\n") if !defined $ret->{$x};
    }

    return $ret;
}

=head2 pusht($target)

    Push a target onto the target array.

=cut

sub pusht {
    my $obj = shift;
    my $t = shift;
    if (defined $obj->{target}){
        push @{$obj->{target}},$t;
    } else {
        $obj->{target} = [$t];
    }
}

=head2 xmlo
  
    Given an XML::Writer object, add the xml information for this AnnotationList.

=cut

sub xmlo {
    my $obj = shift;
    my $xo = shift;
    my %p;
    foreach my $x (@FIELDS){
        next if $x eq "target";
        $p{$x} = $obj->{$x} if defined $obj->{$x};
    }
    $xo->startTag("annotationList",%p);
    foreach my $c (@{$obj->{target}}){ #if we are a targetList we must have target
	$c->xmlo($xo);
    }
    $xo->endTag("annotationList");
}

=head2 xml()

    Return the xml format of a AnnotationList object. Intended for special cases; normally the Video::CPL 
    method <b>xml</b> is called to obtain XML for the entire Video::CPL object at once.

=cut

sub xml {
    my $obj = shift;
    my $a;
    my $xo = new XML::Writer(OUTPUT=>\$a);
    $obj->xmlo($xo);
    $xo->end();
    return $a;
}

sub fromxml {
    my $s = shift;
    my %s = %{$s};
    my %parms;
    foreach my $q (@FIELDS){
        next if $q eq "target";
        $parms{$q} = $s{$q} if defined($s{$q});
    }
    #process targets
    my @t;
    foreach my $x (@{$s{target}}){
	push @t,Video::CPL::Target::fromxml($x);
    }
    $parms{target} = \@t;
    return new Video::CPL::AnnotationList(%parms);
}

=head1 AUTHOR

Carl Rosenberg, C<< <perl at coincident.tv> >>

=head1 BUGS

Please report any bugs or feature requests to Coincident TV.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

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
