use warnings FATAL => qw(all);

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test::More ;

use Tk ;
use ExtUtils::testlib ;
BEGIN { use_ok ('Tk::ObjScanner') ; };

use strict ;
my $trace = shift || 0 ;

package myHash;
use Tie::Hash ;
use vars qw/@ISA/;

@ISA=qw/Tie::StdHash/ ;

sub TIEHASH {
    my $class = shift;
    my %args = @_ ;
    return bless { %args, dummy => 'foo' } , $class ;
}


sub STORE {
    my ($self, $idx, $value) = @_ ;
    $self->{$idx}=$value;
    return $value;
}

package MyScalar;
use Tie::Scalar ;
use vars qw/@ISA/;

@ISA=qw/Tie::StdHash/ ;

sub TIESCALAR {
    my $class = shift;
    my %args = @_ ;
    return bless { %args, dummy => 'foo default value' } , $class ;
}


sub STORE {
    my ($self, $value) = @_ ;
    $self->{data} = $value;
    return $value;
}

sub FETCH {
    my ($self) = @_ ;
    # print "\t\t",'@.....@.....@..... MeScalar read',"\n";
    return $self->{data} || $self->{dummy} ;
}

package Toto ;
use Scalar::Util qw(weaken) ;

sub new {
    my $type = shift ;

    my %h ;
    tie (%h, 'myHash', 'dummy key' => 'dummy value') or die ;
    $h{data1}='value1';


    # add recursive data only if interactive test
    my $tkstuff = $trace ? shift : "may be another time ..." ;

    my $scalar = 'dummy scalar ref value';
    open (FILE,"t/basic.t") || die "can't open myself !\n";
    my %a_hash = (for => 'weak ref') ;
    my $glob = \*FILE ;         # ???
    my $self = {
        'key1' => 'value1',
        'array' => [qw/a b sdf/, {'v1' => '1', 'v2' => 2},'dfg'],
        'key2' => {
            'sub key1' => 'sv1',
            'sub key2' => 'sv2'
        },
        'some_code' => sub {print "some_code\n";},
        'piped|key' => {a => 1 , b => 2},
        'scalar_ref_ref' => \\$scalar,
        'filehandle' => $glob,
        'empty string' => '',
        'non_empty string' => ' ',
        'long' => 'very long line'.'.' x 80 ,
        'is undef' => undef,
        'some text' => "some \n dummy\n Text\n",
        'tied hash' => \%h ,
        'not weak' => \%a_hash,
        'weak' => \%a_hash ,
        'tk widget' => $tkstuff
    };

    tie ($self->{tied_scalar}, 'MyScalar', 'dummy key' => 'dummy value')
        or die ;

    weaken($self->{weak}) ;


    $self->{tied_scalar} = 'some scalar huh?';

    bless $self,$type;
}


package main;

SKIP: {
    my $toto ;
    my $mw = eval { MainWindow-> new ; };

    # cannot create Tk window
    if (not $mw) {
        skip "Cannot create Tk window", 1 ;
        done_testing ;
        exit;
    }

    $mw->geometry('600x400+10+10');

    my $w_menu = $mw->Frame(-relief => 'raised', -borderwidth => 2);
    $w_menu->pack(-fill => 'x');

    my $f = $w_menu->Menubutton(-text => 'File', -underline => 0)
        -> pack(-side => 'left' );
    $f->command(-label => 'Quit',  -command => sub{$mw->destroy;} );

    my $dummy = Toto->new ($mw);

    ok($dummy, "created dummy object");

    my $s = $mw -> ObjScanner ('-caller' => $dummy, -columns => 4, -header => 1 );

    ok($s, "Created obj scanner");

    $s->headerCreate(1,-text =>'coucou') ;

    $s -> pack(-expand => 1, -fill => 'both') ;

    $mw->idletasks;

    sub scan {
        my $topName = shift ;
        $s->yview($topName) ;
        ok(1, "view $topName");
        $mw->after(200);    # sleep 300ms

        foreach my $c ($s->infoChildren($topName)) {
            $s->displaySubItem($c);
            scan($c);
        }
        $mw->idletasks;
    }

    if ($trace) {
        MainLoop ;              # Tk's
    }
    else {
        scan('root');
    }

}

done_testing;

