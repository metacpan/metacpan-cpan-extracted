use ExtUtils::MakeMaker;

my $pm = 'HP';

WriteMakefile(
    NAME         => "Tk::Calculator::RPN::$pm",
    DISTNAME     => "Tk-Calculator-RPN-$pm",
    EXE_FILES    => ['tkhpcalc'],
    MAN3PODS     => {},
    PREREQ_PM    => {
        'Getopt::EvaP'         => 2.3.5,
        'Tk::LCD'              => 1.2,
        'Tk::ProgressBar::Mac' => 1.1,
        'Tk::SlideSwitch'      => 1.1,
        'Tk::Splashscreen'     => 1.0,
    },
    PM           => {
        "Tk/Calculator/RPN/${pm}.pm"                  => "\$(INST_LIBDIR)/${pm}.pm",
        "Tk/Calculator/RPN/${pm}_16C.pm"              => "\$(INST_LIBDIR)/${pm}_16C.pm",
        "Tk/Calculator/RPN/${pm}_21.pm"               => "\$(INST_LIBDIR)/${pm}_21.pm",
        "Tk/Calculator/RPN/images/hp_16c-back.gif"    => "\$(INST_LIBDIR)/images/hp_16c-back.gif",
        "Tk/Calculator/RPN/images/hp_16c-splash.gif"  => "\$(INST_LIBDIR)/images/hp_16c-splash.gif",
        "Tk/Calculator/RPN/images/hp_21-back.gif"     => "\$(INST_LIBDIR)/images/hp_21-back.gif",
        "Tk/Calculator/RPN/images/hp_21-splash.gif"   => "\$(INST_LIBDIR)/images/hp_21-splash.gif",
        "Tk/Calculator/RPN/images/pi.xbm"             => "\$(INST_LIBDIR)/images/pi.xbm",
        "Tk/Calculator/RPN/images/rold.xbm"           => "\$(INST_LIBDIR)/images/rold.xbm",
        "Tk/Calculator/RPN/images/rolu.xbm"           => "\$(INST_LIBDIR)/images/rolu.xbm",
        "Tk/Calculator/RPN/images/swap.xbm"           => "\$(INST_LIBDIR)/images/swap.xbm",
    },
    VERSION_FROM => "Tk/Calculator/RPN/$pm.pm",
    dist         => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ($] >= 5.005 ?
	(ABSTRACT => 'Hewlett-Packard RPN Calculators',
	 AUTHOR   => 'Stephen O. Lidie (sol0@lehigh.edu)') : ()),
);
