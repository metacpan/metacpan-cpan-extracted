#!/usr/bin/env perl
use warnings;
use strict;
use Test::More qw/no_plan/;

BEGIN {
	use_ok( 'Text::Format::Interview' );
}

diag( "Testing Text::Format::Interview $Text::Format::Interview::VERSION, Perl $], $^X" );

my $no_denoted_txt = qq {
# Interview between Fred Flintstone and Barney Rubble, 3rd April, 2000 BC

Fred: [00:00:00]
So, Barney, when did you decide to become a Flintstone?

Barney: [00:00:10]
Well Fred, I'm not actually a Flintstone, my surname is Rubble and I live in Bedrock.

};

my $denoted_txt = qq{
# Interview between Fred Flintstone and Barney Rubble, 3rd April, 2000 BC
interviewer: fred,wilma
interviewee: barney,betty

Fred: [00:00:00]
So what's it like to be a flintstone?

Barney: [00:00:05]
I'm not a Flintstone, I'm a Rubble.  What do you think Betty?

Betty:  [00:00:10]
Yes Fred, you're confused.

Wilma:  [00:00:15]
I'm so terribly embarrassed by my husband.
    };

my $no_denoted_out = qq{

<p># Interview between Fred Flintstone and Barney Rubble, 3rd April, 2000 BC<br>
</p>

<h2 >Fred:</h2>

<p><span class='timestamp'>[00:00:00]</span>So, Barney, when did you decide to become a Flintstone?</p>

<h2 >Barney:</h2>

<p><span class='timestamp'>[00:00:10]</span>Well Fred, I'm not actually a Flintstone, my surname is Rubble and I live in Bedrock.</p>

};
my $denoted_out = qq{

<p># Interview between Fred Flintstone and Barney Rubble, 3rd April, 2000 BC<br>
interviewer: fred,wilma<br>
interviewee: barney,betty<br>
</p>

<h2 class = "interviewer">Fred:</h2>

<p><span class='timestamp'>[00:00:00]</span>So what's it like to be a flintstone?</p>

<h2 class = "interviewee">Barney:</h2>

<p><span class='timestamp'>[00:00:05]</span>I'm not a Flintstone, I'm a Rubble.  What do you think Betty?</p>

<h2 class = "interviewee">Betty:</h2>

<p><span class='timestamp'>[00:00:10]</span>Yes Fred, you're confused.</p>

<h2 class = "interviewer">Wilma:</h2>

<p><span class='timestamp'>[00:00:15]</span>I'm so terribly embarrassed by my husband.
    </p>

};

my $txt = Text::Format::Interview->new();
my $no_d_out =  $txt->process($no_denoted_txt);
my $d_out = $txt->process($denoted_txt);
$DB::single=1;
cmp_ok($no_denoted_out, 'eq', $no_d_out, "undenoted text outputs ok");
cmp_ok($denoted_out,    'eq', $d_out,    "denoted text outputs ok");
