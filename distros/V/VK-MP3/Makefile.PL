use 5.008008;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'VK::MP3',
    AUTHOR        => 'Aleksander Alekseev <eax@cpan.org>',
    LICENSE       => 'perl_5',
    VERSION_FROM  => 'lib/VK/MP3.pm',
    ABSTRACT_FROM => 'lib/VK/MP3.pm',
    EXE_FILES     => [qw!bin/vkmp3!],
    PREREQ_PM     => {
      'LWP'                  => 6.04,
      'LWP::Protocol::https' => 6.03,
      'HTML::Entities'       => 3.69,
      'URI::Escape'          => 3.31,
      'Test::Mock::LWP'      => 0.06,
      'Text::Unidecode'      => 0.04,
      'MP3::Info'            => 1.24,
      'JSON::XS'             => 2.32,
      'Encode'               => 2.47,
    },
    META_MERGE   => {
      requires  => { perl => '5.008008' },
      resources => {
        homepage    => 'http://eax.me/vk-get-mp3/',
        license     => 'http://dev.perl.org/licenses/',
        repository  => 'https://github.com/afiskon/p5-vk-mp3',
        bugtracker  => 'https://github.com/afiskon/p5-vk-mp3/issues'
      },
    }
  );
