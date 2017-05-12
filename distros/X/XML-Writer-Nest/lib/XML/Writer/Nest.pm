package XML::Writer::Nest;

our $VERSION = '1.0';

use Moose;
has 'tag'    => (isa => 'Str', is => 'ro', required => 1);
has 'attr'   => (isa => 'ArrayRef[Maybe[Str]]',    is => 'ro', default => sub { [] } ); # hashref wont preserve order!
has 'writer' => (isa => 'XML::Writer', is => 'ro', required => 1);


use XML::Writer;

sub nest {
    my($self, $tag, @attr)=@_;

    my @nattr;

    if (scalar @attr and ref $attr[0] eq 'ARRAY') {
	@nattr = @{$attr[0]};
    } else {
	@nattr = @attr;
    }

    XML::Writer::Nest->new(tag => $tag, attr => \@nattr, writer => $self->writer);
}
    
    

sub BUILD {
    my($self)=@_;

    my @attr = defined($self->attr) ? @{$self->attr} : () ;

    #warn "Writer" . $self->writer;
    
    $self->writer->startTag($self->tag, @attr);

    $self;
}
 
sub DEMOLISH {
    my($self)=@_;

    $self->writer->endTag();
}



=head1 NAME

XML::Writer::Nest - dataElement() for when you need to embed elements, not data




=head1 SYNOPSIS

    use XML::Writer::Nest;

     my $writer = new XML::Writer;

     {  my $level1 = XML::Writer::Nest->new(tag => 'level1', attr => [ hee => 'haw', fee => 'fi' ], writer => $writer  );

        {  my $level2 = $level1->nest(level2 => [ attr1 => 3 ] ); # or call the class conc. again.
     
           {  my $level3 = $level2->nest('level3');

           } # endTag created automatically

        } # endTag created automatically

    } # endTag created automatically

Vanilla L<XML::Writer> would not have indentation and you would have to manually close your start tags:

  $writer->startTag("level1");
  $writer->startTag("level2");
  $writer->startTag("level3");
  $writer->endTag();
  $writer->endTag();
  $writer->endTag();




=head1 DESCRIPTION

When nesting XML elements with XML::Writer, you have to manually close your startTags. 
Also, you dont necessarily have any visual feedback via indentation for each level
of tag nesting. 

C<< XML::Writer::Nest >> solves both of those problems.

=head2 XML::Generator

L<XML::Generator|XML::Generator> solves this problem a different way. But 
I dont see an easy way to make use of object-oriented dispatch to specialize
and generalize XML production with it.

My current module and Moose's C<inner> work just fine together.


=head1 API

There is a class-level constructor and an object-level constructor. The class level constructor
requires 3 arguments (tag, attributes, and C<XML::Writer> instance). The object-level
constructor only requires tag and attribute arguments - it passes along the 
C<XML::Writer> instance.

NOTE: This module operates based on lexical scope. So both object and class level construction
are done right after creating a new lexical scope with braces.

=head2 Class-based constructor

  { my $xml_nest = XML::Writer::Nest->new(tag => 'tagname', attr => \@attr, writer => $xml_writer);

    # add some additional things for this nest level via $xml_writer->api_calls
  } # when $xml_nest goes out of scope, it calls $xml_writer->endTag automatically

=head2 Object-based constructor

  { my $xml_nest2 = $xml_nest->nest(tagname => \@attr);

    # add some additional things for this nest level via $xml_writer->api_calls
  } # when $xml_nest2 goes out of scope, it calls $xml_writer->endTag automatically

  { my $xml_nest2 = $xml_nest->nest(tagname => @attr);

    # add some additional things for this nest level via $xml_writer->api_calls
  } # when $xml_nest2 goes out of scope, it calls $xml_writer->endTag automatically

Please note: the object-level constructor will B<either> an arrayref or array of attributes.
The class-based constructor will take B<only> an B<arrayref> of attributes.


=head1 DISCUSSION

=head2 Caveat emptor

If you wish to nest elements at the same level ("sibling elements"), then you must brace each:

  #!/usr/bin/perl

  use strict;
  use XML::Writer::Nest;

  my $output;
  my $writer = new XML::Writer(OUTPUT => $output);
  my $main = new XML::Writer::Nest(tag => 'main', writer => $writer);
  
  {
      my $head = $main->nest('head');
  
  }
  {
      my $body = $main->nest('body');
  }

  print STDOUT $output . "\n\n";


=head2 XML::Generator

L<XML::Generator|XML::Generator> is another module which allows for automatic creation of closing tags based
on behavior of the Perl programming language.

From what I can see, one is not able to leverage object-oriented re-use of parts of the XML generation by
delegating specialized aspects of the rendering to subclasses.

Concretely, Moose's augment function has demonstrated a way of allowing generic and specific aspects of 
XML generation to co-operate.

Therefore, I like Moose in combination with XML::Writer for object-oriented XML production. However, 
the automatic creation of closing XML tags by XML::Generator is quite attractive. Not only that, but the 
automatic source-code indentation is especially handy when you are creating highly nested XML.

Another thing I don't like about XML::Generator is that you must use one highly nested function call to produce the
output document. I prefer brace-levels and a series of calls to the XML::Writer interface.

=head2 Practical Comparison

Let's take the synopsis example from XML::Generator and write it in all 3 approaches. First let's take a look at 
the desired XML output.

  <foo xmlns:qux="http://qux.com/">
     <bar baz="3">
       <bam />
     </bar>
     <qux:bar>Hey there, world</qux:bar>
   </foo>

=head3 XML::Generator

  use XML::Generator ':pretty';

  print foo(bar({ baz => 3 }, bam()),
            bar([ 'qux' => 'http://qux.com/' ],
                  "Hey there, world"));




=head2

=head1 AUTHOR

Terrence Brannon, C<< <metaperl at gmail.com> >>

=head1 SEE ALSO

=head2 "Constructive Use of Destructors"

L<http://www.metaperl.org/publications>

This talk to the Columbus, OH Perl mongers discusses XML::Writer::Nest in detail.


=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-writer-nest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Writer-Nest>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Writer::Nest


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Writer-Nest>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Writer-Nest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Writer-Nest>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Writer-Nest/>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks to #moose, especially Jeese Luehrs (doy)!, matt trout, doy, and confound.



=head1 COPYRIGHT & LICENSE

Copyright 2009 Terrence Brannon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of XML::Writer::Nest
