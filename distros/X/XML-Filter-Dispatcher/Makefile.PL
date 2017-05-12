use ExtUtils::MakeMaker;

my $have_yapp = eval { require Parse::Yapp ;          1 };
my $have_gvpy = eval { require GraphViz::Parse::Yapp; 1 };

warn <<'NO_HAVE_END' unless $have_yapp && $have_gvpy;

Only if you plan on altering XML::Filter::Dispatcher::Parser
============================================================

NO_HAVE_END

warn <<'NO_HAVE_END' unless $have_yapp ;
You'll need to install Parse::Yapp to rebuild
XML::Filter::Dispatcher::Parser from xfdxpath.yp
To do this, install Parse::Yapp and redo "perl Makefile.PL".
This will add a rule to the Makefile to rebuild Grammar.pm
from xfdxpath.yp.

NO_HAVE_END

warn <<'NO_HAVE_END' unless $have_gvpy ;
Optionally, you may want to graph the grammar.  Install
GraphViz::Parse::Yapp and redo "perl Makefile.PL".  Then
do a "make xfdxpath.png" to build a (large!) xfdxpath.png
file, or "make xfdxpath.dot" to make a file you can play
with using dotty.

NO_HAVE_END

my %soft_prereqs;

$soft_prereqs{Devel::TraceSAX} = 0.021
    if eval "use Devel::TraceSAX; 1";

WriteMakefile(
    NAME          => 'XML::Filter::Dispatcher',
    VERSION_FROM  => 'lib/XML/Filter/Dispatcher.pm',
    EXE_FILES     => [qw( bin/xfd_dump )],

    PREREQ_PM => {
       XML::SAX::Base             => 0,
       XML::NamespaceSupport      => 0,
       XML::SAX::EventMethodMaker => 0,
       XML::SAX::ParserFactory    => 0,
       %soft_prereqs,
    },
);


sub MY::libscan {
    package MY;
    my $self = shift;
    my ( $path ) = @_;
    return '' if /\.sw[a-z]$/;
    return '' unless length $self->SUPER::libscan( $path );
    return $path;
}


# Note the literal tabes herein
sub MY::postamble { return $have_yapp ? <<'POSTAMBLE_END' : '' }
lib/XML/Filter/Dispatcher/Parser.pm : xfdxpath.yp
	yapp -m XML::Filter::Dispatcher::Parser \
		-o lib/XML/Filter/Dispatcher/Parser.pm \
		-s \
		xfdxpath.yp

xfdxpath.output: xfdxpath.yp
	yapp -v xfdxpath.yp

xfdxpath.png: xfdxpath.output
	$(PERL) -MGraphViz::Parse::Yapp \
                -e 'binmode STDOUT; print GraphViz::Parse::Yapp->new( "xfdxpath.output" )->as_png' \
                > xfdxpath.png

xfdxpath.dot: xfdxpath.output
	$(PERL) -MGraphViz::Parse::Yapp \
                -e 'binmode STDOUT; print GraphViz::Parse::Yapp->new( "xfdxpath.output" )->as_dot' \
                > xfdxpath.dot

POSTAMBLE_END
