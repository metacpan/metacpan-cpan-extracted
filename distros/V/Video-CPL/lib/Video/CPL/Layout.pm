package Video::CPL::Layout;

use warnings;
use strict;
use Carp;
use XML::Writer;
use Data::Dumper;

=head1 NAME

Video::CPL::Layout - Manage layouts.

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';


=head1 SYNOPSIS

Create or manage CPL layouts.

=head1 SUBROUTINES/METHODS

=cut

our @FIELDS = qw(videoHeight videoVCenter videoTop videoBottom videoWidth videoHCenter videoLeft videoRight webHeight webVCenter webTop webBottom webWidth webHCenter webLeft webRight name);

=head2 videoHeight([$val])

    Accessor method to get or set videoHeight.

=cut

sub videoHeight { my $obj = shift; $obj->{videoHeight} = shift if @_; return $obj->{videoHeight};};

=head2 videoVCenter([$val])

    Accessor method to get or set videoVCenter.

=cut

sub videoVCenter { my $obj = shift; $obj->{videoVCenter} = shift if @_; return $obj->{videoVCenter};};

=head2 videoTop([$val])

    Accessor method to get or set videoTop.

=cut

sub videoTop { my $obj = shift; $obj->{videoTop} = shift if @_; return $obj->{videoTop};};

=head2 videoBottom([$val])

    Accessor method to get or set videoBottom.

=cut

sub videoBottom { my $obj = shift; $obj->{videoBottom} = shift if @_; return $obj->{videoBottom};};

=head2 videoWidth([$val])

    Accessor method to get or set videoWidth.

=cut

sub videoWidth { my $obj = shift; $obj->{videoWidth} = shift if @_; return $obj->{videoWidth};};

=head2 videoHCenter([$val])

    Accessor method to get or set videoHCenter.

=cut

sub videoHCenter { my $obj = shift; $obj->{videoHCenter} = shift if @_; return $obj->{videoHCenter};};

=head2 videoLeft([$val])

    Accessor method to get or set videoLeft.

=cut

sub videoLeft { my $obj = shift; $obj->{videoLeft} = shift if @_; return $obj->{videoLeft};};

=head2 videoRight([$val])

    Accessor method to get or set videoRight.

=cut

sub videoRight { my $obj = shift; $obj->{videoRight} = shift if @_; return $obj->{videoRight};};

=head2 webHeight([$val])

    Accessor method to get or set webHeight.

=cut

sub webHeight { my $obj = shift; $obj->{webHeight} = shift if @_; return $obj->{webHeight};};

=head2 webVCenter([$val])

    Accessor method to get or set webVCenter.

=cut

sub webVCenter { my $obj = shift; $obj->{webVCenter} = shift if @_; return $obj->{webVCenter};};

=head2 webTop([$val])

    Accessor method to get or set webTop.

=cut

sub webTop { my $obj = shift; $obj->{webTop} = shift if @_; return $obj->{webTop};};

=head2 webBottom([$val])

    Accessor method to get or set webBottom.

=cut

sub webBottom { my $obj = shift; $obj->{webBottom} = shift if @_; return $obj->{webBottom};};

=head2 webWidth([$val])

    Accessor method to get or set webWidth.

=cut

sub webWidth { my $obj = shift; $obj->{webWidth} = shift if @_; return $obj->{webWidth};};

=head2 webHCenter([$val])

    Accessor method to get or set webHCenter.

=cut

sub webHCenter { my $obj = shift; $obj->{webHCenter} = shift if @_; return $obj->{webHCenter};};

=head2 webLeft([$val])

    Accessor method to get or set webLeft.

=cut

sub webLeft { my $obj = shift; $obj->{webLeft} = shift if @_; return $obj->{webLeft};};

=head2 webRight([$val])

    Accessor method to get or set webRight.

=cut

sub webRight { my $obj = shift; $obj->{webRight} = shift if @_; return $obj->{webRight};};

=head2 name([$val])

    Accessor method to get or set name.

=cut

sub name { my $obj = shift; $obj->{name} = shift if @_; return $obj->{name};};

=head2 new([videoHeight=>$val,videoVCenter=>$val,videoTop=>$val,videoBottom=>$val,videoWidth=>$val,
            videoHCenter=>$val,videoLeft=>$val,videoRight=>$val,webHeight=>$val,webVCenter=>$val,
	    webTop=>$val,webBottom=>$val,webWidth=>$val,webHCenter=>$val,webLeft=>$val,webRight=>$val,
	    name=>$val])

    Create a new Layout object. A name must be specified and will not be auto-generated. Other objects
    which refer to this Layout should use the name and not the object.

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
        confess("Parameter ('$x') given to Video::CPL::Layout::new, but not understood\n") if !defined $ret->{$x};
    }

    return $ret;
}

=head2 xmlo
  
    Given an XML::Writer object, add the xml information for this Layout.

=cut

sub xmlo {
    my $obj = shift;
    my $xo = shift;
    my %p;
    foreach my $x (@FIELDS){
        $p{$x} = $obj->{$x} if defined $obj->{$x};
    }
    $xo->emptyTag("layout",%p);
}

=head2 xml()

    Return the xml format of a Layout object.

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
    my %p;
    foreach my $q (@FIELDS){
        $p{$q} = $s{$q} if defined($s{$q});
    }
    return new Video::CPL::Layout(%p);
}

=head1 AUTHOR

Carl Rosenberg, C<< <perl at coincident.tv> >>

=head1 BUGS

Please report any bugs or feature requests to Coincident TV.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Video::CPL::Layout

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

1; # End of Video::CPL::Layout
