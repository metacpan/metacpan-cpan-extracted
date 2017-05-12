use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.2 2006/01/24 17:45:08 mrodrigu Exp $

(my $EUMM= $ExtUtils::MakeMaker::VERSION)=~ tr/_//d;
my @license = $EUMM > 6.30 ? qw(LICENSE perl) : ();

WriteMakefile(
    NAME              => 'Tree::DAG_Node::XPath',
    VERSION_FROM      => 'lib/Tree/DAG_Node/XPath.pm', # finds $VERSION
    PREREQ_PM         => { 'Tree::XPathEngine'  => '0.05',
                           'Tree::DAG_Node' => '1.04',
                         }, 
    @license,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tree/DAG_Node/XPath.pm', # retrieve abstract from module
       AUTHOR         => 'Michel Rodriguez <mirod@cpan.org>') : ()),
);
