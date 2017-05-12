use strict;

use Test;
use XML::SAX::EventMethodMaker qw( :all );


my @sax_event_names_tests = (
## These tests extracted manually from Robin's paper at  #'
## http://robin.menilmontant.com/perl/xml/sax-chart.html
## Thanks to Kip and Robin.
[ [qw(                     )], 33 ],
[ [qw( 1                   )], 33 ],
[ [qw( 2                   )], 28 ],
[ [qw( 1 2                 )], 33 ],
[ [qw( Handler             )], 33 ],
[ [qw( Handler 1           )], 33 ],
[ [qw( Handler 2           )], 28 ],
[ [qw( Handler 1 2         )], 33 ],
[ [qw( DTDHandler          )],  6 ], 
[ [qw( DTDHandler 1        )],  6 ], 
[ [qw( DTDHandler 2        )],  2 ], 
[ [qw( LexicalHandler      )],  7 ],
[ [qw( DocumentHandler     )],  9 ],
[ [qw( DeclHandler         )],  4 ],
[ [qw( ErrorHandler        )],  3 ],
[ [qw( DocumentHandler 1   )],  9 ],
[ [qw( DocumentHandler 2   )],  0 ],
[ [qw( DocumentHandler 1 2 )],  9 ],

## These are my own madness, cribbed from XML::SAX::Base source code.
[ [qw( ParseMethods        )],  4 ],
[ [qw( ParseMethods 1      )],  1 ],
[ [qw( ParseMethods 2      )],  4 ],
[ [qw( ParseMethods 1 2    )],  4 ],

[ [qw( Handler ParseMethods     )],  37 ],
[ [qw( Handler ParseMethods 1   )],  34 ],
[ [qw( Handler ParseMethods 2   )],  32 ],
[ [qw( Handler ParseMethods 1 2 )],  37 ],
);

my @missing_methods_tests = (
[ "Foo1", 33 ],
[ "Test", 29 ],
);

sub Test::start_document;
sub Test::end_document;
sub Test::start_element;
sub Test::end_element;

plan( tests => 
    @sax_event_names_tests
    + @missing_methods_tests
    + 33
    + 4
);

for (@sax_event_names_tests) {
    ok
        scalar sax_event_names( @{$_->[0]} ),
        $_->[1],
        join ",", @{$_->[0]};
}

for (@missing_methods_tests) {
    ok 
        scalar missing_methods( $_->[0], sax_event_names ),
        $_->[1],
        join ",", $_->[0];
}

compile_methods __PACKAGE__, "sub <EVENT> {}", sax_event_names ;
compile_methods __PACKAGE__, "sub <METHOD> {}", sax_event_names "ParseMethods" ;

for ( sax_event_names "Handler", "ParseMethods" ) {
    ok __PACKAGE__->can( $_ ) ? 1 : 0, 1, $_;
}
