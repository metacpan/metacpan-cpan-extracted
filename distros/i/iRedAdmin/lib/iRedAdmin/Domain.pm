package iRedAdmin::Domain;

use Moo;

has 'ref' => (is => 'ro');

sub Add {
    my ($self, %data) = @_;
    
    if (Email::Valid->address('domain@'.$data{domain})) {
        $self->ref->mech->get($self->ref->_address . '/create/domain');
        $self->ref->mech->submit_form(
            form_number => 1,
            fields => {
                domainName => $data{domain},
                cn => $data{name}
            }
        );
        
        my $success = $self->ref->_success;
        $self->Add(%data) if $success == 2;
        return $success ? 1 : 0;
    }else{
        $self->ref->set_error('Domain is invalid!');
        return 0;
    }
}

sub Edit {
    my ($self, %data) = @_;
    
    if (Email::Valid->address('domain@'.$data{domain})) {
        $self->ref->mech->get($self->ref->_address . '/profile/domain/general/' . $data{domain});
        
        my %form;
        $form{cn} = $data{name} if exists $data{name};
        if (exists $data{enable}) {
            $form{accountStatus} = 'active' if $data{enable};
            $self->ref->mech->untick('accountStatus', 'active') unless $data{enable};
        }
        $self->ref->mech->submit_form(
            form_number => 1,
            fields => \%form
        );
        
        my $success = $self->ref->_success;
        $self->Edit(%data) if $success == 2;
        return $success ? 1 : 0;
    }else{
        $self->ref->set_error('Domain is invalid!');
        return 0;
    }
}

sub Enable {
    my ($self, @domain) = @_;
    
    $self->_apply('enable', [@domain]);
}

sub Disable {
    my ($self, @domain) = @_;
    
    $self->_apply('disable', [@domain]);
}

sub Delete {
    my ($self, @domain) = @_;
    
    $self->_apply('delete', [@domain]);
}

sub _apply {
    my ($self, $type, @domain) = @_;
    
    $self->ref->mech->get($self->ref->_address . '/domains');

    my %form;
    $form{action} = $type;
    $form{domainName} = \@domain;
    $self->ref->mech->submit_form(
        form_number => 1,
        fields => \%form
    );
    
    my $success = $self->ref->_success;
    $self->_apply($type, @domain) if $success == 2;
    return $success ? 1 : 0;
}

1;

__END__

=encoding utf8
 
=head1 NAME

iRedAdmin::Domain - API for add, edit, delete, enable and disable Domain

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
    
    my $admin = $iredadmin->Domain->Add(
        domain => 'foo.com',
        name => 'Company Foo',
    );
    
    print $iredadmin->error unless $admin; # print error if $admin is equal 0
    
=cut

=head1 METHODS

=head2 Add

Method to add Domain.

=cut

=head3 Arguments

B<domain>

Address of Domain

B<name>

Company/Organization Name

=head2 Edit

Method to edit Admin.

=cut

=head3 Arguments

B<name>

Change Company/Organization Name

B<enable>

1 to enable, 0 to disable, without set not change domain

=head2 Enable

Method to enable Domains.

B<Example>

    $iredadmin->Domain->Enable(
       'foo.com',
       'bar.com',
       'baz.com'
    );

=head2 Disable

Method to disable Domains.

B<Example>

    $iredadmin->Domain->Disable(
       'foo.com',
       'bar.com',
       'baz.com'
    );

=head2 Delete

Method to delete Domains.

B<Example>

    $iredadmin->Domain->Delete(
       'foo.com',
       'bar.com',
       'baz.com'
    );

=head1 AUTHOR

Lucas Tiago de Moraes, C<< <lucastiagodemoraes@gmail.com> >>

=cut

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.

=cut