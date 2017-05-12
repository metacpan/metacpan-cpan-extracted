
use strict;

use Test::More qw(no_plan);
use Test::Deep;

use YAML::Syck qw(LoadFile);;

BEGIN { 
  use_ok('WWW::Google::API::Base');
}

my $gapi_file = $ENV{HOME}.'/.gapi';

my $file_conf;
$file_conf = LoadFile($gapi_file) if -e $gapi_file;

my $api_key  = $ENV{gapi_key}  || $file_conf->{key}  || '';
my $api_user = $ENV{gapi_user} || $file_conf->{user} || '';
my $api_pass = $ENV{gapi_pass} || $file_conf->{pass} || '';


if ($api_key and $api_user and $api_pass) {

  my $gbase = WWW::Google::API::Base->new( { auth_type => 'ProgrammaticLogin',
                                             api_key   => $api_key,
                                             api_user  => $api_user,
                                             api_pass  => $api_pass  },
                                           { } );

  # $gbase is a GBaes API Client
  isa_ok($gbase, 'WWW::Google::API::Base');

  # The security token was obtained 
  isnt($gbase->client->token, '', 'Token is not empty');

  # insert, update, delete, select all exist
  can_ok('WWW::Google::API::Base', qw(insert update delete select));

  # Can handle 404 / non existant item
  my $expected_404_content = <<'EOF';
<errors>
<error type="request" reason="Cannot find item"/>
</errors>
EOF

  my $selected_fail;
  eval {
    $selected_fail =$gbase->select('http://www.google.com/base/feeds/items/00000000000000000');
  };

  ok($@, 'Got an expected error');
  {
    my $e = $@;
    ok($e->is_error,                       'Expected error response');
    is($e->code,    '404',                 'Expected 404');
    is($e->content, $expected_404_content, 'Expected missing error content');
  }

  # Insert
  my $new_id;
  my $insert_entry;
  { 
    my $expected_insert_response = <<'EOF';
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:gm="http://base.google.com/ns-metadata/1.0" xmlns:g="http://base.google.com/ns/1.0" xmlns:batch="http://schemas.google.com/gdata/batch">
  <id>foo.bar</id>
  <category scheme="http://base.google.com/categories/itemtypes" term="recipes"/>
  <title type="text">He Jingxian's chicken</title>
  <content type="html">&lt;div xmlns='http://www.w3.org/1999/xhtml'&gt;Delectable Sichuan specialty&lt;/div&gt;</content>
  <link rel="alternate" type="text/html" href="http://localhost/uniqueid"/>
  <g:cooking_time type="int">30</g:cooking_time>
  <g:main_ingredient type="text">chicken</g:main_ingredient>
  <g:main_ingredient type="text">chili</g:main_ingredient>
  <g:main_ingredient type="text">peanuts</g:main_ingredient>
  <g:item_type type="text">recipes</g:item_type>
  <g:item_language type="text">en</g:item_language>
  <g:label type="text">bar</g:label>
  <g:label type="text">baz</g:label>
  <g:label type="text">foo</g:label>
  <g:target_country type="text">US</g:target_country>
  <g:customer_id type="int">1018459</g:customer_id>
  <g:servings type="int">5</g:servings>
</entry>
EOF
    my $expected_entry = XML::Atom::Entry->new(\$expected_insert_response);
    
    $insert_entry = $gbase->insert( 
      'http://www.google.com/base/feeds/itemtypes/en_US/Recipes',
      { -title      => 'He Jingxian\'s chicken',
        -content    => "<div xmlns='http://www.w3.org/1999/xhtml'>Delectable Sichuan specialty</div>",
        -link       => [ 
          { rel  => 'alternate',
            type => 'text/html',
            href => 'http://localhost/uniqueid'
          },
        ],
        cooking_time    => 30,
        label           => [qw(foo bar baz)],
        main_ingredient => [qw(chicken chili peanuts)],
        servings        => 5,
      },
    );

    compare_entries($gbase, $insert_entry, $expected_entry);
  }

  # Get inserted items ID
  $new_id = $insert_entry->id;
  ok($new_id, 'Have a new entry id');

  # Select an actual item (just inserted)
  { 
    my $select_inserted_entry;
    eval {
      $select_inserted_entry =$gbase->select($new_id);
    };
    ok(!$@, 'No errors selecting inserted item');
      
    compare_entries($gbase, $select_inserted_entry, $insert_entry);
  }

  # Update
  my $update_entry;
  {
    my $expected_update_response = <<'EOF';
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:gm="http://base.google.com/ns-metadata/1.0" xmlns:g="http://base.google.com/ns/1.0" xmlns:batch="http://schemas.google.com/gdata/batch">
  <id>foo.bar</id>
  <category scheme="http://base.google.com/categories/itemtypes" term="recipes"/>
  <title type="text">He Jingxian's chicken</title>
  <content type="html">&lt;div xmlns='http://www.w3.org/1999/xhtml'&gt;Delectable Sichuan specialty&lt;/div&gt;</content>
  <link rel="alternate" type="text/html" href="http://localhost/uniqueid"/>
  <g:cooking_time type="int">60</g:cooking_time>
  <g:main_ingredient type="text">chicken</g:main_ingredient>
  <g:main_ingredient type="text">chili</g:main_ingredient>
  <g:main_ingredient type="text">peanuts</g:main_ingredient>
  <g:item_type type="text">recipes</g:item_type>
  <g:item_language type="text">en</g:item_language>
  <g:label type="text">bir</g:label>
  <g:label type="text">biz</g:label>
  <g:label type="text">fio</g:label>
  <g:target_country type="text">US</g:target_country>
  <g:customer_id type="int">1018459</g:customer_id>
  <g:servings type="int">15</g:servings>
</entry>
EOF
    my $expected_entry = XML::Atom::Entry->new(\$expected_update_response);
   
    $update_entry = $gbase->update( 
      $new_id,
      { -title      => 'He Jingxian\'s chicken',
        -content    => "<div xmlns='http://www.w3.org/1999/xhtml'>Delectable Sichuan specialty</div>",
        -link       => [ 
          { rel  => 'alternate',
            type => 'text/html',
            href => 'http://localhost/uniqueid'
          },
        ],
        cooking_time    => 60,
        label           => [qw(fio bir biz)],
        main_ingredient => [qw(chicken chili peanuts)],
        servings        => 15,
      },
    );

    compare_entries($gbase, $update_entry, $expected_entry);
  } 

  # Compare Selet to Updated item
  { 
    my $select_updated_entry;
    eval {
      $select_updated_entry =$gbase->select($new_id);
    };
    ok(!$@, 'No errors selecting updated entry');
      
    compare_entries($gbase, $select_updated_entry, $update_entry);
  }

  # Delete 
  {
    my $delete_response;
    eval {
      $delete_response =$gbase->delete($new_id);
    };
    ok(!$@);
    is($delete_response->code, '200', 'Deletion returned successfully');
  } 


  # Select, Confirm Delete was successful on the server
  eval {
    $selected_fail =$gbase->select($new_id);
  };

  ok($@, 'Got an expected error');
  {
    my $e = $@;
    ok($e->is_error,                       'Expected error response');
    is($e->code,    '404',                 'Expected 404');
    is($e->content, $expected_404_content, 'Expected missing error content');
  }

} else {
  diag("API Key, User, and Pass not all defined.  Skipping network tests.");
}

sub compare_entries {
  my $gbase   = shift;
  my $entry_1 = shift;
  my $entry_2 = shift;

  isa_ok($entry_1, 'XML::Atom::Entry', 'Entry 1 is an XML::Atom::Entry');
  isa_ok($entry_2, 'XML::Atom::Entry', 'Entry 2 is an XML::Atom::Entry');

  is($entry_1->content->body,
     $entry_2->content->body,
     'Content bodies match');

  is($entry_1->get(${$gbase->namespaces}{g}, 'servings'),
     $entry_2->get(${$gbase->namespaces}{g}, 'servings'),
     'Servings values match');
  
  is($entry_1->category->term,
     $entry_2->category->term,
     'Category terms match');
  
  is($entry_1->category->scheme,
     $entry_2->category->scheme,
     'Category schemes match');
  
  cmp_bag([$entry_1->getlist(${$gbase->namespaces}{g}, 'label')],
          [$entry_2->getlist(${$gbase->namespaces}{g}, 'label')],
          'Labels match');
  
  cmp_bag([$entry_1->getlist(${$gbase->namespaces}{g}, 'main_ingredient')],
          [$entry_2->getlist(${$gbase->namespaces}{g}, 'main_ingredient')],
          'Main Intredients match');

}
