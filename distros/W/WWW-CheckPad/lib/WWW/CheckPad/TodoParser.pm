package WWW::CheckPad::TodoParser;

use strict;
use warnings;
use WWW::CheckPad::Parser;
use HTML::Parser;
use base qw(WWW::CheckPad::Parser);


############################################################
# Usage: Called by WWW::CheckPad::Parser->convert_to_item().
#
# Will return array of following hash-structure.
# {
#   id=>?, title=>?, is_finished=>?, finished_time=>?
# }
############################################################
sub _parse {
  my ($self, $content) = @_;

  $self->param('todos', []);
  $self->parse($content);
  $self->eof;

  my $todos = $self->param('todos');
  return $todos;
}


sub start {
    my ($self, $tagname, $attr, $attr_array,$source) = @_;

    # Take out the unfinished todo item from input tag.
    if ($tagname eq 'input' and
            defined $attr->{type} and $attr->{type} eq 'text' and
                defined $attr->{id} and
                    defined $attr->{value} and
                        $attr->{id} =~ /^ms_([0-9]*)_edit/) {
        $self->_add_todo($1, $attr->{value}, 0);
    }
    # Mark that we are in fished todo item area.
    elsif ($tagname eq 'div' and
               defined $attr->{id} and $attr->{id} =~ /ms_done_([0-9]+)/) {
        $self->param('current_finished_id', $1);
    }
    
    # Finally we are in unfinished todo item.
    elsif ($tagname eq 'div' and
           defined $attr->{id} and
           defined $self->param('current_finished_id') and
           $attr->{id} eq $self->param('current_finished_id')) {
        $self->param('in_finished_div', 1);
        $self->_add_todo($self->param('current_finished_id'), "", 1);
    }
    # We are in the finished-date area of finished checkitem.
    elsif ($self->param('in_finished_div') and
           $tagname eq 'span' and
           $attr->{class} eq 's10') {
        #print "in the s10 area\n";
        $self->param('in_finished_date_span', 1);
    }
    
    if ($self->param('in_finished_div')) {
      #printf "in finished area: [%s] class=%s\n", $tagname, 'dummy';
    }
}


sub text {
    my ($self, $text) = @_;
    my %time_calc_map = (
        WWW::CheckPad->_jconvert('“ú‘O', 'euc-jp')   => (60*60*24),
        WWW::CheckPad->_jconvert('ŽžŠÔ‘O', 'euc-jp') => (60*60),
        WWW::CheckPad->_jconvert('•ª‘O', 'euc-jp')   => (60),
    );

    if (defined $self->param('in_finished_div') and
            $self->param('current_finished_id') > 0) {
        ## Remove space and line-breaks.
        $text =~ s/^[ \n]+//;
        $text =~ s/[ \n]+$//;

        return if ($text eq '');
        my $todo = $self->_get_last_todo();
        
        # We are in the in_finished_date_span.
        if ($self->param('in_finished_date_span') and
            $text =~ /\(([0-9]+)(.*)\)/) {

            my $time_diff = $1 * $time_calc_map{$2};

            $todo->{finished_time} = time - $time_diff;
            return;
        }
        # This is delete button ([x]).
        elsif ($text =~ /\[x\]/) {
            return;
        }

        $todo->{title} .= $text;
        
    }

}


sub end {
    my ($self, $tagname) = @_;

    if ($tagname eq 'span') {
        $self->param('in_finished_date_span', 0);
    }
}


sub comment {
    my ($self, $token) = @_;
    #printf "COMMENT: %s\n", $token;
    my $id = $self->param('current_finished_id');
    if (defined $id and
        $token =~ /end of ms_($id)/) {
        #printf "Found End Mark\n";
        $self->param('current_finished_id', 0);
        $self->param('in_finished_div', 0);
    }
}


sub _add_todo {
    my ($self, $id, $name, $finished) = @_;
    my $todos = $self->param('todos');
    my $todo = {
        id => $id,
        title => $name,
        is_finished => $finished,
    };
    push @{$todos}, $todo;
    return $todo;
}


sub _get_last_todo {
    my ($self) = @_;
    my $todos = $self->param('todos');
    return $todos->[$#{$todos}];
}




1;
