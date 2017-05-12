{ package aa;
use Scope::Upper qw/localize reap unwind want_at :words/;
sub too {
    #localize '$tt', 'nacana' => UP;
    eval q{
        sub foo {
            #require strict; strict->import()
            require strict; strict->import();
            require Moose; Moose->import();
            #my $a = 'Moose::import';
            my $p = caller;
            print "Imported into $p\n";
        }
    };
    #reap \&foo => HERE;
    #reap sub { require Moose; Moose->import } => UP;
    reap sub { require strict; strict->import } => HERE;
    #reap sub { require Scalar::Util; Scalar::Util->import('refaddr') } => UP;
    reap sub { require List::Util; my $f='List::Util::import'; @_=('List::Util::import', 'first'); goto &$f } => HERE;

}
}

{
    package JJ;
    #BEGIN { aa::too(); }
    $b = 11;
#BEGIN { require Moose; Moose->import() }

    #has 'aa' => ( is=>'rw', isa=>'Str' );
}

package main;
#BEGIN { require List::Util; my $f='List::Util::import'; local @_=('List::Util::import', 'first'); goto &$f };
BEGIN { require Moose; my $f='Moose::import'; local @_=('Moose::import'); goto &$f };
#BEGIN { aa::too(); }
my $bb = 12;
#print "ADD=" . refaddr( \$bb );
#print "TT=" . $tt;
