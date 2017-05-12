package XML::Toolkit::Cmd::ClassTemplate;
{
  $XML::Toolkit::Cmd::ClassTemplate::VERSION = '0.15';
}
use Moose::Role;

has template => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_template {
    return <<'END_TEMPLATE';
package [% meta.name %];
use Moose;
use namespace::autoclean;
use XML::Toolkit;

[% FOREACH attr_name IN meta.get_attribute_list.sort -%]
[% attr = meta.get_attribute(attr_name) -%]
has '[% attr_name %]' => (
     isa         => '[% attr.type_constraint.name %]',
     is          => '[% IF attr.has_accessor %]rw[% ELSE %]ro[%END%]',
 [%- IF attr.type_constraint.is_subtype_of("ArrayRef") %]
     init_arg    => '[% attr_name.remove("_collection") %]s',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_[% attr_name.remove("_collection") %] => ['push'] },
[%- ELSE %]
   
     traits      => [ 'XML'],
[% END -%]
     description => {
[% FOREACH name IN attr.description.keys -%]
        [% name %] => "[% attr.description.$name %]",
[% END -%]
        sort_order => [% loop.index() %],
     },
);
[% END -%]
1;

END_TEMPLATE

}

1;
__END__
