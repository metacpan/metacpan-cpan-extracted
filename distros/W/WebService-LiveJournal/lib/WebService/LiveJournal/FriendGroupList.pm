package WebService::LiveJournal::FriendGroupList;

use strict;
use warnings;
use WebService::LiveJournal::List;
use WebService::LiveJournal::FriendGroup;
our @ISA = qw/ WebService::LiveJournal::List /;

# ABSTRACT: List of LiveJournal friend groups
our $VERSION = '0.08'; # VERSION


sub init
{
  my $self = shift;
  my %arg = @_;
  
  if(defined $arg{response})
  {
    foreach my $f (@{ $arg{response}->value->{friendgroups} })
    {
      $self->push(new WebService::LiveJournal::FriendGroup(%{ $f }));
    }
  }
  
  return $self;
}

sub as_string
{
  my $self = shift;
  my $str = "[friendgrouplist \n";
  foreach my $friend (@{ $self })
  {
    $str .= "\t" . $friend->as_string . "\n";
  }
  $str .= ']';
  $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LiveJournal::FriendGroupList - List of LiveJournal friend groups

=head1 VERSION

version 0.08

=head1 DESCRIPTION

List of friend groups returned from L<WebService::LiveJournal>.
See L<WebService::LiveJournal::FriendGroup> for how to use
this class.

=head1 SEE ALSO

L<WebService::LiveJournal>,

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
