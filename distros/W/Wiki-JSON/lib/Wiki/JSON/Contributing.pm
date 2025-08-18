package Wiki::JSON::Contributing;

use v5.16.3;
use strict;
use warnings;

1;
=encoding utf8

=head1 WAYS TO CONTRIBUTE

=head2 REPORTING BUGS

If you think some behavior is undesired you can use the Github repository L<https://github.com/sergiotarxz/Perl-Wiki-JSON> to report it
in the issues tab.

This should be enough, but if you really want to ensure I understand you ideally you could write in markdown an example of a is_deeply
test in your issue or even send a pull request just with the new test.

This is how a test may look like:

 use v5.16.3;
 
 use strict;
 use warnings;
 
 use lib 'lib';
 
 use Test::Most;
 
 use_ok 'Wiki::JSON';
 
 {
     my $parsed = Wiki::JSON->new->parse(
         q(= This is a wiki title =
 '''This is bold'''
 ''This is italic''
 '''''This is bold and italic'''''
 == This is a smaller title, the user can use no more than 6 equal signs ==
 <nowiki>''This is printed without expanding the special characters</nowiki>
 * This
 * Is
 * A
 * Bullet
 * Point
 * List
 {{foo|Templates are generated|with their arguments}}
 {{stub|This is under heavy development}}
 The parser has some quirks == This will generate a title ==
 ''' == '' Unterminated syntaxes will still be parsed until the end of file
 This is a link to a wiki article: [[Cool Article]]
 This is a link to a wiki article with an alias: [[Cool Article|cool article]]
 This is a link to a URL with an alias: [[https://example.com/cool-source.html|cool article]]
 This is a link to a Image [[File:https:/example.com/img.png|50x50px|frame|This is a caption]]
 Let's end them '' == '''
  )
     );
 
 #    print STDERR Data::Dumper::Dumper($parsed);
     is_deeply $parsed, [ 
           {
             'type' => 'hx',
             'output' => [
                           'This is a wiki title'
                         ],
             'hx_level' => 1
           },
           {
             'output' => [
                           'This is bold'
                         ],
             'type' => 'bold'
           },
           {
             'type' => 'italic',
             'output' => [
                           'This is italic'
                         ]
           },
           {
             'type' => 'bold_and_italic',
             'output' => [
                           'This is bold and italic'
                         ]
           },
           {
             'output' => [
                           'This is a smaller title, the user can use no more than 6 equal signs'
                         ],
             'type' => 'hx',
             'hx_level' => 2
           },
           '\'\'This is printed without expanding the special characters',
           {
             'output' => [
                           {
                             'type' => 'list_element',
                             'output' => [
                                           'This'
                                         ]
                           },
                           {
                             'output' => [
                                           'Is'
                                         ],
                             'type' => 'list_element'
                           },
                           {
                             'type' => 'list_element',
                             'output' => [
                                           'A'
                                         ]
                           },
                           {
                             'output' => [
                                           'Bullet'
                                         ],
                             'type' => 'list_element'
                           },
                           {
                             'output' => [
                                           'Point'
                                         ],
                             'type' => 'list_element'
                           },
                           {
                             'output' => [
                                           'List'
                                         ],
                             'type' => 'list_element'
                           }
                         ],
             'type' => 'unordered_list'
           },
           {
             'type' => 'template',
             'output' => [
                           'Templates are generated',
                           'with their arguments'
                         ],
             'template_name' => 'foo'
           },
           {
             'template_name' => 'stub',
             'type' => 'template',
             'output' => [
                           'This is under heavy development'
                         ]
           },
           'The parser has some quirks ',
           {
             'type' => 'hx',
             'hx_level' => 2,
             'output' => [
                           'This will generate a title'
                         ]
           },
           {
             'type' => 'bold',
             'output' => [
                           ' ',
                           {
                             'type' => 'hx',
                             'hx_level' => 2,
                             'output' => [
                                           {
                                             'output' => [
                                                           ' Unterminated syntaxes will still be parsed until the end of file',
                                                           'This is a link to a wiki article: ',
                                                           {
                                                             'title' => 'Cool Article',
                                                             'link' => 'Cool Article',
                                                             'type' => 'link'
                                                           },
                                                           'This is a link to a wiki article with an alias: ',
                                                           {
                                                             'type' => 'link',
                                                             'link' => 'Cool Article',
                                                             'title' => 'cool article'
                                                           },
                                                           'This is a link to a URL with an alias: ',
                                                           {
                                                             'link' => 'https://example.com/cool-source.html',
                                                             'type' => 'link',
                                                             'title' => 'cool article'
                                                           },
                                                           'This is a link to a Image ',
                                                           {
                                                             'caption' => 'frame',
                                                             'options' => {
                                                                            'format' => {
                                                                                          'frame' => 1
                                                                                        },
                                                                            'resize' => {
                                                                                          'height' => 50,
                                                                                          'width' => 50
                                                                                        }
                                                                          },
                                                             'link' => 'https:/example.com/img.png',
                                                             'type' => 'image'
                                                           },
                                                           'Let\'s end them ',
                                                         ],
                                             'type' => 'italic'
                                           },
                                         ]
                           },
                           ' ',
                         ]
           },
           ' ',
      ], 'Demo wiki works';
 }
 done_testing();

The first argument for is_deeply is how Wiki::JSON would parse your structure and the second is how do you expect it to be parsed.

=head2 REQUESTING FEATURES

Mostly like reporting bugs but if you are bringing new methods you could also bring some tests for those methods, look L<Test::Most>, L<Test::MockModule>, and L<Test::MockObject>.

=head2 CONTRIBUTING CODE

Running prove in perl-5.38.2 and perl-5.16.3 and having it pass is highly recommended.

You can use this mail address L<mailto:sergioxz@cpan.org> to report bugs and send patches if for whatever reason
you cannot or do not want to use Github, Github is also a approved way of contributing.

I will require you agree with any future license change for the case some dist needs a more lax license and wants
to use this library as a dependency.

=head2 Wiki::JSON as a CPAN dependency

This dist is very young and needs further testing and correctness, if your dist depends on some behavior of Wiki::JSON
this should become a test to avoid unexpected breakage.

If you want to contribute a test for something that may break your CPAN dist you can create a test suite on:
    
    t/dependent-dist/000001-Your-Dist.t

Being the number the last number available under that folder plus 1.

Contact via Github or email if that's the case.

=head2 The CPAN email is sometimes unreliable

If you do not get a reply try sending another mail or using an alternative contact way.

=cut
