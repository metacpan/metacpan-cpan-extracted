package Text::Template::Simple::Cache::ID;
$Text::Template::Simple::Cache::ID::VERSION = '0.91';
use strict;
use warnings;
use overload q{""} => 'get';

use Text::Template::Simple::Constants qw(
   MAX_FILENAME_LENGTH
   RE_INVALID_CID
);
use Text::Template::Simple::Util qw(
   LOG
   DEBUG
   DIGEST
   fatal
);

sub new {
   my $class = shift;
   my $self  = bless do { \my $anon }, $class;
   return $self;
}

sub get {
   my $self = shift;
   return ${$self};
}

sub set { ## no critic (ProhibitAmbiguousNames)
   my $self = shift;
   my $val  = shift;
   ${$self} = $val if defined $val;
   return;
}

sub generate { # cache id generator
   my($self, $data, $custom, $regex) = @_;

   if ( ! $data ) {
      fatal('tts.cache.id.generate.data') if ! defined $data;
      LOG( IDGEN => 'Generating ID from empty data' ) if DEBUG;
   }

   $self->set(
      $custom ? $self->_custom( $data, $regex )
              : $self->DIGEST->add( $data )->hexdigest
   );

   return $self->get;
}

sub _custom {
   my $self  = shift;
   my $data  = shift or fatal('tts.cache.id._custom.data');
   my $regex = shift || RE_INVALID_CID;
      $data  =~ s{$regex}{_}xmsg; # remove bogus characters
   my $len   = length $data;

   # limit file name length
   if ( $len > MAX_FILENAME_LENGTH ) {
      $data = substr $data,
                     $len - MAX_FILENAME_LENGTH,
                     MAX_FILENAME_LENGTH;
   }

   return $data;
}

sub DESTROY {
   my $self = shift || return;
   LOG( DESTROY => ref $self ) if DEBUG;
   return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Cache::ID

=head1 VERSION

version 0.91

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

   TODO

=head1 NAME

Text::Template::Simple::Cache::ID - Cache ID generator

=head1 METHODS

=head2 new

Constructor

=head2 generate DATA [, CUSTOM, INVALID_CHARS_REGEX ]

Generates an unique cache id for the supplied data.

=head2 get

Returns the generated cache ID.

=head2 set

Set the cache ID.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
