#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  Text::OutdentEdge.
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Text-OutdentEdge/lib/Text/OutdentEdge.pm 252 2006-11-25T09:35:55.628540Z hio  $
# -----------------------------------------------------------------------------
package Text::OutdentEdge;
use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw(xoutdent outdent);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = 0.01;

1;

# -----------------------------------------------------------------------------
# $out = xoutdent($text);
#
sub xoutdent($;$)
{
	my $text = shift;
	my $opts = shift || {};
	defined($opts->{indent}) or $opts->{indent} = qr/[ \t]+/;
	defined($opts->{xchar})  or $opts->{xchar}  = qr/\S([ \t]|$)/;
	if( !exists($opts->{trim}) || $opts->{trim} )
	{
		$text =~ s/\A\r?\n?//s;
		$text =~ s/[ \t]+\z//s;
	}
	$text =~ s/^$opts->{indent}$opts->{xchar}//mg;
	if( $opts->{chomp} )
	{
		chomp $text;
	}
	$text;
}

# -----------------------------------------------------------------------------
# $out = outdent($text);
# $out = outdent($text, qr//);
# $out = outdent($text, $opts);
#
sub outdent($;$)
{
	my $text = shift;
	my $opts = shift;
	my $re;
	if( (ref($opts)||'') eq 'Regexp' )
	{
		$re = $opts;
		$opts = {};
	}
	$re ||= $opts->{indent};
	if( !$re )
	{
		my ($len) = sort{ $a<=>$b } map{length($_)} $text =~ /^([ \t]*(?=\S))/gm;
		$re = $len ? qr/[ \t]{1,$len}/ : qr//;
	}
	xoutdent $text, {%$opts, indent=>$re, xchar=>'' };
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
__END__

=encoding utf8

=for stopwords
	YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT
	xoutdent
	xchar

=head1 NAME

Text::OutdentEdge - remove indent chars.


=head1 VERSION

Version 0.01


=head1 SYNOPSIS

 use Text::OutdentEdge qw(xoutdent);
 
 print <<INDENT, xoutdent <<XOUTDENT;
   Hello, World!
 INDENT
   X Hello, Edged-Outdent!
 XOUTDENT
 # ==> print "  Hello, World!\n", "Hello, Edged-Outdent!\n";

=head1 EXPORT

This Module can export two function.


=head1 FUNCTIONS

=head2 xoutdent

 my $text = xoutdent $in;
 my $text = xoutdent $in, $opts;

This function removed edged-indent.
For example:


 print xoutdent <<TEXT;
   X Hello,
   X World!
 TEXT

just prints two words, "Hello" and "World!" on each lines.


This function take two arguments.
First one is target text which may be indented.
Second one is optional hash-ref. Options are:


=over

=item indent => $regexp

specifies what are removed.
Default is qr/[ \t]+/;


=item xchar => $regexp

specifies edge-string regexp.
Default is qr/\S([ \t]|$)/;


=item chomp => $flag

specifies whether chomp result text.
Default is false.


=item trim => $flag

specified whether trimming spaces of multiline q{..}.
Default is true.


=back

=head2 outdent

 my $text = outdent $in;
 my $text = outdent $in, qr/^ {4}/;
 my $text = outdent $in, $opts;

This function take two arguments.
This function is same as:


 xoutdent $in, { %$opts, indent => minimum-indent, xchar => '', }

If regexp is passed as second argument, it treated as
C<{ indent => $regexp, xchar => '', }>.


=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-outdentedge at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-OutdentEdge>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.


    perldoc Text::OutdentEdge

You can also look for information at:


=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-OutdentEdge>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-OutdentEdge>


=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-OutdentEdge>


=item * Search CPAN

L<http://search.cpan.org/dist/Text-OutdentEdge>


=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 YAMASHINA Hio, all rights reserved.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


