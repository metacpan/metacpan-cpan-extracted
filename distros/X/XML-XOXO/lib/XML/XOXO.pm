package XML::XOXO;
use strict;
use XML::XOXO::Node;
use XML::XOXO::Parser;
use vars qw($VERSION);
$VERSION = 0.034;
1;

__END__

=begin

=head1 NAME

XML::XOXO - Package for working with Extensible Open XHTML Outlines
(XOXO) lists.

=head1 SYNOPSIS

 #!/usr/bin/perl -w
 
 use strict; 
 use XML::XOXO;
 
 my $x = XML::XOXO::Parser->new; 
 my $xoxo = $x->parsefile('/Users/tima/Desktop/code/xoxo/test.xoxo');
 
 # print a list of urls and titles extracted from
 # the XOXO data.
 my @nodes = $xoxo->[0]->query('//li');
 foreach (@nodes) {
     if (defined $_->attributes->{url}) {
         print $_->attributes->{url};
         print ' '.$_->attributes->{title} if $_->attributes->{title};
         print "\n";
     }
 }
 
 # output the XOXO markup from the root element of 
 # the first list found.
 print $xoxo->[0]->as_xml;
 
=head1 DESCRIPTION

XML::XOXO is an object-oriented Perl API for working with XOXO lists.
The package includes a parser, a simple perlish object tree model and a
basic facility for re-serializing the data into XHTML fragments. The
intent of XML::XOXO was to provide developer's with the core
functionality needed to implement this more expressive and versatile
alternative to OPML in their applications. It was also designed as the
foundation for a library to work with the attention.xml specification
and API that is in-progress, but incomplete.

=head1 DEPENDENCIES

L<XML::Parser>, L<Class::XPath>

=head1 SEE ALSO

L<XML::XOXO::Parser>, L<XML::XOXO::Node>

Extensible Open XHTML Outlines (XOXO) 
L<http://developers.technorati.com/wiki/xhtmloutlines>

=head1 LICENSE

The software is released under the Artistic License. The terms of
the Artistic License are described at
L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, XML::XOXO is 
Copyright 2005, Timothy Appnel, cpan@timaoutloud.org. All rights 
reserved.

=cut

=end
