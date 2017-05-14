use strict;
package WWWXML::Modules::Transfer;

use POSIX qw/strftime mktime/;

sub history {
    my ($class) = @_;
    my $form = WWWXML::Output->new_form(
        name => 'transfers',
        validate => {
            for_last => '/^\d+$/'
        },
    );
    
    return $form unless($form->validate);

    my @cond;
    push @cond, sprintf(q{[client/@id='%s']}, $::user->{id});
    
    if((my $d = $::query->get_param('for_last')) ne '') {
        push @cond, sprintf(q{[time>=%s]}, (int(mktime(localtime time)/(24*60*60)) - $d)*(24*60*60));
    }

    $::t->simplify([keyattr => [], forcearray => [qw/transfer/]]);
    my $inf = $::t->xquery(q{
        for $x in input()/transfers/transfer%s
        return
            <transfer>
                {$x/client/number}
                {$x/client/card}
                <old_sum>{string($x/client/sum)}</old_sum>
                <new_sum>{$x/client/sum + $x/sum}</new_sum>
                {$x/sum}
                {$x/time}
            </transfer>
        sort by (time)
    }, join('',@cond)) or die "X-Error: ".$::t->error;
    
    my $sum = 0;
    $_->{time} = strftime("%F %T",gmtime($_->{time})) and $sum += $_->{sum} for @{$inf->{transfer}};
    $form->tmpl_param(transfers => $inf->{transfer});
    $form->tmpl_param(transfers_sum => $sum);

    $form->field(
        name => 'for_last',
        type => 'select',
        value => '30',
        options => [
            {'' => 'ALL'},
            {0  => 'Today'},
            map +{ $_ => $_ }, qw/1 5 10 20 30 91 182 365/
        ],
    );
    
    return $form;
}

sub pay {
    my ($class) = @_;
    $::session->clear('transfer');
    if(defined $::query->get_param('submit_action')) {
        return $class->_pay_process;
    }
    return $class->_pay_form;
}

sub _pay_form {
    my ($class) = @_;
    
    my $form = WWWXML::Output->new_form(
        name => 'pay',
        validate => {
            sum      => q{/^\d+(?:\.\d+)?$/},
        },
    );
    
    $form->field(
        name => 'number',
        type => 'select',
        options => [ map +{ $_ => $_ }, map { $_->{num} } @{$::user->{numbers}->{number}} ],
    );
    
    $form->field(
        name => 'card',
        type => 'select',
        options => [ map +{ $_ => $_ }, map { $_->{id} } @{$::user->{cards}->{card}} ],
    );
    
    $form->field(
        name => 'sum',
        type => 'text',
    );
    
    return $form;
}

sub _pay_process {
    my ($class) = @_;

    my $form = $class->_pay_form;
    return $form unless $form->validate;
    
    my $card   = $::query->get_param('card');
    die "Bad card selected" unless(grep { $_->{id} eq $card } @{$::user->{cards}->{card}});
    
    my $number = $::query->get_param('number');
    die "Bad number selected" unless(grep { $_->{num} eq $number } @{$::user->{numbers}->{number}});
    
    $::session->param(transfer => {
        card => $card,
        number => $number,
        sum => $::query->get_param('sum'),
    });
    
    WWWXML::Output->redirect("?action=pay2");
    return;
}

sub pay2 {
    my ($class) = @_;
    
    unless($::session->param('transfer')) {
        WWWXML::Output->redirect("?action=pay");
        return;
    }
    
    if(defined $::query->get_param('submit_action')) {
        return $class->_pay2_process;
    }
    return $class->_pay2_form;
}

sub _pay2_form {
    my ($class) = @_;
    
    my $form = WWWXML::Output->new_form(name => 'pay');
    $form->tmpl_param(action_pay  => 1);
    $form->tmpl_param(action_pay2 => 1);

    $form->field(
        name => 'pass',
        type => 'password',
        value => '',
        force => 1
    );
    
    my $t = $::session->param('transfer');
    $form->tmpl_param($_ => $t->{$_}) for qw/card number sum/;
    
    return $form;
}

sub _pay2_process {
    my ($class) = @_;
    
    my $t = $::session->param('transfer');
    $::session->clear('transfer');

    my $form = $class->_pay2_form;
    if($::query->get_param('pass') ne $::user->{pass}) {
        $form->field(name => 'pass', invalid => 1);
        return $form;
    }
    
    my $tran = $::tamino->begin_tran or die "Can't begin transaction: X-Error: ".$::tamino->error;
    
    $tran->xquery(q{
        update
            for $c in input()/clientz/client[@id='%s'],
                $n in $c/numbers/number[num=%s],
                $a in $c/cards/card[id='%s']
            do insert
                <transfer>
                    <client>{$c/@id}
                        <number>{string($n/num)}</number>
                        <card>{string($a/id)}</card>
                        <sum>{string($n/sum)}</sum>
                    </client>
                    <operator id="{$n/@vendor}" sub="{$n/@sub}">{
                        for $oz in input()/services_db/services/op[@id=$n/@vendor]/zone[@id=$n/@sub]
                        return $oz/acc[position()=1]
                    }</operator>
                    <sum>%s</sum>
                    <time>%s</time>
                </transfer>
            into input()/transfers
    }, $::user->{id}, $t->{number}, $t->{card}, $t->{sum}, mktime(localtime time)) or die "X-Error: ".$tran->error;

    $tran->xquery(q{update 
        for $s in input()/clientz/client[@id='%s']/numbers/number[num=%s]/sum
        do replace $s with <sum>{$s+%s}</sum>
    }, $::user->{id}, $t->{number}, $t->{sum}) or die "X-Error: ".$tran->error;
    
    $tran->commit or die "X-Error: ".$tran->error;
    
    WWWXML::Output->redirect("?action=history");
    return;
}

1;

