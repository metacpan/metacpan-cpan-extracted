use strict;
package WWWXML::Modules::Profile;

use Date::Simple;

sub home {
    my ($class) = @_;
    if(defined $::query->get_param('submit_action')) {
        return $class->_home_process;
    }
    return $class->_home_form;
}

sub _home_form ($;$) {
    my ($class,$login_enable) = @_;
    my $form = WWWXML::Output->new_form(
        name => 'profile',
        validate => {
            login   => q{/^.+$/},
            fname   => q{/^.+$/},
            sname   => q{/^.+$/},
            inn     => q{/^\d+$/},
            birth   => {
                perl => q{ =~ /^\d{4}-\d\d-\d\d$/ && Date::Simple->new($&) }
            }
        },
    );

    $form->field(
        name => 'login',
        type => 'text',
        value => $login_enable ? '' : $::user->{id},
        disabled => !$login_enable,
    );
    
    $form->field(
        name => $_,
        type => 'text',
        value => $login_enable ? '' : $::user->{$_},
    ) for qw/fname sname inn birth/;
    
    return $form;
}

sub _home_process {
    my ($class) = @_;
    my $form = $class->_home_form;
    return $form unless $form->validate;
    
    $::t->xquery(q{
        update for $c in input()/clientz/client[@id='%s']
        do (
            replace $c/sname with <sname>%s</sname>
            replace $c/fname with <fname>%s</fname>
            replace $c/inn   with <inn>%s</inn>
            replace $c/birth with <birth>%s</birth>
        )
    }, $::user->{id}, map {$::query->get_param($_)} qw/sname fname inn birth/) or die "X-Error: ".$::t->error;
    
    WWWXML::Output->redirect("?action=home");
    return;
#    return $form;
}

sub register {
    my ($class) = @_;
    if(defined $::query->get_param('submit_action')) {
        return $class->_reg_process;
    }
    return $class->_reg_form;
}

sub _reg_form ($) {
    my ($class) = @_;
    my $form = $class->_home_form(1);
    $form->tmpl_param(register => 1);

    $form->field(
        name => 'pass',
        type => 'password',
        value => '',
        force => 1,
    );
    
    $form->field(
        name => 'password2',
        type => 'password',
        value => '',
        force => 1,
    );
    
    return $form;
}

sub _reg_process {
    my ($class) = @_;
    my $form = $class->_reg_form;
    if(!$form->validate || $::query->get_param('pass') ne $::query->get_param('password2') || $::query->get_param('pass') eq '') {
        if($::query->get_param('pass') ne $::query->get_param('password2')) {
            $form->error("The passwords did not match");
        } elsif($::query->get_param('pass') eq '') {
            $form->error("The password cannot be empty");
        }
        return $form;
    }
    
    $::t->simplify(undef);
    my $u = $::t->xquery(q{for $x in input()/clientz/client[@id='%s'] return $x}, $::query->get_param('login')) or die "X-Error: ".$::t->error;
    if($u->{client}) {
        $form->fields_invalid([qw/login/]);
        $form->error("This login already exists");
        return $form;
    }
    
    my $clients = XML::Twig::Elt->new('clientz');
    $u = XML::Twig::Elt->new('client');
    $u->set_att(id => $::query->get_param('login'));
    for (qw/pass sname fname inn birth/) {
        my $n = XML::Twig::Elt->new($_);
        $n->set_text($::query->get_param($_));
        $n->paste(last_child => $u);
    }
    XML::Twig::Elt->new($_)->paste(last_child => $u) for qw/numbers cards/;
    $u->paste(last_child => $clients);
    
    $::t->process([{data => $clients}]) or die "X-Error: ".$::t->error;

    $::session->param(uid => $u->{client}->{id});
    WWWXML::Output->redirect('?action=home');
    return;
}

sub cards {
    my ($class) = @_;
    if(defined $::query->get_param('submit_action')) {
        return $class->_cards_process;
    }
    return $class->_cards_form;
}

sub _cards_form {
    my ($class) = @_;
    my $form = WWWXML::Output->new_form(
        name => 'cards',
        validate => {
            id      => q{/^.+$/},
            cvv     => q{/^\d{3}$/},
            valid   => q{/^\d\d\/\d\d$/},
        },
    );
    
    $::t->simplify([keyattr => [], forcearray => [qw/paysys bank/]]);
    my $inf = $::t->xquery(q{
        for $x in ( input()/services_db/systems/paysys,
                    input()/services_db/banks/bank )
        return $x
    });
    
    $form->field(
        name => 'sys',
        type => 'select',
        options => [ map +{$_ => $_}, grep {$_} @{$inf->{paysys}} ],
    );
    
    $form->field(
        name => 'vendor',
        type => 'select',
        options => [ map +{$_->{id} => $_->{id}}, grep {$_->{id}} @{$inf->{bank}} ],
    );                                                            
    
    $form->field(
        name => $_,
        type => 'text',
    ) for qw/id cvv valid/;

    return $form;
}

sub _cards_process {
    my ($class) = @_;

    if($::query->get_param('submit_action') eq 'delete') {
        $::t->xquery(q{update delete input()/clientz/client[@id='%s']/cards/card[id=(%s)]}, $::user->{id}, join(',', map "'$_'", grep {$::query->get_param("s_${_}")} map {$_->{id}} @{$::user->{cards}->{card}})) or die "X-Error: ".$::t->error;
        WWWXML::Output->redirect("?action=cards");
        return;
    }
    
    my $form = $class->_cards_form;
    return $form unless $form->validate;
    
    my $card_id = $::query->get_param('id');

    my $sys    = $::query->get_param('sys');
    my $vendor = $::query->get_param('vendor');
    
    $::t->simplify([keyattr => [], forcearray => []]);
    my $inf = $::t->xquery(q{
        for $x in (input()/services_db/systems/paysys[text()='%s'],
                   input()/services_db/banks/bank[@id='%s'])
        return $x
    },$sys,$vendor) or die "X-Error: ".$::t->error;
    die "Bad vendor selected" unless($inf->{bank});
    die "Bad system selected" unless($inf->{paysys});

    my $card = qq{<card sys="$sys" vendor="$vendor">};
    $card .= qq{<$_->[0]>$_->[1]</$_->[0]>} for grep {defined $_->[1]} map { [$_, $::query->get_param($_)] } qw/id cvv valid/;
    $card .= qq{</card>};
    
    if(grep { $_->{id} eq $card_id } @{$::user->{cards}->{card}}) {
        $::t->xquery(q{update replace input()/clientz/client[@id='%s']/cards/card[id='%s'] with %s}, $::user->{id}, $card_id, $card) or die "X-Error: ".$::t->error;
    } else {
        $::t->xquery(q{update insert %s into input()/clientz/client[@id='%s']/cards}, $card, $::user->{id}) or die "X-Error: ".$::t->error;
    }
    
    WWWXML::Output->redirect("?action=cards");
    return;
}

sub numbers {
    my ($class) = @_;
    if(defined $::query->get_param('submit_action')) {
        return $class->_numbers_process;
    }
    return $class->_numbers_form;
}

sub _numbers_form {
    my ($class) = @_;
    my $form = WWWXML::Output->new_form(
        name => 'numbers',
        validate => {
            num     => q{/^\d+$/},
            sum     => q{/^\d+(?:\.\d+)?/},
            vendor  => q{/^.+$/},
        },
    );
    
    $::t->simplify([keyattr => [], forcearray => [qw/op zone acc/]]);
    my $inf = $::t->xquery(q{
        for $x in ( input()/services_db/services/op )
        return $x
    });
    
    my %ops;
    $form->field(
        name => 'vendor',
        type => 'select',
        options => [ map {
            my $id   = $_->{id};
            my $name = $_->{name};
            map { my @a = $_->{id} eq 'all' ? ("$id/all" => $name) : ( "$id/$_->{id}" => "$name - $_->{suffix}" ); $ops{$a[0]}=$a[1]; +{@a} } grep {$_->{id}} @{$_->{zone}}
        } grep {$_->{id}} @{$inf->{op}} ],
    );                                                            

    for (@{$::user->{numbers}->{number}}) {
        $_->{sub}||='all';
        $_->{vendor_text} = $ops{ "$_->{vendor}/$_->{sub}" };
    }
    
    $form->field(
        name => $_,
        type => 'text',
    ) for qw/num sum/;
    
    return $form;
}

sub _numbers_process {
    my ($class) = @_;

    if($::query->get_param('submit_action') eq 'delete') {
        $::t->xquery(q{update delete input()/clientz/client[@id='%s']/numbers/number[num=(%s)]}, $::user->{id}, join(',', grep {$::query->get_param("n_${_}")} map {$_->{num}} @{$::user->{numbers}->{number}})) or die "X-Error: ".$::t->error;
        WWWXML::Output->redirect("?action=numbers");
        return;
    }
    
    my $form = $class->_numbers_form;
    return $form unless $form->validate;
    
    my $num = $::query->get_param('num');
    my ($op,$zone) = split '/',$::query->get_param('vendor');

    $::t->simplify([keyattr => [], forcearray => [qw/zone acc/]]);
    my $inf = $::t->xquery(q{for $x in input()/services_db/services/op[@id='%s'] return $x}, $op) or die "X-Error: ".$::t->error;
    die "Bad vendor selected" unless($inf->{op} && grep { $_->{id} eq $zone } @{$inf->{op}->{zone}});

    $zone = $zone ne 'all' && qq{ sub="$zone"};
    my $number = qq{<number vendor="$op"$zone>};
    $number .= qq{<$_->[0]>$_->[1]</$_->[0]>} for map { [$_, $::query->get_param($_)] } qw/num sum/;
    $number .= qq{</number>};
    
    if(grep { $_->{num} eq $num } @{$::user->{numbers}->{number}}) {
        $::t->xquery(q{update replace input()/clientz/client[@id='%s']/numbers/number[num=%s] with %s}, $::user->{id}, $num, $number) or die "X-Error: ".$::t->error;
    } else {
        $::t->xquery(q{update insert %s into input()/clientz/client[@id='%s']/numbers}, $number, $::user->{id}) or die "X-Error: ".$::t->error;
    }
    
    WWWXML::Output->redirect("?action=numbers");
    return;
}

1;

