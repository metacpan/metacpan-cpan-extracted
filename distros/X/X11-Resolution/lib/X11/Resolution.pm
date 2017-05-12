package X11::Resolution;

use warnings;
use strict;
use X11::Protocol;

=head1 NAME

X11::Resolution - Get information on the current resolution for X.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use X11::Resolution;

    my $xres=X11::Resolution->new();
    if($xres->{error}){
         print "Error:".$xres->{error}.": ".$xres->{errorString}."\n";
    }

    #gets it currently the current screen
    my ($x, $y)=$xres->getResolution;
    if($xres->{error}){
         print "Error:".$xres->{error}.": ".$xres->{errorString}."\n";
    }
    print "x=".$x."\ny=".$y."\n";

    #gets it for screen zero
    my ($x, $y)=$xres->getResolution(0);
    if($xres->{error}){
         print "Error:".$xres->{error}.": ".$xres->{errorString}."\n";
    }
    print "x=".$x."\ny=".$y."\n";

=head1 methodes

=head2 new

This initiates the object.

    my $xres=X11::Resolution->new();
    if($xres->{error}){
         print "Error:".$xres->{error}.": ".$xres->{errorString}."\n";
    }

=cut

sub new{
	my $self = {error=>undef, errorString=>''};

	if (!defined($ENV{DISPLAY})) {
		warn('X11-Resolution new:1: No enviromentail variable "DISPLAY" defined');
		$self->{error}=1;
		$self->{errorString}='No enviromentail variable "DISPLAY" defined.';
		return $self;
	}

	$self->{x}=X11::Protocol->new();

	bless $self;

	return $self
}

=head2 getResolution

This fetches the resolution for the current or a given screen.

    #gets it currently the current screen
    my ($x, $y)=$xres->getResolution;
    if($xres->{error}){
         print "Error:".$xres->{error}.": ".$xres->{errorString}."\n";
    }
    print "x=".$x."\ny=".$y."\n";

    #gets it for screen zero
    my ($x, $y)=$xres->getResolution(0);
    if($xres->{error}){
         print "Error:".$xres->{error}.": ".$xres->{errorString}."\n";
    }
    print "x=".$x."\ny=".$y."\n";

=cut

sub getResolution{
	my $self=$_[0];
	my $display=$_[1];

	if (!defined($display)) {
		$display=$ENV{DISPLAY};

		$display=~s/.*\.//g;

	}

	if (!defined($self->{x}->{'screens'}[$display])) {
		warn('X11-Resolution getResolution:2: ');
	}

	my $x=$self->{x}->{'screens'}[$display]{'width_in_pixels'};
	my $y=$self->{x}->{'screens'}[$display]{'height_in_pixels'};

	return $x, $y;
}

=head2 errorBlank

This is a internal function and should not be called.

=cut

#blanks the error flags
sub errorBlank{
        my $self=$_[0];

        $self->{error}=undef;
		$self->{errorString}='';

        return 1;
};

=head1 ERROR CODES

=head2 1

No enviromental variable 'DISPLAY' listed.

=head2 2

None existant display.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-x11-resolution at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=X11-Resolution>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc X11::Resolution


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=X11-Resolution>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/X11-Resolution>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/X11-Resolution>

=item * Search CPAN

L<http://search.cpan.org/dist/X11-Resolution/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of X11::Resolution
