package Tk::MIMEApp::DataToTk;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Tk::MIMEApp::DataToTk - The great new Tk::MIMEApp::DataToTk!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use subs qw/data2tk/;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(data2tk);

use Tk;
use Tk::MIMEApp;


our ($MW,$MTB);




=head1 SYNOPSIS

This module is a shortcut to get Tk::MIMEApp to run whatever is after __DATA__.


	#!perl
	use strict;
	use Tk::MDTextBook::Data2Tk;
	data2tk;
	__DATA__
	MIME Version: 1.0
	Content-Type: multipart/mixed; boundary=##--##--##--##--##
	Title: Window Title

	Here is a prologue
	--##--##--##--##--##
	Content-Type: application/x-ptk.markdown
	Title: _Basic MarkDown
	ID: Page1

	# MarkDown Tk Text Thingy.

	## Here is a sub-header

	And a paragraph here
	because I wanted to 
	check that it handles stuff
	right over several lines.

	--##--##--##--##--##
	Content-Type: application/x-ptk.markdown
	Title: _Tk and Scripting
	ID: Page2

	##### Tk windows and scripts

	Here is my markdown.  Here is some stuff in a preformatted block:

	    field label    <Tk::Entry>   <-- put stuff here!
	    another label  <Tk::Entry>   ... and more
	    and so on      <Tk::Button -text="Here is some text!"> 

	--##--##--##--##--##
	Content-Type: application/x-yaml.menu

	---
	- _File:
	  - _Exit: exit
	- '---' : '---'  
	- _Help:
	  - _About: MyPackage::ShowPreamble
	  - _Help : MyPackage::ShowEpilog 

	--##--##--##--##--##
	Content-Type: application/x-perl

	package MyPackage;

	sub myScriptSub {
	  print "Hello from script sub!\n";
	}

	sub getObjectList {
	  my @shelf = @Tk::MDTextBook::Shelf;
	  my $object = $shelf[$#shelf]; # get the last one!
	  return $object->{Objects};
	}

	sub getMW {
	  return $Tk::MDTextBook::Data2Tk::MW;
	}

	sub getPreamble {
	  return getObjectList()->{Main}->{Preamble};
	}

	sub getEpilog {
	  return getObjectList()->{Main}->{Epilog};
	}

	sub ShowPreamble {
	  getMW()->messageBox(-message=>getPreamble());
	}

	sub ShowEpilog {
	  getMW()->messageBox(-message=>getEpilog());
	}

	--##--##--##--##--##--
	Here is the epilogue


=head1 EXPORT

=over 

=item data2tk - EXPORTED BY DEFAULT!

=back

=head1 SUBROUTINES/METHODS

=head2 data2tk

=cut


sub data2tk {
  # call this to set up a window and populate it using what's in <DATA>
  $MW = new MainWindow();
  $MTB = $MW->MIMEApp->pack(-expand=>1,-fill=>'both');
  $MTB->loadMultipart(\*main::DATA); # takes a file handle
  $MW->MainLoop;
}

=head2 raise 

You can call this from your App code, to raise a page by ID.
ID has to be given in the MIME header for that part.

=cut

sub raise {
  my ($id) = @_;
  $MTB->raise($id);
}

=head1 AUTHOR

jimi, C<< <jimi at webu.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tk-mimeapp-datatotk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-MIMEApp-DataToTk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::MIMEApp::DataToTk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-MIMEApp-DataToTk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-MIMEApp-DataToTk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-MIMEApp-DataToTk>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-MIMEApp-DataToTk/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 jimi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Tk::MIMEApp::DataToTk
