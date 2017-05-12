#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw(no_plan);
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok "Zen::Koan";
}

Create_Koan: {
    my $k = Zen::Koan->new( title => 'foo', body => 'bar' );
    isa_ok $k, 'Zen::Koan';
    is $k->title, 'foo';
    is $k->body,  'bar';
    is $k->as_html, <<EOT;
<div id='koan_title'>foo</div>
<div id='koan_body'>
<p>bar</p>
</div>
EOT
}

Create_by_hashref: {
    my $k = Zen::Koan->new( { title => 'foo' } );
    isa_ok $k, 'Zen::Koan';
    is $k->title, 'foo';
}

Multi_paragraph_koan: {
    my $body = "this\nand that\n\nand others.\n";
    my $k = Zen::Koan->new( title => 'foo', 
                            body => $body,
                          );
    isa_ok $k, 'Zen::Koan';
    is $k->title, 'foo';
    is $k->body,  $body;
    is $k->as_html, <<EOT;
<div id='koan_title'>foo</div>
<div id='koan_body'>
<p>this</p>
<p>and that</p>
<p>and others.</p>
</div>
EOT
}

sub poem_koan { Zen::Koan->new( body => <<EOK ) }
Here is my poem:
  No more water in the pail!
  No more moon in the water!
That is my poem.
EOK

Koan_with_poem: {
    my $k = poem_koan();
    is $k->as_html, <<EOK;
<div id='koan_title'>A koan by no other name</div>
<div id='koan_body'>
<p>Here is my poem:</p>
<blockquote>
<p>No more water in the pail!</p>
<p>No more moon in the water!</p>
</blockquote>
<p>That is my poem.</p>
</div>
EOK
}

Koan_as_text: {
    my $k = poem_koan();
    is $k->as_text, <<EOK;
	A koan by no other name

Here is my poem:
  No more water in the pail!
  No more moon in the water!
That is my poem.
EOK
}

Less_specified_koans: {
    my $k = Zen::Koan->new;
    isa_ok $k, 'Zen::Koan';
    is $k->title, 'A koan by no other name';
    is $k->body,  'This koan offers little wisdom.  It just is.';
}

Other_functions: {
    my $k = Zen::Koan->new;
    isa_ok $k, 'Zen::Koan';
    like $k->underlying_meaning, qr#You are expecting too much#;
}

