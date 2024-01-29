use strict;
use warnings;
use feature qw/say/;

use Benchmark qw/cmpthese timethese/;

use Template::Mustache;
use Text::MustacheTemplate;

my $template = do { local $/; <DATA> };
my %vars = (
    name    => 'Chris',
    company => '<b>GitHub</b>',
);

say '=============================';
say 'parse';
say '=============================';
cmpthese timethese -10, {
    'Template::Mustache'   => sub { Template::Mustache->new(template => $template)->parsed },
    'Text::MustacheTemplate' => sub { Text::MustacheTemplate->parse($template) },
};

say '=============================';
say 'render';
say '=============================';
my $render_result = timethese -10, {
    'Template::Mustache'     => sub { Template::Mustache->render($template, \%vars) },
    'Text::MustacheTemplate' => sub { Text::MustacheTemplate->render($template, \%vars) },
};
cmpthese $render_result;

say '=============================';
say 'render (contextual optimization)';
say '=============================';
my $render_opt_result = timethese -10, {
    'disabled' => sub { Text::MustacheTemplate->parse($template)->(\%vars) },
};
$render_opt_result->{enabled} = $render_result->{'Text::MustacheTemplate'};
cmpthese $render_opt_result;

say '=============================';
say 'render(cached)';
say '=============================';
cmpthese timethese -10, {
    'Template::Mustache' => do {
        my $t = Template::Mustache->new(template => $template);
        $t->parsed; # to parse template and cache it
        sub { $t->render(\%vars) },
    },
    'Text::MustacheTemplate' => do {
        my $f = Text::MustacheTemplate->parse($template);
        sub { $f->(\%vars) },
    },
};

__DATA__
* {{name}}
* {{age}}
* {{company}}
* {{{company}}}