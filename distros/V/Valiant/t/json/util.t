use Test::Most;
use Valiant::JSON::Util 'escape_javascript';

{
  my $string = qq[
    This
    is a 
    test
    "
    '
  ];
  is escape_javascript($string), q[\n    This\n    is a \n    test\n    \"\n    \'\n  ], "properly escaped";
}

done_testing;
