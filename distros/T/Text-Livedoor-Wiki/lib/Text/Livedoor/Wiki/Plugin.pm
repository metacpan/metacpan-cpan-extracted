package Text::Livedoor::Wiki::Plugin;

use warnings;
use strict;
use Module::Pluggable::Object;

sub inline_plugins {
    my $self = shift;
    my $opts = shift;
    $self->_load_plugins( 'Inline' , $opts );
}
sub function_plugins {
    my $self = shift;
    my $opts = shift;
    $self->_load_plugins( 'Function' , $opts );
}
sub block_plugins {
    my $self = shift;
    my $opts = shift;
    $self->_load_plugins( 'Block' , $opts );
}

#{{{ private 
sub _load_plugins {
    my $self = shift;
    my $type = shift;
    my $opts = shift;
    my @search_path = ( 'Text::Livedoor::Wiki::Plugin::' . $type ); 
    # XXX
    my @except      = ( 'Text::Livedoor::Wiki::Plugin::Block::ListBase' );

    if( $opts->{search_path} ) {
        push @search_path , @{$opts->{search_path}};
    }

    if( $opts->{except} ) {
        push @except , @{$opts->{except}};
    }

    my $finder  
        = Module::Pluggable::Object->new(  search_path => \@search_path , except => \@except );
    my @plugins = $finder->plugins;

    if( $opts->{addition} ) {
            push @plugins , @{ $opts->{addition} } ;
    }

    return \@plugins;
}
#}}}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin - Getting Plugin List

=head1 SYNOPSIS

 my $block_plugins   = Text::Livedoor::Wiki::Plugin->block_plugins;
 my $inline_plugins  = Text::Livedoor::Wiki::Plugin->inline_plugins;
 my $function_plugins= Text::Livedoor::Wiki::Plugin->function_plugins;

 my $custom_block_plugins 
    = Text::Livedoor::Wiki::Plugin->block_plugins({ 
        except => ['My::Plugin::Hoge'], search_path => [ 'My::Plugin' ] , addition => [ 'My::Plugin::Hage' ] 
      })
    ;

=head1 DESCRIPTION

this module only return plugin list .

=head1 FUNCTIONS

=head2 block_plugins

return block plugin list

=head2 inline_plugins

return inline plugin list

=head2 function_plugins

return inline function list

=head1 ARGS

=head2 search_path

SEE L<Module::Pluggable::Object> search_path option.

=head2 except 

SEE L<Module::Pluggable::Object> except option.

=head2 addition

set list of plugin you want to set

=head1 SEE ALSO

L<Module::Pluggable::Object>

=head1 AUTHOR

polocky

=cut
