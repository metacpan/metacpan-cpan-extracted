#
# $Id: Plugin.pm,v 1.3 2006/11/12 09:43:38 6-o Exp $
#
package Text::HikiDoc::Plugin;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $obj = shift;
    my $plugin_type = shift;

    my $self = bless {
                      %$obj,
                      PLUGIN_TYPE => $plugin_type,
                     } , $class;

    return $self;
}

sub to_html {
    my $self = shift;
    my $str = shift;

    return $str;
}
#sub DESTROY {
#    my $self = shift;
#    print STDERR $self,"\t",$self->{PLUGIN_TYPE},"\n";
#}


1;
__END__

=head1 NAME

Text::HikiDoc::Plugin - Base class of plug-in module for Text::HikiDoc .

=head1 SYNOPSIS

  package Text::HikiDoc::Plugin::your-plugin

  use base 'Text::HikiDoc::Plugin';

  sub to_html {
      my $self = shift;
      my @args = @_;
      #
      # plug-in logic
      #
      return $string;
  }

=head1 DESCRIPTION

  Text::HikiDoc::Plugin can add a new format to Text::HikiDoc .

=head1 Methods

=head2 to_html(ARGS)

=over 4

When Text::HikiDoc encounters the description of {{your-plugin}}, Text::HikiDoc::Plugin::your-plugin::to_html() is executed. And {{your-plugin} is replaced with the returned character string.

=over 4

=item ARGS

There are some methods for you to pass the plug-in the argument. The following result the same all. 

  {{br '2'}}

    or

  {{br(2)}}

    or

  {{br
  '2'
  }}

=back

=back

=head1 SEE ALSO

=over 4

=item Text::HikiDoc

=back

=cut
