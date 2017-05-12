package Video::CPL::Story;

use warnings;
use strict;
use Carp;
use XML::Writer;

=head1 NAME

Video::CPL::Story - Video::CPL::Story object.

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';
our @FIELDS = qw(alpha balloonText forever picLoc picOverLoc);

=head1 SYNOPSIS

    This is mostly an internal package for CPL.pm. You can use it directly, but it is recommended to use the cue point creation routines in CPL.pm.

    use Video::CPL::Story;
    my $foo = Video::CPL::Story->new(balloonText=>"Hello");

=head1 METHODS/METHODS

=cut

=head2 new([alpha=>$value,balloonText=>$string,forever=>"false",picLoc=$url,picOverLoc=>$url])

    Create a new Video::CPL::Story object.

=cut 

sub new {
    my $pkg = shift;
    my %p = @_;
    my $ret = {};
    bless $ret,$pkg;

    foreach my $x (@FIELDS){
	$ret->{$x} = $p{$x} if defined $p{$x};
    }

    foreach my $x (keys %p){
        confess("Parameter ('$x') value ($p{$x}) given to Video::CPL::Story::new, but not understood\n") if defined($p{$x}) && !defined($ret->{$x});
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
    $xo->emptyTag("story",%p);
}

=head2 xml()

    Return the xml format of a Video::CPL::Story object.

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

    Return a Video::CPL::Story object given that part of the parse tree from XML::Simple::XMLin.

=cut

sub fromxml {
    my $s = shift;
    my %s = %{$s};
    my %p;
    foreach my $q (@FIELDS){
        $p{$q} = $s{$q} if defined $s{$q};
    }
    foreach my $q (keys %s){
        confess "Video::CPL::Story::fromxml confused by key ($q)\n" if !defined($p{$q});
    }
    return new Video::CPL::Story(%p);
}

=head2 alpha([$string])

    Accessor function to set or return C<alpha>.

=cut

sub alpha { my $obj = shift; $obj->{alpha} = shift if @_; return $obj->{alpha}; }

=head2 balloonText([$string])

    Accessor function to set or return C<balloonText>.

=cut

sub balloonText { my $obj = shift; $obj->{balloonText} = shift if @_; return $obj->{balloonText}; }

=head2 forever([$string])

    Accessor function to set or return the boolean B<forever>. Values are in text, "true" or "false".

=cut

sub forever { my $obj = shift; $obj->{forever} = shift if @_; return $obj->{forever}; }

=head2 picLoc([$url])

    Accessor function to set or return the B<picLoc>. This should be a local or remote URL, e.g. 
C<http://www.foo.com/x.jpg> or C<x.jpg>

=cut

sub picLoc { my $obj = shift; $obj->{picLoc} = shift if @_; return $obj->{picLoc}; }

=head2 picOverLoc([$url])

    Accessor function to set or return the B<picOverLoc>, the image to be displayed when the mouse is over the image.. This should be a local or remote URL, e.g. 
C<http://www.foo.com/x.jpg> or C<x.jpg>

=cut

sub picOverLoc { my $obj = shift; $obj->{picOverLoc} = shift if @_; return $obj->{picOverLoc}; }

=head1 AUTHOR

Carl Rosenberg, C<< <perl at coincident.tv> >>

=head1 BUGS

Please report any bugs or feature requests to Coincident TV.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Video::CPL::Story

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

1; # End of Video::CPL::Story
