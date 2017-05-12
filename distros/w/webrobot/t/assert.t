#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use Test::More tests => 10;
use WWW::Webrobot::XML2Tree;
use WWW::Webrobot::Assert;



my $parser = WWW::Webrobot::XML2Tree -> new();

sub cmp_postfix {
    my ($name, $postfix, $xml) = @_;
    my $tree = $parser -> parse($xml);
    my $assert = WWW::Webrobot::Assert -> new($tree);
    is_deeply($postfix, $assert->postfix, $name);
}


cmp_postfix("predicate: status", [
    ['status', [ {'value' => '3'} ] ],
], <<'EOF');
<status value='3'/>
EOF

cmp_postfix("predicate: regex", [
    ['regex', [ {'value' => 'a regular expression' } ] ],
], <<'EOF');
<regex value='a regular expression'/>
EOF

cmp_postfix("predicate: xpath", [
    ['xpath', [{'xpath' => '//title/text()', 'value' => 'Will.*?abas'}]],
], <<'EOF');
<xpath xpath='//title/text()' value='Will.*?abas'/>
EOF

cmp_postfix("not predicate", [
    ['status', [ {'value' => '3'} ] ],
    'not',
], <<'EOF');
<not>
    <status value='3'/>
</not>
EOF

cmp_postfix("and predicate", [
    ['status', [ {'value' => '3'} ] ],
    ['regex', [ {'value' => 'a regular expression' } ] ],
    'and',
    ['xpath', [{'xpath' => '//title/text()', 'value' => 'Will.*?abas'}]],
    'and',
], <<'EOF');
<and>
    <status value='3'/>
    <regex value='a regular expression'/>
    <xpath xpath='//title/text()' value='Will.*?abas'/>
</and>
EOF

cmp_postfix("or predicate", [
    ['status', [ {'value' => '3'} ] ],
    ['regex', [ {'value' => 'a regular expression' } ] ],
    'or',
    ['xpath', [{'xpath' => '//title/text()', 'value' => 'Will.*?abas'}]],
    'or',
], <<'EOF');
<or>
    <status value='3'/>
    <regex value='a regular expression'/>
    <xpath xpath='//title/text()' value='Will.*?abas'/>
</or>
EOF

cmp_postfix("predicat and not predicate", [
    ['status', [ {'value' => '2'} ] ],
    ['status', [ {'value' => '3'} ] ],
    'not',
    'and',
], <<'EOF');
<and>
    <status value='2'/>
    <not>
        <status value='3'/>
    </not>
</and>
EOF

cmp_postfix("not (or predicate)", [
    ['status', [ {'value' => '3'} ] ],
    ['regex', [ {'value' => 'a regular expression' } ] ],
    'or',
    ['xpath', [{'xpath' => '//title/text()', 'value' => 'Will.*?abas'}]],
    'or',
    'not',
], <<'EOF');
<not>
    <or>
        <status value='3'/>
        <regex value='a regular expression'/>
        <xpath xpath='//title/text()' value='Will.*?abas'/>
    </or>
</not>
EOF

cmp_postfix("complex expression 1", [
    ['status', [ {'value' => '3'} ] ],
    ['regex', [ {'value' => 'Anmeldung' } ] ],
    'and',
    ['regex', [ {'value' => 'Der abas-eB-Shop kann als'} ] ],
    'and',
    ['xpath', [{'xpath' => '//title/text()', 'value' => 'Willkommen im abas'}]],
    'and',
    ['xpath', [{'xpath' => '//title/text()', 'value' => 'Will.*?abas'}]],
    'and',
    ['regex', [{'value' => 'Passwort'}]],
    'not',
    'not',
    'and'
], <<'EOF');
<and>
    <and>
        <status value='3'/>
        <regex value='Anmeldung'/>
    </and>
    <regex value='Der abas-eB-Shop kann als'/>
    <xpath xpath='//title/text()' value='Willkommen im abas'/>
    <xpath xpath='//title/text()' value='Will.*?abas'/>
    <not>
        <not>
            <regex value='Passwort'/>
        </not>
    </not>
</and>
EOF

cmp_postfix("complex expression 2", [
    ['status', [ {'value' => '3'} ] ],
    ['regex', [ {'value' => 'Anmeldung' } ] ],
    'and',
    ['regex', [ {'value' => 'Der abas-eB-Shop kann als'} ] ],
    ['xpath', [{'xpath' => '//title/text()', 'value' => 'Willkommen im abas'}]],
    'or',
    ['xpath', [{'xpath' => '//title/text()', 'value' => 'Will.*?abas'}]],
    'or',
    'and',
    ['regex', [ {'value' => 'Der abas-eB-Shop kann als'} ] ],
    'and',
    ['xpath', [{'xpath' => '//title/text()', 'value' => 'Willkommen im abas'}]],
    'and',
    ['xpath', [{'xpath' => '//title/text()', 'value' => 'Will.*?abas'}]],
    'and',
    ['regex', [{'value' => 'Passwort'}]],
    'not',
    'not',
    'and'
], <<'EOF');
<and>
    <and>
        <status value='3'/>
        <regex value='Anmeldung'/>
    </and>
    <or>
        <regex value='Der abas-eB-Shop kann als'/>
        <xpath xpath='//title/text()' value='Willkommen im abas'/>
        <xpath xpath='//title/text()' value='Will.*?abas'/>
    </or>
    <regex value='Der abas-eB-Shop kann als'/>
    <xpath xpath='//title/text()' value='Willkommen im abas'/>
    <xpath xpath='//title/text()' value='Will.*?abas'/>
    <not>
        <not>
            <regex value='Passwort'/>
        </not>
    </not>
</and>
EOF


1;
