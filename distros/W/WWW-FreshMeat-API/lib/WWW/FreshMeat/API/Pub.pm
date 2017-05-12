package WWW::FreshMeat::API::Pub;
use Moose::Role;
use WWW::FreshMeat::API::Pub::V1_03 qw/get_api_info/;

our $VERSION = '0.01';

#requires 'sid';

sub BUILD {
    my $self = shift;
    my $api  = get_api_info();
    
    for my $name ( keys %{ $api } ) {
        
        # if mock then setup some dummy methods
        if ( $self->mock ) {
            $self->meta->add_method( $name => sub {
                my ( $self, %params ) = @_;
                return $api->{ $name }->{ returns };
            });
            next;
        }
         
        # else public methods... however next two require setting up session
        next  if $name eq 'login';
        next  if $name eq 'logout';
        
        # now all remaining public methods - v1.03
        if ( @{ $api->{ $name }->{ params } } ) {
            
            # build methods with params
            $self->meta->add_method( $name => sub {
                my ( $self, %params ) = @_;
                
                # add SID if it needs it (must be first in array)
                %params = ( SID => $self->session->{ SID }, %params )
                    if  $api->{ $name }->{ params }->[0] eq 'SID';
                    
                $self->agent->call( $name, \%params );
            });
        }
        
        else {
            # build method with no params
            $self->meta->add_method( $name => sub {
                my $self = shift;
                $self->agent->call( $name );
            });
        }
    }   
}

# session methods
sub login {
    my ( $self, %params ) = @_;
    $self->session( $self->agent->call( 'login', \%params ) );
}

sub logout {
    my $self = shift;
    $self->agent->call( 'logout', { SID => $self->session->{ SID } } );
    $self->clear_session;
}

no Moose::Role;

1;


__END__

=pod

=head1 NAME

WWW::FreshMeat::API::Pub - FreshMeats published / public (take your pick!) API methods

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

    use Moose;
    
    with 'WWW::FreshMeat::API::Pub';


=head1 DESCRIPTION

This is a Moose role which builds the public/published FreshMeat API from WWW::FreshMeat::API::Pub::V1_03 metadata.
    

=head1 EXPORT

None.


=head1 METHODS

See FreshMeat API docs.  Methods use same names.  
Where docs say returns "Array" then a ArrayRef is return.
Where docs says returns "Struct" then HashRef is returned.
So if docs say "Array of structs" then ArrayRef of HashRefs is returned by said method.



=head2 fetch_available_licenses

=head2 fetch_available_release_foci

=head2 fetch_branch_list

=head2 fetch_project_list

=head2 fetch_release

=head2 publish_release

=head2 withdraw_release

=head2 login

=head2 logout

To satisfy pod-coverage!

=head2 get_api_info

=head2 BUILD


=head1 AUTHOR

Barry Walsh, C<< <draegtun at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-freshmeat-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-FreshMeat-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::FreshMeat::API::Pub


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-FreshMeat-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-FreshMeat-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-FreshMeat-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-FreshMeat-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 SEE ALSO

=head2 Freshmeat API FAQ

http://freshmeat.net/faq/view/49/

=head2 Freshmeat XML-RPC API announcement

http://freshmeat.net/articles/view/1048/

=head2 Other WWW::FreshMeat::API modules

L<WWW::FreshMeat::API>




=head1 COPYRIGHT & LICENSE

Copyright 2009 Barry Walsh (Draegtun Systems Ltd), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

