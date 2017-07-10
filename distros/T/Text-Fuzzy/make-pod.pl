#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Template;
use FindBin '$Bin';
use Perl::Build qw/get_info get_commit/;
use Perl::Build::Pod ':all';
use BKB::Stuff;

make_examples ("$Bin/examples", undef, undef);

# Template toolkit variable holder

my %vars;
my $tt = Template->new (
    ABSOLUTE => 1,
    FILTERS => {
        xtidy => [
            \& xtidy,
            0,
        ],
    },
    INCLUDE_PATH => [
	$Bin,
	"$Bin/examples",
	pbtmpl (),
    ],
    STRICT => 1,
);
my $info = get_info ();
$vars{info} = $info;
$vars{commit} = get_commit ();
my $pod = $info->{pod};
chmod 0644, $pod;
$tt->process ("$pod.tmpl", \%vars, $pod) or die '' . $tt->error ();
chmod 0444, $pod;
exit;

