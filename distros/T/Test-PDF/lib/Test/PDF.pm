
package Test::PDF;

use strict;
use warnings;

our $VERSION = '0.01';

use Test::Builder ();
use Test::Deep    ();
use Scalar::Util 'blessed';
use CAM::PDF;

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(cmp_pdf);

my $Test = Test::Builder->new;

sub cmp_pdf ($$;$) {
    my ($got, $expected, $message) = @_;
    unless (blessed($got) && $got->isa('CAM::PDF')) {
        $got = CAM::PDF->new($got) 
               || die "Could not create CAM::PDF instance with : $got";
    }
    unless (blessed($expected) && $expected->isa('CAM::PDF')) {
        $expected = CAM::PDF->new($expected) 
               || die "Could not create CAM::PDF instance with : $expected";
    }    
    
    # if they dont have the same number of 
    # pages, then they can't be "equal" so 
    # we can short-circuit a potentially 
    # long test here ...
    unless ($got->numPages() == $expected->numPages()) {
        $Test->ok(0, $message);
        return;
    }

    my $do_PDFs_match = 0;
    foreach my $page_num (1 .. $got->numPages()) {
        my $tree1 = $got->getPageContentTree($page_num, "verbose");
        my $tree2 = $expected->getPageContentTree($page_num, "verbose");
        if (Test::Deep::eq_deeply($tree1->{blocks}, $tree2->{blocks})) {
            $do_PDFs_match = 1;
        }
        else {
            # exit the loop as soon as we
            # determine the PDFs do not match
            $do_PDFs_match = 0;            
            last;
        }
    }

    $Test->ok($do_PDFs_match, $message); 
}

1;

__END__

=head1 NAME

Test::PDF - A module for testing and comparing PDF files

=head1 SYNOPSIS

  use Test::More plan => 1;
  use Test::PDF;
  
  cmp_pdf('foo.pdf', 'bar.pdf', '... our PDFs are identical');
  
  # or
  
  my $foo = CAM::PDF->new('foo.pdf');
  my $bar = CAM::PDF->new('bar.pdf');  
  cmp_pdf($foo, $bar, '... our PDFs are identical');

=head1 DESCRIPTION

This module is meant to be used for testing custom generated PDF files, it provides only one 
function at the moment, which is C<cmp_pdf>, and can be used to compare two PDF files to see if 
they are I<visually> similar. Future versions may include other testing functions.

=head2 What is "Visually" Similar?

This module uses the C<CAM::PDF> module to parse PDF files, then compares the parsed data 
structure for differences. We ignore cetain components of the PDF file, such as embedded fonts, 
images, forms and annotations, and focus entirely on the layout of each PDF page instead. Future 
versions will likely support font and image comparisons, but not in this initial release.

=head2 Important Disclaimer

It should be clearly noted that this module does not claim to provide a fool-proof comparison of 
generated PDFs. In fact there are still a number of ways in which I want to expand the existing 
comparison functionality. This module I<is> actively being developed for a number of projects I am 
currently working on, so expect many changes to happen. If you have any suggestions/comments/questions 
please feel free to contact me.

=head1 FUNCTIONS

=over 4

=item C<cmp_pdf($got, $expected, ?$message)>

This function will tell you whether the two PDF files are "visually" different, ignoring differences 
in embedded fonts/images and metadata.

Both $got and $expected can be either instances of CAM::PDF or a file path (which is in turn passed 
to the CAM::PDF constructor).

=back

=head1 CAVEATS

=head2 Testing Large PDFs

Testing of large PDFs (30+ pages) can take a long time, this is because, well, we are doing a lot of
computation. In fact, this modules developer test suite includes tests against several large PDFs, 
however I am not including those in this distibution for obvious reasons.

=head1 TO DO

=over 4

=item More functions for more testing

=item Testing of font data

=item Testing of embedded image data

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. This is still 
a very early version, so it is always possible that I have just "gotten it wrong" in some places. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt   bran   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 Test/PDF.pm                    94.3   87.5   60.0  100.0  100.0  100.0   88.5
 ---------------------------- ------ ------ ------ ------ ------ ------ ------ 
 Total                          94.3   87.5   60.0  100.0  100.0  100.0   88.5
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

NOTE: This code coverage report does not include a number of (long running) developer tests.

=head1 SEE ALSO

=over 4

=item C<CAM::PDF> - I could not have written this without this module. 

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item Chris Dolan (author of CAM::PDF) for answering my many questions and writing CAM::PDF.

=back

=head1 AUTHOR

Stevan Little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

