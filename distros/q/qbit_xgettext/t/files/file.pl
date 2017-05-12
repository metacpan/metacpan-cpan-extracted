#!/usr/bin/perl

=head1

Some POD inforamtion
Test =cut in body

gettext('Text in POD');

=head2

=cut

gettext("Test 1' # \" "); # gettext('Text in comment')
gettext('Test 2:
%s', 'param message');

my $str = ' gettext("Text in string")';

ngettext(
    'Server',
    'Servers',
    2
);

ngettext('Server','Servers', $$);

ngettext('Server "%s"', 'Servers "%s"', 2, 'beta');

d_gettext('DServer');
d_ngettext('DServer', 'DServers', 2);

npgettext('Context', 'Server', 'Servers', 2);

my $other_str => sub {gettext('From sub')},

gettext("1

3");

gettext('(something in parenthetical)');

gettext('Server');

=head 1

POD at EOF
