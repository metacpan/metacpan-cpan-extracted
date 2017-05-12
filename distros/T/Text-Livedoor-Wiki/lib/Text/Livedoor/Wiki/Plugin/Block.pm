package Text::Livedoor::Wiki::Plugin::Block;

use warnings;
use strict;
use base qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata('trigger');

sub check  { die 'implement me'; }
sub get    { die 'implement me'; }
sub mobile { shift->get(@_) }

sub trigger_check {
    my $class   = shift;
    my $id      = shift;
    my $line    = shift;
    my $trigger = $Text::Livedoor::Wiki::scratchpad->{core}{block_trigger};

    my $skip = 0;
    my $child_check = $class->get_child($id)  ;
    
    if( $child_check ) {
        $skip = $trigger->{$child_check}{escape} ? 1 : 0;
    }

    for my $key ( keys %$trigger ) {
        last if $skip;
        # append stocks
        if ( $line =~ m/\G($trigger->{$key}{start})/ ) {
            $class->push_children( $id, $key );
        #    warn 'size_up:' . $line . ':' .$id.':'. scalar @{$Text::Livedoor::Wiki::scratchpad->{block}{$id}{children}};
        }
    }

    if ( my $child = $class->get_child($id) ) {
        if ( $line =~ m/\G($trigger->{$child}{end})/ ) {
            #warn 'killed:' . $id . ':' .$line ;
            $class->kill_child( $id );
            return 0;
        }
        else {
            return 0;
        }
    }


    1;
}

sub kill_child {
    my $class = shift;
    my $id    = shift;
    pop @{$Text::Livedoor::Wiki::scratchpad->{block}{$id}{children}};
}

sub get_child {
    my $class = shift;
    my $id    = shift;
    return unless $Text::Livedoor::Wiki::scratchpad->{block}{$id}{children};

    return $Text::Livedoor::Wiki::scratchpad->{block}{$id}{children}[-1];
}

sub push_children {
    my $class = shift;
    my $id    = shift;
    my $key   = shift;
    $Text::Livedoor::Wiki::scratchpad->{block}{$id}{children} ||= [];
    push @{ $Text::Livedoor::Wiki::scratchpad->{block}{$id}{children} }, $key;
}

sub opts {
    return $Text::Livedoor::Wiki::opts;
}
1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block - Block Plugin Base Class

=head1 DESCRIPTION

you can use this class as base to create Base Plugin. 

=head1 SYNOPSIS

 package Text::Livedoor::Wiki::Plugin::Block::Pre;
 
 use warnings;
 use strict;
 use base qw(Text::Livedoor::Wiki::Plugin::Block);
 
 sub check {
     my $self = shift;
     my $line = shift;
     my $args        = shift;
     my $on_next     = $args->{on_next};
 
     if( $line =~ /^\^/ ) {
         $line =~ s/^\^// unless $on_next;;
         return  { line => $line . "\n" };
     }
     return;
 
 }
 
 sub get {
     my $self = shift;
     my $block = shift;
     my $inline = shift;
     my $items = shift;
     my $html = '';
     $html .= $inline->parse( $_->{line} ) . "\n" for @$items;
     return "<pre>\n$html</pre>\n";
 
 }
 1;
 
=head1 FUNCTION

=head2 trigger

for $class->trigger_check. If your plugin has start tag and end tag then you should set it , 
otherwise the other plugin does not know your plugin so , they may be mess up your block.

=over 4

=item start

regexp for start tag

=item end

regexp for end tag

=item escape

set 1 if your plugin escape Wiki parser in your block.

=back

=head2 check

implement validation

=head2 get

implement Wiki to HTML.

=head2 mobile

if you did not use it , then $class->get() return.

=head2 trigger_check

use checking the other plugin status.

=head2 kill_child

kill child block

=head2 get_child

get child block

=head2 push_children

push new child

=head2 opts

get opts

=head1 AUTHOR

polocky

=cut
