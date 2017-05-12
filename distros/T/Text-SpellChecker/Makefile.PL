use ExtUtils::MakeMaker;

my $speller = "Text::Aspell";

eval { require Text::Hunspell };
$speller = "Text::Hunspell" unless $@;

WriteMakefile(
    NAME              => 'Text::SpellChecker',
    VERSION_FROM      => 'lib/Text/SpellChecker.pm', 
    PREREQ_PM         => {
        $speller       => 0,
        'Storable'     => 0,
        'MIME::Base64' => 0
    },
    META_MERGE   => {
        requires  => {perl => '5.010001'},
        resources => {
          repository => 'https://github.com/bduggan/Text-SpellChecker.git',
      }
    },
    LICENSE            => 'perl',
    ($] >= 5.005 ?   
      ( AUTHOR         => 'Brian Duggan <bduggan@matatu.org>') : ()),
);
