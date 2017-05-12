# NAME

XML::Diver - Dive XML with XML and first-class collection + alpha

# SYNOPSIS

    use XML::Diver;
    my $xml_str = ...;
    my $diver  = XML::Diver->load_xml(string => $xml_str); # same as XML::LibXML;
    my $images = $diver->dive('//img'); # $images is Class::Builtin::Array class!
    my $urls   = $images->each(sub {
        my $node = shift;        # this is img element node, but XML::Diver object!
        $node->attr('src');      # return image url 
    });
    $urls->each(sub { say shift });  # say image url
    

    # as oneline
    $diver->dive('//img')->each(sub{ say shift->attr('src') });
    

    # or simple perl way
    my @images = $diver->dive('//img');
    my @urls = map { $_->attr('src') } @images;
    say $_ for @urls;
    



# DESCRIPTION

XML::Diver is XML data parse tool class that inherits [XML::LibXML::XPathContext](http://search.cpan.org/perldoc?XML::LibXML::XPathContext).

# METHODS

## dive

    my $nodes = $diver->dive($xpath); # first-class collection (Class::Builtin::Array object)
    my @nodes = $diver->dive($xpath); # primitive array

Returns Class::Builtin::Array object or primitive array. These contains XML::Diver objects.

For this reason, It can as following.

    # case of first-class collection
    my $child_nodes = $nodes->each(sub{
        my $node = shift; # !!! This is a XML::Diver object !!!
        $node->dive($some_xpath);
    });
    

    # case of primitive array
    my @child_nodes = map {( $_->dive($some_xpath) )} @nodes;

## attr

Returns string value of attribute that specified.

## text

    my $str = $diver->text($xpath);

Returns string that contained in specified xpath element.

$xpath is default '/'.

## to\_string

Returns XML data as string.

# MOTIVE

I thought, I want a simple and easy XML parsing module. And its directivity are followings.

1\. Parsable with XPath

2\. Less Rules

3\. Depth Preference Parsing

4\. Iterative Processing to horizontally

5\. Lightweight

Some months ago, I wrote XML::XPath::Diver as a concept release of above. But, that inherits [XML::XPath](http://search.cpan.org/perldoc?XML::XPath). [XML::XPath](http://search.cpan.org/perldoc?XML::XPath) has been abandoned for a long time (Last update is 26 Jan. 2003). For this reason, I decided to remove its dependency.

Then, I wrote this module (without "XPath" string in dist-name!).

# PERFORMANCE

300% or over faster than XML::XPath::Diver. See [https://gist.github.com/ytnobody/10354590/](https://gist.github.com/ytnobody/10354590/)

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
