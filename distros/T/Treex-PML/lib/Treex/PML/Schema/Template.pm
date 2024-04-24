package Treex::PML::Schema::Template;

use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.26'; # version template
}
no warnings 'uninitialized';
use Carp;
use Treex::PML::Schema::Constants;
use base qw(Treex::PML::Schema::XMLNode);

sub get_decl_type     { return(PML_TEMPLATE_DECL); }
sub get_decl_type_str { return('template'); }

sub simplify {
  my ($template,$opts)=@_;
  for my $c (
    sort {$a->{'-#'} <=> $b->{'-#'}}
      ((map { @{$template->{$_}} } grep {exists $template->{$_} } qw(copy import)),
       (map { values %{$template->{$_}} } grep {exists $template->{$_} } qw(template derive)))) {
    #    print STDERR "Processing <$c->{-xml_name}>\n";
    $c->simplify($opts);
  }
  delete $template->{template} unless $opts->{'preserve_templates'};
  delete $template->{copy} unless $opts->{'no_copy'};
  for (qw(derive import)) {
    if ($template->get_decl_type == PML_TEMPLATE_DECL) {
      delete $template->{$_} unless $opts->{'no_template_'.$_};
    } else {
      delete $template->{$_} unless $opts->{'no_'.$_};
    }
  }
}
sub for_each_decl {
  my ($self,$sub)=@_;
  $sub->($self);
  for my $d (qw(template type)) {
    if (ref $self->{$d}) {
      foreach (values %{$self->{$d}}) {
	$_->for_each_decl($sub);
      }
    }
  }
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Treex::PML::Schema::Template - a class representing templates in a Treex::PML::Schema

=head1 SYNOPSIS

use Treex::PML::Schema::Template;

=head1 DESCRIPTION

This class represents templates in a Treex::PML::Schema and is also a base for
PMLShema class itself.

=head1 METHODS

=over 5

=item $decl->get_decl_type ()

Returns the constant PML_TEMPLATE_DECL.

=item $decl->get_decl_type_str ()

Returns the string 'template'.

=item $decl->simplify ()

Process all modularity instructions used in within the template and
simplify embedded templates.

=item $schema->for_each_decl (sub{...})

This method traverses all nested declarations and sub-declarations and
calls a given subroutine passing the sub-declaration object as a
parameter.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Treex::PML::Schema>, L<Treex::PML::Schema::Copy>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

