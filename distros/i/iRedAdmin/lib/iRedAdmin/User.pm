package iRedAdmin::User;

use Moo;

has 'ref' => (is => 'ro');

sub Add {
    my ($self, %data) = @_;
    
    if (Email::Valid->address($data{email})) {
        my ($email, $domain) = $data{email} =~ m!^(.*?)@(.*?)$!gs;
        $self->ref->mech->get($self->ref->_address . '/create/user/');
        $self->ref->mech->submit_form(
            form_number => 1,
            fields => {
                username => $email,
                domainName => $domain,
                newpw => $data{password},
                confirmpw => $data{password},
                cn => $data{name},
                mailQuota => $data{quota}
            }
        );
        
        my $success = $self->ref->_success;
        $self->Add(%data) if $success == 2;
        return $success ? 1 : 0;
    }else{
        $self->ref->set_error('Email is invalid!');
        return 0;
    }
}

sub Edit {
    my ($self, %data) = @_;
    
    if (Email::Valid->address($data{email})) {
        $self->ref->mech->get($self->ref->_address . '/profile/user/general/' . $data{email});
        
        my %form;
        $form{cn} = $data{name} if exists $data{name};
        $form{preferredLanguage} = $self->ref->_lang($data{lang}) if $data{lang};
        $form{mailQuota} = $data{quota} if $data{quota};
        $form{employeeNumber} = $data{user_id} if exists $data{user_id};
        if (exists $data{domainGlobalAdmin}) {
            $form{domainGlobalAdmin} = 'global' if $data{global_admin};
            $self->ref->mech->untick('domainGlobalAdmin', 'global') unless $data{global_admin};
        }
        if (exists $data{enable}) {
            $form{accountStatus} = 'active' if $data{enable};
            $self->ref->mech->untick('accountStatus', 'active') unless $data{enable};
        }
        $self->ref->mech->submit_form(
            form_number => 1,
            fields => \%form
        );
        
        my $success = $self->ref->_success;
        $self->Add(%data) if $success == 2;
        return $success ? 1 : 0;
    }else{
        $self->ref->set_error('Email is invalid!');
        return 0;
    }
}

sub Password {
    my ($self, %data) = @_;
    
    if (Email::Valid->address($data{email})) {
        $self->ref->mech->get($self->ref->_address . '/profile/user/general/' . $data{email});
        
        $self->ref->mech->submit_form(
            form_number => 2,
            fields => {
                newpw => $data{password},
                confirmpw => $data{password}
            }
        );
        
        my $success = $self->ref->_success;
        $self->Password(%data) if $success == 2;
        return $success ? 1 : 0;
    }else{
        $self->ref->set_error('Email is invalid!');
        return 0;
    }
}

sub Enable {
    my ($self, @email) = @_;
    
    $self->_apply('enable', [@email]);
}

sub Disable {
    my ($self, @email) = @_;
    
    $self->_apply('disable', [@email]);
}

sub Delete {
    my ($self, @email) = @_;
    
    $self->_apply('delete', [@email]);
}

sub _apply {
    my ($self, $type, @email) = @_;
    
    my $domain = undef;
    for(@{$email[0]}){
        $_ =~ m!@(.*?)$!s;
        if ($domain) {
            if ($domain ne $1) {
                $self->ref->set_error('All email needs be of same domain!');
                return 0;
            }
        }else{
            $domain = $1;
        }
    }
    
    $self->ref->mech->get($self->ref->_address . '/users/' . $domain);

    my %form;
    $form{action} = $type;
    $form{mail} = \@email;
    $self->ref->mech->submit_form(
        form_number => 1,
        fields => \%form
    );
    
    my $success = $self->ref->_success;
    $self->_apply($type, @email) if $success == 2;
    return $success ? 1 : 0;
}

1;

__END__

=encoding utf8
 
=head1 NAME

iRedAdmin::User - API for add, edit, delete, enable and disable User

=cut

=head1 VERSION
 
Version 0.03
 
=cut
 
=head1 SYNOPSIS
 
    use iRedAdmin;
     
    my $iredadmin = iRedAdmin->new(
        url => 'https://hostname.mydomain.com/iredadmin',
        username => 'postmaster@mydomain.com',
        password => 'your_password',
        cookie => '/home/user/cookie.txt',
        lang => 3
    );
    
    my $user = $iredadmin->User->Add(
        email => 'foo@domain.com',
        password => 'password_of_email',
        name => 'Foo',
        quota => 2048
    );
    
    print $iredadmin->error unless $user; # print error if $user is equal 0
    
=cut

=head1 METHODS

=head2 Add

Method to add User.

=cut

=head3 Arguments

B<email>

Email of User


B<password>

Password of User

B<name>

Display Name of User (Optional)

B<quota>

Mailbox Quota of User (Optional)

=head2 Edit

Method to edit User.

=cut

=head3 Arguments

B<email>

Email of User

B<name>

Change Display Name of User

B<lang>

Change language default of User

B<enable>

1 to enable, 0 to disable, without set not change account

B<global_admin>

1 to enable, 0 to disable, without set not change account

=head2 Password

Method to change password of User.

=cut 

=head3 Arguments

B<email>

Email of User

B<password>

New password of User

=head2 Enable

Method to enable Users.

B<Example>

    $iredadmin->User->Enable(
       'foo@domain.com',
       'bar@domain.com',
       'baz@domain.com'
    );

=head2 Disable

Method to disable Users.

B<Example>

    $iredadmin->User->Disable(
       'foo@domain.com',
       'bar@domain.com',
       'baz@domain.com'
    );

=head2 Delete

Method to delete Users.

B<Example>

    $iredadmin->User->Delete(
       'foo@domain.com',
       'bar@domain.com',
       'baz@domain.com'
    );

=head1 AUTHOR

Lucas Tiago de Moraes, C<< <lucastiagodemoraes@gmail.com> >>

=cut

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.

=cut