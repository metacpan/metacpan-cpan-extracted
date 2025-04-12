package Text::MustacheTemplate::HTML;
use 5.022000;
use strict;
use warnings;

use Exporter 5.57 'import';

our @EXPORT_OK = qw/escape_html/;

use HTML::Escape ();

our $ESCAPE = \&HTML::Escape::escape_html;

sub escape_html { goto $ESCAPE }

1;

=encoding utf-8

=head1 NAME

Text::MustacheTemplate::HTML - HTML escape for Text::MustacheTemplate

=head1 SYNOPSIS

    use Text::MustacheTemplate;
    use Text::MustacheTemplate::HTML;

    # custom html escape
    local $Text::MustacheTemplate::HTML::ESCAPE = sub { ... };

    my @tokens = Text::MustacheTemplate->parse('* {{variable}}');

=head1 DESCRIPTION

Text::MustacheTemplate::HTML is a HTML escape for Mustache template.

This is low-level interface for Text::MustacheTemplate.
The APIs may be change without notice.

=head1 EXPORTS

=over 2

=item escape_html

By default, it is the C<escape_html> function of L<HTML::Escape> itself.
When C<$Text::MustacheTemplate::HTML::ESCAPE> is overwritten, call that instead of L<HTML::Escape>.

=back

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

