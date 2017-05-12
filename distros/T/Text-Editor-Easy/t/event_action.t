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


my $editor = Text::Editor::Easy->new({  
	'bloc' => "use Text::Editor::Easy;\nmy \$editor = Text::Editor::Easy->new\n",
	'focus' => 'yes',
    'events' => {
        'clic' => {
            'sequence' => ['add_3_event', 'mul_3_event', 'sub_3_event'],
        },    
        'add_3_event' => { 
            'sub'    => 'add_3',
            'action' => 'exit',
        },
        'mul_3_event' => { 
            'sub'    => 'mul_3',
        },
        'sub_3_event' => { 
            'sub'    => 'sub_3',
        },
    }
});


is ( ref($editor), "Text::Editor::Easy", "Object type");

$editor->clic;

is ( $integer, 6, 'exit action');

$integer = 6;

$editor->set_event('add_3_event', {
    'sub'    => 'add_3',
    'action' => 'change',
} );

$editor->clic;

is ( $integer, 24, 'change action, not used');

$integer = 24;

$editor->set_event('add_3_event', {
    'code'   => "return [ 'sub_3_event' ]",
    'action' => 'jump',
} );

$editor->clic;

is ( $integer, 21, 'jump action, info unchanged and undefined');

$integer = 21;

$editor->set_event('add_3_event', {
    'code'   => "return [ [ 'sub_3_event', 'sub_3_event' ] ]",
    'action' => 'reentrant',
} );

$editor->clic;

is ( $integer, 42, 'reentrant action, info unchanged and undefined');

$integer = 42;

$editor->set_event('add_3_event', {
    'code'   => "return [ [ 'sub_3_event', 'sub_3_event', '_exit' ] ]",
    'action' => 'reentrant',
} );

$editor->clic;

is ( $integer, 36, 'reentrant action with exit label');

$integer = 36;

$editor->set_event('div_event', {
    'sub'   => 'div_info',
} );

$editor->set_event('set_integer', {
    'sub'   => 'set_integer',
} );

$editor->set_event('set_info', {
    'sub'    => 'set_info',
    'action' => 'change',
} );

$editor->set_event('add_3_event', {
    'code'   => "return [ [ 'set_info', 'div_event', 'set_integer', 'sub_3_event', '_exit' ] ]",
    'action' => 'reentrant',
} );

$editor->clic;

is ( $integer, 33, 'info change without change option');

$integer = 33;

$editor->set_event('div_event', {
    'sub'    => 'div_info',
    'action' => 'change',
} );


$editor->clic;

is ( $integer, 8, 'info change with change option');

$integer = 8;

$editor->set_event('add_3_event', {
    'code'   => "return [ 'mul_3_event' ]",
    'action' => 'reentrant',
} );

$editor->clic;

is ( $integer, 21, 'useless jump with reentrant value');

$integer = 21;

$editor->set_event('add_3_event', {
    'code'   => "return { 'integer' => 9 }",
    'action' => 'reentrant',
} );

$editor->set_event('mul_3_event', {
    'code'   => "return [ ['set_integer'] ]",
    'action' => 'reentrant',
} );

$editor->clic;

is ( $integer, 6, 'change with reentrant value');

$integer = 6;

$editor->set_event('add_3_event', {
    'code'   => "return [ q{}, { 'integer' => 12 } ]",
    'action' => 'reentrant',
} );

$editor->clic;

is ( $integer, 9, 'change with reentrant value and empty label');

$integer = 9;

$editor->set_event('add_3_event', {
    'code'   => "return [ undef, { 'integer' => 15 } ]",
    'action' => 'reentrant',
} );

$editor->clic;

is ( $integer, 12, 'change with reentrant value and undef label');

$integer = 12;

$editor->set_event('add_3_event', {
    'code'   => "return [ undef, { 'integer' => 18 } ]",
    'action' => 'jump',
} );

$editor->clic;

is ( $integer, 15, 'change with jump value and undef label');

$integer = 15;

$editor->set_event('add_3_event', {
    'code'   => "return [ q{}, { 'integer' => 21 } ]",
    'action' => 'jump',
} );

$editor->clic;

is ( $integer, 18, 'change with jump value and empty label');

$integer = 18;

$editor->set_event('add_3_event', {
    'code'   => "return { 'integer' => 6 }",
    'action' => 'jump',
} );

$editor->clic;

is ( $integer, 3, 'change with jump value');

$integer = 3;

$editor->set_event('mul_3_event', {
    'code'   => "return [ [ 'set_info', 'set_integer'], { 'integer' => 6000 } ]",
    'action' => 'reentrant',
} );

$editor->set_event('add_3_event', {
    'code'   => "return [ [ 'sub_3_event' ] ]",
    'action' => 'jump',
} );

$editor->clic;

is ( $integer, 0, 'wrong reentrant try with jump value');

$integer = 0;

$editor->set_sequence( { 'clic'=> [ 'set_info', 'add_3_event', 'set_integer', 'mul_3_event', 'sub_3_event' ] } );

$editor->set_event('add_3_event', {
    'code' => <<'code'
my ( $editor, $info_ref ) = @_;

$info_ref->{'integer'} += 3;

print STDERR "Dans code de add_3_event : info_ref->{'integer'} =", $info_ref->{'integer'}, "\n";

return $info_ref
code
    ,
    'action' => 'change',
} );

$editor->set_event( 'mul_3_event', {
    'sub' => 'mul_3',
} );

$editor->clic;

is ( $integer, 6, 'change value OK');

$integer = 6;

$editor->set_event('add_3_event', {
    'code' => <<'code'
my ( $editor, $info_ref ) = @_;

$info_ref->{'integer'} += 3;

return [ 'set_integer', $info_ref ]
code
    ,
    'action' => 'change',
} );

$editor->clic;

is ( $integer, 15, 'try to jump with change value');

$integer = 15;

$editor->set_event('add_3_event', {
    'code' => <<'code'
my ( $editor, $info_ref ) = @_;

$info_ref->{'integer'} += 3;

return [ [ 'set_integer', 'sub_3_event', 'mul_3_event' ], $info_ref ]
code
    ,
    'action' => 'change',
} );

$editor->clic;

is ( $integer, 42, 'try to jump with change value');

#$integer = 42;