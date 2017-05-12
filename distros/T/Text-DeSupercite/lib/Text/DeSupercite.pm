package Text::DeSupercite;

use strict;
use Text::Quoted;
use Exporter;
use vars qw(@EXPORT_OK $VERSION);
use base qw(Exporter);

@EXPORT_OK = qw(desupercite);

$VERSION = '0.6';

sub desupercite ($;$);
sub _desupercite_aux ($$);

=pod

=head1 NAME 

Text::DeSupercite - remove supercite quotes and other non-standard quoting from text

=head1 SYNOPSIS

    use Text::DeSupercite qw/desupercite/;

    # just convert supercite quotes to '>'s    
    $text = desupercite($mail->body());

    # or convert *all* quot characters that aren't '>'s
    $text = desupercite($mail->body(),1);

    # set it back again
    $mail->body_set($text);

    
=head1 DESCRIPTION

Supercite is a Emacs Gnus package (http://www.gnus.org/) for providing a more 
err ... comprehensive ... form of quoting which tends to look like

    >>>>> "Foo" == Foo  <foo@foo.com> writes:
    >> blah blah blah blah blah blah blah blah blah blah blah blah blah blah
    >> blah blah blah blah blah blah blah blah blah blah blah blah blah blah

    Foo> yak yak yak yak yak yak yak yak yak yak yak yak yak yak yak yak yak
    Foo> yak yak yak yak yak yak yak yak yak yak yak yak yak yak yak yak yak
    Foo> yak yak yak yak yak yak yak yak yak yak yak yak yak yak yak yak yak


which annoys quite a lot of people who find it too noisy.

There's also people who quote like this 

    | this is a quote 
    
    this is not

which annoys another load of people. Mostly the two sets of annoyed people intersect.
Which is quite understandable.

This module takes a simplistic approach to removing these forms of quoting and 
replacing them with the more normal

    > this is a quote

    this is not 

    > > this is a quote of a quote 

style.

It has two modes, harsh and lenient. Lenient just desupercites. Harsh normalises
B<all> quoting.

=head1 BUGS

Non known but I haven't really hunted out pathological cases of superciting so
if you find one then please let me know.

It currently fails to desupercite stuff looking like

    Name1> some quote

this is a bug in Text::Quoted. There's a patch included with this module to fix it
if it's not fixed by Simon Cozens soon.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

(c)opyright Simon Wistow, 2003

Distributed under the same terms as Perl itself.

This software is under no warranty and will probably ruin your life, kill your friends, burn your house and bring about the apocalypse

=head1 SEE ALSO

L<Text::Quoted>, L<desupercite>

=cut

sub desupercite ($;$) {

    my $text      = shift || return "";
    my $merciless = shift || 0;


    return _desupercite_aux(extract($text),$merciless);

}


sub _desupercite_aux($$) {
    my $node      = shift || return "";
    my $merciless = shift || 0; # paranoia, paranoia, everybody's coming to get you

    if (ref $node eq 'ARRAY') {
        my $ret="";
        $ret.=_desupercite_aux($_, $merciless) for (@$node);
        return $ret;


    } elsif (ref $node eq 'HASH') {
        return "\n" if $node->{empty};

        if (!defined $node->{quoter} || $node->{quoter} eq '') {
                return $node->{raw}."\n";
        } else { 
            my $new  = join ' ', 
                       map { ($merciless)?_merciless($_):_lenient($_) } 
                       split /\s+/, 
                       $node->{quoter}; 
            
            $node->{raw} =~ s!^\Q$node->{quoter}!$new!mg;
            return $node->{raw}."\n";
        }
    } else {
            die "Eeeek unknown node type - ".(ref $node)."\n";
    }
    

}


sub _merciless {
    return '>';
}

sub _lenient {
    return ($_[0] =~ /^[\w\d]+\>/i)? '>' : $_[0];
}


1;
