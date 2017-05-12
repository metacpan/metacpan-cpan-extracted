package VCS::Lite::Element::Binary;

use strict;
use warnings;

our $VERSION = '0.12';

#----------------------------------------------------------------------------

use base qw/VCS::Lite::Element/;
use Carp;
use File::Spec::Functions qw/:ALL !path/;
use Params::Validate qw(:all);

our @CARP_NOT = qw/VCS::Lite::Element/;

#----------------------------------------------------------------------------

sub new {
    my $pkg  = shift;
    my $name = shift;
    my %args = validate ( @_, 
        {
            store       => 0,   # Handled by SUPER::new
            verbose     => 0,
            recordsize  => { type => SCALAR, default => 128 },
        } );
    $pkg->SUPER::new($name,%args);
}

sub _slurp_lite {
    my $self = shift;
    my $name = shift;
    my $recsiz = $self->{recordsize};

    my $in;

    open $in,'<',$name or croak "$name: $!";
    binmode $in;
    my @fil;
    my $buff;
    while (sysread($in,$buff,$recsiz)) {
       push @fil,$buff;
    }
    VCS::Lite->new($name,undef,\@fil);
}

sub _contents {
    my $self = shift;

    my $recsiz = $self->{recordsize};
    my $bin = $self->{store}->store_path($self->path,'vbin');
    my $cont;              
    if (@_) {
        $cont = shift;
        my $out;
        open $out,'>',$bin or croak "$bin: $!";
        binmode $out;
        for (@$cont) {
            my $str = pack 'n',length $_;
            syswrite($out,$str.$_);
        }
    } else {
        return [] unless -f $bin;
        my $in;

        open $in,'<',$bin or croak "$bin: $!";
        binmode $in;
        my @fil;
        my $buff;
        while (sysread($in,$buff,2)) {
            my $rsz = unpack 'n',$buff;
            sysread($in,$buff,$rsz);
            push @fil,$buff;
        }
        $cont = \@fil;
    }
    $cont;
}
        
1; #this line is important and will help the module return a true value

__END__

#----------------------------------------------------------------------------

=head1 NAME

VCS::Lite::Element::Binary - Minimal Version Control System - binary file support

=head1 SYNOPSIS

  use VCS::Lite::Element::Binary;

  my $bin_ele = VCS::Lite::Element::Binary->new('foo.jpg', recordsize => 16);

=head1 DESCRIPTION

This module is a subclass of VCS::Lite::Element to handle versioning of 
binary files

=head1 METHODS

See L<VCS::Lite::Element> for the list of object methods available.

=head2 new

  my $obj = VCS::Lite::Element::Binary->new( $filename, [param => value...]);

Constructs a VCS::Lite::Element::Binary object for a given file. Note, if
the object has an existing YAML, it will return the existing object.

If you want to create a new binary element in a repository, call C<new> then
add it to the repository.

=head1 SEE ALSO

L<VCS::Lite::Element>, L<VCS::Lite::Repository>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (see link below). However, it would help greatly if you are able to 
pinpoint problems or even supply a patch.

http://rt.cpan.org/Public/Dist/Display.html?Name=VCS-Lite-Repository

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Original Author: Ivor Williams (RIP)          2002-2009
  Current Maintainer: Barbie <barbie@cpan.org>  2014-2015

=head1 COPYRIGHT

  Copyright (c) Ivor Williams, 2002-2009
  Copyright (c) Barbie,        2014-2015

=head1 LICENCE

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
