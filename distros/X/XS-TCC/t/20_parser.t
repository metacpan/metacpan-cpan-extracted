use strict;
use warnings;

use Test::More;
use XS::TCC;

SCOPE: {
  my $res = XS::TCC::Parser::extract_function_metadata("");
  is_deeply(
    $res,
    {function_names => [], functions => {}},
    'Parsing no code yields empty but valid result'
  );
}

SCOPE: {
  my $res = XS::TCC::Parser::extract_function_metadata(q{
    int foo(int bar) {
      return bar * 2;
    }
  });

  is_deeply(
    $res,
    { 'functions' => {
        'foo' => { 'return_type' => 'int',
                   'arg_names' => ['bar'],
                   'arg_types' => ['int']  }
      },
      'function_names' => ['foo']
    },
    "parsing basic function"
  );
}

SCOPE: {
  my $res = XS::TCC::Parser::extract_function_metadata(q{
    uint32_t *foo(SV **bar, unsigned long long baz) { return &SvUV(*bar); }
  });

  is_deeply(
    $res,
    { 'functions' => {
        'foo' => { 'return_type' => 'uint32_t *',
                   'arg_names' => ['bar', 'baz'],
                   'arg_types' => ['SV **', 'unsigned long long']  }
      },
      'function_names' => ['foo']
    },
    "parsing basic function"
  );
}

done_testing();
