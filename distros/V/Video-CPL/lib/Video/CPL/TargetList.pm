package Video::CPL::TargetList;

use warnings;
use strict;
use Video::CPL::Target;
use XML::Writer;
use Carp;
use Data::Dumper;


=head1 NAME

Video::CPL::TargetList

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

Create and modify TargetList objects. Usually invoked from within Video::CPL.

=head1 SUBROUTINES/METHODS

=cut

our @FIELDS = qw(backgroundPicLoc headerText operation target);

=head2 backgroundPicLoc([$url])

    Accessor method to get or set backgroundPicLoc.

=cut

sub backgroundPicLoc { my $obj = shift; $obj->{backgroundPicLoc} = shift if @_; return $obj->{backgroundPicLoc};};

=head2 headerText([$text])

    Accessor method to get or set headerText.

=cut

sub headerText { my $obj = shift; $obj->{headerText} = shift if @_; return $obj->{headerText};};

=head2 operation([$operation])

    Accessor method to get or set operation.

=cut

sub operation { my $obj = shift; $obj->{operation} = shift if @_; return $obj->{operation};};

=head2 target([$target])

    Accessor method to get or set target.

=cut

sub target { my $obj = shift; $obj->{target} = shift if @_; return $obj->{target};};

=head2 new([backgroundPicLoc=>$url,headerText=>$text,operation=>$op,target=>$target])

    Create a new TargetList object.

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
        confess("Parameter ('$x') given to Video::CPL::TargetList::new, but not understood\n") if !defined $ret->{$x};
    }

    return $ret;
}

=head2 xmlo
  
    Given an XML::Writer object, add the xml information for this TargetList.

=cut

sub xmlo {
    my $obj = shift;
    my $xo = shift;
    my %p;
    foreach my $x (@FIELDS){
        next if $x eq "target";
        $p{$x} = $obj->{$x} if defined $obj->{$x};
    }
    $xo->startTag("targetList",%p);
    foreach my $c (@{$obj->{target}}){ #if we are a targetList we must have target
        #print "Video::CPL::TargetList::xmlo in loop\n".Dumper($xo);
	$c->xmlo($xo);
    }
    $xo->endTag("targetList");
}

=head2 xml()

    Return the xml format of a TargetList object.

=cut

sub xml {
    my $obj = shift;
    my $a;
    my $xo = new XML::Writer(OUTPUT=>\$a);
    $obj->xmlo($xo);
    $xo->end();
    return $a;
}

=head2 fromxml()

=cut

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
    return new Video::CPL::TargetList(%parms);
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
