### Tests for Text::MessageLibrary class

use strict;
use Test;

BEGIN { plan tests => 7 }

use Text::MessageLibrary;
ok(1);

# Create a couple of MessageLibrary objects for testing purposes.

# The first one just offers a couple of simple messages, using mostly
# default behavior.

my $error_messages = Text::MessageLibrary->new({
  file_open_failed => sub {return qq{file open failed on $_[0]: $!}},
  file_open_static => 'file open failed',                            
});

# The second one offers some more sophisticated interpolation and logic,
# along with a custom fallback handler and suppressed prefixes and suffixes.

my $status_messages = Text::MessageLibrary->new({
  files_processed    => sub{ "Processed $_[0] file" . ($_[0] == 1 ? '' : 's') },
  starting_parser    => "Starting parser",
  _default           => sub {"Unknown message " . shift() . " with params " . (join ",",@_)},
});
$status_messages->set_prefix();
$status_messages->set_suffix("\n\n");


# test a static message

open INPUT, "/totally/bogus/filename/that/doesnt/exist";
ok(
  $error_messages->file_open_static('myfile'),
  "test.pl: file open failed\n"
);

# test a message with interpolation

open INPUT, "/totally/bogus/filename/that/doesnt/exist";
ok(
  $error_messages->file_open_failed('myfile'),
  "test.pl: file open failed on myfile: No such file or directory\n"
);

# test a message that falls through to the default handler

ok(
  $error_messages->no_such_thing('myfile'),
  "test.pl: message no_such_thing(myfile)\n"
);


# test a static message with overriden prefix and suffix

ok(
  $status_messages->starting_parser,
  "Starting parser\n\n"
);

# test a relatively complex dynamic with overriden prefix and suffix

ok(
  $status_messages->files_processed(3),
  "Processed 3 files\n\n"
);

# test a pretty complex default behavior

ok(
  $status_messages->bogus('one','two','three'),
  "Unknown message bogus with params one,two,three\n\n"
);

exit;
