use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# The interface: what's exported, and what each function takes. What
# each finds is tested with the rules.

use Text::Redact::Secrets qw(find redact);

subtest 'Nothing is exported unless asked for' => sub {

    package My::Importer {
        use Text::Redact::Secrets;
    }
    ok !My::Importer->can('redact'), 'not redact';
    ok !My::Importer->can('find'),   'not find';
};

subtest 'Text with no secret in it' => sub {
    my $text = "Nothing to see here.\n";
    is redact($text), $text, 'redact returns it as it was';
    is [find($text)], [],    'find returns nothing';
};

subtest "redact leaves the string it's given as it was" => sub {
    my $text = 'aws_access_key_id = ' . join '', 'AKIA', 'MADEUP', 'FORTESTS',
        'ZZ';
    my $copy = $text;
    isnt redact($text), $text, 'it returns it redacted';
    is $text,           $copy, 'and the string is as it was';
};

subtest 'What isn\'t a string croaks, at the caller\'s line' => sub {
    for my $case ([undef, 'undef'], [[], 'a reference']) {
        my($arg, $name) = @$case;
        my $line = __LINE__ + 1;
        is dies { redact($arg) },
            "Expected a string to redact at ${\ __FILE__ } line $line.\n",
            "redact, given $name";
        $line = __LINE__ + 1;
        is dies { find($arg) },
            "Expected a string to search at ${\ __FILE__ } line $line.\n",
            "find, given $name";
    }
};

done_testing;
