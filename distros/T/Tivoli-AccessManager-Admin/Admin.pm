package Tivoli::AccessManager::Admin;
use Tivoli::AccessManager::Admin::ACL;
use Tivoli::AccessManager::Admin::Action;
use Tivoli::AccessManager::Admin::AuthzRule;
use Tivoli::AccessManager::Admin::Context;
use Tivoli::AccessManager::Admin::Domain;
use Tivoli::AccessManager::Admin::Group;
use Tivoli::AccessManager::Admin::Objectspace;
use Tivoli::AccessManager::Admin::POP;
use Tivoli::AccessManager::Admin::ProtObject;
use Tivoli::AccessManager::Admin::Server;
use Tivoli::AccessManager::Admin::User;        
use Tivoli::AccessManager::Admin::SSO::Web;
use Tivoli::AccessManager::Admin::SSO::Group;
use Tivoli::AccessManager::Admin::SSO::Cred;

$Tivoli::AccessManager::Admin::VERSION = '1.11';
use Inline( C => 'DATA',
	    NAME => 'Tivoli::AccessManager::Admin',
	    VERSION => '1.11'
	  );

my %dispatch = ( 
    acl 	=> 'Tivoli::AccessManager::Admin::ACL',
    action 	=> 'Tivoli::AccessManager::Admin::Action',
    authzrule 	=> 'Tivoli::AccessManager::Admin::AuthzRule',
    context 	=> 'Tivoli::AccessManager::Admin::Context',
    group 	=> 'Tivoli::AccessManager::Admin::Group',
    objectspace	=> 'Tivoli::AccessManager::Admin::Objectspace',
    'pop'	=> 'Tivoli::AccessManager::Admin::POP',
    protobject 	=> 'Tivoli::AccessManager::Admin::ProtObject',
    server	=> 'Tivoli::AccessManager::Admin::Server',
    user 	=> 'Tivoli::AccessManager::Admin::User;       ',
    ssoweb	=> 'Tivoli::AccessManager::Admin::SSO::Web',
    ssocred	=> 'Tivoli::AccessManager::Admin::SSO::Cred',
);


sub new {
    my $class = shift;  # Ignore this.
    my $desired = lc shift;
    if ( defined $dispatch{ $desired } ) {
	return $dispatch{$desired}->new( @_ );
    }
    else {
	return Tivoli::AccessManager::Admin::Context->new( $desired, @_ );
    }
}

1;

=head1 NAME

Tivoli::AccessManager::Admin

=head1 SYNOPSIS

    use Tivoli::AccessManager::Admin

    # Do cool and wicked TAM things

=head1 DESCRIPTION

B<Tivoli::AccessManager::Admin> is a convenience module.  You can simply B<use> it and have access to:

=over 4

=item L<Tivoli::AccessManager::Admin::Context|Tivoli::AccessManager::Admin::Context>

=item L<Tivoli::AccessManager::Admin::Response|Tivoli::AccessManager::Admin::Response>

=item L<Tivoli::AccessManager::Admin::ACL|Tivoli::AccessManager::Admin::ACL>

=item L<Tivoli::AccessManager::Admin::Action|Tivoli::AccessManager::Admin::Action>

=item L<Tivoli::AccessManager::Admin::Authzrule|Tivoli::AccessManager::Admin::Authzrule>

=item L<Tivoli::AccessManager::Admin::Group|Tivoli::AccessManager::Admin::Group>

=item L<Tivoli::AccessManager::Admin::Objectspace|Tivoli::AccessManager::Admin::Objectspace>

=item L<Tivoli::AccessManager::Admin::POP|Tivoli::AccessManager::Admin::POP>

=item L<Tivoli::AccessManager::Admin::ProtObject|Tivoli::AccessManager::Admin::ProtObject>

=item L<Tivoli::AccessManager::Admin::Server|Tivoli::AccessManager::Admin::Server>

=item L<Tivoli::AccessManager::Admin::User|Tivoli::AccessManager::Admin::User>

=item L<Tivoli::AccessManager::Admin::SSO::Web|Tivoli::AccessManager::Admin::SSO::Web>

=item L<Tivoli::AccessManager::Admin::SSO::Cred|Tivoli::AccessManager::Admin::SSO::Cred>

Each of these objects provide access to the equivalent calls in the TAM API.
See the documentation for each of these modules for more information.

=over 4

=head1 Unimplemented

You may have noticed from the previous list that I have not yet implemented
the full API.  I still need to write:

=over 4

=item B<Tivoli::AccessManager::Admin::Config>

This module will be written, but I just haven't gotten there yet.

=item B<Tivoli::AccessManager::Admin::AccessOutdata>

=item B<Tivoli::AccessManager::Admin::Context::cleardelcred>

=item B<Tivoli::AccessManager::Admin::Context::hasdelcred>

=item B<Tivoli::AccessManager::Admin::ProtObject::access>

=item B<Tivoli::AccessManager::Admin::ProtObject::multiaccess>

The first is a class and the following are methods.  They are not implemented
due to my own ignorance.  I vaguely understand what they are supposed to do,
but I just cannot figure out how to implement them.

=back

=head1 TODO

=over 4

=item *

Implement the missing objects

=item *

Basic clean up.  Most of this code was written as I was learning.  I think you
can see my style evolve from B<Tivoli::AccessManager::Admin::Context> to
B<Tivoli::AccessManager::Admin::User>.  I would like to make it consistent.

=head1 SEE ALSO

L<Tivoli::AccessManager::Admin::Context|Tivoli::AccessManager::Admin::Context>, L<Tivoli::AccessManager::Admin::Response|Tivoli::AccessManager::Admin::Response>, L<Tivoli::AccessManager::Admin::ACL|Tivoli::AccessManager::Admin::ACL>, L<Tivoli::AccessManager::Admin::Action|Tivoli::AccessManager::Admin::Action>, L<Tivoli::AccessManager::Admin::Authzrule|Tivoli::AccessManager::Admin::Authzrule>, L<Tivoli::AccessManager::Admin::Group|Tivoli::AccessManager::Admin::Group>, L<Tivoli::AccessManager::Admin::Objectspace|Tivoli::AccessManager::Admin::Objectspace>, L<Tivoli::AccessManager::Admin::POP|Tivoli::AccessManager::Admin::POP>, L<Tivoli::AccessManager::Admin::ProtObject|Tivoli::AccessManager::Admin::ProtObject>, L<Tivoli::AccessManager::Admin::Server|Tivoli::AccessManager::Admin::Server>, L<Tivoli::AccessManager::Admin::User|Tivoli::AccessManager::Admin::User>, L<Tivoli::AccessManager::Admin::SSO::Web|Tivoli::AccessManager::Admin::SSO::Web>, L<Tivoli::AccessManager::Admin::SSO::Cred|Tivoli::AccessManager::Admin::SSO::Cred>

=head1 ACKNOWLEDGEMENTS

None of this would have been possible if not for Brian Ingerson's B<Inline::C>.

Major thanks to Michael G Schwern's B<Test::More> -- the code would have been
a lot buggier without running everything through Test::More.

An equal share of thanks and curses goes to Paul Johnson for B<Devel::Cover>.
I cannot count the number of bugs this module helped me find or the number of
times I cursed it for keeping me up to 3:00 am saying "I will go to bed after
I get just one more percent branch coverage".  Those who use it know what I mean.

=head1 BUGS

None known yet.

=head1 AUTHOR

Mik Firestone E<lt>mikfire@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2011 Mik Firestone.  All rights reserved.  This program is
free software; you can redistibute it and/or modify it under the same terms as
Perl itself.

All references to TAM, Tivoli Access Manager, etc are copyrighted, trademarked
and otherwise patented by IBM.

=cut

__DATA__

__C__

int silly() {
    printf("Go away\n");
    return(0);
}

