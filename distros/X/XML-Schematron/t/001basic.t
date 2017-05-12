use Test::More;
use_ok('XML::Schematron');


my @tests = (
  { 
    context     => '/',
    test_type   => 'assert',
    expression  => 'order',
    message     => "Root element should be named 'order'.",
  },
  { 
    context     => 'order',
    test_type   => 'assert',
    expression  => 'date_created',
    message     => "Order element must contain a 'date_created' element.",
  },
  {
    context     => 'order',
    test_type   => 'assert',
    expression  => 'order_authorizations',
    message     => "Order element must contain an 'order_authorizations' element.",
  },
  {        
    context     => 'order_authorizations',
    test_type   => 'assert',
    expression  => 'order_authorization',
    message     => "order_authorizations element must contain at least one 'order_authorization' element.",
  },
  {
    context     => 'order_authorization',
    test_type   => 'assert',
    expression  => 'tttaddress',
    message     => "Each order_authorization must contain and address element.",
  },
);

SKIP: {
    eval { require XML::XPath };
    
    skip "XML::XPath not installed", 1 if $@;

    my $tron = XML::Schematron->new_with_traits( traits => ['XPath'] );

    isa_ok($tron, 'XML::Schematron', 'Schematron instance created');
    
    $tron->add_tests( @tests );
    
    my @errors = $tron->verify('t/data/order.xml');

    ok( scalar @errors == 1, 'Address check, XPath, perl tests' );
    
    $tron = undef;
    @errors = ();

    $tron = XML::Schematron->new_with_traits( traits => ['XPath'], schema => 't/data/order.scm' );

    isa_ok($tron, 'XML::Schematron', 'Schematron instance created');

    
    @errors = $tron->verify('t/data/order.xml');

    ok( scalar @errors == 1, 'Address check, XPath, schema tests' );
    
};

SKIP: {
    eval { require XML::LibXSLT };
    
    skip "XML::LibXSLT not installed", 1, if $@;

    my $tron2 = XML::Schematron->new_with_traits( traits => ['LibXSLT'], schema => 't/data/order.scm' );
    
    isa_ok($tron2, 'XML::Schematron', 'Schematron instance created');
    
    my @errors2 = $tron2->verify('t/data/order.xml');
    
    ok( scalar @errors2 == 3, 'Address check, LibXSLT' );

};

done_testing();