use strict;
use warnings;

use Test::More 0.98;
use Test::Base::Less;

use Text::MustacheTemplate::Generator;

filters {
    input => [qw/eval/],
    expected => [qw/chomp/],
};

for my $block (blocks) {
    my $source = Text::MustacheTemplate::Generator->generate_from_tokens(@{ $block->input });
    is $source, $block->expected, $block->name;
}

done_testing;
__DATA__
=== Variables
--- expected
* {{name}}
* {{age}}
* {{company}}
* {{{company}}}
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,2,"name"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,10,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,13,"age"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,20,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,23,"company"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,34,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,37,"{","company"],
]

=== Dotted Names
--- expected
* {{client.name}}
* {{age}}
* {{client.company.name}}
* {{{company.name}}}
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,2,"client.name"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,17,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,20,"age"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,27,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,30,"client.company.name"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,53,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,56,"{","company.name"],
]

=== Implicit Iterator
--- expected
{{.}}
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,0,"."],
]

=== Sections
--- expected
Shown.
{{#person}}
  Never shown!
{{/person}}
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"Shown.\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,7,"#","person"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,18,"\n  Never shown!\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,34,"/","person"],
]

=== Inverted Sections
--- expected
{{#repo}}
  <b>{{name}}</b>
{{/repo}}
{{^repo}}
  No repos :(
{{/repo}}
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,0,"#","repo"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,9,"\n  <b>"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,15,"name"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,23,"</b>\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,28,"/","repo"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,37,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,38,"^","repo"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,47,"\n  No repos :(\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,62,"/","repo"],
]

=== Comments
--- expected
<h1>Today{{! ignore me }}.</h1>
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"<h1>Today"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,9,"!"," ignore me "],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,25,".</h1>"],
]

=== Partials
--- expected
<h2>Names</h2>
{{#names}}
  {{> user}}
{{/names}}

Hello {{>*dynamic}}
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"<h2>Names</h2>\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,15,"#","names"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,25,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,26,"  "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,28,">"," user"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,38,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,39,"/","names"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,49,"\n\nHello "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,57,">","*dynamic"],
]

=== Blocks
--- expected
<h1>{{$title}}The News of Today{{/title}}</h1>
{{$body}}
<p>Nothing special happened.</p>
{{/body}}

{{<article}}
  Never shown
  {{$body}}
    {{#headlines}}
    <p>{{.}}</p>
    {{/headlines}}
  {{/body}}
{{/article}}

{{<article}}
  {{$title}}Yesterday{{/title}}
{{/article}}

Hello {{>*dynamic}}

{{!normal.mustache}}
{{$text}}Here goes nothing.{{/text}}

{{!bold.mustache}}
<b>{{$text}}Here also goes nothing but it's bold.{{/text}}</b>

{{!dynamic.mustache}}
{{<*dynamic}}
  {{$text}}Hello World!{{/text}}
{{/*dynamic}}
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"<h1>"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,4,"\$","title"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,14,"The News of Today"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,31,"/","title"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,41,"</h1>\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,47,"\$","body"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,56,"\n<p>Nothing special happened.</p>\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,90,"/","body"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,99,"\n\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,101,"<","article"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,113,"\n  Never shown\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,128,"  "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,130,"\$","body"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,139,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,140,"    "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,144,"#","headlines"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,158,"\n    <p>"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,166,"."],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,171,"</p>\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,176,"    "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,180,"/","headlines"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,194,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,195,"  "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,197,"/","body"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,206,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,207,"/","article"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,219,"\n\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,221,"<","article"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,233,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,234,"  "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,236,"\$","title"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,246,"Yesterday"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,255,"/","title"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,265,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,266,"/","article"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,278,"\n\nHello "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,286,">","*dynamic"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,299,"\n\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,301,"!","normal.mustache"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,321,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,322,"\$","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,331,"Here goes nothing."],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,349,"/","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,358,"\n\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,360,"!","bold.mustache"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,378,"\n<b>"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,382,"\$","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,391,"Here also goes nothing but it's bold."],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,428,"/","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,437,"</b>\n\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,443,"!","dynamic.mustache"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,464,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,465,"<","*dynamic"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,478,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,479,"  "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,481,"\$","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,490,"Hello World!"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,502,"/","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,511,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,512,"/","*dynamic"],
]

=== Set Delimiter
--- expected
* {{default_tags}}
{{=<% %>=}}
* <% erb_style_tags %>
<%={{ }}=%>
* {{ default_tags_again }}
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,2,"default_tags"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,18,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,19,"<% %>","<%","%>"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,30,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,33," erb_style_tags "],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,53,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,54,"{{ }}","{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,65,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,68," default_tags_again "],
]
