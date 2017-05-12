#!perl

use strict;
use Test::More tests => 19;

use Data::Dumper;

use lib qw(lib);

use Test::HTML::Form;

my $filename = 't/form_with_errors.html';

title_matches($filename,qr/inzerce zdarma Praha/,'title matches');

no_title($filename,'test site','no english title');

tag_matches($filename,
       'p',
       { class => 'formError',
	 _content => qr/Omlouváme se, byly nalezeny chyby a Váš inzerát nemohl být odeslán/ },
       'main error message appears as expected' );

tag_matches($filename, [qw/weak strong/], { _content => qr/Titulek/ }, 'tag_matches will match one of several tags ok' );

no_tag($filename,
       'p',
       { class => 'formError',
	 _content => 'Error' },
       'no unexpected english errors' );


text_matches($filename,'Kulturní přehled, hudba, koncerty','found text : Kulturní přehled, hudba, koncerty'); # check text found in file
no_text($filename,'Concert','no text matching : Concert'); # check text found in file

script_matches($filename, qr/function someWidget/, 'found widget in JS');

# script_matches($filename, qr/function foobar/, 'found widget in JS');

image_matches($filename,'/images/error.gif','matching image found image in HTML');
no_image($filename,'/images/hello_kitty.jpg','no matching image found in HTML');

link_matches($filename,'/foo/select_foo.html?id=12345678','Found link in HTML');
no_link($filename,'/foo/select_foo.html?id=87654321','Not found wrong link in HTML');
link_matches($filename,'/css/layout.css','Found css link in HTML');

form_field_value_matches($filename,'tit1e','test event', undef, 'have title');

form_field_value_matches($filename,'body','some test text',undef,"body field value");

form_select_field_matches($filename,{ field_name => 'day_posting_date', selected => 19, form_name => undef}, 'date matches select');

form_checkbox_field_matches($filename,{ field_name => 'contact_method', selected => 1, form_name => undef}, 'contact method radio matches');

my $word = Test::HTML::Form->extract_text({filename => $filename, pattern => 'hudba,\s(koncerty)'});

is($word,'koncerty','extracted word from text matches');

my $form_values = Test::HTML::Form->get_form_values({filename => $filename});

ok ($form_values->{tit1e}[0], 'have a title field extracted ok');
