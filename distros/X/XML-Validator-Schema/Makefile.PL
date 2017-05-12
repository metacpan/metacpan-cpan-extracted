use 5.006;

# make sure XML::SAX isn't broken - if it's just not installed then 
if (eval "require XML::SAX") {
    my $parsers = XML::SAX->parsers;
    unless ($parsers and @$parsers) {
        warn <<END;

**** Your XML::SAX install is broken! ****

You have XML::SAX installed, but you have no parsers defined.  Most
likely this is the result of not having ParserDetails.ini installed.

Please fix your XML::SAX install and try again.

Please do not email me about this problem.  I am but a poor XML::SAX
consumer with no power to fix your XML::SAX install.

END

        exit(0);    # CPAN testers, bug me not!
    }
}

use ExtUtils::MakeMaker;
WriteMakefile(NAME         => 'XML::Validator::Schema',
              VERSION_FROM => 'Schema.pm',
              PREREQ_PM    => {
                            'Test::More'              => 0.47,
                            'XML::SAX'                => 0.12,
                            'Carp'                    => 0,
                            'Tree::DAG_Node'          => 0,
                            'XML::Filter::BufferText' => 0,
                           },
              ABSTRACT_FROM => 'Schema.pm',
              AUTHOR        => 'Sam Tregar <sam@tregar.com>');
