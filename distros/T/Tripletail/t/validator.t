#! perl -w
use strict;
use warnings;
use Test::Exception;
use Test::More tests =>
  154
  +3  # Char filter.
  +21 # MultiValues filter.
  +9  # ExistentDay,ExistentTime,ExistentDateTime filter.
;

use lib '.';
use t::make_ini {
	ini => {
		TL => {
			trap => 'none',
		},
	},
};
use Tripletail $t::make_ini::INI_FILE;


#---------------------------------- 一般

my $form = $TL->newForm;
  my $validator;
  my $error;
  my @keys;

#---all
  ok($validator = $TL->newValidator, 'newValidator');
  ok($validator->addFilter(
    {
      name  => 'NotEmpty;NotWhitespace',
      email => 'NotEmpty;NotWhitespace[NotEmpty];Email',
    }
  ), 'addFilter');

sub toHash {
	$_ = {map {$_ => 1} @_};
	$_;
}
  ok(@keys = $validator->getKeys, 'getKeys');
  is_deeply(toHash(@keys), toHash(qw{email name}), 'getKeys');

  $form->set(email => ' ');
  ok($error = $validator->check($form), 'check');

  is($error->{name}, 'NotEmpty', 'check');
  is($error->{email}, 'NotEmpty', 'check');

  $form->set(name => '', email => 'mail@@mail');
  $error = $validator->check($form);

  is($error->{name}, 'NotEmpty', 'check');
  is($error->{email}, 'Email', 'check');

#---Blank
  $form->delete('notexists');
  $form->set(space => ' ');
  $form->set(null => '');
  $form->set(null2 => '');
  $form->set(notblank => '123');
  ok($validator->addFilter({
      notexists => 'Blank',
      space     => 'Blank',
      null      => 'Blank',
      null2     => 'Blank;Email',
      notblank  => 'Blank',
  }), 'addFilter');
  $error = $validator->check($form);
  is($error->{notexists}, undef, 'check');
  is($error->{space},     undef, 'check');
  is($error->{null},      undef, 'check');
  is($error->{null2},     undef, 'check');
  is($error->{notblank},  undef, 'check');

#---NotBlank
  $form->delete('notexists');
  $form->set(space => ' ');
  $form->set(null => '');
  $form->set(email => 'tl@tripletail.jp');
  ok($validator->addFilter({
      notexists => 'NotBlank',
      space     => 'NotBlank',
      null      => 'NotBlank',
      email     => 'NotBlank',
  }), 'addFilter');
  $error = $validator->check($form);
  is($error->{notexists}, 'NotBlank', 'check');
  is($error->{space},     'NotBlank', 'check');
  is($error->{null},      'NotBlank', 'check');
  is($error->{email},          undef, 'check');

#---Empty
  $form->delete('notexists');
  $form->set(space => ' ');
  $form->set(null => '');
  $form->set(null2 => '');
  $form->set(notempty => '123');
  ok($validator->addFilter({
      notexists => 'Empty',
      space     => 'Empty',
      null      => 'Empty',
      null2     => 'Empty;Email',
      notempty  => 'Empty',
  }), 'addFilter');
  $error = $validator->check($form);
  is($error->{notexists}, undef, 'check');
  is($error->{space},     undef, 'check');
  is($error->{null},      undef, 'check');
  is($error->{null2},     undef, 'check');

#---NotEmpty
  $form->delete('notexists');
  $form->set(space => ' ');
  $form->set(null => '');
  $form->set(email => 'tl@tripletail.jp');
  ok($validator->addFilter({
      notexists => 'NotEmpty',
      space     => 'NotEmpty',
      null      => 'NotEmpty',
      email     => 'NotEmpty',
  }), 'addFilter');
  ok($validator->addFilter({
      true  => 'NotEmpty',
      false  => 'NotEmpty',
  }), 'addFilter');
  $error = $validator->check($form);
  is($error->{notexists}, 'NotEmpty', 'check');
  is($error->{space},          undef, 'check');
  is($error->{null},      'NotEmpty', 'check');
  is($error->{email},          undef, 'check');

#---NotWhitespace
  $form->delete('notexists');
  $form->set(space => ' ');
  $form->set(null => '');
  $form->set(email => 'tl@tripletail.jp');
  ok($validator->addFilter({
      notexists => 'NotWhitespace',
      space     => 'NotWhitespace',
      null      => 'NotWhitespace',
      email     => 'NotWhitespace',
  }), 'addFilter');
  $error = $validator->check($form);
  is($error->{notexists},           undef, 'check');
  is($error->{space},     'NotWhitespace', 'check');
  is($error->{null},                undef, 'check');
  is($error->{email},               undef, 'check');

#---PrintableAscii
  ok($validator->addFilter({
      true  => 'PrintableAscii',
      false  => 'PrintableAscii',
  }), 'addFilter');
  $form->set(true => 'a', false => "\n");
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'PrintableAscii', 'check');

#---Wide
  ok($validator->addFilter({
      true  => 'Wide',
      false  => 'Wide',
  }), 'addFilter');
  $form->set(true => '　', false => ' ');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Wide', 'check');

#---Password
  ok($validator->addFilter({
      true  => 'Password',
      false  => 'Password',
  }), 'addFilter');
  $form->set(true => '1Aa]', false => '1Aa');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Password', 'check');

  ok($validator->addFilter({
      true  => 'Password(alpha,ALPHA,digit)',
      false  => 'Password(alpha,ALPHA,digit)',
  }), 'addFilter');
  $form->set(true => '1Aa', false => '1AB');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Password', 'check');

#---ZipCode
  ok($validator->addFilter({
      true  => 'ZipCode',
      false  => 'ZipCode',
  }), 'addFilter');
  $form->set(true => '000-0000', false => '00a-0000');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'ZipCode', 'check');

#---TelNumber
  ok($validator->addFilter({
      true  => 'TelNumber',
      false  => 'TelNumber',
  }), 'addFilter');
  $form->set(true => '0-0', false => 'a-0');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'TelNumber', 'check');

#---Email
  ok($validator->addFilter({
      true  => 'Email',
      false  => 'Email',
  }), 'addFilter');
  $form->set(true => 'null@example.org', false => 'null.@example.org');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Email', 'check');

#---MobileEmail
  ok($validator->addFilter({
      true  => 'MobileEmail',
      false  => 'MobileEmail',
  }), 'addFilter');
  $form->set(true => 'null.@example.org', false => 'null@@example.org');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'MobileEmail', 'check');

#---Integer
  ok($validator->addFilter({
      true  => 'Integer(1,10)',
      false  => 'Integer(1,9)',
  }), 'addFilter');
  $form->set(true => 10, false => 10);
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Integer', 'check');

  ok($validator->addFilter({
      true  => 'Integer(,20)',
      false  => 'Integer(,20)',
  }), 'addFilter');
  $form->set(true => 10, false => '100');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Integer', 'check');

  ok($validator->addFilter({
      true  => 'Integer',
      false  => 'Integer',
  }), 'addFilter');
  $form->set(true => 10, false => '10a');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Integer', 'check');

#---Real
  ok($validator->addFilter({
      true  => 'Real(1,2)',
      false  => 'Real(1,1)',
  }), 'addFilter');
  $form->set(true => 1.5, false => 1.5);
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Real', 'check');

  ok($validator->addFilter({
      true  => 'Real(,2)',
      false  => 'Real(,1)',
  }), 'addFilter');
  $form->set(true => 1.5, false => 1.5);
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Real', 'check');

  ok($validator->addFilter({
      true  => 'Real',
      false  => 'Real',
  }), 'addFilter');
  $form->set(true => 1.5, false => '10a');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Real', 'check');

#---Hira
  ok($validator->addFilter({
      true  => 'Hira',
      false  => 'Hira',
  }), 'addFilter');
  $form->set(true => 'ひらがな', false => 'カタカナ');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Hira', 'check');

#---Kata
  ok($validator->addFilter({
      true  => 'Kata',
      false  => 'Kata',
  }), 'addFilter');
  $form->set(true => 'カタカナ', false => 'ひらがな');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Kata', 'check');

#---ExistentDay
  ok($validator->addFilter({
      true  => 'ExistentDay',
      true2  => 'ExistentDay(format => "YMD")',
      false  => 'ExistentDay',
  }), 'addFilter');
  $form->set(true => '2006-02-28', true2 => '2006-2-28', false => '2006-02-29');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{true2}, undef, 'check');
  is($error->{false}, 'ExistentDay', 'check');

#---ExistentTime
  ok($validator->addFilter({
      true  => 'ExistentTime',
      true2  => 'ExistentTime(format => "HMS")',
      false  => 'ExistentTime',
  }), 'addFilter');
  $form->set(true => '00:00:00', true2 => '0:0:0', false => '24:00:00');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{true2}, undef, 'check');
  is($error->{false}, 'ExistentTime', 'check');
  
#---ExistentDateTime
  ok($validator->addFilter({
      true  => 'ExistentDateTime',
      true2  => "ExistentDateTime('format' => 'YMD HMS', date_delim => '/', time_delim => ':')",
      false  => 'ExistentDateTime',
  }), 'addFilter');
  $form->set(true => '2006-02-28 00:00:00', true2 => '2006/2/28 0:0:0', false => '2006-02-28 24:00:00');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{true2}, undef, 'check');
  is($error->{false}, 'ExistentDateTime', 'check');

#---Gif
  ok($validator->addFilter({
      true  => 'Gif',
      false  => 'Gif',
  }), 'addFilter');
  $form->set(true => 'GIF89a', false => 'GIF');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Gif', 'check');

#---Jpeg
  ok($validator->addFilter({
      true  => 'Jpeg',
      false  => 'Jpeg',
  }), 'addFilter');
  $form->set(true => "\xFF\xD8", false => 'Jpeg');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Jpeg', 'check');

#---Png
  ok($validator->addFilter({
      true  => 'Png',
      false  => 'Png',
  }), 'addFilter');
  $form->set(true => "\x89PNG\x0D\x0A\x1A\x0A", false => 'Png');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Png', 'check');

#---HttpUrl
  ok($validator->addFilter({
      true  => 'HttpUrl',
      true2  => 'HttpUrl(s)',
      false  => 'HttpUrl',
  }), 'addFilter');
  $form->set(true => 'http://tripletail.jp/', true2 => 'https://tripletail.jp/', false => 'https://tripletail.jp/');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'HttpUrl', 'check');

  ok($validator->addFilter({
      true  => 'HttpUrl(a)',
      true2  => 'HttpUrl(s)',
      false  => 'HttpUrl(s)',
  }), 'addFilter');
  $form->set(true => 'http://tripletail.jp/', true2 => 'http://tripletail.jp/', false => 'tripletail.jp');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{true2}, undef, 'check');
  is($error->{false}, 'HttpUrl', 'check');

#---isHttpsUrl
  ok($validator->addFilter({
      true  => 'HttpsUrl',
      false  => 'HttpsUrl',
  }), 'addFilter');
  $form->set(true => 'https://tripletail.jp/', false => 'http://tripletail.jp/');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'HttpsUrl', 'check');

#---Len
  ok($validator->addFilter({
      true  => 'Len(1,3)',
      true2  => 'Len(,3)',
      true3  => 'Len',
      false  => 'Len(1,2)',
  }), 'addFilter');
  $form->set(true => 'あ', true2 => 'あ', false => 'あ');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{true2}, undef, 'check');
  is($error->{true3}, undef, 'check');
  is($error->{false}, 'Len', 'check');

#---SjisLen
  ok($validator->addFilter({
      true  => 'SjisLen(1,2)',
      true2  => 'SjisLen(,2)',
      true3  => 'SjisLen',
      false  => 'SjisLen(1,1)',
  }), 'addFilter');
  $form->set(true => 'あ', true2 => 'あ', false => 'あ');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{true2}, undef, 'check');
  is($error->{true3}, undef, 'check');
  is($error->{false}, 'SjisLen', 'check');

#---CharLen
  ok($validator->addFilter({
      true  => 'CharLen(1,2)',
      true2  => 'CharLen(,2)',
      true3  => 'CharLen',
      false  => 'CharLen(1,1)',
  }), 'addFilter');
  $form->set(true => 'あい', true2 => 'あい', false => 'あい');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{true2}, undef, 'check');
  is($error->{true3}, undef, 'check');
  is($error->{false}, 'CharLen', 'check');

#---Portable
  ok($validator->addFilter({
      true  => 'Portable',
      false  => 'Portable',
      false2  => 'Portable',
      force  => 'ForcePortable',
  }), 'addFilter');
  $form->set(true => 'I',
	false => 'Ⅰ', 
	false2 => Unicode::Japanese->new("\x00\x0f\xf0\x10", 'ucs4')->utf8,
	force => Unicode::Japanese->new("\x00\x0f\xf0\x10", 'ucs4')->utf8,
  );
  $error = $validator->correct($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Portable', 'check');
  is($error->{false2}, 'Portable', 'check');
  is($form->get('force'), '', 'check force');

#---PcPortable
  ok($validator->addFilter({
      true  => 'PcPortable',
      true2 => 'PcPortable',
      false => 'PcPortable',
      force => 'ForcePcPortable',
  }), 'addFilter');
  $form->set(true => 'I',
	true2 => 'Ⅰ', 
	false => Unicode::Japanese->new("\x00\x0f\xf0\x10", 'ucs4')->utf8,
	force => Unicode::Japanese->new("\x00\x0f\xf0\x10", 'ucs4')->utf8,
  );
  $error = $validator->correct($form);
  is($error->{true}, undef, 'check');
  is($error->{true2}, undef, 'check');
  is($error->{false}, 'PcPortable', 'check');
  is($form->get('force'), '', 'check force');
  $validator = $TL->newValidator;

#---DomainName
  ok($validator->addFilter({
      true  => 'DomainName',
      false => 'DomainName',
  }), 'addFilter');
  $form->set(true => 'example.com', false => 'example-.com');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'DomainName', 'check');

#---IpAddress
  ok($validator->addFilter({
      true  => 'IpAddress(127.0.0.1/24)',
      false  => 'IpAddress(127.0.0.1/24)',
  }), 'addFilter');
  $form->set(true => '127.0.0.1', false => '128.0.0.1');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'IpAddress', 'check');
  ok($validator->addFilter({
      true  => 'IpAddress(0.0.0.0/0)',
      false  => 'IpAddress(0.0.0.0/0)',
  }), 'addFilter');
  $form->set(true => '127.0.0.1', false => '1.0.0');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'IpAddress', 'check');

#---Enum
  ok($validator->addFilter({
      true  => 'Enum(1,あ,テスト)',
      false  => 'Enum(1,あ,テスト)',
  }), 'addFilter');
  $form->set(true => 'テスト', false => 'あい');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'Enum', 'check');

#---Or
  ok($validator->addFilter({
      true  => 'Or(Hira|Kata)',
      true2  => 'Or(Hira|Kata)',
      false  => 'Or(Hira|Kata)',
  }), 'addFilter');
  $form->set(true => 'テスト', true2 => 'あ', false => 'あテスト');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{true2}, undef, 'check');
  is($error->{false}, 'Or', 'check');

#---RegExp
  ok($validator->addFilter({
      true  => 'RegExp(^\d+$)',
      false  => 'RegExp(^\d+$)',
  }), 'addFilter');
  $form->set(true => '12345', false => '12345 ');
  $error = $validator->check($form);
  is($error->{true}, undef, 'check');
  is($error->{false}, 'RegExp', 'check');


  ok($validator->addFilter({true => 'test;file'}), 'addFilter');
  dies_ok {$validator->check($form)} 'check die';

#---check with correct filter
  my $validator_correct = $TL->newValidator->addFilter({ correct => 'ForceNumber' });
  dies_ok {$validator->check($form)} 'check with correct filter';

#---correct with const form
  my $form_const = $TL->newForm->set(correct => 'test123')->const;
  dies_ok {$validator->correct($form_const)} 'correct with const form';


#---Char
SKIP:
{
  pass("Char validator");
  lives_ok {
    $TL->newValidator()->addFilter({ test => 'Char(Digit)', })->check($TL->newForm());
  } ": Char exists" or skip "Char validator not exists", 3-2;

  my $form = $TL->newForm({
    digit => '0123456789',
    lower => 'abcdefghijklmnopqrstuvwxyz',
    upper => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  });
  my $vtor = $TL->newValidator()->addFilter({
    digit => 'Char(Digit)',
    lower => 'Char(LowerAlpha)',
    upper => 'Char(UpperAlpha)',
  });
  is($vtor->check($form), undef, ": check");
}

#---multiply
SKIP:
{
  my ($form, $vtor);

  pass("MultiValues filter");

  $form = $TL->newForm({
    one   => [1],
    two   => [1,2],
    three => [1,2,3],
  });

  my $exists = 1;
  lives_ok {
    $TL->newValidator()->addFilter({ test => 'NoValues', })->check($form);
  } ": NoValues exists" or $exists = 0;
  lives_ok {
    $TL->newValidator()->addFilter({ test => 'SingleValue', })->check($form);
  } ": SingleValue exists" or $exists = 0;
  lives_ok {
    $TL->newValidator()->addFilter({ test => 'MultiValues(1)', })->check($form);
  } ": MultiValues exists" or $exists = 0;
  if( !$exists )
  {
    skip "NoValues/SingleValue/MultiValues not exists", 21-4;
  }

  # NoValues.

  $vtor = $TL->newValidator()->addFilter({
    none => 'NotEmpty',
  });
  is_deeply($vtor->check($form), {none=>'NotEmpty'}, ": none : NotEmpty ng");

  $vtor = $TL->newValidator()->addFilter({
    none => 'NoValues;NotEmpty',
  });
  is_deeply($vtor->check($form), undef, ": none : NoValues;NotEmpty ok");

  $vtor = $TL->newValidator()->addFilter({
    two => 'NoValues;NotEmpty',
  });
  is_deeply($vtor->check($form), undef, ": two : NoValues;NotEmpty ok");

  # SingleValue.

  $vtor = $TL->newValidator()->addFilter({
    none => 'SingleValue',
  });
  is_deeply($vtor->check($form), {none=>'SingleValue'}, ": SingleValue ng none");

  $vtor = $TL->newValidator()->addFilter({
    one => 'SingleValue',
  });
  is_deeply($vtor->check($form), undef, ": SingleValue ok [1]");

  $vtor = $TL->newValidator()->addFilter({
    two => 'SingleValue',
  });
  is_deeply($vtor->check($form), {two=>'SingleValue'}, ": SingleValue ng [1,2]");

  # MultiValues(2).

  $vtor = $TL->newValidator()->addFilter({
    none => 'MultiValues(2,)',
  });
  is_deeply($vtor->check($form), {none=>'MultiValues'}, ": MultiValues(2) ng none");

  $vtor = $TL->newValidator()->addFilter({
    one => 'MultiValues(2,)',
  });
  is_deeply($vtor->check($form), {one=>'MultiValues'}, ": MultiValues(2) ng [1]");

  $vtor = $TL->newValidator()->addFilter({
    two => 'MultiValues(2,)',
  });
  is_deeply($vtor->check($form), undef, ": MultiValues(2) ok [1,2]");

  $vtor = $TL->newValidator()->addFilter({
    three => 'MultiValues(2)',
  });
  is_deeply($vtor->check($form), undef, ": MultiValues(2) ok [1,2,3]");

  # MultiValues(1,2).

  $vtor = $TL->newValidator()->addFilter({
    none => 'MultiValues(1,2)',
  });
  is_deeply($vtor->check($form), {none=>'MultiValues'}, ": MultiValues(1,2) ng none");

  $vtor = $TL->newValidator()->addFilter({
    one => 'MultiValues(1,2)',
  });
  is_deeply($vtor->check($form), undef, ": MultiValues(1,2) ok [1]");

  $vtor = $TL->newValidator()->addFilter({
    two => 'MultiValues(1,2)',
  });
  is_deeply($vtor->check($form), undef, ": MultiValues(1,2) ok [1,2]");

  $vtor = $TL->newValidator()->addFilter({
    three => 'MultiValues(1,2)',
  });
  is_deeply($vtor->check($form), {three=>'MultiValues'}, ": MultiValues(1,2) ng [1,2,3]");

  # none/MultiValues(0,)

  $vtor = $TL->newValidator()->addFilter({
    none => 'SingleValue',
  });
  is_deeply($vtor->check($form), {none=>'SingleValue'}, ": none / SingleValue ng");

  $vtor = $TL->newValidator()->addFilter({
    none => 'NoValues;SingleValue',
  });
  is_deeply($vtor->check($form), undef, ": none / NoValues;SingleValue accepted");

  $vtor = $TL->newValidator()->addFilter({
    none => 'MultiValues(0,);SingleValue',
  });
  is_deeply($vtor->check($form), undef, ": none / MultiValues(0,);SingleValue accepted");
}

