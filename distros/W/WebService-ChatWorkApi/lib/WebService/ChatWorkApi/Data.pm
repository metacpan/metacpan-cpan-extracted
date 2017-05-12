use strict;
use warnings;
package WebService::ChatWorkApi::Data;
use Mouse;

has ds => ( is => "rw", isa => "WebService::ChatWorkApi::DataSet" );

1;

__END__
=encoding utf8

=head1 NAME

WebService::ChatWorkApi::Data - represents a data with a few methods, and some attributes

=head1 SYNOPSIS

  use WebService::ChatWorkApi::Data::Me;
  my $me = WebService::ChatWorkApi::Data::Me->new(
      ds => $ds,
      account_id => 3,
      # ...
  );
  my $my_chat_room = $me->room;
  my @rooms = $me->rooms;

=head1 DESCRIPTION

This module, and sub modules are for declare the attributes of the data.
And a few methods these may relate with the other data.

=head1 SUB MODULES

- Me
- Message
- Room

=head1 TODO

Add `Status`, `Task`, `Contact` sub modules.
