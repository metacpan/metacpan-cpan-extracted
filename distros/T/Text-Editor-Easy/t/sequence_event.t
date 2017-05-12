use Test::More;
use Config;
BEGIN {
    if ( ! $Config{'useithreads'} ) {
        plan skip_all => "Perl not compiled with 'useithreads'";
    }
    elsif ( ! -f 'tk_is_ok' ) {
        plan skip_all => "Tk is not working properly on this machine";
    }
    else {
        plan no_plan;
    }
}

use strict;
use lib '../lib';

our $integer = 3;

sub mul_3 {
    $integer = $integer * 3;
}

sub add_3 {
    my ( $editor ) = @_;
    
    $integer = $integer + 3;
}

sub sub_3 {
    #print STDERR "Dans sub_3, nteger = $integer\n";
    
    $integer = $integer - 3;
}

sub div_3 {
    $integer = $integer / 3;
}

sub sub_6 {
    $integer = $integer - 6;
}

sub div_info {
    my ( $editor, $info_ref ) = @_;
    
    #print STDERR "Dans div_info : info_integer = ", $info_ref->{'integer'}, "\n";
    
    $info_ref->{'integer'} = $info_ref->{'integer'} / 3;
    return $info_ref;
}

sub set_integer {
    my ( $editor, $info_ref ) = @_;
    
    #print STDERR "Dans set integer : info_integer = ", $info_ref->{'integer'}, "\n";
    
    $integer = $info_ref->{'integer'};
}

sub set_info {
    my ( $editor, $info_ref ) = @_;
    
    #print STDERR "Dans set info : integer = $integer\n";
    
    $info_ref->{'integer'} = $integer;
    return $info_ref;
}

use Text::Editor::Easy {
    #'trace' => {
    #    'all' => 'tmp/',
    #    'trace_print' => 'full',
    #},
};
use Text::Editor::Easy::Comm;


Text::Editor::Easy->set_event( 'add_3', {
    'sub'    => 'add_3',
} );

Text::Editor::Easy->set_event( 'div_3', {
    'sub'    => 'div_3',
} );

my $editor = Text::Editor::Easy->new({
    'name' => 'toto',
	'bloc' => "use Text::Editor::Easy;\nmy \$editor = Text::Editor::Easy->new\n",
	'focus' => 'yes',
    'events' => {
        'clic' => {
            'sequence' => ['add_3', 'mul_3', 'sub_3'],
        },    
        'mul_3' => { 
            'sub'    => 'mul_3',
        },
        'sub_3' => { 
            'sub'    => 'sub_3',
        },
        'set_integer' => {
            'sub' => 'set_integer',
        },
        'set_info' => {
            'sub' => 'set_info',
        },
    }
});


is ( ref($editor), "Text::Editor::Easy", "Object type");

$editor->clic;

is ( $integer, 15, 'sequence option of events');

$editor->set_sequence( { 'clic' => [ 'add_3', 'sub_3' ] }, { 'values' => 'undefined' } );

$integer = 3;

$editor->clic;

is ( $integer, 15, 'set_sequence inactive, value is defined');

$editor->set_sequence( { 'clic' => [ 'add_3', 'sub_3', 'add_3' ] }, { 'values' => 'defined', 'seq' => 'o' } );

$integer = 3;

$editor->clic;

is ( $integer, 6, 'set_sequence active, value is defined');

Text::Editor::Easy->set_sequence( { 'clic' => [ 'mul_3', 'sub_3' ] }, { 'names' => qr/t.*t/ } );

$editor->clic;

is ( $integer, 15, 'set_sequence active, names OK');

$integer = 9;

Text::Editor::Easy->set_sequence( { 'clic' => [ 'div_3', 'add_3' ] }, { 'instances' => 'future' } );

$editor->clic;

# expected sequence : [ 'mul_3', 'sub_3' ] for existing instance $editor

is ( $integer, 24, 'set_sequence inactive, future option');

$integer = 9;

Text::Editor::Easy->set_sequence( { 'clic' => [ 'add_3', 'div_3' ] }, { 'instances' => 'existing' } );

$editor->clic;

is ( $integer, 4, 'set_sequence active, existing option');

$integer = 12;

my $ed_2 = Text::Editor::Easy->new;

use Data::Dump qw( dump );

#print "Clic séquence pour ed_2 = ", dump( $ed_2->sequences('clic') ), "\n";
#print "Evènements pour ed_2 = ", dump( $ed_2->events ), "\n";

$ed_2->clic;

is ( $integer, 7, 'set_sequence for future instances working');

