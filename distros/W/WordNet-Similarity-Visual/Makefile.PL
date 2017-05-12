use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WordNet::Similarity::Visual',
    VERSION_FROM      => 'lib/WordNet/Similarity/Visual.pm',
    PREREQ_PM         => {'Gtk2'  => '1.0',
                          'Gnome2' => '1.0',
                          'WordNet::QueryData'  => '1.30',
                          'Text::Similarity'    => '0.02',
                          'WordNet::Similarity' => '0.14'},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WordNet/Similarity/Visual.pm', # retrieve abstract from module
       AUTHOR         => 'root <root@localdomain>') : ()),
);
