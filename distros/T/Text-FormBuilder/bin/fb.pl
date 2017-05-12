#!/usr/bin/perl -w
use strict;
use warnings;

use Getopt::Long;
use Text::FormBuilder;

GetOptions(
    'o=s' => \my $outfile,
    'D=s' => \my %fb_options,
);
my $src_file = shift;

create_form($src_file, \%fb_options, $outfile);
#Text::FormBuilder->parse($src_file)->build(%fb_options)->write($outfile);

=head1 NAME

fb - Frontend script for Text::FormBuilder

=head1 SYNOPSIS

    $ fb my_form.txt -o form.html
    
    $ fb my_form.txt -o my_form.html -D action=/cgi-bin/my-script.pl

=head1 DESCRIPTION

Parses a formspec file from the command line and creates an output
file. The sort of output file depends on the value given to the C<-o>
option. If it ends in F<.pm>, a standalone module is created. If it
ends in F<.pl> or F<.cgi>, a skeleton CGI script is created. Any other
value, will be taken as the name of an HTML file to write. Finally, if
not C<-o> option is given then the HTML will be written to STDOUT.

=head1 OPTIONS

=over

=item C<< -D <parameter>=<value> >>

Define options that are passed to the CGI::FormBuilder object. For example,
to create a form on a static html page, and have it submitted to an external
CGI script, you would want to define the C<action> parameter:

    $ fb ... -D action=/cgi-bin/some_script.pl

=item C<< -o <output file> >>

Where to write output, and what form to write it in. See C<create_form> in 
L<Text::FormBuilder> for a more detailed explanation.

    # write a standalone module
    $ fb myform -o MyForm.pm
    
    # write a CGI script
    $ fb myform -o form.cgi
    $ fb myform -o form.pl

=back

=head1 AUTHOR

Peter Eichman, C<< <peichman@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright E<copy>2004 by Peter Eichman.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
