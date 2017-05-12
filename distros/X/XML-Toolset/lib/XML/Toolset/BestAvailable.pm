# Factory class providing a common interface to different XML validators

package XML::Toolset::BestAvailable;

use strict;
use XML::Toolset;
use App;
use vars qw($VERSION @ISA);

$VERSION = sprintf"%d.%03d", q$Revision: 1.25 $ =~ /: (\d+)\.(\d+)/;
@ISA = ("XML::Toolset");

# Xerces is preferred over MSXML as we've found in practice that MSXML4's schema validation occasionally
# lets through invalid documents which Xerces catches.
# At the time of writing, LibXML didn't have schema validation support.
my $DEFAULT_PRIORITISED_LIST = [ qw( Xerces MSXML LibXML XMLDOM ) ];

sub _init {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;
    
    if (!$options->{bestavailable_initialized}) {   # protect against infinite recursion
        my $list = $options->{prioritized_list} || $DEFAULT_PRIORITISED_LIST;
        my $type = $self->_best_available($list) or die sprintf("None of the listed backends (%s) are available\n",join(", ",@$list));
        my $class = "XML::Toolset::" . $type;

        my %options = ( %$options );    # make a copy
        $options{bestavailable_initialized} = 1;
        bless $self, $class;
        $self->_init(\%options);  # in case the newly blessed class want to do initialization
    }

    &App::sub_exit($self) if ($App::trace);
    return $self;
}

sub _best_available {
    &App::sub_entry if ($App::trace);
    my ($self, $list) = @_;
    $list = $self->{prioritized_list} if (!$list);
    $list = $DEFAULT_PRIORITISED_LIST if (!$list);
    my $backend_found = "";
    foreach my $backend (@{$list}) {
        eval "use XML::Toolset::$backend";
        if (!$@) {
            $backend_found = $backend;
            last;
        }
    }
    &App::sub_exit($backend_found) if ($App::trace);
    return($backend_found);
}

1;

__END__

=head1 NAME

XML::Toolset::BestAvailable - find the best available XML toolset and rebless self as that class

=head1 SYNOPSIS

  my $context = App->context();
  my $xml_toolset = $context->service("XMLToolset", "default", class => "XML::Toolset::BestAvailable");
  ...
  
=head1 DESCRIPTION

Finds the best available XML toolset and rebless self as that class.

=head1 AUTHORS

Stephen Adkins <spadkins@gmail.com>

Original Code (XML::Validate): Nathan Carr, Colin Robertson (see XML::Validate) E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) 2007 Stephen Adkins. XML-Toolset is derived from XML-Validate under the terms of the GNU GPL.
(c) 2005 BBC. XML-Toolset is derived from XML-Validate. XML-Validate is free software; you can redistribute it and/or modify it under the GNU GPL.
See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
