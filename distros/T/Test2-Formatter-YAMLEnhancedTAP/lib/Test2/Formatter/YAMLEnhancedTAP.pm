package Test2::Formatter::YAMLEnhancedTAP;

use strict;
use warnings;
use TAP::Parser::YAMLish::Writer;
use base 'Test2::Formatter::TAP';

our $VERSION = '0.0.5';

# Private: TAP::Parser::YAMLish::Writer instance to write YAML TAP snippets
#          it didn't really like YAML::PP in the output for whatever reason
my $_yaml_writer = TAP::Parser::YAMLish::Writer->new;

sub _yamilify_message {
  my ($self, $frame, $event, $message) = @_;
  my (undef, $filename, $lineno, $caller_class) = @{$frame};

  my $yaml = "";
  # Cleanup comments
  $message =~ s/#\s+//gm;
  # Cleanup extra newlines
  chomp($message);

  # Build the YAML.
  $_yaml_writer->write({
      at => {
        test_num => 0,
        filename => $filename,
        line => $lineno
      },
      emitter => $caller_class,
      message => $message
  }, \$yaml);

  # indent two spaces for the TAP parser.
  $yaml =~ s/^/  /mg;
  # add an extra newline for readability
  $yaml .= "\n";
  return $yaml;
}

#
sub print_optimal_pass {
  my $self = shift;
  my $ret = $self->SUPER::print_optimal_pass(@_);
  $self->{_optimal_pass_happened} = $ret;
  return $ret;
}

sub write {
  my ($self, $e, $num, $f) = @_;

  # The most common case, a pass event with no amnesty and a normal name.
  return if $self->print_optimal_pass($e, $num);

  $f ||= $e->facet_data;
  my $frame = $f->{trace}{frame};

  $self->encoding($f->{control}->{encoding}) if $f->{control}->{encoding};

  my @tap = $self->event_tap($f, $num) or return;

  $self->{MADE_ASSERTION} = 1 if $f->{assert};

  my $nesting = $f->{trace}->{nested} || 0;
  my $handles = $self->{handles};
  my $indent = '    ' x $nesting;

  # Local is expensive! Only do it if we really need to.
  local ($\, $,) = (undef, '') if $\ || $,;

  for my $set (@tap) {
    my ($hid, $msg) = @$set;
    next unless $msg;
    my $io = $handles->[$hid] or next;

    print $io "\n"
      if $ENV{HARNESS_ACTIVE}
      && $hid == $self->SUPER::OUT_ERR()
      && $self->{_LAST_FH} != $io
      && $msg =~ m/^#\s*Failed( \(TODO\))? test /;

    my (undef, $filename, $lineno, $caller_class) = @{$frame};

    my $is_comment = $msg =~ m/^#/;
    my $is_not_subtest_call = $caller_class ne 'Test::More::subtest';
    my $is_failed_msg = $msg =~ m/Looks like you failed/;
    my $filename_not_within_t_dir = $filename =~ m/^(t|xt)/;

    $msg = $self->_yamilify_message($frame, $e, $msg)
      if $is_comment
      && $is_not_subtest_call
      && !$is_failed_msg
      && $filename_not_within_t_dir;

    $msg =~ s/^/$indent/mg if $nesting;
    print $io $msg;
    $self->{_LAST_FH} = $io;
  }
}

1;
__END__

=head1 NAME

Test2::Formatter::YAMLEnhancedTAP - YAML-enhanced TAP output for your tests

=head1 SYNOPSIS

It renders extra pieces of context as YAML output on failed assertions.

On the command line, with I<prove>:

  $ T2_FORMATTER=YAMLEnhancedTAP prove ...

It's unbeknownst to me how to avoid the C<T2_FORMATTER=YAMLEnhancedTAP> env...

=head2 IMPORTANT NOTE

YAML is allowed on TAP version 13 onwards, make sure your parser accepts it.

=head1 DESCRIPTION

C<Test2::Formatter::YAMLEnhancedTAP> provides context on failed assertions as
YAML snippets following TAP version 13 grammar.

The sole purpose of this module is to be used with
L<TAP::Formatter::GitHubActions> to bring more accurate annotations.

=head1 SEE ALSO

=over 1

- L<TAP::Formatter::GitHubActions>: GitHub Actions annotations for your test
  runs!

- L<TAP Version 13 Spec|https://testanything.org/tap-version-13-specification.html>: For more information about the output syntax.

- L<Node-TAP|https://node-tap.org/tap-format/>: For source of inspiration

=back

=head1 AUTHOR

Jose, D. Gomez R. E<lt>1josegomezr [AT] gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Jose D. Gomez R.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
