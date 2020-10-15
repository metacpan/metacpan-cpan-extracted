use strict;
use warnings;
use Path::Tiny;
use Test::More tests => 7;

use Text::vCard::Precisely::V4;
my $vc = Text::vCard::Precisely::V4->new();

# NAME, PROFILE, MAILER, LABEL, AGENT, CLASS, and SORT-STRING are DEPRECATED in vCard4.0

my $fail = '';

$fail = eval { $vc->name('some names') };
is $fail, undef, "fail to declare 'NAME' type";    # 1

$fail = eval { $vc->profile('some profiles') };
is $fail, undef, "fail to declare 'PROFILE' type";    # 2

$fail = eval { $vc->mailer('some mailers') };
is $fail, undef, "fail to declare 'MAILER' type";     # 3

$fail = eval {
    $vc->label(
        {   types => ['home'],
            value => '123 Main St.\nSpringfield, IL 12345\nUSA',
        }
    );
};
is $fail, undef, "fail to declare 'LABEL' type";      # 4

$fail = eval { $vc->agent('some agents') };
is $fail, undef, "fail to declare 'AGENT' type";      # 5

$fail = eval { $vc->class('some classes') };
is $fail, undef, "fail to declare 'CLASS' type";      # 6

$fail = eval { $vc->sort_string('SORT-STRING') };         # DEPRECATED in vCard4.0
is $fail, undef, "fail to declare 'SORT-STRING' type";    # 7

done_testing;
