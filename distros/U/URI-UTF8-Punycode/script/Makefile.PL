use ExtUtils::Embed;
use ExtUtils::MakeMaker;
use Config;

open PNY, '>./puny';
print PNY "#!$Config{perlpath}\n\n";
open PIN, '<./puny.in';
print PNY join '', <PIN>;
close(PIN);
chmod 0755, './puny';
close(PNY);

WriteMakefile(
  NAME          => 'puny',
  AUTHOR        => 'Twinkle Computing <twinkle@cpan.org>',
  LICENSE       => 'GPL_3',
);
