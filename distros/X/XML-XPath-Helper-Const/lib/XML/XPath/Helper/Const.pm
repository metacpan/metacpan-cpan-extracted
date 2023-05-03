package XML::XPath::Helper::Const;

use 5.010;
use strict;
use warnings;

use Exporter 'import';

use XML::LibXML;

our $VERSION = '0.04';

our @EXPORT_OK = qw(XPATH_SIMPLE_LIST
                    XPATH_SIMPLE_TAGS
                    XPATH_NESTED_TAGS);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

use constant
  {
   # The following is taken from:
   # https://stackoverflow.com/questions/75059177/is-it-possible-to-find-nodes-containing-a-simple-list-using-xpath-1-0/75061420#75061420
   XPATH_SIMPLE_LIST => XML::LibXML::XPathExpression->new(<<"EOT"),
    ./*[
         *[not(*)]
         and
         not(*[position()>1
         and
         name(.) != name(preceding-sibling::*[1])])
       ]
EOT
   XPATH_SIMPLE_TAGS => XML::LibXML::XPathExpression->new("*[count(*) = 0]"),
   XPATH_NESTED_TAGS => XML::LibXML::XPathExpression->new("*[count(*) > 0]"),
};



1; # End of XML::XPath::Helper::Const

__END__


=head1 NAME

XML::XPath::Helper::Const - Exports some precompiled xpath constants for L<XML::LibXML>.

=head1 VERSION

Version 0.04


=head1 SYNOPSIS

   use XML::LibXML;
   use XML::XPath::Helper::Const qw(:all);

   @nodes = $my_node->findnodes(XPATH_SIMPLE_LIST);

=head1 DESCRIPTION

This module provides some precompiled XPath expressions (refer to
L<XML::LibXML::XPathExpression> for details about this).

The provided constants are:

=over

=item C<XPATH_SIMPLE_LIST>

Selects the "simple list nodes" contained in the current node; i.e. the
nodes that contain at least one child node, all the child nodes have the same
name and no child node has child nodes again.

Example:

    my $dom = XML::LibXML->load_xml(string => <<'EOT');
       <root>
         <findthis>
           <entry>a</entry>
           <entry>b</entry>
           <entry>c</entry>
         </findthis>
         <ignorethis>
           <foo>a</foo>
           <bar>b</bar>
         </ignorethis>
         <ignorethat>
           <child>
             <childofchild></childofchild>
           </child>
         </ignorethat>
         <simpletag>blah</simpletag>
       </root>
   EOT
    my @nodes = $dom->documentElement->findnodes(XPATH_SIMPLE_LIST);

Array C<@nodes> contains a single node: C<E<lt>findthisE<gt>>

=item C<XPATH_SIMPLE_TAGS>

Find all nodes that have no child nodes.

=item C<XPATH_NESTED_TAGS>

Find all nodes that have at least one child node.

=back



=head1 EXPORT

This modules exports nothing by default. You can export the constants you need
individually, or use tag C<:all> to export them all.,

=head1 SEE ALSO

L<XML::LibXML>,
L<XML::LibXML::XPathExpression>,
L<XML::XPath::Helper::String>



=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-xpath-helper-const at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-XPath-Helper-Const>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::XPath::Helper::Const


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-XPath-Helper-Const>

=item * Search CPAN

L<https://metacpan.org/release/XML-XPath-Helper-Const>

=item * GitHub Repository

L<https://github.com/AAHAZRED/perl-XML-XPath-Helper-Const>

=back


=head1 ACKNOWLEDGEMENTS

The XPath expression for C<XPATH_SIMPLE_LIST> is taken from here:
L<https://stackoverflow.com/questions/75059177/is-it-possible-to-find-nodes-containing-a-simple-list-using-xpath-1-0/75061420#75061420>. Thanks
to Michael Kay who posted this solution.



=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut
