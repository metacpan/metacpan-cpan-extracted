use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Tickit::Terminal::Prompt',
    VERSION_FROM => 'lib/Tickit/Terminal/Prompt.pm',
    ABSTRACT     => 'Scrolling terminal output with a command entry',
    AUTHOR       => 'Joel Roth',
    LICENSE      => 'artistic_2',
    MIN_PERL_VERSION => '5.036',
    PREREQ_PM => {
        'IO::Async::Loop'                     => 0,
        'Tickit::Async'                       => 0,
        'Tickit::Widget::Entry'               => 0,
        'Tickit::Widget::Scroller'            => 0,
        'Tickit::Widget::Scroller::Item::Text'=> 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
);
