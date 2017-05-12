use strict;
my $VERSION = do { my @r = ( q$Revision: 1.6 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };
use ExtUtils::testlib;
use Test::More;
use Tk;
use lib qw(../lib . t/);


BEGIN {
	plan skip_all => 'No longer used';
}

__END__

    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
        plan "no_plan";    # TODO Can't count tests atm
    }
    $mwTest->destroy if Tk::Exists($mwTest);
	use_ok('WizTestSettings');
	use_ok('Tk::Wizard') or BAIL_OUT;
}

my $wizard = Tk::Wizard->new( -title => "Bad Argument Test", );
isa_ok( $wizard, "Tk::Wizard" );

my $i1 = $wizard->addPage(
    sub {
        return $wizard->blank_frame(
            -title => "title",
            -text  => 'test',
        );
    }
);
is( $i1, 1, 'Add page rv' );

eval {
	$wizard->addPage( "This should break" )
};
like( $@, qr/addPage requires one or more CODE references as arguments/, 'err msg' );

exit;

__END__


