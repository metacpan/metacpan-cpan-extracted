#!perl -w

BEGIN { $| = 1; $n = 1; print "1..1\n"; }

use Text::Bind;

TEST1: {
    my $obj	= new MyObj;
    my $text	= new Text::Bind "t/test$n.in";

    $text->bind_site("imageURL", "/images");
    $text->bind_site("strsite", "##STRING##");
    $text->bind_site("funcsite", \&func);
    $text->bind_site("funcsiteargs", \&func, "ARG1", "ARG2");
    $text->bind_site("objsite", $obj);
    if (!open(FILE, "t/file.txt")) {
	print "not ok $n\n";
	die "Unable to open t/file.txt: $!\n";
    }
    if (!open(OUT, ">t/test$n.out")) {
	print "not ok $n\n";
	die "Unable to create t/test$n.out: $!\n";
    }
    $text->bind_site("filehandlesite", \*FILE);
    if (!$text->read_text(\*OUT)) {
	print "not ok $n\n";
    }
    close FILE;
    print "ok $n\n"; ++$n;
}


########################################################################

sub func {
    my $text = shift;
    my $fh = shift;
    my $site = shift;
    my @args = @_;
    print $fh "##FUNCSITE=$site, ARGS=@args##";
}

package MyObj;

sub new {
    my $this	= { };
    my $class	= shift;
    bless $this, $class;
    $this;
}

sub fill_site {
    my $this	= shift;
    my $text	= shift;
    my $fh	= shift;
    my $site	= shift;

    print $fh <<END;
<p>This data comes from an object binding.
</p>
END

}
