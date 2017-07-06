# Copyrights 2007-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

# test environment at home: unpublished XML::Compile
use lib '../XMLCompile/lib', '../LogReport/lib', '../XMLTester/lib';

package TestTools;
use vars '$VERSION';
$VERSION = '3.22';

use base 'Exporter';

use Test::More;

use Log::Report  qw/try/;
use Data::Dumper qw/Dumper/;

# avoid refcount errors perl 5.8.8, libxml 2.6.26, XML::LibXML 2.60,
# and Data::Dump::Streamer 2.03;  actually, the bug can be anywhere...
our $skip_dumper = 1;

$ENV{SCHEMA_DIRECTORIES} = 'xsd';

our @EXPORT = qw/
 $skip_dumper
 $TestNS
 $SchemaNS
 $dump_pkg
 /;

our $TestNS   = 'http://test-types';
our $SchemaNS = 'http://www.w3.org/2001/XMLSchema';
our $dump_pkg = 't::dump';

# check whether the dumped code produces the same HASH as
# the freshly compiled code.
my $lab = 1;
sub reader_dump($$$)
{   my ($reader, $xml, $hash) = @_;

    my $e = '';
    open OUT, '>:utf8', \$e;

    my $d =  XML::Compile::Dumper->new
     ( package    => $dump_pkg
     , filehandle => \*OUT
     );

    my $label = 'dump_reader_'.$lab++;
    $d->freeze($label => $reader);

    $d->close;

    # Wow!!! name-space polution!
    eval $e;
    cmp_ok($@, 'eq', '');

    no strict 'refs';
    my $r = *{"${dump_pkg}::$label"}{CODE};
    ok(defined $r);

    my $h = $r->($xml);
    ok(defined $h, 'processed via dumped source');
 
    is_deeply($h, $hash, "dump and direct trees");
}


# check whether the dumped code produces the same XML as
# the freshly compiled code.
sub writer_dump($$)
{   my ($writer, $xml) = @_;

    my $e = '';
    open OUT, '>:utf8', \$e;

    my $d =  XML::Compile::Dumper->new
     ( package    => $dump_pkg
     , filehandle => \*OUT
     );

    my $label = 'dump_writer_'.$lab++;
    $d->freeze($label => $writer);

    $d->close;

    # Wow!!! name-space polution!
    eval $e;
    cmp_ok($@, 'eq', '');

    no strict 'refs';
    my $w = *{"${dump_pkg}::$label"}{CODE};
    ok(defined $w);

    my $doc = XML::LibXML->createDocument('test doc', 'utf-8');
    isa_ok($doc, 'XML::LibXML::Document');

    my $tree2 = $w->($doc, $xml);
    ok(defined $tree2, 'processed via dumped source');

    $tree2;
}

1;
