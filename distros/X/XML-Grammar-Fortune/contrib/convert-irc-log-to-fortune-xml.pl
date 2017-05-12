#!/usr/bin/perl

=head1 SYNOPSIS

    $ cat my_conversation.log | perl convert-irc-log-to-fortune-xml.pl

=head1 DESCRIPTION

This is a script to convert an XChat conversation to part of the
Fortune-XML (see L<XML::Grammar::Fortune> ). It reads stuff on ARGV.

=cut

use strict;
use warnings;

use open IO => ':encoding(utf8)';

use CGI qw();

binmode STDOUT, ':encoding(utf8)';
binmode STDIN, ':encoding(utf8)';

my @messages;
while(<>)
{
    chomp;
    if (m{^[^<\*]*(<[^>]+>|\*)\t(.*)$})
    {
        my ($nick, $msg) = ($1, $2);
        if ($nick eq "*")
        {
            $msg =~ m{([^ ]+) (.*)};
            my ($real_nick, $real_msg) = ($1,$2);
            push @messages,
                {
                    type => "me",
                    nick => $real_nick,
                    msg => $real_msg,
                };
        }
        else
        {
            my ($real_nick) = ($nick =~ m{<([^>]+)>});
            push @messages,
                {'type' => "say", 'nick' => $real_nick, 'msg' => $msg};
        }
    }
    elsif (m{^[^\-]* ---\t(\S+) is now known as (\S+)})
    {
        my ($old_nick, $new_nick) = ($1, $2);
        push @messages,
            {'type' => "change_nick", 'old' => $old_nick, 'new' => $new_nick};
    }
    else
    {
       push @messages, {'type' => "raw", 'msg' => $_};
    }
}

sub esc
{
    return CGI::escapeHTML(shift);
}

for my $m (@messages)
{
    if ($m->{'type'} eq "say")
    {
        print qq{<saying who="} . $m->{nick} . qq{">} .
            esc($m->{msg}) . qq{</saying>\n};
    }
    elsif ($m->{'type'} eq "raw")
    {
        print esc($m->{'msg'}), "\n";
    }
    elsif ($m->{'type'} eq "change_nick")
    {
        print qq{<me_is who="} . $m->{old} . qq{">is now known as }.
            $m->{'new'} . qq{</me_is>\n};
    }
    elsif ($m->{'type'} eq "me")
    {
        print qq{<me_is who="} . $m->{nick} . qq{">} .
            esc($m->{msg}) . qq{</me_is>\n};
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 Shlomi Fish

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

