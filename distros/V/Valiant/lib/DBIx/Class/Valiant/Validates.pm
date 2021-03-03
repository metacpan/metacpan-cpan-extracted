package DBIx::Class::Valiant::Validates;

use Moo::Role;
use Valiant::I18N;
use Scalar::Util;

with 'Valiant::Validates';

around default_validator_namespaces => sub {
  my ($orig, $self, @args) = @_;
  return 'DBIx::Class::Valiant::Validator', $self->$orig(@args);
};

around validate => sub {
  my ($orig, $self, %args) = @_;

  #return $self if $args{refs}{Scalar::Util::refaddr $self}||''; # try to stop circular
  #$args{refs}{Scalar::Util::refaddr $self}++;
  
  return $self->$orig(%args);
};

1;

=head1 NAME

DBIx::Class::Valiant::Validates - Add Valiant to DBIC

=head1 DESCRIPTION

This is pretty much undocumented but seems to be working, you'll need to look
at test cases and file bug reports.   Please don't use this unless you are willing
to deal with sharp edges and file broken test cases.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Valiant>, L<DBIx::Class>

=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
