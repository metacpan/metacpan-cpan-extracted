package XML::Parser::GlobEvents;

use 5.006;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse parse_xml);
our $VERSION = '0.400';

use XML::Parser::Expat;
use Carp;

sub parse {
    my $file = shift;
    my(%handler, @handler);
    while(@_) {
        if(ref $_[1] eq 'CODE') {
            my($pattern, $code) = splice @_, 0, 2;
            unshift @_, $pattern => { End => $code };
        }
        my($pattern, $hash) = splice @_, 0, 2;
        if(ref $hash ne 'HASH') {
          require Carp;
          Carp::croak("Invalid parameter for $pattern: '$hash', expected hashref");
        }
        foreach my $key (qw(Start End)) {
            if(my $code = $hash->{$key}) {
                unless(ref $code eq 'CODE') {
                    require Carp;
                    Carp::croak("Invalid $key handler for $pattern");
                }
            }
        }
        my %order;
        for($pattern) {
            s{///+}{//}g;
            s{^//}{};
        }
        my $regex = $pattern;
        for($regex) {
            $order{depth} = () = m{[^/]+}g;
            s/([.])/\\$1/g;
            $order{star} = s{\*}{[^/]+}g;
            $order{desc} = s{//}{(?=/).*/}g;
            s{\Q(?=/).*/[^/]+}{/.+}g;
            $order{abs} = s{^/}{^/} or s{^}{(?:/|^)}, $order{desc}++;
            s/$/\$/;
        }
        $hash->{pattern} = $pattern;
        $hash->{regex}  = qr/$regex/;
        $hash->{order} = \%order;
        @{$handler{$pattern}}{keys %$hash} = values %$hash;
    }
    @handler = sort { $b->{order}{depth} <=> $a->{order}{depth} ||
                      $a->{order}{star} <=> $b->{order}{star} ||
                      $a->{order}{desc} <=> $b->{order}{desc}
      } values %handler;
    # use Data::Dumper; print Dumper \@handler;
    use IO::File;
    my $fh = ref $file eq 'SCALAR' ? $$file :
      ref $file ? $file : IO::File->new($file, 'r')
      or croak "Cannot read file '$file': $!";
    my $parser = XML::Parser::Expat->new;
    my @stack;
    my $node = {};
    my $current = { -path => '/', -name => '', -node => $node };
    $parser->setHandlers(
      Start => sub {
        my($self, $name, %attr) = @_;
        push @stack, my $parent = $current;
        (my $path = join '/', $parent->{-path}, $name ) =~ s(^//)(/);
        # print STDERR "Entering $path\n";
        my $parentnode = $node;
        $node = { -path => $path, -name => $name, -attr => \%attr };
        $node->{-position} = ++$parent->{-childcount}{$name};
        $current = { -path => $path, -name => $name, -node => $node };
        if($parent->{-store}) {
            $current->{-store} = 1;
            push @{$parentnode->{-contents}}, $node;
            push @{$parentnode->{"$name\[]"}}, $node;
            $parentnode->{$name} = $node;
        }
        my $store;
        foreach (grep { $path =~ $_->{regex} } @handler) {
            # print STDERR "Match handler rule $_->{pattern}\n";
            if($_->{Start}) {
                # print STDERR "Firing Start rule $_->{pattern}\n";
                $_->{Start}->($node, \@stack);
            }
            if(defined $_->{Store}) {
                $store = $_->{Store} unless defined $store;
            }
            if($_->{End}) {
                push @{$current->{End}}, $_;
                $current->{-node} = $node;
                $store = 1 unless defined $store;
            }
            if(defined $_->{Whitespace}) {
                $current->{Whitespace} = $_->{Whitespace};
            }
        }
        $current->{-store} = $store if defined $store;
        $node->{-text} = '' if $current->{-store};
      },
      End => sub {
        my($self, $name) = @_;
        my $path = $current->{-path};
        # print STDERR "Exiting $path\n";
        if($current->{-store}) {
            my $ws = $current->{Whitespace};
            $ws = 'normalize' unless defined $ws;
            if($ws =~ /normalize|trim/i) {
                for($node->{-text}) {
                    s/^\s+//;
                    s/\s+$//;
                }
            }
            if($ws =~ /normalize|collapse/i) {
                for($node->{-text}) {
                    tr/ \t\n\r\f/ /s;
                }
            }
            $node->{-contents} ||= [];
        }
        if($current->{End}) {
            foreach (@{$current->{End}}) {
                # print STDERR "Firing End rule $_->{pattern}\n";
                $_->{End}->($node, \@stack);
            }
        }
        $current = pop @stack;
        $node = $current->{-node};
      },
      Char => sub {
        my($self, $text) = @_;
        if($current->{-store}) {
            $node->{-text} .= $text;
            if(!$node->{-contents} or ref $node->{-contents}[-1]) {
                push @{$node->{-contents}}, $text;
            } else {
                $node->{-contents}[-1] .= $text;
            }
        }
      },
    );
    my $error;
    eval {
        $parser->parse($fh);
        1;
    } or $error = $@;
    $parser->release;
    close($fh);
    die $error if $error;
}

*parse_xml = \&parse;

1;
