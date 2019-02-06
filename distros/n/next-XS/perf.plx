use 5.012;
use warnings;
use Benchmark 'timethis', 'timethese', 'cmpthese';
use Time::HiRes 'time';

*stdnext::can = \&next::can;
*stdnext::method = \&next::method;
*stdmaybe::next::method = \&maybe::next::method;

require next::XS;

my $cnt = 1000;
my $bsuper_str = "super::bsuperdyn";

sub cbench {
    my ($package, $name, $code) = @_;
    $code = "$code;" x $cnt;
    eval "
        package $package;
        sub $name { my \$self = shift; $code }
    ";
}

{
    package M1;
    sub meth { say "ARGS '@_'"; return 1 }
    sub smeth { say "ARGS '@_'"; return 1 }
    sub bSUPER {}
    sub bcan_my {}
    sub bcan_std {}
    sub bdcan_my {}
    sub bdcan_std {}
    sub bmethod_my {}
    sub bmethod_std {}
    sub bdmethod_my {}
    sub bdmethod_std {}
    sub method_my {}
    sub method_my2 {}
    sub bsuper {}
    sub super {}
    sub bmaybe_method_my {}
    sub bmaybe_method_std {}
    sub ncan {}
    sub bsuperdyn {}
    sub bdsuper {}
    sub bmaybe_super {}
    
    package M2;
    use mro 'c3';
    our @ISA = 'M1';
    sub meth { shift->next::method(@_) + 2 }
    sub smeth { $_[0]->super::smeth + 2}
    sub dcan_my { my $self = shift; next::can($self) }
    sub can_my { my $self = shift; $self->next::can }
    
    main::cbench(__PACKAGE__, 'bcan_my',  '$self->next::can');
    main::cbench(__PACKAGE__, 'bcan_std', '$self->stdnext::can');
    
    main::cbench(__PACKAGE__, 'bmethod_my',  '$self->next::method');
    main::cbench(__PACKAGE__, 'bmethod_std', '$self->stdnext::method');
    main::cbench(__PACKAGE__, 'bsuper',      '$self->super::bsuper');
    
    main::cbench(__PACKAGE__, 'bmaybe_method_my',     '$self->maybe::next::method');
    main::cbench(__PACKAGE__, 'bmaybe_method_my_ne',  '$self->maybe::next::method');
    main::cbench(__PACKAGE__, 'bmaybe_method_std',    '$self->stdmaybe::next::method');
    main::cbench(__PACKAGE__, 'bmaybe_method_std_ne', '$self->stdmaybe::next::method');
    main::cbench(__PACKAGE__, 'bmaybe_super',         '$self->super::maybe::bmaybe_super');
    main::cbench(__PACKAGE__, 'bmaybe_super_ne',      '$self->super::maybe::bmaybe_super_ne');
    
    main::cbench(__PACKAGE__, 'bSUPER',       '$self->SUPER::bSUPER');
    main::cbench(__PACKAGE__, 'bsuperdyn', '$self->$bsuper_str');
    main::cbench(__PACKAGE__, 'bdcan_my',     'next::can($self)');
    main::cbench(__PACKAGE__, 'bdcan_std',    'stdnext::can($self)');
    main::cbench(__PACKAGE__, 'bdmethod_my',  'next::method($self)');
    main::cbench(__PACKAGE__, 'bdmethod_std', 'stdnext::method($self)');
    main::cbench(__PACKAGE__, 'bdsuper', 'super::bdsuper($self)');
    
    sub ncan { shift->next::can() }
    sub maybe_method { my @ret = shift->maybe::next::method(1,2,3); return @ret }
    
    package M4;
    our @ISA = 'M1';
    sub meth { $_[0]->next::method + 4 }
    sub smeth { $_[0]->super::smeth + 4}
    
    package M8;
    #use mro 'c3';
    our @ISA = ('M2', 'M4');
    sub meth { next::method(@_) + 8 }
    sub smeth { super::smeth(@_) + 8}
}

say $$;
my $o = bless {}, 'M2';

say M1->meth(1,2,3) for 1..2;
say M2->meth(1,2,3) for 1..2;
say M4->meth for 1..2;
say M8->meth for 1..2;

#say M1->smeth(1,2,3) for 1..2;
#say M2->smeth(1,2,3) for 1..3;
#say M4->smeth for 1..3;
#say M8->smeth for 1..3;

#$o->bmaybe_super_ne for 1..2;

#exit;

for (1..10) {
    cmpthese(-1, {
        perl_nextcan  => sub { $o->bcan_std },
        xs_nextcan    => sub { $o->bcan_my },
    });
    cmpthese(-1, {
        perl_next_method  => sub { $o->bmethod_std },
        xs_next_method    => sub { $o->bmethod_my },
        xs_super          => sub { $o->bsuper },
    });    
    cmpthese(-1, {
        perl_maybe_next_method       => sub { $o->bmaybe_method_std },
        perl_maybe_next_method_last  => sub { $o->bmaybe_method_std_ne },
        xs_maybe_next_method         => sub { $o->bmaybe_method_my },
        xs_maybe_next_method_last    => sub { $o->bmaybe_method_my_ne },
        xs_maybe_super               => sub { $o->bmaybe_super },
        xs_maybe_super_last          => sub { $o->bmaybe_super_ne },
    });    
}

#cmpthese(-1, {
##    bSUPER => sub { $o->bSUPER },
#    xs_super => sub { $o->bsuper },
##    bdsuper => sub { $o->bdsuper },
##    bsuperdyn => sub { $o->bsuperdyn },
##    bcan_my => sub { $o->bcan_my },
##    subcan => sub { $o->subcan },
##    bcan_std => sub { $o->bcan_std },
##    bdcan_my => sub { $o->bdcan_my },
##    bdcan_std => sub { $o->bdcan_std },
#    xs_next_method => sub { $o->bmethod_my },
##    method_my => sub { $o->method_my },
##    method_my2 => sub { $o->method_my2 },
#    perl_next_method => sub { $o->bmethod_std },
##    bdmethod_my => sub { $o->bdmethod_my },
##    bdmethod_std => sub { $o->bdmethod_std },
##    bmaybe_method_my => sub { $o->bmaybe_method_my },
##    bmaybe_method_my_ne => sub { $o->bmaybe_method_my_ne },
#}) for 1..50;

#$o->bcan_my for 1..10000000;
#$o->method_my2 for 1..1000000000;
#$o->bmethod_my for 1..1000000;
#$o->bdcan_my for 1..1000000;

