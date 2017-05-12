#!/usr/bin/env perl
use Test::More tests => 21;
# use Test::More qw(no_plan);

# look if we can load it
BEGIN { use_ok( 'WWW::Scroogle::Result' ); }

# lets test the construktor

# does the construktor even exist?
can_ok(WWW::Scroogle::Result, "new");
# can we create an object with it?
ok(
   my $result = WWW::Scroogle::Result->new({
                                            url => 'foo.bar.org',
                                            position => '3',
                                            searchstring => 'foobar',
                                            language => 'all',
                                          }),
   'WWW::Scroogle::Result->new(valid_options)'
  );
# is the returned object a valid WWW::Scroogle::Result object?
isa_ok($result, 'WWW::Scroogle::Result');
# lets see if the construktor throws errors where expected
my $error;
eval{$error = WWW::Scroogle::Result->new()};
ok($@, 'WWW::Scroogle::Result->new() - fails (no options hash provided)' );
eval{$error = WWW::Scroogle::Result->new({})};
ok($@, 'WWW::Scroogle::Result->new({}) - fails (missing options)');
eval{$error = WWW::Scroogle::Result->new({url=>'foo.bar.org',})};
ok($@, 'WWW::Scroogle::Result->new({options-missing}) - fails (missing options)');
eval{$error = WWW::Scroogle::Result->new({url=>'foo.bar.org',position=>3,})};
ok($@, 'WWW::Scroogle::Result->new({options-missing}) - fails (missing options)');
eval{$error = WWW::Scroogle::Result->new({url=>'foo.bar.org',position=>3,searchstring=>'foobar',})};
ok($@, 'WWW::Scroogle::Result->new({options-missing}) - fails (missing options)');

# test the searchstring method
can_ok('WWW::Scroogle::Result', 'searchstring');
eval{$error = WWW::Scroogle::Result->searchstring};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle::Result->searchstring - fails (instance variable needed)');
is($result->searchstring,'foobar','$object->searchstring eq "foobar"');

# test the language method
can_ok('WWW::Scroogle::Result', 'language');
eval {$error = WWW::Scroogle::Result->language};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle::Resukt->language - fails (instance variable needed)');
is($result->language, 'all','$object->language eq "all"');

# test the position method
can_ok('WWW::Scroogle::Result', 'position');
eval{$error = WWW::Scroogle::Result->position};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle::Result->position - fails (instance variable needed)');
is($result->position,3,'$object->position == 3');

# test the url method
can_ok('WWW::Scroogle::Result', 'url');
eval{$error = WWW::Scroogle::Result->url};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle::Result->url - fails (instance variable needed)');
is($result->url,'foo.bar.org','$object->url eq "foo.bar.org"');
