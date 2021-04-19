package DBIx::Class::Valiant::ResultSet;

use warnings;
use strict;
use Carp;
use Valiant::Util 'debug';
use namespace::autoclean -also => ['debug'];

sub build {
  my ($self, %attrs) = @_;
  return $self->new_result(\%attrs);
}

sub skip_validation {
  my ($self, $arg) = @_;
  if(defined($arg)) {
    $self->{_skip_validation} = $arg ? 1:0;
  }
  return $self->{_skip_validation};
}
  
sub skip_validate {
  my ($self) = @_;
  $self->skip_validation(1);
  return $self;
}
sub do_validate {
  my ($self) = @_;
  $self->skip_validation(0);
  return $self;
}

sub new_result {
  my ($self, $fields, @args) = @_;
  my $context = delete $fields->{__context};

  my %related = ();
  my %nested = $self->result_class->accept_nested_for;
  
  foreach my $associated (keys %nested) {
    $related{$associated} = delete($fields->{$associated})
      if exists($fields->{$associated});
  }

  # Remove any relationed keys we didn't find with the allows nested
  my @rel_names = $self->result_source->relationships();
  my @m2m_names = keys  %{ $self->result_class->_m2m_metadata ||+{} };

  my %found = map { $_ => delete($fields->{$_}) } @rel_names, @m2m_names;

  if(grep { defined $_ } values %found) {
    my $related = join(', ', grep { $found{$_} } keys %found);
    die "You are trying to create a relationship ($related) without setting 'accept_nested_for'";
  }

  my $result = $self->next::method($fields, @args);
  $result->{__VALIANT_CREATE_ARGS}{context} = $context if $context; # Need this for ->insert
  $result->skip_validation(1) if $self->skip_validation;

  debug 2, "made new_result @{[ $result ]}";
  RELATED: foreach my $related(keys %related) {

    if(my $cb = $nested{$related}->{reject_if}) {
      my $response = $cb->($result, $related{$related});
      next RELATED if $response;
    }

    if(my $limit_proto = $nested{$related}->{limit}) {
      my $limit = (ref($limit_proto)||'' eq 'CODE') ?
        $limit_proto->($self) :
        $limit_proto;
      my $num = scalar @{$related{$related}};
      confess "Relationship $related can't create more than $limit rows at once" if $num > $limit;      
    }

    $result->set_related_from_params($related, $related{$related});
  }

  return $result;
}

1;

=head1 NAME

DBIx::Class::Valiant::ResultSet - Validation support for resultsets

=head1 DESCRIPTION

=head1 METHODS

This component adds the following methods to your resultset classes.

=head2 build

This just wraps C<new_result> to provide a new result object, optionally
with fields set, that is not yet in storage.  

=head2 skip_validation

    $schema->resultset('User')->skip_validation(1)->...

Turns off automatic validation on any creates / updates / etc going forward 
in this chain if arg is true

=head2 skip_validate

=head2 do_validate

Skip validations or reenable validations

  $schema->resultset('User')
    ->skip_validate
    ->create(\%user_args);

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
 
=head1 SEE ALSO
 
L<Valiant>, L<DBIx::Class>, L<DBIx::Class::Valiant>

=head1 AUTHOR

See L<Valiant>.

=head1 COPYRIGHT & LICENSE

See L<Valiant>.

=cut

