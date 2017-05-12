use Test::More tests => 2;
BEGIN { use_ok('Win32::MultiLanguage') };

is(
  Win32::MultiLanguage::Transcode(
    65001,            # UTF-8
    1252,             # Windows-1252
    qq(Bj\xC3\xB6rn), # proper UTF-8
    0                 # no flags
  ),
  qq(Bj\xF6rn),
  'Transcodes UTF-8 to Windows-1252 properly'
);

