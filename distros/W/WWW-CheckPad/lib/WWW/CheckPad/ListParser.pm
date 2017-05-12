package WWW::CheckPad::ListParser;

use strict;
use warnings;
use WWW::CheckPad::Parser;
use HTML::Parser;
use base qw(WWW::CheckPad::Parser);


sub _parse {
    my ($self, $content) = @_;
    
    $self->param('list', []);
    $self->parse($content);
    $self->eof;
    return $self->param('list');
}


sub start {
    my ($self, $tagname, $attr, $attr_array,$source) = @_;
    if ($tagname eq 'li' and
            $attr->{id} =~ /^item_/) {
        $self->param('in_list_tag', 1);
        $self->param('current_item_id', $attr->{id} =~ /item_(.*)/)
    }
    else {
        $self->param('in_list_tag', 0);
    }
}

sub text {
    my ($self, $text) = @_;
    if ($self->param('in_list_tag')) {
        ## Remove space and line-breaks.
        $text =~ s/^[ \n]+//;
        $text =~ s/[ \n]+$//;
        if ($text ne '') {
            my $list = $self->param('list');
            push @{$list}, {id=>$self->param('current_item_id'), title=>$text};
            $self->param('list', $list);
        }
    }
}



1;
