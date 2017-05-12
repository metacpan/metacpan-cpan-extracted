# Generate a Makefile for SenseClusters. 
# $Id: Makefile.PL,v 1.75 2015/10/03 14:12:13 tpederse Exp $

# if you want to understand how Makefile.PL works, you should check out
# http://search.cpan.org/~rgarcia/perl-5.6.2/lib/ExtUtils/MakeMaker.pm

print "Welcome to SenseClusters !\n" unless -f "Makefile";

use 5.006;		# require perl 5.6

use ExtUtils::MakeMaker;

# lists that specify executables to copy into /bin

# wrappers from main dir

my @wrappers = qw (discriminate.pl);

# Now the Toolkit programs !

# preprocessors

my @toolkit_preprocess_plain = qw (text2sval.pl);

my @toolkit_preprocess_sval = qw (preprocess.pl balance.pl frequency.pl filter.pl keyconvert.pl prepare_sval2.pl windower.pl sval2plain.pl maketarget.pl);

# count 

my @toolkit_count = qw (reduce-count.pl);

# vector constructors

my @toolkit_vector = qw (nsp2regex.pl order1vec.pl order2vec.pl wordvec.pl);

# svd interface

my @toolkit_svd = qw (mat2harbo.pl svdpackout.pl);

# matrix constructors

my @toolkit_matrix = qw (simat.pl bitsimat.pl);

# evaluation programs

my @toolkit_evaluate = qw (cluto2label.pl label.pl report.pl format_clusters.pl);

# cluster labeling program

my @toolkit_cluslabel = qw (clusterlabeling.pl);

# cluster stopping program

my @toolkit_cluststop = qw (clusterstopping.pl);

# svdcompare.pl - only used for testing
## my @testing_svd_svdpackout = qw (svdcompare.pl);

WriteMakefile(

	'NAME'		=> 'Text::SenseClusters',
        'VERSION_FROM'      => 'lib/Text/SenseClusters.pm',   

## This lists various CPAN modules that are used and must be available
## for SenseClusters to function.

	'PREREQ_PM'	=> {'Bit::Vector' => '6.3',
			    'Set::Scalar' => '1.19',
			    'PDL' => '2.006',
			 ## the following modules were developed in Duluth,
			 ## home of SenseClusters
			    'Algorithm::Munkres' => '0.07',
			    'Algorithm::RandomMatrixGeneration' => '0.06',
			    'Math::SparseVector' => '0.03',
			    'Math::SparseMatrix' => '0.02',
			    'Text::NSP' => '1.09'},

## if you change INSTALLDIRS from site to perl or default, some of the
## below must change too. Search for INSTALLDIRS to find where. 

	'INSTALLDIRS'	=> 'site',

# do not install any man3 documentation

	'INSTALLMAN3DIR' => 'none',

#  install man pages, we use MAN1PODS to keep all man pages in /man1

	'MAN1PODS' =>  {
# only create man pages for *.pl programs in the Toolkit of SenseClusters
		'lib/Text/SenseClusters.pm' => '$(INST_MAN1DIR)/SenseClusters.1',
		'discriminate.pl' => '$(INST_MAN1DIR)/discriminate.pl.1',
		'Toolkit/clusterlabel/clusterlabeling.pl' => '$(INST_MAN1DIR)/clusterlabeling.pl.1',
		'Toolkit/clusterstop/clusterstopping.pl' => '$(INST_MAN1DIR)/clusterstopping.pl.1',
		'Toolkit/evaluate/cluto2label.pl' => '$(INST_MAN1DIR)/cluto2label.pl.1',
		'Toolkit/evaluate/label.pl' => '$(INST_MAN1DIR)/label.pl.1',
		'Toolkit/evaluate/report.pl' => '$(INST_MAN1DIR)/report.pl.1',
		'Toolkit/evaluate/format_clusters.pl' => '$(INST_MAN1DIR)/format_clusters.pl.1',
		'Toolkit/matrix/simat.pl' => '$(INST_MAN1DIR)/simat.pl.1',
		'Toolkit/matrix/bitsimat.pl' => '$(INST_MAN1DIR)/bitsimat.pl.1',
		'Toolkit/svd/mat2harbo.pl' => '$(INST_MAN1DIR)/mat2harbo.pl.1',
		'Toolkit/svd/svdpackout.pl' => '$(INST_MAN1DIR)/svdpackout.pl.1',
		'Toolkit/count/reduce-count.pl' => '$(INST_MAN1DIR)/reduce-count.pl.1',
		'Toolkit/vector/order1vec.pl' => '$(INST_MAN1DIR)/order1vec.pl.1',
		'Toolkit/vector/order2vec.pl' => '$(INST_MAN1DIR)/order2vec.pl.1',
		'Toolkit/vector/wordvec.pl' => '$(INST_MAN1DIR)/wordvec.pl.1',
		'Toolkit/vector/nsp2regex.pl' => '$(INST_MAN1DIR)/nsp2regex.pl.1',
		'Toolkit/preprocess/plain/text2sval.pl' => '$(INST_MAN1DIR)/text2sval.pl.1',
		'Toolkit/preprocess/sval2/balance.pl' => '$(INST_MAN1DIR)/balance.pl.1',
		'Toolkit/preprocess/sval2/maketarget.pl' => '$(INST_MAN1DIR)/maketarget.pl.1',
		'Toolkit/preprocess/sval2/sval2plain.pl' => '$(INST_MAN1DIR)/sval2plain.pl.1',
		'Toolkit/preprocess/sval2/filter.pl' => '$(INST_MAN1DIR)/filter.pl.1',
		'Toolkit/preprocess/sval2/frequency.pl' => '$(INST_MAN1DIR)/frequency.pl.1',
		'Toolkit/preprocess/sval2/keyconvert.pl' => '$(INST_MAN1DIR)/keyconvert.pl.1',
		'Toolkit/preprocess/sval2/prepare_sval2.pl' => '$(INST_MAN1DIR)/prepare_sval2.pl.1',
		'Toolkit/preprocess/sval2/windower.pl' => '$(INST_MAN1DIR)/windower.pl.1',
		'Toolkit/preprocess/sval2/preprocess.pl' => '$(INST_MAN1DIR)/preprocess.pl.1',
	},

# if INSTALLBINS is changed from site, the directories mentioned below 
# of the form INSTALLSITE* must change. 

# install blib/lib and blib/bin and blib/auto back into themselves.
# we really don't want them installed, so this is the best I could
# come up with to avoid that. make clean will remove all of this
# from blib. This also has the effect of discarding .packlist, which
# is unfortunate, but there is no clear place for it to reside since
# we are only creating /bin and /man.

	'INSTALLSITEBIN'=> '$(INST_BIN)',
	'LIB'=> '$(INST_LIB)',
	'INSTALLSITEARCH'=> '$(INST_ARCHLIB)',

	'EXE_FILES'	=> [
		map ("$_", @wrappers),
		map ("Toolkit/preprocess/plain/$_", @toolkit_preprocess_plain),
		map ("Toolkit/preprocess/sval2/$_", @toolkit_preprocess_sval),
		map ("Toolkit/count/$_", @toolkit_count),
		map ("Toolkit/vector/$_", @toolkit_vector),
		map ("Toolkit/svd/$_", @toolkit_svd),
		map ("Toolkit/matrix/$_", @toolkit_matrix),
		map ("Toolkit/clusterlabel/$_", @toolkit_cluslabel),
		map ("Toolkit/clusterstop/$_", @toolkit_cluststop),
		map ("Toolkit/evaluate/$_", @toolkit_evaluate),
	  ],	

 	($] >= 5.005 ?

	(ABSTRACT => 'SenseClusters - Clustering similar written contexts',
	AUTHOR => 'Ted Pedersen <tpederse at d.umn.edu>'):()), 

       # allows make dist to create .tar.gz with correct name/version
       'dist'             => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
       # allows for automatic creation of META.yml
       ($ExtUtils::MakeMaker::VERSION ge '6.30_00'?
       ('LICENSE' => 'gpl', ) : ()),

);


## postamble is run with "make install"
## this is no longer displayed either

sub MY::postamble {

	my $postamble = <<'END';
html: 
	@echo "*****************************************************"
	@echo "Installing SenseClusters Package, V $(VERSION)..."
	@echo "into $(PREFIX) "
	@echo "Make sure that the following are in your PATH:"
	@echo "     $(INSTALLSCRIPT)"
	@echo "and that the following is in your MANPATH:"
	@echo "     $(INSTALLSITEMAN1DIR)"
	@echo "After your paths are set, run the test scripts: "
	@echo "    cd Testing"
	@echo "    csh ./ALL-TESTS.sh"
	@echo "    cd .."
	@echo "to verify that installation is ok"
	@echo "*****************************************************"
END
	return ($postamble);
}

sub MY::install {
	my $self = shift;
	my $string = $self->MM::install;
	my $add = 'html';
	$string =~ s/(pure_install\s+)(.*)/$1 $add $2/;
	return $string;
}

