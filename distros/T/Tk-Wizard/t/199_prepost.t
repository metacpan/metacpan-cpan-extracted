#!/usr/bin/perl -w

use strict;
use ExtUtils::testlib;
use Test::More;
use Tk;
use lib qw(../lib . t/);

    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
        plan tests => 36;
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok('WizTestSettings');
    use_ok('Tk::Wizard');

my $VERSION = do { my @r = ( q$Revision: 1.7 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my @out;
my $Wait = 100;

foreach my $style (qw[ top 95 ]) {
    my $wizard = Tk::Wizard->new(
        -debug => undef,
        -style => $style,
    );
    isa_ok( $wizard, 'Tk::Wizard' );
    ok(
        $wizard->configure(
            -preNextButtonAction   => sub { &preNextButtonAction($wizard) },
            -postNextButtonAction  => sub { &postNextButtonAction($wizard) },
            -preFinishButtonAction => sub { &postNextButtonAction($wizard) },
            -finishButtonAction    => sub { &postNextButtonAction($wizard) },
        ),
        "Configure"
    );
    isa_ok( $wizard->cget( -preNextButtonAction ), "Tk::Callback" );
    ok(
        $wizard->addPage(
            sub {
                $wizard->blank_frame(
                    -title => "page 1",
                    -wait  => $Wait,
                );
            }
        ),
        "blank_frame 1"
    );

    ok(
        $wizard->addPage(
            sub {
                $wizard->blank_frame(
                    -title => "page 2",
                    -wait  => $Wait,
                    -width => 300,
                );
            }
        ),
        "blank_frame 2"
    );

    ok(
        $wizard->addPage(
            sub {
                $wizard->blank_frame(
                    -title => "page 3",
                    -wait  => $Wait,
                    -width => 900,
                );
            }
        ),
        "blank_frame 3"
    );

    ok(
        $wizard->addPage(
            sub {
                $wizard->blank_frame(
                    -title => "page last",
                    -wait  => $Wait,
                );
            }
        ),
        "blank_frame 4"
    );

    $wizard->Show;
    MainLoop;
    pass;
}    # foreach

sub preNextButtonAction {
    my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "pre next button on page $_";

    # diag $out[-1];
    pass "preNextButtonAction";
    return 1;
}

sub postNextButtonAction {
    my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "post next button on page $_";

    # diag $out[-1];
    pass "postNextButtonAction";
    return 1;
}

sub preFinishButtonAction {
    my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "pre finish button on page $_";

    # diag $out[-1];
    pass "preFinishButtonAction";
    return 1;
}

sub finishButtonAction {
    my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "finish button on page $_";

    # diag $out[-1];
    pass "finishButtonAction";
    return 1;
}

__END__

