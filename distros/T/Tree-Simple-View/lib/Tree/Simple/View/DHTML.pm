
package Tree::Simple::View::DHTML;

use strict;
use warnings;

our $VERSION = '0.19';

use parent 'Tree::Simple::View::HTML';

use Tree::Simple::View::Exceptions;

use constant OPEN_TAG  => 1;
use constant CLOSE_TAG => 2;
use constant EXPANDED  => 3;

## private methods

sub _init {
    my ($self, @args) = @_;
    $self->SUPER::_init(@args);
    $self->{list_counter_id} = 0;
    ($self->{obj_id}) = ("$self" =~ /\((.*?)\)$/);
}

sub _createUID {
    my ($self, $tree) = @_;
    return $tree->getUID() if $self->{config}->{use_tree_uids};
    $self->{list_counter_id}++;
    return join "_" => ($self->{obj_id}, $self->{list_counter_id});
}

## public methods

sub expandPathSimple  {
    my ($self, $tree, $current_path, @path) = @_;
    my @results = ("<UL>");
    my $root_depth = $tree->getDepth() + 1;
    my $last_depth = -1;
    my $traversal_sub = sub {
        my ($t) = @_;
        my $display_style = "none";
        if (defined $current_path && $self->_compareNodeToPath($current_path, $t)) {
            $display_style = "block";
            $current_path = shift @path;
        }
        my $current_depth = $t->getDepth();
        push @results => ("</UL>" x ($last_depth - $current_depth)) if ($last_depth > $current_depth);
        unless ($t->isLeaf()) {
            my $uid = $self->_createUID($t);
            push @results => ("<LI><A HREF='javascript:void(0);' onClick='toggleList(\"$uid\")'>" .
                                $t->getNodeValue() . "</A></LI>");
            push @results => "<UL ID='$uid' STYLE='display: $display_style;'>";
        }
        else {
            push @results => ("<LI>" . $t->getNodeValue() . "</LI>");
        }
        $last_depth = $current_depth;
    };
    $traversal_sub->($self->{tree}) if $self->{include_trunk};
    $self->{tree}->traverse($traversal_sub);
    $last_depth -= $root_depth;
    $last_depth++ if $self->{include_trunk};
    push @results => ("</UL>" x ($last_depth + 1));

    return (join "\n" => @results);
}

sub expandPathComplex {
    my ($self, $tree, $config, $current_path, @path) = @_;

    my ($list_func, $list_item_func) = $self->_processConfig($config);

    my @results = $list_func->(OPEN_TAG);
    my $root_depth = $tree->getDepth() + 1;
    my $last_depth = -1;
    my $traversal_sub = sub {
        my ($t) = @_;
        my $display_style = "none";
        if (defined $current_path && $self->_compareNodeToPath($current_path, $t)) {
            $display_style = "block";
            $current_path = shift @path;
        }
        my $current_depth = $t->getDepth();
        push @results => ($list_func->(CLOSE_TAG) x ($last_depth - $current_depth)) if ($last_depth > $current_depth);
        unless ($t->isLeaf()) {
            my $uid = $self->_createUID($t);
            push @results => ($list_item_func->($t, EXPANDED, $uid));
            push @results => $list_func->(OPEN_TAG, $uid, $display_style);
        }
        else {
            push @results => ($list_item_func->($t));
        }
        $last_depth = $current_depth;
    };
    $traversal_sub->($self->{tree}) if $self->{include_trunk};
    $self->{tree}->traverse($traversal_sub);
    $last_depth -= $root_depth;
    $last_depth++ if $self->{include_trunk};
    push @results => ($list_func->(CLOSE_TAG) x ($last_depth + 1));
    return (join "\n" => @results);
}

sub expandAllSimple  {
    my ($self) = @_;
    my @results = ("<UL>");
    my $root_depth = $self->{tree}->getDepth() + 1;
    my $last_depth = -1;
    my $traversal_sub = sub {
        my ($t) = @_;
        my $current_depth = $t->getDepth();
        push @results => ("</UL>" x ($last_depth - $current_depth)) if ($last_depth > $current_depth);
        unless ($t->isLeaf()) {
            my $uid = $self->_createUID($t);
            push @results => ("<LI><A HREF='javascript:void(0);' onClick='toggleList(\"$uid\")'>" .
                                $t->getNodeValue() . "</A></LI>");
            push @results => "<UL ID='$uid'>";
        }
        else {
            push @results => ("<LI>" . $t->getNodeValue() . "</LI>");
        }
        $last_depth = $current_depth;
    };
    $traversal_sub->($self->{tree}) if $self->{include_trunk};
    $self->{tree}->traverse($traversal_sub);
    $last_depth -= $root_depth;
    $last_depth++ if $self->{include_trunk};
    push @results => ("</UL>" x ($last_depth + 1));
    return (join "\n" => @results);
}

sub expandAllComplex {
    my ($self, $config) = @_;

    my ($list_func, $list_item_func) = $self->_processConfig($config);

    my @results = $list_func->(OPEN_TAG);
    my $root_depth = $self->{tree}->getDepth() + 1;
    my $last_depth = -1;
    my $traversal_sub = sub {
        my ($t) = @_;
        my $current_depth = $t->getDepth();
        push @results => ($list_func->(CLOSE_TAG) x ($last_depth - $current_depth)) if ($last_depth > $current_depth);
        unless ($t->isLeaf()) {
            my $uid = $self->_createUID($t);
            push @results => ($list_item_func->($t, EXPANDED, $uid));
            push @results => $list_func->(OPEN_TAG, $uid);
        }
        else {
            push @results => ($list_item_func->($t));
        }
        $last_depth = $current_depth;
    };
    $traversal_sub->($self->{tree}) if $self->{include_trunk};
    $self->{tree}->traverse($traversal_sub);
    $last_depth -= $root_depth;
    $last_depth++ if $self->{include_trunk};
    push @results => ($list_func->(CLOSE_TAG) x ($last_depth + 1));
    return (join "\n" => @results);
}

# code strings

use constant LIST_FUNCTION_CODE_STRING => q|
    sub {
        my ($tag_type, $list_id, $display_style) = @_;
        # allow this to be found quickly
        return "</${list_type}>" if ($tag_type == CLOSE_TAG);
        # test the most functional first
        if ($tag_type == OPEN_TAG && $list_id && $display_style) {
            my $temp_list_css;
            if ($list_css && $list_css !~ /CLASS/) {
                # in case someone has already set the list_css
                # property, we need to add out display property
                # to it, so we need to do a little text mangling
                $temp_list_css = $list_css;
                chop($temp_list_css);
                $temp_list_css .= " display: $display_style;'";
            }
            elsif ($list_css) {
                $temp_list_css = "${list_css} STYLE='display: $display_style;'"
            }
            else {
                $temp_list_css = " STYLE='display: $display_style;'"
            }
            return "<${list_type}${temp_list_css} ID='${list_id}'>"
        }
        # next...
        return "<${list_type}${list_css} ID='${list_id}'>"
            if ($tag_type == OPEN_TAG && $list_id);
        # and finally, something that does nothing really
        return "<${list_type}${list_css}>" if ($tag_type == OPEN_TAG);
    }
|;

sub _buildListItemFunction {
    my ($self, %config) = @_;
    # process the configuration directives
    my ($list_item_css, $expanded_item_css, $node_formatter) = $self->_processListItemConfig(%config);

    my $link_css = "";
    if (exists $config{link_css}) {
        $link_css = " STYLE='" . $config{link_css}. "'";
    }
    elsif (exists $config{link_css_class}) {
        $link_css = " CLASS='" . $config{link_css_class} . "'";
    }

    my $form_element_formatter;
    if (exists $config{form_element_formatter}) {
        $form_element_formatter = $config{form_element_formatter};
    }
    else {
        if (exists $config{radio_button}) {
            $form_element_formatter = $self->_makeRadioButtonFormatter($config{radio_button});
        }
        elsif (exists $config{checkbox}) {
            $form_element_formatter = $self->_makeCheckBoxFormatter($config{checkbox});
        }
    }

    # now compile the subroutine in the current environment
    return eval $self->LIST_ITEM_FUNCTION_CODE_STRING;
}

sub _makeRadioButtonFormatter {
    my ($self, $radio_button_id) = @_;
    return sub {
        my ($t) = @_;
        return "<INPUT TYPE='radio' NAME='$radio_button_id' VALUE='" . $t->getUID() . "'>";
    }
}

sub _makeCheckBoxFormatter {
    my ($self, $checkbox_id) = @_;
    return sub {
        my ($t) = @_;
        return "<INPUT TYPE='checkbox' NAME='$checkbox_id' VALUE='" . $t->getUID() . "'>";
    }
}

use constant LIST_ITEM_FUNCTION_CODE_STRING  => q|;
    sub {
        my ($t, $is_expanded, $tree_id) = @_;
        my $item_css = $list_item_css;
        if ($is_expanded) {
            $item_css = $expanded_item_css if $expanded_item_css;
            return "<LI${item_css}>" .
                        (($form_element_formatter) ? $form_element_formatter->($t) : "") .
                    "<A${link_css} HREF='javascript:void(0);' onClick='toggleList(\"${tree_id}\")'>" .
                            (($node_formatter) ? $node_formatter->($t) : $t->getNodeValue()) .
                    "</A></LI>";
        }
        return "<LI${item_css}>" .
                    (($form_element_formatter) ? $form_element_formatter->($t) : "") .
                    (($node_formatter) ? $node_formatter->($t) : $t->getNodeValue()) .
                "</LI>";
    }
|;

use constant javascript => q|
<SCRIPT LANGUAGE="javascript">
function toggleList(tree_id) {
    var element = document.getElementById(tree_id);
    if (element) {
        if (element.style.display == 'none') {
            element.style.display = 'block';
        }
        else {
            element.style.display = 'none';
        }
    }
}
</SCRIPT>
|;

1;

__END__

=pod

=head1 NAME

Tree::Simple::View::DHTML - A class for viewing Tree::Simple hierarchies in DHTML

=head1 SYNOPSIS

  use Tree::Simple::View::DHTML;

  ## a simple example

  # use the defaults (an unordered list with no CSS)
  my $tree_view = Tree::Simple::View::DHTML->new($tree);

  ## more complex examples

  # using the CSS properties
  my $tree_view = Tree::Simple::View::DHTML->new($tree => (
                                list_type  => "ordered",
                                list_css => "list-style: circle;",
                                list_item_css => "font-family: courier;",
                                expanded_item_css => "font-family: courier; font-weight: bold",
                                link_css => "text-decoration: none;"
                                ));

  # using the CSS classes
  my $tree_view = Tree::Simple::View::DHTML->new($tree => (
                                list_css_class => "myListClass",
                                list_item_css_class => "myListItemClass",
                                expanded_item_css_class => "myExpandedListItemClass",
                                link_css_class => "myListItemLinkClass"
                                ));

  # mixing the CSS properties and CSS classes
  my $tree_view = Tree::Simple::View::DHTML->new($tree => (
                                list_css => "list-style: circle;",
                                list_item_css => "font-family: courier;",
                                expanded_item_css_class => "myExpandedListItemClass",
                                link_css_class => "myListItemLinkClass"
                                # format complex nodes with a function
                                node_formatter => sub {
                                    my ($tree) = @_;
                                    return "<B>" . $tree->getNodeValue()->description() . "</B>";
                                    },
                                # add a radio button element to the tree
                                # with the name of 'tree_id'
                                radio_button => 'tree_id'
                                ));

  # print out the javascript nessecary for the DHTML
  # functionality of this tree
  print $tree_view->javascript();

  # print out the tree fully expanded
  print $tree_view->expandAll();

  # print out the tree expanded along a given path (see below for details)
  print $tree_view->expandPath("Root", "Child", "GrandChild");

=head1 DESCRIPTION

This is a class for use with Tree::Simple object hierarchies to serve as a means of
displaying them in DHTML. It is the "View", while the Tree::Simple object hierarchy
would be the "Model" in your standard Model-View-Controller paradigm.

This class outputs fairly vanilla HTML, which is augmented with CSS and javascript
to produce an expanding and collapsing tree widget. The javascript code used is
intentionally very simple, and makes no attempt to do anything but expand and collapse
the tree. The javascript code is output seperately from the actual tree, and so it
can be overridden to implement more complex behaviors if you like. see the documentation
for the C<javascript> method for more details.

It should be noted that each expandable/collapsable level is tagged with a unique ID
which is constructed from the object instances hex-address and a counter. This means
if you call C<expandAll> and/or C<expandPath> on the same object in the same output,
you will have generated two totally different trees, which just happend to look
exactly alike, but will behave independently of one another. However, abuse of this
"feature" is not recommended, as I am cannot guarentee it will always be this way.

=head1 METHODS

=over 4

=item B<new ($tree, %configuration)>

Accepts a C<$tree> argument of a Tree::Simple object (or one derived from Tree::Simple),
if C<$tree> is not a Tree::Simple object, and exception is thrown. This C<$tree> object
does not need to be a ROOT, you can start at any level of the tree you desire. The
options in the C<%config> argument are as follows:

=over 4

=item I<list_type>

This can be either 'ordered' or 'unordered', which will produce ordered and unordered
lists respectively. The default is 'unordered'.

=item I<list_css>

This can be a string of CSS to be applied to the list tag (C<UL> or C<OL> depending
    upon the I<list_type> option). This option and the I<list_css_class> are mutually
    exclusive, and this option will override in a conflict.

=item I<list_css_class>

This can be a CSS class name which is applied to the list tag (C<UL> or C<OL>
    depending upon the I<list_type> option). This option and the I<list_css> are
    mutually exclusive, and the I<list_css> option will override in a conflict.

=item I<list_item_css>

This can be a string of CSS to be applied to the list item tag (C<LI>). This option
and the I<list_item_css_class> are mutually exclusive, and this option will
override in a conflict.

=item I<list_item_css_class>

This can be a CSS class name which is applied to the list item tag (C<LI>). This
option and the I<list_item_css> are mutually exclusive, and the I<list_item_css>
option will override in a conflict.

=item I<expanded_item_css>

This can be a string of CSS to be applied to the list item tag (C<LI>) if it has
an expanded set of children. This option and the I<expanded_item_css_class> are
mutually exclusive, and this option will override in a conflict.

=item I<expanded_item_css_class>

This can be a CSS class name which is applied to the list item tag (C<LI>) if it
has an expanded set of children. This option and the I<expanded_item_css> are
mutually exclusive, and the I<expanded_item_css> option will override in a conflict.

=item I<link_css_class>

This can be a string of CSS to be applied to the link (C<A> tag) which serves as
the handler to drive the expansion and collapsing of the tree. This option and
the I<link_css_class_class> are mutually exclusive, and this option will override
in a conflict.

=item I<link_css_class_class>

This can be a CSS class name which is applied to the link (C<A> tag) which serves
as the handler to drive the expansion and collapsing of the tree. This option and
the I<link_css_class> are mutually exclusive, and the I<link_css_class> option
will override in a conflict.

=item I<node_formatter>

This can be a CODE reference which will be given the current tree object as its
only argument. The output of this subroutine will be placed within the link tags
(C<A>) which themselves are within the list item tags (C<LI>). This option can
be used to implement; custom formatting of the node, handling of complex node
objects.

=item I<radio_button>

This will create a radio button for each node of the tree with the C<INPUT>
C<NAME> attribute being the value of this attribute. This is basically a 'macro'
for the I<form_element_formatter>.

=item I<checkbox>

This will create a checkbox for each node of the tree with the C<INPUT> C<NAME>
attribute being the value of this attribute. This is basically a 'macro' for
the I<form_element_formatter>.

=item I<form_element_formatter>

This can be a CODE reference which will be given the current tree object as its
only argument. The output of this subroutine will be placed after the list
item (C<LI>) tags, and if applicable, before the the link tag (C<A>). This
option can be used to add a form element such a radio button or checkbox to
each element of the tree, which is useful when creating selection widgets.

=item I<use_tree_uids>

This item allows you to bypass the built in unique ID generation feature of
this module and instead use the unique ID from the Tree::Simple object itself
(gotten by calling the method C<getUID>).

=back

=item B<getTree>

A basic accessor to reach the underlying tree object.

=item B<getConfig>

A basic accessor to reach the underlying configuration hash.

=item B<includeTrunk ($boolean)>

This controls the getting and setting (through the optional C<$boolean>
argument) of the option to include the tree's trunk in the output. Many times,
the trunk is not actually part of the tree, but simply a root from which
all the branches spring. However, on occasion, it might be nessecary to
view a sub-tree, in which case, the trunk is likely intended to be part
of the output. This option defaults to off.

=item B<setPathComparisonFunction ($CODE)>

This takes a C<$CODE> reference, which can be used to add custom path
comparison features to Tree::Simple::View. The function will get two
arguments, the first is the C<$current_path>, the second is the C<$current_tree>.
When using C<expandPath>, it may sometimes be nessecary to be able to control
the comparison of the path values. For instance, your node may be an object
and need a specific method called to match the path against.

=item B<expandPath (@path)>

This method will return a string of HTML which will represent your tree
expanded along the given C<@path>. This is best shown visually. Given
this tree:

  Tree-Simple-View
      lib
          Tree
              Simple
                  View.pm
                  View
                      HTML.pm
                      DHTML.pm
      Makefile.PL
      MANIFEST
      README
      Changes
      t
          10_Tree_Simple_View_test.t
          20_Tree_Simple_View_HTML_test.t
          30_Tree_Simple_View_DHTML_test.t

And given this path:

  Tree-Simple-View, lib, Tree, Simple

Your display would like something like this:

  Tree-Simple-View
      lib
          Tree
              Simple
                  View.pm
                  View
      Makefile.PL
      MANIFEST
      README
      Changes
      t

As you can see, the given path has been expanded, but no other sub-trees
are shown. However, the other sub-trees are actually there, and can be
expanded or collapsed by clicking on them. It is worth noting that this
method will actually output the entire tree, but with only the expanded
path shown.

It should be noted that this method actually calls either the C<expandPathSimple>
or C<expandPathComplex> method depending upon the C<%config> argument in the
constructor. See their documenation for details.

=item B<expandPathSimple ($tree, @path)>

If no C<%config> argument is given in the constructor, then this method is
called by C<expandPath>. This method is optimized since it does not need
to process any configuration, but just as the name implies, it's output
is simple.

This method can also be used for another purpose, which is to bypass a
previously specified configuration and use the base "simple" configuration
instead.

=item B<expandPathComplex ($tree, $config, @path)>

If a C<%config> argument is given in the constructor, then this method
is called by C<expandPath>. This method has been optimized to be used with
configurations, and will actually custom compile code (using C<eval>) to
speed up the generation of the output.

This method can also be used for another purpose, which is to bypass a
previously specified configuration and use the configuration specified
(as a HASH reference) in the C<$config> parameter.

=item B<expandAll>

This method will return a string of HTML which will represent your tree
completely expanded. You can then collapse and re-expand any items at
will though the DHTML functionality.

It should be noted that this method actually calls either the C<expandAllSimple>
or C<expandAllComplex> method depending upon the C<%config> argument in
the constructor.

=item B<expandAllSimple>

If no C<%config> argument is given in the constructor, then this method is
called by C<expandAll>. This method too is optimized since it does not need
to process any configuration.

This method as well can also be used to bypass a previously specified
configuration and use the base "simple" configuration instead.

=item B<expandAllComplex ($config)>

If a C<%config> argument is given in the constructor, then this method
is called by C<expandAll>. This method too has been optimized to be used
with configurations, and will also custom compile code (using C<eval>) to
speed up the generation of the output.

Just as with C<expandPathComplex>, this method can be to bypass a previously
specified configuration and use the configuration specified (as a HASH
reference) in the C<$config> parameter.

=item B<javascript>

This method is used to output an HTML C<SCRIPT> tag which contains the
javascript used to drive the DHTML in this widget. This is not done
automatically, so that one can optionally override my javascript and
implement a more complex handler to serve their purposes. The javascript
function returned is documented here:

=over 5

=item B<toggleTree (tree_id)>

The DOM element whose ID attribute corresponds to the given C<tree_id> is found.
If its CSS I<display> property is set to 'none', it is then set to 'block'.
If its CSS I<display> property is not set to 'none', it is then set to 'none'.
This controls the basic expansion and collapsing of the tree widget.

=back

=back

=head1 TO DO

=over 4

=item B<depth-based css>

See this item in the Tree::Simple::View::HTML documentation, since
Tree::Simple::View::DHTML actually is a subclass of Tree::Simple::View::HTML,
this functionality would be inherited.

=item B<optional javascript handler override>

This class implements the javascript handler for the DHTML functionally as an
anchor tag (C<A>) whose CSS properties can be set, but nothing more. I would
like to allow this to be overridden, but I want to do it in the correct way
which will eliminate issues with the DHTML. I am still giving this some thought.

=item B<expand/collapse all javascript function>

An available javascript function which would expand or collapse the entire
tree. This is would be pretty reasonable to implement since I know all the
C<tree_id>s I have created. However, on large trees, this would inadvisable
as it would probably bring the browser to a screaching halt.

=back

=head1 BROWSER SUPPORT

While DHTML in the early days (1998-2001) was a bug ridden cross-platform/cross-browser
nightmare (believe me I know, I made my living doing it back then). Recent browsers
(5.0 and above) tend to be able to handle a decent sub-set of CSS1 and the javascript
DOM objects to drive it. This module output DHTML which should work on any browser
that supports CSS1, in particular the 'display' property, and DOM1, in particular the
'getElementById' method and the ability to manipulate the CSS 'display' property of
the object that DOM method would return.

But in case you don't care that much about CSS1 and the DOM, and just want to know
what browsers/platforms this supports, here is the list (of ones I have tested so far):

=over 4

=item B<Mac OS X>

=over 4

=item Safari 1.2 and above

=item OmniWeb 4.5

=item Internet Explorer 5.2 and above

=item Netscape 7.1

=back

=item B<Windows XP Pro>

=over 4

=item Mozilla 1.7

=item Firefox

=item Internet Explorer 6.0

=item Netscape 7.1

=back

=back

This is also known to gracefully degrade in Netscape 4.7.2, in which it just shows
the entire expanded tree.

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be
sure to fix it.

=head1 CODE COVERAGE

See the CODE COVERAGE section of Tree::Simple::View for details.

=head1 ACKNOWLEDGEMENTS

=over 4

=item Thanks to Brett Nuske for the idea of the I<use_tree_uid> configuration parameter.

=back

=head1 SEE ALSO

A great CSS reference can be found at:

    http://www.htmlhelp.com/reference/css/

Information specifically about CSS for HTML lists is at:

    http://www.htmlhelp.com/reference/css/classification/list-style.html

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

