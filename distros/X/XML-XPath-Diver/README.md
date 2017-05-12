# NAME

XML::XPath::Diver - Dive XML with XML::XPath and first-class collection + alpha

# SYNOPSIS

    use XML::XPath::Diver;
    my $diver  = XML::XPath::Diver->new(...);  # same as XML::XPath;
    my $images = $diver->dive('//img');        # OMG! $images is Class::Builtin::Array class!
    my $urls   = $images->each(sub {
        my $node = shift;        # this is img element node, but XML::XPath::Diver object!
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

XML::XPath::Diver is XML data parse tool class that inherits [XML::XPath](http://search.cpan.org/perldoc?XML::XPath).

# METHODS

## dive

    my $nodes = $diver->dive($xpath); # first-class collection (Class::Builtin::Array object)
    my @nodes = $diver->dive($xpath); # primitive array

Returns Class::Builtin::Array object or primitive array. These contains XML::XPath::Diver objects.

For this reason, It can as following.

    # case of first-class collection
    my $child_nodes = $nodes->each(sub{
        my $node = shift; # !!! This is a XML::XPath::Diver object !!!
        $node->dive($some_xpath);
    });
    

    # case of primitive array
    my @child_nodes = map {( $_->dive($some_xpath) )} @nodes;

# attr

Returns string value of attribute that specified.

# text

    my $str = $diver->text($xpath);

Returns string that contained in specified xpath element.

$xpath is default '/'.

# to\_string

Returns XML data as string.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
