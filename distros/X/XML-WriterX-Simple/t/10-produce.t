use strict;
use warnings FATAL => 'all';
use Test::More;

sub simple_producer{
    my ($writer, $tag) = @_;
    $writer->characters( 'foobar' );
    $writer->produce( dumy => [ ':attr1' => 'valattr1', child1 => 'valchild1', '"' => 'text1' ] );
}

my @tests = (
    [ 'empty tag' => [ doc => undef ], eq => '<doc />', ],
    [ 'tag from scalar' => [ doc => 'test' ], eq => '<doc>test</doc>', ],
    [ 'tag from array' => [ doc => [ foo => 'v1', bar => 'v2' ] ], eq => '<doc><foo>v1</foo><bar>v2</bar></doc>', ],
    [ 'tag from hash' => [ doc => { foo => 'v1', bar => 'v2' }  ], like => qr#<doc>(<foo>v1</foo>|<bar>v2</bar>){2}</doc>#, ],
    [ 'tag from scalar reference' => [ doc => \'test' ], eq => '<doc>test</doc>', ],
    [ 'tag from code' => [ doc => sub{ shift->characters('test'); }], eq => '<doc>test</doc>', ],
    [ 'tag from code with attributes' => [ doc => [ ':at1' => 'va1', '"' => sub{ shift->characters('test'); } ] ], eq => '<doc at1="va1">test</doc>', ],
    [ 'complexe structure' => [ doc => [   #an ARRAY ref will produce ordered children
                                            ':attr' => [ id => 42, time => '132400' ], 
                                            '"' => \&simple_producer,
                                            '#foobar' => "comment after content tag",
                                            footer => [ #if use a hash ref in place of array ref, it may produce unordered children
                                                ':name' => 'bar',   #unordered arguments
                                                ':id'   => 6*7,
                                                '"' => 'Text content',
                                                child1 => 'val1',
                                                child2 => 'val2',
                                            ],
                                            '#foobar' => "comment after footer tag",
                                        ] 
                                ], 'eq' => '<doc id="42" time="132400">foobar<dumy attr1="valattr1"><child1>valchild1</child1>text1</dumy><!-- comment after content tag --><footer name="bar" id="42">Text content<child1>val1</child1><child2>val2</child2></footer><!-- comment after footer tag --></doc>' ],
    [ 'tag sequence' => [ doc => sub{ shift->produce(tag1 => 'test', tag2 => 'test2') } ], eq => '<doc><tag1>test</tag1><tag2>test2</tag2></doc>', ],
    [ 'hidden doc tag' => [ '.doc' => sub{ shift->produce(tag1 => 'test') } ], eq => '<tag1>test</tag1>', ],
);

plan tests => 2 + @tests;
use_ok 'XML::Writer';
use_ok 'XML::WriterX::Simple';

for my $test ( @tests ){
    my $writer = new XML::Writer(OUTPUT => \my $xml); #, DATA_INDENT => 1, DATA_MODE => 1);
    $writer->xmlDecl('UTF-8');
    #~ $DB::single=1 if $test->[0] =~ /attributes/;
    $writer->produce( @{$test->[1]} );
    $writer->end();
    if($test->[2] eq 'like'){
        like $xml, $test->[3], $test->[0];
    }
    else{
        cmp_ok $xml, $test->[2], "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n$test->[3]\n", $test->[0];
    }
}

__END__
$writer->produce( docTag => [   #an ARRAY ref will produce ordered children
        ':attr' => [ id => 42, time => localtime() ], 
        content => \&simple_producer,
        '#foobar' => "comment after content tag",
        footer => { 
            ':name' => 'bar',   #unordered arguments
            ':id'   => 6*7,
            '"' => 'Text content',
            child1 => 'val1',
            child2 => 'val2',
        }, #An hash ref may produce unordered children.
        '#foobar' => "comment after footer tag",
    ]
);

sub simple_producer{
    my ($writer, $tag) = @_;
    $writer->characters( 'foobar' );
    $writer->produce( dumy => [ ':attr1' => 'valattr1', child1 => 'valchild1', '"' => 'text1' ] );
}

cmp_ok $xml, 'eq', <<'XML', 'produce method';
<?xml version="1.0"><docTag id="42" time=".........">foobar<dumy attr1="valattr1"><child1>valchild1</child1>text1</dumy><!-- comment after content tag --><footer name="bar" id="42">Text content<child1>val1</child1><child2>val2</child2></footer><!-- comment after footer tag --></docTag>
XML
