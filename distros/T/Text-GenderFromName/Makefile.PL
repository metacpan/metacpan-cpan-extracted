use strict;
use ExtUtils::MakeMaker;

my %opts =
    ( 'NAME' => 'Text::GenderFromName',
      'VERSION_FROM' => 'GenderFromName.pm',
      );

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'ABSTRACT_FROM'} = 'GenderFromName.pm';
    $opts{'AUTHOR'} = 'Eamon Daly <eamon@eamondaly.com>';
}

eval {
    require Text::GenderFromName;
    if ($Text::GenderFromName::VERSION < .30) {
        print <<END_OF_WARNING;

Version $Text::GenderFromName::VERSION of Text::GenderFromName found!

WARNING! You seem to have an older version of Text::GenderFromName
already installed. Version 0.30 makes significant changes in behavior,
most notably using completely new seed lists and a very strict
matching method by default.

See Changes for details and the COMPATIBILITY section in the perldoc
for how to revert to a (mostly) backward compatible mode.

END_OF_WARNING
    }
};

eval "require Text::DoubleMetaphone";

if ($@) {
    print <<END_OF_WARNING;

You don't seem to have Text::DoubleMetaphone installed. This isn't
fatal, but the author strongly recommends installing it for fuzzy
matching. See the perldoc for this module for details.

END_OF_WARNING

    my $x = prompt('Would you like me to make Text::DoubleMetaphone a prerequisite for this module [Y/n]? ');
    $opts{'PREREQ_PM'} = { 'Text::DoubleMetaphone' => '0.05' } if $x ne 'n';
}

ExtUtils::MakeMaker::WriteMakefile(%opts);
