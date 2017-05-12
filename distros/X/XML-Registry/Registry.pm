# 
# Copyright (c) 1998 Jonathan Eisenzopf <eisen@pobox.com>
# XML::Registry is free software. You can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package XML::Registry;

BEGIN {
    use strict;
    use vars qw($VAR1 $VERSION $ref $index);
    use Data::Dumper;
    $VERSION='0.02';
}

sub new {
    my $class = {};
    local($index) = 0;
    bless $class;
}

sub xml2pl {
    my ($obj,$xml) = @_;
    return Dumper($xml);
}

sub pl2xml {
    my ($obj,$ref) = @_;
    print "<perl>";
    &Tree2XML($ref->[0],$ref->[1]);
    print "\n</perl>\n";
}

sub Tree2XML {
    local ($el,$tree) = @_;

    # increment tree index
    $index++;

    # print element name
    print "\n", " "x($index), "<", $el;

    # loop through array
    for (my $i=0; $i < scalar(@$tree); $i++) {
	# is a sub-element
	if (ref($tree->[$i]) eq 'ARRAY') {	    
	    &Tree2XML($el,$tree->[$i]);
	
        # print element attribs
	} elsif (ref($tree->[$i]) eq 'HASH') {
	    my $attribs = $tree->[$i];
	    foreach my $attrib (keys(%$attribs)) {
		print " $attrib=".'"'.$attribs->{$attrib}.'"'
	    }
	    # print closing bracket
	    if (scalar(@$tree) > 2) {
		print ">";
	    # no cdata for this element
	    } else {
		print "/>";
	    }

        # print cdata
	} elsif ($tree->[$i] eq 0) {
	    print $tree->[++$i];	    
	}
    }
    
    # close element
    print "\n", " "x$index, "</$el>" if scalar(@$tree) > 2;

    # decrement tree index
    $index--;
}

1;
__END__

=head1 NAME

XML::Registry - Perl module for loading and saving an XML registry.

=head1 SYNOPSIS

  use XML::Parser;
  use XML::Registry;

  # create a new XML::Parser instance using Tree Style
  $parser = new XML::Parser (Style => 'Tree');

  # create new instance of XML::Registry
  $dump = new XML::Registry;

  # Convert XML Registry to Perl code
  $tree = $parser->parsefile($file); 
  $tree = $parser->parse('<foo id="me">Hello World</foo>');
  # print the results
  print $dump->xml2pl($tree);

  # Convert Perl code to XML Registry 
  # read file in Data::Dumper format
  open(PL,$file) || die "Cannot open $file: $!";
  $perl = eval(join("",<PL>));
  # print the results
  print $dump->pl2xml($perl);


=head1 DESCRIPTION

XML::Registry can dump an XML registry to Perl code using
Data::Dumper, or dump Perl code into an XML registry.

This is done via the following 2 methods:
XML::Registry::xml2pl
XML::Registry::pl2xml

This module was originally written for an article in
TPJ. It was an exercise in using the XML::Parser module.

=head1 AUTHOR

Jonathan Eisenzopf, eisen@pobox.com

=head1 SEE ALSO

perl(1), XML::Parser(3).

=cut
