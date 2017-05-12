package WWW::Google::Contacts::GroupList;
{
    $WWW::Google::Contacts::GroupList::VERSION = '0.39';
}

use Moose;
use WWW::Google::Contacts::Group;

extends 'WWW::Google::Contacts::Base';

with 'WWW::Google::Contacts::Roles::List';

sub baseurl {
    my $self = shift;
    return sprintf( "%s://www.google.com/m8/feeds/groups/default",
        $self->server->protocol );
}
sub element_class { 'WWW::Google::Contacts::Group' }

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 SYNOPSIS

    use WWW::Google::Contacts;

    my $google = WWW::Google::Contacts->new( username => "your.username", password => "your.password" );

    my $groups = $google->groups;

    while ( my $gr = $groups->next ) {
       print "You got a contact group called " . $gr->title . "\n";
    }

=head1 METHODS

=head2 $groups->next

Returns the next L<WWW::Google::Contacts::Group> object

=head2 $groups->search( $args )

B<WARNING> This is quite slow at the moment, at least if you've got a lot of contacts.

Given search criteria, will return all your contacts that matches critera.

 my @spam_groups = $groups->search({
   title => "Spam",
 });

B<TODO>: Speed up. Make search arguments more flexible ( AND / OR / Regex / ... ).

=head1 AUTHOR

  Magnus Erixzon <magnus@erixzon.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Magnus Erixzon / Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut
