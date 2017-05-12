# YAML test runner for XML::Validator::Schema.  Takes .yml files
# containing a schema and applies it to one or more files evaluating
# the results as specified.  Just look at t/*.yml and you'll get the
# idea.

package TestRunner;
use strict;
use warnings;

use Test::Builder;
my $Test = Test::Builder->new;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = ('test_yml', 'foreach_parser', 'test_yml_xerces');

use YAML qw(LoadFile);
use XML::SAX::ParserFactory;
use XML::Validator::Schema;
use XML::SAX;
use Cwd qw(cwd);

use Data::Dumper;

sub foreach_parser (&) {
    my $tests = shift;

    my @parsers = map { $_->{Name} } (@{XML::SAX->parsers});
    @parsers = ($ENV{XMLVS_TEST_PARSER}) if exists $ENV{XMLVS_TEST_PARSER};
    
    # remove XML::LibXML::SAX::Parser and XML::SAX::RTF.  Neither works.
    @parsers = grep { $_ ne 'XML::LibXML::SAX::Parser' and
                      $_ ne 'XML::SAX::RTF' } @parsers;

    # run tests with all available parsers
    foreach my $pkg (@parsers) {
        $XML::SAX::ParserPackage = $pkg;    
        
        print STDERR "\n\n                ======> Testing against $pkg ".
          "<======\n\n";
        $tests->();            
    }
}

sub test_yml {
    my $file = shift;
    my ($prefix) = $file =~ /(\w+)\.yml$/;
    my @data = LoadFile($file);

    # write out the schema file
    my $xsd = shift @data;
    open(my $fh, '>', "t/$prefix.xsd") or die $!;
    print $fh $xsd;
    close($fh) or die $!;

    my $num = 0;
    while(@data) {
        my $xml = shift @data;
        my $result = shift @data;
        chomp($result);
        $num++;

        # run the xml through the parser
        eval { 
            my $parser = XML::SAX::ParserFactory->parser(
              Handler => XML::Validator::Schema->new(cache => 1,
                                                     file => "t/$prefix.xsd"));
            $parser->parse_string($xml);
        };
        my $err = $@;

        if ($result =~ m!^FAIL\s*(?:/(.*?)/)?$!) {
            my $re = $1;
            $Test->ok($err, "$prefix.yml: block $num should fail validation");
            if ($re) {
                if ($err) {
                    $Test->like($err, qr/$re/, 
                                "$prefix.yml: block $num should fail matching /$re/");
                } else {
                    $Test->ok(0, "$prefix.yml: block $num should fail matching /$re/");
                }
            }
        } else {
            $Test->ok(not($err), "$prefix.yml: block $num should pass validation");
            print STDERR "$prefix.yml: block $num ====> $@\n" if $err;
        }
    }

    # cleanup
    unlink "t/$prefix.xsd" or die $!;
}

sub test_yml_xerces {
    my $file = shift;
    my ($prefix) = $file =~ /(\w+)\.yml$/;
    my @data = LoadFile($file);

    my $old_dir = cwd;
    chdir("t") or die "Unable to chdir to t/: $!";

    # write out the schema file
    my $xsd = shift @data;
    open(my $fh, '>', "$prefix.xsd") or die $!;
    print $fh $xsd;
    close($fh) or die $!;

    my $num = 0;
    while(@data) {
        my $xml = shift @data;
        my $result = shift @data;
        chomp($result);
        $num++;

        # fixup $xml to refer to schema
        $xml =~ s!<([^?].*?)(/?)>!<$1 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="$prefix.xsd"$2>!;

        # write the xml into a temp file
        open(XML, '>', "_$prefix.xml") or die $!;
        print XML $xml;
        close XML;

        # run the xml through the parser
        my $out = `$ENV{XERCES_DOMCOUNT} -v=always -n -s -f _$prefix.xml 2>&1`;
        my $err;
        if ($out =~ /Error/) {
            $out =~ s!Errors occurred, no output available!!g;
            $out =~ s!^\s+!!;
            $out =~ s{\s+$}{};
            $err = $out;
        }

        if ($result =~ m!^FAIL\s*(?:/(.*?)/)?$!) {
            print STDERR "==> $ENV{XERCES_DOMCOUNT} -v=always -n -s -f _$prefix.xml:\nout\n" unless $err;
            $Test->ok($err, "$prefix.yml: block $num should fail validation");
        } else {
            print STDERR "==> $ENV{XERCES_DOMCOUNT} -v=always -n -s -f _$prefix.xml:\n$out\n" if $err;
            $Test->ok(not($err), "$prefix.yml: block $num should pass validation");
        }
    }

    # cleanup
    unlink "$prefix.xsd" or die $!;
    unlink "_$prefix.xml" or die $!;

    chdir($old_dir);
}


1;
