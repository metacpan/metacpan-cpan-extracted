package Config::MVP::Reader::Findable;
# ABSTRACT: a config class that Config::MVP::Reader::Finder can find
$Config::MVP::Reader::Findable::VERSION = '2.200011';
use Moose::Role;

#pod =head1 DESCRIPTION
#pod
#pod Config::MVP::Reader::Findable is a role meant to be composed alongside
#pod Config::MVP::Reader.
#pod
#pod =method refined_location
#pod
#pod This method is used to decide whether a Findable reader can read a specific
#pod thing under the C<$location> argument passed to C<read_config>.  The location
#pod could be a directory or base file name or dbh or almost anything else.  This
#pod method will return false if it can't find anything to read.  If it can find
#pod something to read, it will return a new (or unchanged) value for C<$location>
#pod to be used in reading the config.
#pod
#pod =cut

requires 'refined_location';

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::MVP::Reader::Findable - a config class that Config::MVP::Reader::Finder can find

=head1 VERSION

version 2.200011

=head1 DESCRIPTION

Config::MVP::Reader::Findable is a role meant to be composed alongside
Config::MVP::Reader.

=head1 METHODS

=head2 refined_location

This method is used to decide whether a Findable reader can read a specific
thing under the C<$location> argument passed to C<read_config>.  The location
could be a directory or base file name or dbh or almost anything else.  This
method will return false if it can't find anything to read.  If it can find
something to read, it will return a new (or unchanged) value for C<$location>
to be used in reading the config.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
