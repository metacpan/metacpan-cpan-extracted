package Text::Hogan;
$Text::Hogan::VERSION = '1.04';
use strict;
use warnings;

1;

__END__

=head1 NAME

Text::Hogan - A mustache templating engine statement-for-statement cloned from hogan.js

=head1 VERSION

version 1.04

=head1 DESCRIPTION

Text::Hogan is a statement-for-statement rewrite of
L<hogan.js|http://twitter.github.io/hogan.js/> in Perl.

It is a L<mustache|https://mustache.github.io/> templating engine which
supports pre-compilation of your templates into pure Perl code, which then
renders very quickly.

It passes the full L<mustache spec|https://github.com/mustache/spec>.

=head1 SYNOPSIS

    use Text::Hogan::Compiler;

    my $text = "Hello, {{name}}!";

    my $compiler = Text::Hogan::Compiler->new;
    my $template = $compiler->compile($text);

    say $template->render({ name => "Alex" });

See L<Text::Hogan::Compiler|Text::Hogan::Compiler> and
L<Text::Hogan::Template|Text::Hogan::Template> for more details.

=head1 TEMPLATE FORMAT

The template format is documented in
L<mustache(5)|https://mustache.github.io/mustache.5.html>.

=head1 SEE ALSO

=head2 hogan.js

L<hogan.js|http://twitter.github.io/hogan.js/> is the original library that
Text::Hogan is based on. It was written and is maintained by Twitter. It runs
on Node.js and pre-compiles templates to pure JavaScript.

=head2 Text::Caml

L<Text::Caml|Text::Caml> is a very good mustache-like templating engine, but
does not support pre-compilation.

=head2 Template::Mustache

L<Template::Mustache|Template::Mustache> is a module written by Pieter van de
Bruggen. Currently has no POD. Used by Dancer::Template::Mustache.

=head2 Mustache::Simple

I don't know anything about L<Mustache::Simple|Mustache::Simple>. It seems to
be available on search.cpan.org but not on metacpan.org which is a bad sign.

=head1 AUTHOR

Started out statement-for-statement copied from hogan.js by Twitter!

Alex Balhatchet (alex@balhatchet.net)

=cut
