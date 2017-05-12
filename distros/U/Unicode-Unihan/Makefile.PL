use strict;
use 5.006;
use ExtUtils::MakeMaker;

print "=" x 64, "\n";
print "Preprocessing source text\n";

my $PM = mkdbm("srctxt", "db");
my $PMNAME = "Unicode::Unihan";
my $PMFILE = "Unihan.pm";
$PM->{$PMFILE} = "\$(INST_LIBDIR)/$PMFILE";

print "done.\n";
print "=" x 64, "\n";

WriteMakefile
    (
     'NAME'		=> $PMNAME,
     'VERSION_FROM'	=> $PMFILE,
     'PREREQ_PM'	=> {}, 
     'PM'               => $PM,

     ($] >= 5.005 ?
      (
       ABSTRACT_FROM    => $PMFILE, # retrieve abstract from module
       AUTHOR           => 'Dan Kogai <dankogai@dan.co.jp>',
      ) : ()),
);

sub mkdbm{
    BEGIN{  @AnyDBM_File::ISA = qw(DB_File GDBM_File SDBM_File) ; }
    use AnyDBM_File;
    use Fcntl;
    use File::Path;
    my ($srcdir, $dstdir) = @_;
    opendir my $dh, $srcdir or die "$srcdir:$!";
    -d $dstdir or mkpath [ $dstdir ], 0, 0755 or die "$dstdir:$!";
    my %PM = ();
    for my $src (grep /\.txt$/io, readdir($dh)){
	my $dst = $src; $dst =~ s/\.txt$/.db/o;
	$PM{"$dstdir/$dst"} = "\$(INST_LIBDIR)/Unihan/$dst";
	if (-f "$dstdir/$dst"){
	    print "$dstdir/$dst exists. skipping\n"; 
	    next;
	}
	print "Processing $src...";
	tie my %hash, 'AnyDBM_File', "$dstdir/$dst", O_RDWR|O_CREAT, 0644
	    or die "$dstdir/$dst: $!";
	my $n = 0;
	open my $fh, "$srcdir/$src" or die "$srcdir/$src:$!";
	while(<$fh>){
	    chomp;
	    my ($uni, $val) = split(/\t/, $_);
	    $uni or next;
	    $hash{hex($uni)} = $val;
	    $n++;
	}
	close $fh;
	print "$n characters processed.\n";
    }
    close $dh;
    return \%PM;
}
