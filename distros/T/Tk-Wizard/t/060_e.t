use strict;
use warnings;
my $VERSION = do { my @r = ( q$Revision: 2.074 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

=head1 TODO

Test the BACK button

Run test 30

=cut

use lib qw(../lib . t/);
use ExtUtils::testlib;
use Test::More;
use Tk;
use Carp;

use Data::Dumper;
$Data::Dumper::Deparse = 1;

# $ENV{TEST_INTERACTIVE} = 1;

    eval { require IO::Capture::Stderr::Extended };
    if ( $@ ) {
        plan skip_all => 'Test requires IO::Capture::Stderr::Extended';
	}

	else {
		my $mwTest;
		eval { $mwTest = Tk::MainWindow->new };
		if ($@) {
			plan skip_all => 'Test irrelevant without a display';
		}
		else {
			plan tests => 13;
		}
		$mwTest->destroy if Tk::Exists($mwTest);
		use_ok('Tk::Wizard', ':old') or BAIL_OUT "Is this a fake-log4perl error?";
		use_ok('WizTestSettings');
	}


my $wiz = Tk::Wizard->new( -debug => 1, );

isa_ok( $wiz, "Tk::Wizard" );

$_ = $wiz->addPage(
	sub {
		$wiz->blank_frame(
			-wait     	=> $ENV{TEST_INTERACTIVE}? -1 : 250,
			-title    	=> "Page One Title ($wiz->{-style} style)",
			-subtitle 	=> "Page One Subtitle ($wiz->{-style} style)",
			-text     	=> '',
			-background	=> 'green',
		);
	},
);
is($_, 1, 'Added one page via code ref');

$_ = $wiz->addPage(
	sub {
		$wiz->blank_frame(
			-wait     	=> $ENV{TEST_INTERACTIVE}? -1 : 250,
			-title    	=> "Page Two Title ($wiz->{-style} style)",
			-subtitle 	=> "Page Two Subtitle ($wiz->{-style} style)",
			-text     	=> '',
			-background	=> 'green',
		);
	},
	-preNextButtonAction => sub { warn "My -preNextButtonAction called by page 1"; },
	-postNextButtonAction => sub { warn "My -postNextButtonAction called by page 1"; },
);
is($_, 2, 'Added second page via code ref');

# warn "Pages: ",Dumper $wiz->{_pages};


$_ = $wiz->addPage(
	sub {
		$wiz->blank_frame(
			-wait     	=> $ENV{TEST_INTERACTIVE}? -1 : 250,
			-title    	=> "Last Page Title ($wiz->{-style} style)",
			-subtitle 	=> "Last Page Subtitle ($wiz->{-style} style)",
			-text     	=> '',
			-background => 'green',
		);
	  }
);
is($_, 3, 'Added page via code ref');

isa_ok( $wiz->{_pages_e}, 'HASH', 'page event stack');
isa_ok( $wiz->{_pages_e}->{-preNextButtonAction}, 'ARRAY', 'event stack');
isa_ok( $wiz->{_pages_e}->{-postNextButtonAction}, 'ARRAY', 'event stack');
isa_ok( $wiz->{_pages_e}->{-preNextButtonAction}->[1], 'CODE', 'event stack entry');
isa_ok( $wiz->{_pages_e}->{-postNextButtonAction}->[1], 'CODE', 'event stack entry');

my $capture = IO::Capture::Stderr::Extended->new;
$capture->start;
$wiz->Show;
$capture->stop;

# unless ( is( $capture->all_screen_lines, 0, "No warnings") ){
# 	my @errs = $capture->all_screen_lines();
# 	BAIL_OUT @errs;
# }

$capture = IO::Capture::Stderr::Extended->new;
$capture->start;
MainLoop;
$capture->stop;

unless ( is( $capture->matches(qr/My -preNextButtonAction called by page 1/), 2, 'Event fired pre' ) ){
	my @errs = $capture->all_screen_lines();
	BAIL_OUT @errs;
}
unless ( is( $capture->matches(qr/My -postNextButtonAction called by page 1/), 2, 'Event fired post' ) ){
	my @errs = $capture->all_screen_lines();
	BAIL_OUT @errs;
}



__END__
