package Text::Microformat::Plugin::Parser::RSS;
use strict;
use warnings;
use HTML::TreeBuilder;

# This plugin parses entity-encoded and CDATA 'description' elements from RSS,
# and inserts them into the tree.
sub parse {
    my $c = shift;
	$c->NEXT::parse(@_); # wait until the XML parser has run
	if ($c->tree and $c->opts->{content_type} =~ /xml/i and $c->tree->root->tag eq 'rss') {
		foreach my $e ($c->tree->look_down(_tag => $c->tag_regex('description'))) {
			my $subtree = $c->html_to_tree($e->as_trimmed_text);
			$e->delete_content;
			$e->push_content($subtree->root->clone);
			$subtree->delete;
		}
	}
}

=head1 NAME

Text::Microformat::Plugin::Parser::RSS - RSS parser plugin for Text::Microformat

=head1 SEE ALSO

L<Text::Microformat>

=head1 AUTHOR

Keith Grennan, C<< <kgrennan at cpan.org> >>

=head1 BUGS

Log bugs and feature requests here: L<http://code.google.com/p/ufperl/issues/list>

=head1 SUPPORT

Project homepage: L<http://code.google.com/p/ufperl/>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Keith Grennan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;