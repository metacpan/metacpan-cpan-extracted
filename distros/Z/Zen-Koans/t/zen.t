#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw(no_plan);
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok "Zen::Koans", qw(get_koan num_koans);
}

my $num_koans = 101;
Num_koans: {
    is num_koans(), $num_koans;
}

Get_koan: {
    my $k = get_koan(1);
    isa_ok $k, 'Zen::Koan';
    is $k->title, 'A Cup of Tea';
    is $k->body, <<EOK;
Nan-in, a Japanese master during the Meiji era (1868-1912), received a university professor who came to inquire about Zen.
Nan-in served tea. He poured his visitor's cup full, and then kept on pouring.
The professor watched the overflow until he no longer could restrain himself. "It is overfull. No more will go in!"
"Like this cup," Nan-in said, "you are full of your own opinions and speculations. How can I show you Zen unless you first empty your cup?"
EOK
    is $k->as_html, <<EOK;
<div id='koan_title'>A Cup of Tea</div>
<div id='koan_body'>
<p>Nan-in, a Japanese master during the Meiji era (1868-1912), received a university professor who came to inquire about Zen.</p>
<p>Nan-in served tea. He poured his visitor's cup full, and then kept on pouring.</p>
<p>The professor watched the overflow until he no longer could restrain himself. "It is overfull. No more will go in!"</p>
<p>"Like this cup," Nan-in said, "you are full of your own opinions and speculations. How can I show you Zen unless you first empty your cup?"</p>
</div>
EOK
}

Invalid_koans: {
    eval { get_koan(0) };
    like $@, qr#Please set num to a number between 1 and $num_koans#;
    eval { get_koan(200) };
    like $@, qr#Please set num to a number between 1 and $num_koans#;
    eval { get_koan() };
    like $@, qr#You must supply num=#;
}

