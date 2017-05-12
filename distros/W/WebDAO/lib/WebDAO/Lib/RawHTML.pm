package WebDAO::Lib::RawHTML;
#$Id$

=head1 NAME

WebDAO::Lib::RawHTML - Component for raw html

=head1 SYNOPSIS

=head1 DESCRIPTION

WebDAO::Lib::RawHTML - Component for raw html

=cut

our $VERSION = '0.01';
use strict;
use warnings;
use WebDAO::Base;
use base qw(WebDAO);

__PACKAGE__->mk_attr(_raw_html=>undef);

sub init {
    my ($self,$ref_raw_html)=@_;
   _raw_html $self $ref_raw_html;
}

sub fetch {
  my $self=shift;
  return ${$self->_raw_html};
}

1;
__DATA__

=head1 SEE ALSO

http://sourceforge.net/projects/webdao

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2014 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
