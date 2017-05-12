
package Tree::Simple::SAX;

use strict;
use warnings;

our $VERSION = '0.01';

# load the handler
use Tree::Simple::SAX::Handler;

1;

__END__

=head1 NAME

Tree::Simple::SAX - A set of classes for using Tree::Simple with XML

=head1 SYNOPSIS

  use Tree::Simple::SAX;
  use XML::SAX::ParserFactory;
  
  my $handler = Tree::Simple::SAX::Handler->new(Tree::Simple->new());
  
  my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
  $p->parse_string('<xml><string>Hello <world/>!</string></xml>');    
  
  # this will create a tree like this:
  # { tag_type => 'xml' }
  #         { tag_type => 'string' }
  #                 { content => 'Hello ', tag_type => 'CDATA' }
  #                 { tag_type => 'world' }
  #                 { content => '!', tag_type => 'CDATA' }

=head1 DESCRIPTION

This is an early implementation of an L<XML::SAX> handler which creates a L<Tree::Simple> object hierarchy from the XML stream. It is currently in the proof-of-concept/experimental stages and I plan to add more features in the future. 

If anyone else is interested in the development of this module, feel free to contact me (use the email in the L<AUTHOR> section). I am always open to discussion, thoughts, criticism and especially patches :)

=head1 DISCLAIMER

This is in no way an attempt to make an alternate to the XML DOM, or to provide I<Yet Another XML Tree> module. My intent is to create a tool for easy reading and writing of L<Tree::Simple> object hierarchies in an XML format. My focus is on making XML work for L<Tree::Simple> rather than making L<Tree::Simple> work for XML.

=head1 TO DO

=over 4

=item Tree::Simple::SAX::Driver

Add an XML::SAX driver which can create an XML string from an existing Tree::Simple heirarchy. 

=item Support more SAX handler hooks

I only support the basic C<start_element>, C<end_element> and C<character>.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt branch   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 Tree/Simple/SAX.pm            100.0    n/a    n/a  100.0    n/a   13.3  100.0
 Tree/Simple/SAX/Handler.pm    100.0  100.0   41.7  100.0  100.0   86.7   89.9
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 Total                         100.0  100.0   41.7  100.0  100.0  100.0   91.4
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

=over 4

=item L<XML::SAX>

=item L<Tree::Simple>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

