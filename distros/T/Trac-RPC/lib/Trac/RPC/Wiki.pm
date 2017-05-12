package Trac::RPC::Wiki;
{
  $Trac::RPC::Wiki::VERSION = '1.0.0';
}



use strict;
use warnings;

use base qw(Trac::RPC::Base);



sub get_page {
    my ($self, $page) = @_;

    return $self->call(
        'wiki.getPage',
        RPC::XML::string->new($page)
    );
}


sub put_page {
    my ($self, $page, $content) = @_;

    $self->call(
        'wiki.putPage',
        RPC::XML::string->new($page),
        RPC::XML::string->new($content),
        RPC::XML::struct->new()
    );

    return ''
}


sub get_all_pages {
    my ($self) = @_;

    return $self->call(
        'wiki.getAllPages'
    );
}

1;

__END__

=pod

=head1 NAME

Trac::RPC::Wiki

=head1 VERSION

version 1.0.0

=encoding UTF-8

=head1 NAME

Trac::RPC::Wiki - access to Trac Wiki methods via Trac XML-RPC Plugin

=head1 GENERAL FUNCTIONS

=head2 get_page

B<Get:> 1) $self 2) scalar with page name

B<Return:> 1) scalar with page content

=head2 put_page

B<Get:> 1) $self 2) scalar with page name 3) scalar with page content

B<Return:> -

=head2 get_all_pages

B<Get:> 1) $self

B<Return:> 1) ref to the array with list of all wiki pages

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
