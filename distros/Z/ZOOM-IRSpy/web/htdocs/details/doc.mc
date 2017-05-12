<%once>
use Pod::Html;
use IO::Dir;
</%once>
<%perl>
my $libdir = $r->dir_config("IRSpyLibDir");
my $module = utf8param($r, "module");
if (!defined $module) {
    print "     <ul>\n";
    render_doc_links($libdir, "ZOOM", 6);
    print "     </ul>\n";
} else {
    print "<b>Documentation for '$module'</b>\n";
    { my $dir = "/tmp/pod2html"; mkdir $dir; chdir $dir || die $!; }
    # For some reason, output to standard output doesn't appear
    my $name = "ZOOM.html";
    pod2html("$libdir/$module", "--outfile=$name");
    open F, "<$name" or die "can't open '$name': $!";
    my $text = join("", <F>);
    close F;
    $text =~ s/.*?<body.*?>//gs;
    $text =~ s/<\/body.*//gs;
    print $text;
}

sub render_doc_links {
    my($base, $dir, $level) = @_;

    my $dh = new IO::Dir("$base/$dir")
	or die "can't open directory handle for '$base/$dir'";

    print " " x $level, "<li><b>$dir</b></li>\n";
    print " " x $level, "<li><ul>\n";

    my(@files, @dirs);
    while (my $file = $dh->read()) {
	if ($file eq "." || $file eq ".." || $file eq "CVS") {
	    next;
	} elsif (-d "$base/$dir/$file") {
	    push @dirs, $file;
	} else {
	    push @files, $file;
	}
    }

    foreach my $file (sort @files) {
	print(" " x $level,
	      qq[ <li><a href="?module=$dir/$file">$file</a></li>\n]);
    }

    foreach my $file (sort @dirs) {
	render_doc_links($base, "$dir/$file", $level+1);
    }

    print " " x $level, "</ul></li>\n";
    undef $dh;
}
</%perl>
