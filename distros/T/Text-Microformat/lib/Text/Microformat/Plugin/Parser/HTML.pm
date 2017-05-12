package Text::Microformat::Plugin::Parser::HTML;
use HTML::TreeBuilder;

sub html_to_tree {
    my $c = shift;
    my $content = shift;
    my $tree = HTML::TreeBuilder->new;
    while (my ($k,$v) = each %{$c->plugin_opts}) {
        $tree->$k($v) if $tree->can($k);
    }
    $tree->parse_content($content);
    return $tree;
}

sub parse {
    my $c = shift;
    if (!$c->tree and $c->opts->{content_type} =~ /html/i) {
    	$c->tree($c->html_to_tree($c->content));     
    }
    return $c->NEXT::parse(@_);
}

=head1 NAME

Text::Microformat::Plugin::Parser::HTML - HTML parser plugin for Text::Microformat

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
