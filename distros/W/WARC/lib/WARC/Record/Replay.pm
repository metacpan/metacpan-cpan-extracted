package WARC::Record::Replay;					# -*- CPerl -*-

use strict;
use warnings;

use WARC; *WARC::Record::Replay::VERSION = \$WARC::VERSION;

=head1 NAME

WARC::Record::Replay - WARC record replay registry and autoloading

=head1 SYNOPSIS

  use WARC::Record;

  $object = $record->replay;

=cut

use Carp;
use File::Spec;

# array of arrays:
#  ( [ predicate coderef, handler coderef ]... )
our @Handlers = ();
#  Each predicate is called with the record object locally stored in $_ and
#  must return false to reject the record or true to accept the record.
#
#  Each handler for which the predicate returns true is tried in order.

=head1 DESCRIPTION

This is an internal module that provides a registry of protocol replay
support modules and an autoloading facility.

=over

=cut

# Scan @INC for autoload descriptors and see if any available modules can
# be autoloaded for this record.

sub _try_autoload_for ($) {
  my $record = shift;
  my $loaded = 0;

  local *_;
  foreach my $area (@INC) {
    my $vol; my $dirpath; my $tail;
    ($vol, $dirpath, $tail) = File::Spec->splitpath($area);
    my @dirs = File::Spec->splitdir($dirpath);
    my $dirname = File::Spec->catpath
      ($vol, File::Spec->catdir(@dirs, $tail, qw/WARC Record Replay/));

    next unless -d $dirname;

    opendir my $dir, $dirname or die "autoload dirscan $dirname: $!";
    my @modules = grep defined, map {/^([[:alnum:]_]+[.]pm)$/; $1} # untaint
      grep /[.]pm$/, readdir $dir;
    closedir $dir or die "autoload dirscan close $dirname: $!";

  FILE:
    foreach my $module (@modules) {
      my $filename = File::Spec->catpath
	($vol, File::Spec->catdir(@dirs, $tail, qw/WARC Record Replay/),
	 $module);
      my $modfilename = File::Spec::Unix->catfile
	(qw/WARC Record Replay/, $module);
      next FILE if $INC{$modfilename};

      open my $file, '<', $filename or die "autoload scan $filename: $!";
      my $descriptor_found = 0;
    LINE:
      while (<$file>) {
	if (m/^=(?:for|begin)\s+autoload(?:\s+|$)/)
	  { $descriptor_found = 1; next LINE; }
	next LINE unless $descriptor_found;
	last LINE if m/^=/;

	if (m/^\[WARC::Record::Replay\]$/)
	  { $descriptor_found = 2; next LINE; }
	next LINE if $descriptor_found < 2;
	last LINE if m/^\[/;

	# ... parse and test conditional; load if matched
	if (m/^([[:alpha:]][_[:alnum:]]*)\(([-_[:alnum:]]*)\)\s*=\s*(.+)$/) {
	  #	$1: method	$2: argument	$3: match
	  my $match_valid = 0; my $match_value;
	  eval {$match_value = $record->$1($2); $match_valid = 1};
	  if ($match_valid and $match_value =~ $3)
	    { require $modfilename; $loaded++; last LINE }
	}
      }
      close $file or die "autoload scan close $file: $!";
    }
  }

  return $loaded
}

=item WARC::Record::Replay::register { predicate } $handler

Add a handler to the internal list of replay handlers.  The given handler
will be used for records on which the given predicate returns true.

The predicate will be evaluated with $_ locally set to the record object to
be replayed and @_ empty each time a record is replayed.

=cut

sub register (&$) {
  croak "attempt to register invalid handler"
    unless (ref $_[0] eq 'CODE') && (ref $_[1] eq 'CODE');

  push @Handlers, [ @_[0, 1] ];

  return # nothing
}

=item WARC::Record::Replay::find_handlers( $record )

Return a list of handlers that can replay the protocol message in $record.

=cut

sub find_handlers ($) {
  my $record = shift;
  my @handlers = ();

  {
    local *_; $_ = $record;
    foreach my $handler (@Handlers)
      { push @handlers, $handler->[1] if $handler->[0]->() }
  }

  if (scalar @handlers == 0 and _try_autoload_for $record)
    # repeat the search now that a module has been loaded
    { unshift @_, $record; goto &find_handlers }

  return @handlers
}

=back

=cut

1;
__END__

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC::Record>, L<WARC>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
