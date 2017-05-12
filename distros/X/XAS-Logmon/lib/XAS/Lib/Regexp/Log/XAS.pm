package XAS::Lib::Regexp::Log::XAS;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Regexp::Log';
use vars qw( %DEFAULT %FORMAT %REGEXP );

# standard log format
#
# [2015-11-30 07:36:39] INFO  - starting up
# %datetime%level%message
#
# with tasks
#
# [2015-11-30 07:36:39] INFO  - connector: tcp_keepalive enabled
# %datetime%level%task%message

%DEFAULT = (
    format  => '%datetime%level%message',
    capture => [qw( datetime level task message )],
);

%FORMAT = (
    ':default' => '%datetime%level%message',
    ':tasks'   => '%datetime%level%task%message',
);

%REGEXP = (
    '%datetime' => '\[(?#=datetime)\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?#!datetime)\]\s+',
    '%level'    => '(?#=level)\w+(?#!level)\s+-\s+',
    '%task'     => '(?#=task)[\w|-]+(?#!task):\s+',
    '%message'  => '(?#=message).*(?#!message)',
);

1;

__END__

=head1 NAME

XAS::Lib::Regexp::Log::XAS - a class to parse XAS log files

=head1 SYNOPSIS

Please refer to L<Regexp::Log|https://metacpan.org/pod/Regexp::Log> for how 
to use and initialize this module.

=head1 DESCRIPTION

The XAS log line is broken down into these fields:

 datetime level message

A log line with tasks is broken down into these fields:

 datetime level task message

=head1 SEE ALSO

=over 4

=item L<Regexp::Log|https://metacpan.org/pod/Regexp::Log>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
