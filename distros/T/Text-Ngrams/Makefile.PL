use ExtUtils::MakeMaker;

my $module = 'Text::Ngrams';
my $name   = 'Ngrams.pm';
(my $dir = $module) =~ s/::/-/g;

WriteMakefile (
   'NAME'       => $module,
   'VERSION_FROM' => $name, # finds $VERSION
   'dist' => { COMPRESS=>"gzip",
               SUFFIX=>"gz",
               #PREOP=>('starfish -replace -o=$dir-\$(VERSION)/README README.sfish'
               #        #."cp -f README $dir-\$(VERSION); "
               #       ),
             },
   'clean' => {FILES => "tmp* testfiles/tmp1 Text *~ Makefile.old"},
   'PREREQ_PM' => {
		   # Foo::Ey => '1.00',
		  },
   'PL_FILES' => {},
   ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM => $name, # retrieve abstract from module
     AUTHOR     => 'Vlado Keselj web.cs.dal.ca/~vlado') : 
    ()
    ),
    EXE_FILES => [ 'ngrams.pl' ],
    MAN3PODS => { 'Ngrams.pm' => 'blib/man3/Text::Ngrams.3' },
    MAN1PODS => { 'ngrams.pl' => 'blib/man1/ngrams.pl.1' }
   );

open(M, ">>Makefile") or die;

if ( -f 'priv.make' ) { print M getfile('priv.make') }

close(M);

sub getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or die "getfile:cannot open $f:$!";
    my @r = <F>;
    close(F);
    return wantarray ? @r : join ('', @r);
}
