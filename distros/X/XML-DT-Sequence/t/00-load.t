#!perl -T

use Test::More tests => 33;

BEGIN {
    use_ok( 'XML::DT::Sequence' ) || print "Bail out!\n";
}

my $x = XML::DT::Sequence->new;

eval { $x->process("t/sample.xml") };
like $@, qr/Option -tag is mantatory./;

{
    my $r = $x->process("t/sample.xml",
                        -tag => 'item',
                        -head => sub {
                            my ($self, $xml) = @_;
                            isa_ok $self => "XML::DT::Sequence";
                            like $xml => qr{^.*<main>.*<head>.*</head>\s*<body>\s*$}s;
                            return "OK HEAD"
                        },
                        -foot => sub {
                            my ($self, $xml) = @_;
                            isa_ok $self => "XML::DT::Sequence";
                            return "FOOT OK"
                        },
                       );

    isa_ok $r => "HASH";
    is $r->{-head} => "OK HEAD";
    is $r->{-body} => 5;
    is $r->{-foot} => "FOOT OK";
}

{
    my $r = $x->process("t/sample.xml",
                        -tag => 'item',
                        -body => sub {
                            my ($self, $xml) = @_;
                            isa_ok $self => "XML::DT::Sequence";
                            like $xml => qr{^\s*<item.*</item>\s*$}s;
                        },
                        -head => sub {
                            my ($self, $xml) = @_;
                            isa_ok $self => "XML::DT::Sequence";
                            like $xml => qr{^.*<main>.*<head>.*</head>\s*<body>\s*$}s;
                            return "OK HEAD"
                        },
                       );

    isa_ok $r => "HASH";
    is $r->{-head} => "OK HEAD";
    is $r->{-body} => 5;
}


{
    my $r = $x->process("t/sample.xml",
                        -tag => 'item',
                        -head => {
                                  -default => sub { $c = "$q $c" },
                                  main => sub {
                                      $c = "$q $c";
                                      $c =~ s/\n/ /g;
                                      $c =~ s/\s+/ /g;
                                      is $c => 'main head something a something b something c something d body '
                                  },
                                 },
                        -body => {
                                  -default => sub { "[$q:$c]" },
                                  item => sub {
                                      like $c => qr/^\s*\[foo:[^]]+\]\s*\[bar:[^]]+\]\s*/s;
                                  }
                                 },
                        -foot => {
                                  -default => sub { "{$q:$c}" },
                                  footer => sub {
                                      $c =~ s/\s*//g;
                                      is $c => '{something:weird}';
                                  },
                                 },
                       );

    isa_ok $r => "HASH";
    is $r->{-body} => 5;
}
