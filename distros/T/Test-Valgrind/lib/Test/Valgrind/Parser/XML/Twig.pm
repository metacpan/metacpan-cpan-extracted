package Test::Valgrind::Parser::XML::Twig;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Parser::XML::Twig - Parse valgrind XML output with XML::Twig.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This subclass of L<XML::Twig> and L<Test::Valgrind::Parser::XML> encapsulates an L<XML::Twig> parser inside the L<Test::Valgrind::Parser> framework.
It is able to parse the XML output from C<valgrind> up to protocol version 4 and to generate the appropriate reports accordingly.

=cut

use Scalar::Util ();

use base qw<Test::Valgrind::Parser::XML Test::Valgrind::Carp XML::Twig>;

BEGIN { XML::Twig->add_options('Stash'); }

my %handlers = (
 '/valgrindoutput/protocolversion' => \&handle_version,
 '/valgrindoutput/error'           => \&handle_error,
);

=head1 METHODS

=cut

sub new {
 my $class = shift;
 $class = ref($class) || $class;

 my %args = @_;
 my $stash = delete $args{stash} || { };

 bless $class->XML::Twig::new(
  elt_class     => __PACKAGE__ . '::Elt',
  stash         => $stash,
  twig_roots    => { map { $_ => 1             } keys %handlers },
  twig_handlers => { map { $_ => $handlers{$_} } keys %handlers },
 ), $class;
}

sub stash { shift->{Stash} }

=head2 C<protocol_version>

The version of the protocol that the current stream is conforming to.
It is reset before and after the parsing phase, so it's effectively only available from inside C<parse>.

=cut

eval "sub $_ { \@_ <= 1 ? \$_[0]->{$_} : (\$_[0]->{$_} = \$_[1]) }"
                                              for qw<_session protocol_version>;

# We must store the session in ourselves because it's only possible to pass
# arguments to XML::Twig objects by a global stash.

sub start {
 my ($self, $sess) = @_;

 $self->SUPER::start($sess);
 $self->_session($sess);

 return;
}

sub parse {
 my ($self, $sess, $fh) = @_;

 $self->protocol_version(undef);

 $self->XML::Twig::parse($fh);
 $self->purge;

 $self->protocol_version(undef);

 return 0;
}

sub finish {
 my ($self, $sess) = @_;

 $self->_session(undef);
 $self->SUPER::finish($sess);

 return;
}

sub handle_version {
 my ($twig, $node) = @_;

 $twig->protocol_version($node->text);

 $twig->purge;
}

sub handle_error {
 my ($twig, $node) = @_;

 my $id   = $node->kid('unique')->text;
 my $kind = $node->kid('kind')->text;

 my $data;

 my ($what, $xwhat);
 if ($twig->protocol_version >= 4) {
  $xwhat = $node->first_child('xwhat');
  $what  = $xwhat->kid('text')->text if defined $xwhat;
 }
 $what = $node->kid('what')->text unless defined $what;
 $data->{what} = $what;

 $data->{stack} = [ map $_->listify_frame,
                                       $node->kid('stack')->children('frame') ];

 for (qw<leakedbytes leakedblocks>) {
  my $kid = ($xwhat || $node)->first_child($_);
  next unless $kid;
  $data->{$_} = int $kid->text;
 }

 if (my $auxwhat = $node->first_child('auxwhat')) {
  if (my $stack = $auxwhat->next_sibling('stack')) {
   $data->{auxstack} = [ map $_->listify_frame, $stack->children('frame') ];
  }
  $data->{auxwhat} = $auxwhat->text;
 }

 if (my $origin = $node->first_child('origin')) {
  $data->{origwhat}  = $origin->kid('what')->text;
  $data->{origstack} = [ map $_->listify_frame,
                                     $origin->kid('stack')->children('frame') ];
 }

 my $sess = $twig->_session;

 $sess->report($sess->report_class($sess)->new(
  kind => $kind,
  id   => $id,
  data => $data,
 ));

 $twig->purge;
}

=head1 SEE ALSO

L<Test::Valgrind>, L<Test::Valgrind::Parser>, L<Test::Valgrind::Parser::XML>.

L<XML::Twig>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Parser::XML::Twig

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

# End of Test::Valgrind::Parser::XML::Twig

package Test::Valgrind::Parser::XML::Twig::Elt;

our $VERSION = '1.19';

BEGIN { require XML::Twig; }

use base qw<XML::Twig::Elt Test::Valgrind::Carp>;

sub kid {
 my ($self, $what) = @_;
 my $node = $self->first_child($what);
 $self->_croak("Couldn't get first $what child node") unless $node;
 return $node;
}

sub listify_frame {
 my ($frame) = @_;

 return unless $frame->tag eq 'frame';

 return [
  map {
   my $x = $frame->first_child($_);
   $x ? $x->text : undef
  } qw<ip obj fn dir file line>
 ];
}

1; # End of Test::Valgrind::Parser::XML::Twig::Elt
