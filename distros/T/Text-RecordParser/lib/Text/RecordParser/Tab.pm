package Text::RecordParser::Tab;

use strict;
use warnings;
use version;

use base qw( Text::RecordParser );

our $VERSION = version->new('1.4.0');

# ----------------------------------------------------------------
sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );

    $self->field_separator("\t");

    return $self;
}

1;

__END__

# ----------------------------------------------------------------

=pod

=head1 NAME

Text::RecordParser::Tab - read tab-delimited files

=head1 SYNOPSIS

  use Text::RecordParser::Tab;

=head1 DESCRIPTION

This module is a shortcut for getting a tab-delimited parser.

=head2 new

Call "new" as normal but without worrying about "field_separator" or "fs."

Because this:

  my $p = Text::RecordParser::Tab->new($file);

Is easier to type than this

  my $p = Text::RecordParser->new( 
      filename        => $file,
      field_separator => "\t",
  );

=head1 AUTHOR

Ken Youens-Clark E<lt>kclark@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006-10 Ken Youens-Clark.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

=cut
