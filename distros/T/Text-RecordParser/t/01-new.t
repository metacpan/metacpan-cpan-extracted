#!perl

use strict;
use File::Spec::Functions;
use FindBin '$Bin';
use Readonly;
use Test::Exception;
use Test::More tests => 26;

Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

require_ok( 'Text::RecordParser' );
require_ok( 'Text::RecordParser::Tab' );

#
# Vanilla "new," test defaults
#
{
    my $p = Text::RecordParser->new;
    isa_ok( $p, 'Text::RecordParser' );

    is( $p->filename, '', 'Filename is blank' );
    is( $p->fh, undef, 'Filehandle is undefined' );
    is( $p->field_filter, '', 'Field filter is blank' );
    is( $p->header_filter, '', 'Header filter is blank' );
    is( $p->field_separator, ',', 'Default separator is a comma' );
    is( $p->trim, undef, 'Default trim value is undefined' );
}

#
# New with arguments
#
{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p    = Text::RecordParser->new($file);
    is( $p->filename, $file, 'Filename sets OK' );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p    = Text::RecordParser->new( { filename => $file } );
    is( $p->filename, $file, 'Filename as hashref sets OK' );
}

{
    my $file             = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p                = Text::RecordParser->new(
        filename         => $file,
        field_separator  => "\t",
        record_separator => "\n\n",
        field_filter     => sub { $_ = shift; s/ /_/g; $_ },
        header_filter    => sub { $_ = shift; s/\s+/_/g; lc $_ },
        trim             => 1,
    );

    is( $p->filename, $file, 'Filename set OK' );
    is( $p->field_separator, "\t", 'Field separator is a tab' );
    is( $p->record_separator, "\n\n", 'Record separator is two newlines' );
    is( ref $p->field_filter, 'CODE', 'Field filter is code' );
    is( ref $p->header_filter, 'CODE', 'Header filter is code' );
    is( $p->trim, 1, 'Trim mode is on' );
}

{
    my $p = Text::RecordParser->new;
    is( $p->trim, undef, 'trim with no args is undefined' );
    is( $p->trim('foo'), 1, 'trim with non-false arg is true' );
    is( $p->trim(''), 0, 'trim with false arg is false' );
}

#
# New with shortened arguments
#
{
    my $p  = Text::RecordParser->new({
        fs => "\t",
        rs => "\n\n",
    });

    is( $p->field_separator, "\t", 'Shortened field separator arg OK' );
    is( $p->record_separator, "\n\n", 'Shortened record separator arg OK' );
}

#
# New with too many arguments
#
{
    throws_ok {
        my $p           = Text::RecordParser->new(
            filename => catfile( $TEST_DATA_DIR, 'simpsons.csv' ),
            data     => "foo\tbar\tbaz",
        );
    } 
    qr/too many arguments/, 
    'new dies because of too many data args';
}

#
# New with just one arg
#
{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p    = Text::RecordParser->new( $file );

    is( $p->filename, $file, 'One argument taken as filename' );
}

#
# New Tab
#
{
    my $p = Text::RecordParser::Tab->new;

    isa_ok( $p, 'Text::RecordParser' );

    is( $p->field_separator, "\t", 'New T::RP::Tab has tab for field sep' );
}
