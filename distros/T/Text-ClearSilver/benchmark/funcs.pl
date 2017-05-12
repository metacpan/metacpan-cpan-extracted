#!perl
use strict;
use Benchmark qw(:all);

use Text::ClearSilver;

print "Text::ClearSilver/$Text::ClearSilver::VERSION\n";

my $template_builtin_sprintf = <<'CS_END';
Hello, <?cs var:sprintf('%s %s %s', lang, lang, lang) ?> world!
CS_END

my $template_my_sprintf = <<'CS_END';
Hello, <?cs var:my_sprintf('%s %s %s', lang, lang, lang) ?> world!
CS_END

my %vars = (
    lang => 'ClearSilver',
);

sub my_sprintf {
    my $fmt = shift;
    return sprintf $fmt, @_;
}

cmpthese -1, {
    'User func' => sub {
        my $output = '';
        my $tcs = Text::ClearSilver->new();
        $tcs->register_function(my_sprintf => \&my_sprintf);
        $tcs->process(\$template_my_sprintf, \%vars, \$output);
    },
    'Builtin func' => sub {
        my $output = '';
        my $tcs = Text::ClearSilver->new();
        $tcs->register_function(my_sprintf => \&my_sprintf);
        $tcs->process(\$template_builtin_sprintf, \%vars, \$output);
    },
};

