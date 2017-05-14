use strict;
package WWWXML::Modules::Login;

sub logout {
    my ($class) = @_;
    $::session->delete;
    WWWXML::Output->redirect('?action=login');
    return;
}

sub login {
    my ($class) = @_;
    if(defined $::query->get_param('submit_action')) {
        return $class->_process;
    }
    return $class->_form;
}

sub _form {
    my ($class) = @_;
    my $form = WWWXML::Output->new_form(name => 'login');
    
    $form->field(
        name => 'login',
        type => 'text',
    );
    
    $form->field(
        name => 'pass',
        type => 'password',
    );
    
    return $form;
}

sub _process {
    my ($class) = @_;
    
    $::t->simplify([keyattr => [], forcearray => [qw/number card/]]);
    my $u = $::t->xquery(q{for $x in input()/clientz/client[@id='%s'][pass='%s'] return $x}, $::query->get_param('login'), $::query->get_param('pass')) or die "X-Error: ".$::t->error;
    
    if($u->{client} && $u->{client}->{id}) {
        $::session->param(uid => $u->{client}->{id});
        WWWXML::Output->redirect('?action=home');
        return;
    }
    
    my $form = $class->_form;
    $form->error('Login/pass mismatch');
    return $form;
}

1;

