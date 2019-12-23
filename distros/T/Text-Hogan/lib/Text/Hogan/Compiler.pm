package Text::Hogan::Compiler;
$Text::Hogan::Compiler::VERSION = '2.03';
use Text::Hogan::Template;

use 5.10.0;
use strict;
use warnings;

use Ref::Util qw( is_arrayref );
use Text::Trim 'trim';

my $r_is_whitespace = qr/\S/;
my $r_quot          = qr/"/;
my $r_newline       = qr/\n/;
my $r_cr            = qr/\r/;
my $r_slash         = qr/\\/;

my $linesep         = "\u{2028}";
my $paragraphsep    = "\u{2029}";
my $r_linesep       = qr/\Q$linesep\E/;
my $r_paragraphsep  = qr/\Q$paragraphsep\E/;

my %tags = (
    '#' => 1, '^' => 2, '<' => 3, '$' => 4,
    '/' => 5, '!' => 6, '>' => 7, '=' => 8, '_v' => 9,
    '{' => 10, '&' => 11, '_t' => 12
);

my $Template = Text::Hogan::Template->new();

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub scan {
    my ($self, $text_orig, $options) = @_;
    my $text = [ split //, $text_orig ];

    my $len = scalar(@$text);
    my ($IN_TEXT, $IN_TAG_TYPE, $IN_TAG) = (0, 1, 2);
    my $state = $IN_TEXT;
    my $tag_type = undef;
    my $tag = undef;
    my $buf = "";
    my @tokens;
    my $seen_tag = 0;
    my $i = 0;
    my $line_start = 0;
    my ($otag, $ctag) = ('{{', '}}');

    my $add_buf = sub {
        if (length $buf > 0) {
            push @tokens, { 'tag' => '_t', 'text' => $buf };
            $buf = "";
        }
    };

    my $line_is_whitespace = sub {
        my $is_all_whitespace = 1;
        for (my $j = $line_start; $j < @tokens; $j++) {
            $is_all_whitespace =
                ($tags{$tokens[$j]{'tag'}} < $tags{'_v'}) ||
                ($tokens[$j]{'tag'} eq '_t' && $tokens[$j]{'text'} !~ $r_is_whitespace);
            if (!$is_all_whitespace) {
                return 0;
            }
        }
        return $is_all_whitespace;
    };

    my $filter_line = sub {
        my ($have_seen_tag, $no_new_line) = @_;

        $add_buf->();

        if ($have_seen_tag && $line_is_whitespace->()) {
            for (my $j = $line_start, my $next; $j < @tokens; $j++) {
                if ($tokens[$j]{'text'}) {
                    if (($next = $tokens[$j+1]) && $next->{'tag'} eq '>') {
                        $next->{'indent'} = "".$tokens[$j]{'text'};
                    }
                    splice(@tokens,$j,1);
                }
            }
        }
        elsif (!$no_new_line) {
            push @tokens, { 'tag' => "\n" };
        }

        $seen_tag = 0;
        $line_start = scalar @tokens;
    };

    my $change_delimiters = sub {
        my ($text_orig, $index) = @_;
        my $text = join('', @$text_orig);

        my $close = '=' . $ctag;
        my $close_index = index($text, $close, $index);
        my $offset = index($text, '=', $index) + 1;
        my @delimiters = (
            split ' ', trim(
                # WARNING
                #
                # JavaScript substring and Perl substring functions differ!
                #
                # JavaScript's length parameter always goes from the beginning
                # of the string, whereas Perl's goes from the offset parameter!
                #
                # node> "{{=<% %>=}}".substring(3, 8)
                # '<% %>'
                #
                # perl> substr("{{=<% %>=}}", 3, 8);
                # <% %>=}}
                #
                #
                substr($text, $offset, $close_index - $offset)
            )
        );

        $otag = $delimiters[0];
        $ctag = $delimiters[-1];

        return $close_index + length($close) - 1;
    };

    if ($options->{'delimiters'}) {
        my @delimiters = split ' ', $options->{'delimiters'};
        $otag = $delimiters[0];
        $ctag = $delimiters[1];
    }

    for (my $i = 0; $i < $len; $i++) {
        if ($state eq $IN_TEXT) {
            if (tag_change($otag, $text, $i)) {
                --$i;
                $add_buf->();
                $state = $IN_TAG_TYPE;
            }
            else {
                if (char_at($text, $i) eq "\n") {
                    $filter_line->($seen_tag);
                }
                else {
                    $buf .= char_at($text, $i);
                }
            }
        }
        elsif ($state eq $IN_TAG_TYPE) {
            $i += length($otag) - 1;
            $i += 1 while($options->{'allow_whitespace_before_hashmark'} and (char_at($text, $i+1) eq ' '));
            $tag = $tags{char_at($text,$i + 1)};
            $tag_type = $tag ? char_at($text, $i + 1) : '_v';
            if ($tag_type eq '=') {
                $i = $change_delimiters->($text, $i);
                $state = $IN_TEXT;
            }
            else {
                if ($tag) {
                    $i++;
                }
                $state = $IN_TAG;
            }
            $seen_tag = $i;
        }
        else {
            if (tag_change($ctag, $text, $i)) {
                push @tokens, {
                    'tag'   => $tag_type,
                    'n'     => trim($buf),
                    'otag'  => $otag,
                    'ctag'  => $ctag,
                    'i'     => (($tag_type eq '/') ? $seen_tag - length($otag) : $i + length($ctag)),
                };
                $buf = "";
                $i += length($ctag) - 1;
                $state = $IN_TEXT;
                if ($tag_type eq '{') {
                    if ($ctag eq '}}') {
                        $i++;
                    }
                    else {
                        clean_triple_stache($tokens[-1]);
                    }
                }
            }
            else {
                $buf .= char_at($text, $i);
            }
        }
    }

    $filter_line->($seen_tag, 1);

    return \@tokens;
}

sub clean_triple_stache {
    my ($token) = @_;

    if (substr($token->{'n'}, length($token->{'n'}) - 1) eq '}') {
        $token->{'n'} = substr($token->{'n'}, 0, length($token->{'n'}) - 1);
    }

    return;
}

sub tag_change {
    my ($tag, $text, $index) = @_;

    if (char_at($text, $index) ne char_at($tag, 0)) {
        return 0;
    }

    for (my $i = 1, my $l = length($tag); $i < $l; $i++) {
        if (char_at($text, $index + $i) ne char_at($tag, $i)) {
            return 0;
        }
    }

    return 1;
}

my %allowed_in_super = (
    '_t' => 1,
    "\n" => 1,
    '$'  => 1,
    '/'  => 1,
);

sub build_tree {
    my ($tokens, $kind, $stack, $custom_tags) = @_;
    my (@instructions, $opener, $tail, $token);

    $tail = $stack->[-1];

    while (@$tokens > 0) {
        $token = shift @$tokens;

        if ($tail && ($tail->{'tag'} eq '<') && !$allowed_in_super{$token->{'tag'}}) {
            die "Illegal content in < super tag.";
        }

        if ($tags{$token->{'tag'}} && ($tags{$token->{'tag'}} <= $tags{'$'} || is_opener($token, $custom_tags))) {
            push @$stack, $token;
            $token->{'nodes'} = build_tree($tokens, $token->{'tag'}, $stack, $custom_tags);
        }
        elsif ($token->{'tag'} eq '/') {
            if (!@$stack) {
                die "Closing tag without opener: /$token->{'n'}";
            }
            $opener = pop @$stack;
            if ($token->{'n'} ne $opener->{'n'} && !is_closer($token->{'n'}, $opener->{'n'}, $custom_tags)) {
                die "Nesting error: $opener->{'n'} vs $token->{'n'}";
            }
            $opener->{'end'} = $token->{'i'};
            return \@instructions;
        }
        elsif ($token->{'tag'} eq "\n") {
            $token->{'last'} = (@$tokens == 0) || ($tokens->[0]{'tag'} eq "\n");
        }

        push @instructions, $token;
    }

    if (@$stack) {
        die "Missing closing tag: ", pop(@$stack)->{'n'};
    }

    return \@instructions;
}

sub is_opener {
    my ($token, $tags) = @_;

    for (my $i = 0, my $l = scalar(@$tags); $i < $l; $i++) {
        if ($tags->[$i]{'o'} eq $token->{'n'}) {
            $token->{'tag'} = '#';
            return 1;
        }
    }

    return 0;
}

sub is_closer {
    my ($close, $open, $tags) = @_;

    for (my $i = 0, my $l = scalar(@$tags); $i < $l; $i++) {
        if (($tags->[$i]{'c'} eq $close) && ($tags->[$i]{'o'} eq $open)) {
            return 1;
        }
    }

    return 0;
}

sub stringify_substitutions {
    my $obj = shift;

    my @items;
    for my $key (sort keys %$obj) {
        push @items, sprintf('"%s" => sub { my ($self,$c,$p,$t,$i) = @_; %s }', esc($key), $obj->{$key});
    }

    return sprintf("{ %s }", join(', ', @items));
}

sub stringify_partials {
    my $code_obj = shift;

    my @partials;
    for my $key (sort keys %{ $code_obj->{'partials'} }) {
        push @partials, sprintf('"%s" => { "name" => "%s", %s }', $key,
            esc($code_obj->{'partials'}{$key}{'name'}),
            stringify_partials($code_obj->{'partials'}{$key})
        );
    }

    return sprintf('"partials" => { %s }, "subs" => %s',
        join(',', @partials),
        stringify_substitutions($code_obj->{'subs'})
    );
}

sub stringify {
    my ($self,$code_obj, $text, $options) = @_;
    return sprintf('{ code => sub { my ($t,$c,$p,$i) = @_; %s }, %s }',
        wrap_main($code_obj->{'code'}),
        stringify_partials($code_obj)
    );
}

my $serial_no = 0;
sub generate {
    my ($self, $tree, $text, $options) = @_;

    $serial_no = 0;

    my $context = { 'code' => "", 'subs' => {}, 'partials' => {} };
    walk($tree, $context);

    if ($options->{'as_string'}) {
        return $self->stringify($context, $text, $options);
    }

    return $self->make_template($context, $text, $options);
}

sub wrap_main {
    my ($code) = @_;
    return sprintf('$t->b($i = $i || ""); %s return $t->fl();', $code);
}

sub make_template {
    my $self = shift;
    my ($code_obj, $text, $options) = @_;

    my $template = make_partials($code_obj);
    $template->{'code'} = eval sprintf("sub { my (\$t, \$c, \$p, \$i) = \@_; %s }", wrap_main($code_obj->{'code'}));
    return $Template->new($template, $text, $self, $options);
}

sub make_partials {
    my ($code_obj) = @_;

    my $key;
    my $template = {
        'subs'     => {},
        'partials' => $code_obj->{'partials'},
        'name'     => $code_obj->{'name'},
    };

    for my $key (sort keys %{ $template->{'partials'} }) {
        $template->{'partials'}{$key} = make_partials($template->{'partials'}{$key});
    }

    for my $key (sort keys %{ $code_obj->{'subs'} }) {
        $template->{'subs'}{$key} = eval "sub { my (\$t, \$c, \$p, \$t, \$i) = \@_; $code_obj->{subs}{$key}; }";
    }

    return $template;
}

sub esc {
    my $s = shift;

    # standard from hogan.js
    $s =~ s/$r_slash/\\\\/g;
    $s =~ s/$r_quot/\\\"/g;
    $s =~ s/$r_newline/\\n/g;
    $s =~ s/$r_cr/\\r/g;
    $s =~ s/$r_linesep/\\u2028/g;
    $s =~ s/$r_paragraphsep/\\u2029/g;

    # specific for Text::Hogan / Perl
    $s =~ s/\$/\\\$/g;
    $s =~ s/\@/\\@/g;
    $s =~ s/\%/\\%/g;

    return $s;
}

sub char_at {
    my ($text, $index) = @_;
    if (is_arrayref($text)) {
        return $text->[$index];
    }
    return substr($text, $index, 1);
}

sub choose_method {
    my ($s) = @_;
    return $s =~ m/[.]/ ? "d" : "f";
}

sub create_partial {
    my ($node, $context) = @_;

    my $prefix = "<" . ($context->{'prefix'} || "");
    my $sym = $prefix . $node->{'n'} . $serial_no++;
    $context->{'partials'}{$sym} = {
        'name'     => $node->{'n'},
        'partials' => {},
    };
    $context->{'code'} .= sprintf('$t->b($t->rp("%s",$c,$p,"%s"));',
        esc($sym),
        ($node->{'indent'} || "")
    );

    return $sym;
}

my %codegen = (
    '#' => sub {
        my ($node, $context) = @_;
        $context->{'code'} .= sprintf('if($t->s($t->%s("%s",$c,$p,1),$c,$p,0,%s,%s,"%s %s")) { $t->rs($c,$p,sub { my ($c,$p,$t) = @_;',
            choose_method($node->{'n'}),
            esc($node->{'n'}),
            @{$node}{qw/ i end otag ctag /},
        );
        walk($node->{'nodes'}, $context);
        $context->{'code'} .= '}); pop @$c;}';
    },
    '^' => sub {
        my ($node, $context) = @_;
        $context->{'code'} .= sprintf('if (!$t->s($t->%s("%s",$c,$p,1),$c,$p,1,0,0,"")){',
            choose_method($node->{'n'}),
            esc($node->{'n'})
        );
        walk($node->{'nodes'}, $context);
        $context->{'code'} .= "};";
    },
    '>' => \&create_partial,
    '<' => sub {
        my ($node, $context) = @_;
        my $ctx = { 'partials' => {}, 'code' => "", 'subs' => {}, 'in_partial' => 1 };
        walk($node->{'nodes'}, $ctx);
        my $template = $context->{'partials'}{create_partial($node, $context)};
        $template->{'subs'} = $ctx->{'subs'};
        $template->{'partials'} = $ctx->{'partials'};
    },
    '$' => sub {
        my ($node, $context) = @_;
        my $ctx = { 'subs' => {}, 'code' => "", 'partials' => $context->{'partials'}, 'prefix' => $node->{'n'} };
        walk($node->{'nodes'}, $ctx);
        $context->{'subs'}{$node->{'n'}} = $ctx->{'code'};
        if (!$context->{'in_partial'}) {
            $context->{'code'} += sprintf('$t->sub("%s",$c,$p,$i);',
                esc($node->{'n'})
            );
        }
    },
    "\n" => sub {
        my ($node, $context) = @_;
        $context->{'code'} .= twrite(sprintf('"\n"%s', ($node->{'last'} ? "" : ' . $i')));
    },
    '_v' => sub {
        my ($node, $context) = @_;
        $context->{'code'} .= twrite(sprintf('$t->v($t->%s("%s",$c,$p,0))',
            choose_method($node->{'n'}),
            esc($node->{'n'})
        ));
    },
    '_t' => sub {
        my ($node, $context) = @_;
        $context->{'code'} .= twrite(sprintf('"%s"', esc($node->{'text'})));
    },
    '{' => \&triple_stache,
    '&' => \&triple_stache,
);

sub triple_stache {
    my ($node, $context) = @_;
    $context->{'code'} .= sprintf('$t->b($t->t($t->%s("%s",$c,$p,0)));',
        choose_method($node->{'n'}),
        esc($node->{'n'})
    );
}

sub twrite { sprintf '$t->b(%s);', @_ }

sub walk {
    my ($nodelist, $context) = @_;

    for my $node (@$nodelist) {
        my $func = $codegen{$node->{'tag'}} or next;
        $func->($node, $context);
    }

    return $context;
}

sub parse {
    my ($self, $tokens, $text, $options) = @_;
    $options ||= {};
    return build_tree($tokens, "", [], $options->{'section_tags'} || []);
}

my %cache;

sub cache_key {
    my ($text, $options) = @_;
    return join('||', $text, !!$options->{'as_string'}, !!$options->{'numeric_string_as_string'}, !!$options->{'disable_lambda'}, ($options->{'delimiters'} || ""), ($options->{'allow_whitespace_before_hashmark'} || 0));
}

sub compile {
    my ($self, $text, $options) = @_;
    $options ||= {};

    $text //= "";

    my $key = cache_key($text, $options);
    my $template = $cache{$key};

    if ($template) {
        my $partials = $template->{'partials'};
        for my $name (sort keys %{ $template->{'partials'} }) {
            delete $partials->{$name}{'instance'};
        }
        return $template;
    }

    $template = $self->generate(
        $self->parse(
            $self->scan($text, $options), $text, $options
        ), $text, $options
    );

    return $cache{$key} = $template;
}

1;

__END__

=head1 NAME

Text::Hogan::Compiler - parse templates and output Perl code

=head1 VERSION

version 2.03

=head1 SYNOPSIS

    use Text::Hogan::Compiler;

    my $compiler = Text::Hogan::Compiler->new;

    my $text = "Hello, {{name}}!";

    my $tokens   = $compiler->scan($text);
    my $tree     = $compiler->parse($tokens, $text);
    my $template = $compiler->generate($tree, $text);

    say $template->render({ name => "Alex" });

=head1 METHODS

=head2 new

Takes nothing, returns a Compiler object.

    my $compiler = Text::Hogan::Compiler->new;

=cut

=head2 scan

Takes template text and returns an arrayref which is a list of tokens.

    my $tokens = $compiler->scan("Hello, {{name}}!");

Optionally takes a hashref with options. 'delimiters' is a string which
represents different delimiters, split by white-space. You should never
need to pass this directly, it it used to implement the in-template
delimiter-switching functionality.

    # equivalent to the above call with mustaches
    my $tokens = Text::Hogan::Compiler->new->scan("Hello, <% name %>!", { delimiters => "<% %>" });

'allow_whitespace_before_hashmark' is a boolean. If true,tags are allowed
to have space(s) between the delimiters and the opening sigil ('#', '/', '^', '<', etc.).

    my $tokens = Text::Hogan::Compiler->new->scan("Hello{{ # foo }}, again{{ / foo }}.", { allow_whitespace_before_hashmark => 1 });

=head2 parse

Takes the tokens returned by scan, along with the original text, and returns a
tree structure ready to be turned into Perl code.

    my $tree = $compiler->parse($tokens, $text);

Optionally takes a hashref that can have a key called "section_tags" which
should be an arrayref. I don't know what it does. Probably something internal
related to recursive calls that you don't need to worry about.

Note that a lot of error checking on your input gets done in this method, and
it is pretty much the only place exceptions might be thrown. Exceptions which
may be thrown include: "Closing tag without opener", "Missing closing tag",
"Nesting error" and "Illegal content in < super tag".

=head2 generate

Takes the parsed tree and the original text and returns a Text::Hogan::Template
object that you can call render on.

    my $template = $compiler->generate($tree, $text);

Optionally takes a hashref that can have

- a key "as_string". If that is passed then instead of getting a template object
back you get some stringified Perl code that you can cache somewhere on
disk as part of your build process.

    my $perl_code_as_string = $compiler->generate($tree, $text, { 'as_string' => 1 });

- a key "numeric_string_as_string". If that is passed output that looks like a number
is NOT converted into a number (ie "01234" is NOT converted to "1234")

    my $perl_code_as_string = $compiler->generate($tree, $text, { 'numeric_string_as_string' => 1 });


The options hashref can have other keys which will be passed to
Text::Hogan::Template::new among other places.

=head2 compile

Takes a template string and calls scan, parse and generate on it and returns
you the Text::Hogan::Template object.

    my $template = $compiler->compile("Hello, {{name}}!");

Also caches templates by a sensible cache key, which can be useful if you're
not stringifying and storing on disk or in memory anyway.

Optionally takes a hashref that will be passed on to scan, parse, and generate.

    my $perl_code_as_string = $compiler->compile(
        $text,
        {
            delimiters => "<% %>",
            as_string => 1,
            allow_whitespace_before_hashmark => 1,
        },
    );

=head1 ENCODING

As long as you are consistent with your use of encoding in your template
variables and your context variables, everything should just work. You can use
byte strings or character strings and you'll get what you expect.

The only danger would be if you use byte strings of a multi-byte encoding and
you happen to get a clash with your delimiters, eg. if your 4 byte kanji
character happens to contain the ASCII '<' and '%' characters next to each
other. I have no idea what the likelihood of that is, but hopefully if you're
working with non-ASCII character sets you're also using Perl's unicode
character strings features.

Compiling long character string inputs with Text::Hogan used to be extremely
slow but an optimisation added in version 2.00 has made the overhead much more
manageable.

=head1 AUTHORS

Started out statement-for-statement copied from hogan.js by Twitter!

Initial translation by Alex Balhatchet (alex@balhatchet.net)

Further improvements from:

Ed Freyfogle
Mohammad S Anwar
Ricky Morse
Jerrad Pierce
Tom Hukins
Tony Finch
Yanick Champoux

=cut
