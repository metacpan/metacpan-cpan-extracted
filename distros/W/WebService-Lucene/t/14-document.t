use Test::More tests => 49;

use strict;
use warnings;

use_ok( 'WebService::Lucene::Document' );
use_ok( 'WebService::Lucene::Field' );

{
    my $doc = WebService::Lucene::Document->new;
    isa_ok( $doc, 'WebService::Lucene::Document' );
}

{
    my $doc = WebService::Lucene::Document->new;
    isa_ok( $doc, 'WebService::Lucene::Document' );

    my $field = WebService::Lucene::Field->text( name => 'value' );
    isa_ok( $field, 'WebService::Lucene::Field' );

    $doc->add( $field );

    {
        my @fields = $doc->name;

        is( scalar @fields, 1, '$doc->name; number of results' );
        is( $fields[ 0 ], $field->value, '$doc->name; value' );
    }

    {
        my @fields = $doc->fields;

        is( scalar @fields, 1, '$doc->fields; number of results' );
        is( $fields[ 0 ], $field, '$doc->fields; value' );
    }

    {
        my @fields = $doc->fields( 'name' );

        is( scalar @fields, 1, '$doc->fields("name"); number of results' );
        is( $fields[ 0 ], $field, '$doc->fields("name"); value' );
    }

    $doc->remove_field( 'name' );
    {
        my @fields = $doc->fields;
        is( scalar @fields, 0, 'field removed' );
    }

    $doc->add( $field );
    $doc->clear_fields;

    {
        my @fields = $doc->fields;
        is( scalar @fields, 0, 'fields cleared' );
    }
}

{
    my $doc = WebService::Lucene::Document->new;
    isa_ok( $doc, 'WebService::Lucene::Document' );

    my @types = qw( text unstored sorted unindexed keyword );

    for my $type ( @types ) {
        my $method = "add_$type";
        $doc->$method( $type => 'value' );
        my @fields = $doc->fields( $type );
        is( scalar @fields, 1 );
        isa_ok( $fields[ 0 ], 'WebService::Lucene::Field' );
        is( $fields[ 0 ]->name,  $type );
        is( $fields[ 0 ]->value, "value" );
        is( $fields[ 0 ]->type,  $type );
    }
}

{
    my $doc = WebService::Lucene::Document->new;
    isa_ok( $doc, 'WebService::Lucene::Document' );
    $doc->add_text( name => 'value' );
    my $entry = $doc->as_entry;
    isa_ok( $entry, 'XML::Atom::Entry' );
    is( $entry->title, 'New Entry' );

    my $expected = <<'';
<dl class="xoxo"><dt class="indexed stored tokenized">name</dt><dd>value</dd></dl>

    my $result = $entry->content->body;

    chomp( $expected );
    $result =~ s{>\s+<}{><}gs;

    is( $result, $expected );

    {
        my $doc = WebService::Lucene::Document->new_from_entry( $entry );
        isa_ok( $doc, 'WebService::Lucene::Document' );
        my @fields = $doc->fields;
        is( scalar @fields, 1 );
        isa_ok( $fields[ 0 ], 'WebService::Lucene::Field' );
        is( $fields[ 0 ]->name,  'name' );
        is( $fields[ 0 ]->value, 'value' );
        is( $fields[ 0 ]->type,  'text' );
    }
}
