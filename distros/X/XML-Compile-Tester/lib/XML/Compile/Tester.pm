# Copyrights 2008-2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.

use warnings;
use strict;

package XML::Compile::Tester;
use vars '$VERSION';
$VERSION = '0.90';

use base 'Exporter';

our @EXPORT = qw/
 set_compile_defaults
 set_default_namespace
 reader_create create_reader
 writer_create create_writer
 writer_test
 reader_error
 writer_error
 templ_xml
 templ_perl
 templ_tree
 compare_xml
 /;

use Test::More;
use Data::Dumper;
use Log::Report        qw/try/;

my $default_namespace;
my @compile_defaults;


# not using pack_type, which avoids a recursive dependency to XML::Compile
sub _reltype_to_abs($)
{   defined $default_namespace && substr($_[0], 0,1) eq '{'
      ? "{$default_namespace}$_[0]" : $_[0] }

sub reader_create($$$@)
{   my ($schema, $test, $reltype) = splice @_, 0, 3;

    my $type   = _reltype_to_abs $reltype;
    my $read_t = $schema->compile
     ( READER             => $type
     , check_values       => 1
     , include_namespaces => 0
     , @compile_defaults
     , @_
     );

    isa_ok($read_t, 'CODE', "reader element $test");
    $read_t;
}
*create_reader = \&reader_create;  # name change in 0.03


sub reader_error($$$)
{   my ($schema, $reltype, $xml) = @_;
    my $r = reader_create $schema, "check read error $reltype", $reltype;
    defined $r or return;

    my $tree  = try { $r->($xml) };
    my $error = ref $@ && $@->exceptions
              ? join("\n", map {$_->message} $@->exceptions)
              : '';
    undef $tree
        if $error;   # there is output if only warnings are produced

    ok(!defined $tree, "no return for $reltype");
    warn "RETURNED TREE=",Dumper $tree if defined $tree;

    ok(length $error, "ER=$error");
    $error;
}


sub writer_create($$$@)
{   my ($schema, $test, $reltype) = splice @_, 0, 3;
    my $type   = _reltype_to_abs $reltype;

    my $write_t = $schema->compile
     ( WRITER                => $type
     , check_values          => 1
     , include_namespaces    => 0
     , use_default_namespace => 1
     , @compile_defaults
     , @_
     );

    isa_ok($write_t, 'CODE', "writer element $test");
    $write_t;
}
*create_writer = \&writer_create;  # name change in 0.03


sub writer_test($$;$)
{   my ($writer, $data, $doc) = @_;

    $doc ||= XML::LibXML->createDocument('1.0', 'UTF-8');
    isa_ok($doc, 'XML::LibXML::Document');

    my $tree = $writer->($doc, $data);
    ok(defined $tree);
    defined $tree or return;

    isa_ok($tree, 'XML::LibXML::Node');
    $tree;
}


sub writer_error($$$)
{   my ($schema, $reltype, $data) = @_;

    my $write = writer_create $schema, "writer for $reltype", $reltype;

    my $node;
    try { my $doc = XML::LibXML->createDocument('1.0', 'UTF-8');
          isa_ok($doc, 'XML::LibXML::Document');
          $node = $write->($doc, $data);
    };

    my $error
       = ref $@ && $@->exceptions
       ? join("\n", map {$_->message} $@->exceptions)
       : '';
    undef $node if $error;   # there is output if only warnings are produced

#   my $error = $@ ? $@->wasFatal->message : '';
    ok(!defined $node, "no return for $reltype expected");
    warn "RETURNED =", $node->toString if ref $node;
    ok(length $error, "EW=$error");

    $error;
}


sub templ_xml($$@)
{   my ($schema, $test, @opts) = @_;

    my $abs = _reltype_to_abs $test;

    $schema->template
     ( XML                => $abs
     , include_namespaces => 1
     , @opts
     ) . "\n";
}


sub templ_perl($$@)
{   my ($schema, $test, @opts) = @_;

    my $abs = _reltype_to_abs $test;

    $schema->template
     ( PERL               => $abs
     , include_namespaces => 0
     , @opts
     );
}


sub templ_tree($$@)
{   my ($schema, $test, @opts) = @_;
    my $abs = _reltype_to_abs($test);

    $schema->template
     ( TREE               => $abs
     , @opts
     );
}



sub set_compile_defaults(@) { @compile_defaults = @_ }


sub set_default_namespace($) { $default_namespace = shift }


sub compare_xml($$;$)
{   my ($tree, $expect, $comment) = @_;
    my $dump = ref $tree ? $tree->toString : $tree;

    for($dump, $expect)
    {   defined $_ or next;
        s/\>\s+/>/gs;
        s/\s+\</</gs;
        s/\>\s+\</></gs;
        s/\s*\n\s*/ /gs;
        s/\s{2,}/ /gs;
        s/\s+\z//gs;
    }
    is($dump, $expect, $comment);
}

1;
