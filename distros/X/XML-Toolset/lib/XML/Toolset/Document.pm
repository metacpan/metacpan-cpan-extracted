package XML::Toolset::Document;

use strict;
use vars qw($VERSION);

$VERSION = sprintf"%d.%03d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;

use XML::Toolset;

sub new {
    &App::sub_entry if ($App::trace);
    my $this = shift;
    my $class = ref($this) || $this;
    my ($lone_arg);
    $lone_arg = shift if ($#_ > -1 && $#_ % 2 == 0);
    my $self = { @_ };
    if ($lone_arg) {
        if (ref($lone_arg)) {
            $self->{dom} = $lone_arg if (!$self->{dom});
        }
        else {
            $self->{xml} = $lone_arg if (!$self->{xml});
        }
    }
    die "an XML document must be initialized with an xml_toolset" if (!$self->{xml_toolset});
    if (!$self->{dom} && !$self->{xml} && $self->{root_element}) {
        $self->{dom} = $self->{xml_toolset}->new_dom($self->{root_element}, $self->{xmlns});
    }
    die "an XML document must be initialized with either a DOM or the XML" if (!$self->{dom} && !$self->{xml});
    bless $self, $class;
    &App::sub_exit($self) if ($App::trace);
    return($self);
}

sub dom {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    my $dom = $self->{dom};
    if (!$dom) {
        my $xml_toolset = $self->{xml_toolset};
        $dom = $xml_toolset->parse($self->{xml});
        $self->{dom} = $dom;
    }
    &App::sub_exit($dom) if ($App::trace);
    return($dom);
}

sub xml {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    my $xml = $self->{xml};
    if (!$xml) {
        my $xml_toolset = $self->{xml_toolset};
        $xml = $xml_toolset->to_string($self);
        $self->{xml} = $xml;
    }
    &App::sub_exit($xml) if ($App::trace);
    return($xml);
}

sub to_string {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    my $xml = $self->xml();
    &App::sub_exit($xml) if ($App::trace);
    return($xml);
}

sub get_root_tag {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    my $xml_toolset = $self->{xml_toolset};
    my $root_tag = $xml_toolset->get_root_tag($self->xml());
    &App::sub_exit($root_tag) if ($App::trace);
    return($root_tag);
}

sub get_first_tag {
    &App::sub_entry if ($App::trace);
    my ($self, $xpath) = @_;
    my $xml_toolset = $self->{xml_toolset};
    my $first_tag = $xml_toolset->get_first_tag($self->dom(), $xpath);
    &App::sub_exit($first_tag) if ($App::trace);
    return($first_tag);
}

sub validate {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;
    my $xml_toolset = $self->{xml_toolset};
    my $is_valid = $xml_toolset->validate_document($self->xml(), $options);
    &App::sub_exit($is_valid) if ($App::trace);
    return($is_valid);
}

sub get_value {
    &App::sub_entry if ($App::trace);
    my ($self, $xpath, $value) = @_;
    my $xml_toolset = $self->{xml_toolset};
    my $result = $xml_toolset->get_value($self->dom(), $xpath);
    &App::sub_exit($result) if ($App::trace);
    return($result);
}

sub set_value {
    &App::sub_entry if ($App::trace);
    my ($self, $xpath, $value) = @_;
    my $xml_toolset = $self->{xml_toolset};
    $xml_toolset->set_value($self->dom(), $xpath, $value);
    delete $self->{xml};
    &App::sub_exit() if ($App::trace);
}

sub transform {
    &App::sub_entry if ($App::trace);
    my ($self, $transform_name) = @_;
    my $xml_toolset = $self->{xml_toolset};
    $xml_toolset->transform($self->dom(), $transform_name);
    delete $self->{xml};
    &App::sub_exit() if ($App::trace);
}

1;

=head1 NAME

XML::Toolset::Document - An object which represents an XML document which knows about an XML::Toolset implementation which can perform operations on it.

=head1 SYNOPSIS

  use XML::Toolset::Document;
  my $xml = <<EOF;
  <hello world="!">
    How are you?
    <how>
      <ya doing="?" />
    </how>
  </hello>
  EOF
  my $doc = XML::Toolset::Document->new($xml);
  
  my $final_xml = $doc->to_string();

=head1 DESCRIPTION

An XML::Toolset::Document object represents an XML document which knows about an
XML::Toolset implementation which can perform operations on it.

Sorry. There's no more documentation yet except the code.

=head1 AUTHOR

Stephen Adkins <spadkins@gmail.com>

=head1 COPYRIGHT

(c) 2007 Stephen Adkins, for the purpose of making it Free.
This is Free Software.  It is licensed under the same terms as Perl itself.

=cut
