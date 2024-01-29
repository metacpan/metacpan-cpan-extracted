use strict;
use warnings;

use Test::More 0.98;
use Test::Base::Less;
use JSON::PP qw/decode_json/;

use Text::MustacheTemplate;
use Text::MustacheTemplate::HTML;

local $Text::MustacheTemplate::LAMBDA_TEMPLATE_RENDERING = 1;

# emulate CGI.escapeHTML https://docs.ruby-lang.org/ja/latest/method/CGI/s/escapeHTML.html
local $Text::MustacheTemplate::HTML::ESCAPE = do {
    my %m = (
        q!'! => '&#39;',
        q!&! => '&amp;',
        q!"! => '&quot;',
        q!<! => '&lt;',
        q!>! => '&gt;',
    );
    sub {
        my $text = shift;
        $text =~ s/(['&"<>])/$m{$1}/mego;
        return $text;
    };
};

subtest parse => sub {
    for my $block (blocks) {
        my $case = decode_json($block->case);
        local %Text::MustacheTemplate::REFERENCES = exists $case->{partials} ? (
            map { $_ => Text::MustacheTemplate->parse($case->{partials}->{$_}) } keys %{$case->{partials}}
        ) : ();
        my $template = Text::MustacheTemplate->parse($case->{template});
        my $result = $template->(expand_lambda($case->{data}));
        is $result, $case->{expected}, $block->name;
    }
};

subtest render => sub {
    for my $block (blocks) {
        my $case = decode_json($block->case);
        local %Text::MustacheTemplate::REFERENCES = exists $case->{partials} ? (
            map { $_ => Text::MustacheTemplate->parse($case->{partials}->{$_}) } keys %{$case->{partials}}
        ) : ();
        my $result = Text::MustacheTemplate->render($case->{template}, expand_lambda($case->{data}));
        is $result, $case->{expected}, $block->name;
    }
};

sub expand_lambda {
    my $data = shift;
    if (ref $data eq 'HASH') {
        if (exists $data->{__tag__} && $data->{__tag__} eq 'code') {
            return eval $data->{perl};
        } else {
            my %h;
            for my $key (keys %$data) {
                $h{$key} = expand_lambda($data->{$key});
            }
            return \%h;
        }
    } elsif (ref $data eq 'ARRAY') {
        return [map { expand_lambda($_) } @$data];
    } else {
        return $data;
    }
}

done_testing;
__DATA__
=== Interpolation: A lambda's return value should be interpolated.
--- case
{
   "data" : {
      "lambda" : {
         "__tag__" : "code",
         "clojure" : "(fn [] \"world\")",
         "go" : "func() string { return \"world\" }",
         "js" : "function() { return \"world\" }",
         "lisp" : "(lambda () \"world\")",
         "perl" : "sub { \"world\" }",
         "php" : "return \"world\";",
         "pwsh" : "\"world\"",
         "python" : "lambda: \"world\"",
         "raku" : "sub { \"world\" }",
         "ruby" : "proc { \"world\" }"
      }
   },
   "expected" : "Hello, world!",
   "template" : "Hello, {{lambda}}!"
}

=== Interpolation - Expansion: A lambda's return value should be parsed.
--- case
{
   "data" : {
      "lambda" : {
         "__tag__" : "code",
         "clojure" : "(fn [] \"{{planet}}\")",
         "go" : "func() string { return \"{{planet}}\" }",
         "js" : "function() { return \"{{planet}}\" }",
         "lisp" : "(lambda () \"{{planet}}\")",
         "perl" : "sub { \"{{planet}}\" }",
         "php" : "return \"{{planet}}\";",
         "pwsh" : "\"{{planet}}\"",
         "python" : "lambda: \"{{planet}}\"",
         "raku" : "sub { q+{{planet}}+ }",
         "ruby" : "proc { \"{{planet}}\" }"
      },
      "planet" : "world"
   },
   "expected" : "Hello, world!",
   "template" : "Hello, {{lambda}}!"
}

=== Interpolation - Alternate Delimiters: A lambda's return value should parse with the default delimiters.
--- case
{
   "data" : {
      "lambda" : {
         "__tag__" : "code",
         "clojure" : "(fn [] \"|planet| => {{planet}}\")",
         "go" : "func() string { return \"|planet| => {{planet}}\" }",
         "js" : "function() { return \"|planet| => {{planet}}\" }",
         "lisp" : "(lambda () \"|planet| => {{planet}}\")",
         "perl" : "sub { \"|planet| => {{planet}}\" }",
         "php" : "return \"|planet| => {{planet}}\";",
         "pwsh" : "\"|planet| => {{planet}}\"",
         "python" : "lambda: \"|planet| => {{planet}}\"",
         "raku" : "sub { q+|planet| => {{planet}}+ }",
         "ruby" : "proc { \"|planet| => {{planet}}\" }"
      },
      "planet" : "world"
   },
   "expected" : "Hello, (|planet| => world)!",
   "template" : "{{= | | =}}\nHello, (|&lambda|)!"
}

=== Interpolation - Multiple Calls: Interpolated lambdas should not be cached.
--- case
{
   "data" : {
      "lambda" : {
         "__tag__" : "code",
         "clojure" : "(def g (atom 0)) (fn [] (swap! g inc))",
         "go" : "func() func() int { g := 0; return func() int { g++; return g } }()",
         "js" : "function() { return (g=(function(){return this})()).calls=(g.calls||0)+1 }",
         "lisp" : "(let ((g 0)) (lambda () (incf g)))",
         "perl" : "do { my $calls = 0; sub { ++$calls } }",
         "php" : "global $calls; return ++$calls;",
         "pwsh" : "if (($null -eq $script:calls) -or ($script:calls -ge 3)){$script:calls=0}; ++$script:calls; $script:calls",
         "python" : "lambda: globals().update(calls=globals().get(\"calls\",0)+1) or calls",
         "raku" : "sub { state $calls += 1 }",
         "ruby" : "proc { $calls ||= 0; $calls += 1 }"
      }
   },
   "expected" : "1 == 2 == 3",
   "template" : "{{lambda}} == {{{lambda}}} == {{lambda}}"
}

=== Escaping: Lambda results should be appropriately escaped.
--- case
{
   "data" : {
      "lambda" : {
         "__tag__" : "code",
         "clojure" : "(fn [] \">\")",
         "go" : "func() string { return \">\" }",
         "js" : "function() { return \">\" }",
         "lisp" : "(lambda () \">\")",
         "perl" : "sub { \">\" }",
         "php" : "return \">\";",
         "pwsh" : "\">\"",
         "python" : "lambda: \">\"",
         "raku" : "sub { \">\" }",
         "ruby" : "proc { \">\" }"
      }
   },
   "expected" : "<&gt;>",
   "template" : "<{{lambda}}{{{lambda}}}"
}

=== Section: Lambdas used for sections should receive the raw section string.
--- case
{
   "data" : {
      "lambda" : {
         "__tag__" : "code",
         "clojure" : "(fn [text] (if (= text \"{{x}}\") \"yes\" \"no\"))",
         "go" : "func(text string) string { if text == \"{{x}}\" { return \"yes\" } else { return \"no\" } }",
         "js" : "function(txt) { return (txt == \"{{x}}\" ? \"yes\" : \"no\") }",
         "lisp" : "(lambda (text) (if (string= text \"{{x}}\") \"yes\" \"no\"))",
         "perl" : "sub { $_[0] eq \"{{x}}\" ? \"yes\" : \"no\" }",
         "php" : "return ($text == \"{{x}}\") ? \"yes\" : \"no\";",
         "pwsh" : "if ($args[0] -eq \"{{x}}\") {\"yes\"} else {\"no\"}",
         "python" : "lambda text: text == \"{{x}}\" and \"yes\" or \"no\"",
         "raku" : "sub { $^section eq q+{{x}}+ ?? \"yes\" !! \"no\" }",
         "ruby" : "proc { |text| text == \"{{x}}\" ? \"yes\" : \"no\" }"
      },
      "x" : "Error!"
   },
   "expected" : "<yes>",
   "template" : "<{{#lambda}}{{x}}{{/lambda}}>"
}

=== Section - Expansion: Lambdas used for sections should have their results parsed.
--- case
{
   "data" : {
      "lambda" : {
         "__tag__" : "code",
         "clojure" : "(fn [text] (str text \"{{planet}}\" text))",
         "go" : "func(text string) string { return text + \"{{planet}}\" + text }",
         "js" : "function(txt) { return txt + \"{{planet}}\" + txt }",
         "lisp" : "(lambda (text) (format nil \"~a{{planet}}~a\" text text))",
         "perl" : "sub { $_[0] . \"{{planet}}\" . $_[0] }",
         "php" : "return $text . \"{{planet}}\" . $text;",
         "pwsh" : "\"$($args[0]){{planet}}$($args[0])\"",
         "python" : "lambda text: \"%s{{planet}}%s\" % (text, text)",
         "raku" : "sub { $^section ~ q+{{planet}}+ ~ $^section }",
         "ruby" : "proc { |text| \"#{text}{{planet}}#{text}\" }"
      },
      "planet" : "Earth"
   },
   "expected" : "<-Earth->",
   "template" : "<{{#lambda}}-{{/lambda}}>"
}

=== Section - Alternate Delimiters: Lambdas used for sections should parse with the current delimiters.
--- case
{
   "data" : {
      "lambda" : {
         "__tag__" : "code",
         "clojure" : "(fn [text] (str text \"{{planet}} => |planet|\" text))",
         "go" : "func(text string) string { return text + \"{{planet}} => |planet|\" + text }",
         "js" : "function(txt) { return txt + \"{{planet}} => |planet|\" + txt }",
         "lisp" : "(lambda (text) (format nil \"~a{{planet}} => |planet|~a\" text text))",
         "perl" : "sub { $_[0] . \"{{planet}} => |planet|\" . $_[0] }",
         "php" : "return $text . \"{{planet}} => |planet|\" . $text;",
         "pwsh" : "\"$($args[0]){{planet}} => |planet|$($args[0])\"",
         "python" : "lambda text: \"%s{{planet}} => |planet|%s\" % (text, text)",
         "raku" : "sub { $^section ~ q+{{planet}} => |planet|+ ~ $^section }",
         "ruby" : "proc { |text| \"#{text}{{planet}} => |planet|#{text}\" }"
      },
      "planet" : "Earth"
   },
   "expected" : "<-{{planet}} => Earth->",
   "template" : "{{= | | =}}<|#lambda|-|/lambda|>"
}

=== Section - Multiple Calls: Lambdas used for sections should not be cached.
--- case
{
   "data" : {
      "lambda" : {
         "__tag__" : "code",
         "clojure" : "(fn [text] (str \"__\" text \"__\"))",
         "go" : "func(text string) string { return \"__\" + text + \"__\" }",
         "js" : "function(txt) { return \"__\" + txt + \"__\" }",
         "lisp" : "(lambda (text) (format nil \"__~a__\" text))",
         "perl" : "sub { \"__\" . $_[0] . \"__\" }",
         "php" : "return \"__\" . $text . \"__\";",
         "pwsh" : "\"__$($args[0])__\"",
         "python" : "lambda text: \"__%s__\" % (text)",
         "raku" : "sub { \"__\" ~ $^section ~ \"__\" }",
         "ruby" : "proc { |text| \"__#{text}__\" }"
      }
   },
   "expected" : "__FILE__ != __LINE__",
   "template" : "{{#lambda}}FILE{{/lambda}} != {{#lambda}}LINE{{/lambda}}"
}

=== Inverted Section: Lambdas used for inverted sections should be considered truthy.
--- case
{
   "data" : {
      "lambda" : {
         "__tag__" : "code",
         "clojure" : "(fn [text] false)",
         "go" : "func(text string) bool { return false }",
         "js" : "function(txt) { return false }",
         "lisp" : "(lambda (text) (declare (ignore text)) nil)",
         "perl" : "sub { 0 }",
         "php" : "return false;",
         "pwsh" : "$false",
         "python" : "lambda text: 0",
         "raku" : "sub { 0 }",
         "ruby" : "proc { |text| false }"
      },
      "static" : "static"
   },
   "expected" : "<>",
   "template" : "<{{^lambda}}{{static}}{{/lambda}}>"
}

