use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

my @modules = grep { !/Treex::PML::Backend::(CSTS|TEIXML|NTRED|TrXML|PML|FS|Storable)/ } all_modules();

plan tests => scalar(@modules);
my %opts = (
  'Treex::PML' => {
    also_private =>
      [ qr/^(Cut | DeleteLeaf | DeleteTree | FirstSon | Index | LBrother | Next |
 	   Parent | Paste | PasteAfter | PasteBefore | Prev | RBrother |
 	   ResourcePath | Root | SetFirstSon | SetLBrother | SetParent |
     	   SetRBrother)/x ]
   },
  'Treex::PML::Schema' => {
    also_private => [ qr/^(get_root_type_obj | get_type_by_name_obj | serialize_exclude_keys | serialize_get_children | init)$/x ],
  },
  'Treex::PML::FSFormat' => {
    also_private => [ qr/^(findSpecialDef | set_special)$/x ]
   },
  'Treex::PML::StandardFactory' => {
    trustme => [ qr/^(createAlt | createContainer | createDocument | createDocumentFromFile
		    | createFSFormat | createList | createNode | createPMLInstance
		    | createPMLSchema | createSeq | createStructure | createTypedNode)$/x ],
  },
  'Treex::PML::Document' => {
    also_private => [ qr/^(newFSFile)$/x ],
   },
  'Treex::PML::Instance' => {
    also_private => [ qr/^(read_reffiles | readas_dom | readas_pml | schema )$/x ],
   },
  'Treex::PML::IO' => {
    also_private => [ qr/^( DOES )$/x ],
  },
  'Treex::PML::Node' => {
    also_private => [ qr/^( flat_attr | set_firstson |  set_lbrother |  set_member |  set_parent | set_rbrother )$/x ],
  },
  'Treex::PML::Schema::XMLNode' => {
    also_private => [ qr/^( serialize(?:_.*)? )$/x ],
  },
  'Treex::PML::Schema::Struct' => {
    also_private => [ qr/^( init | validate_object )$/x ],
  },
  'Treex::PML::Schema::Container' => {
    also_private => [ qr/^( init | validate_object | serialize(?:_.*)? )$/x ],
  },
  'Treex::PML::Schema::Seq' => {
    also_private => [ qr/^( init | validate_object )$/x ],
  },
  'Treex::PML::Schema::List' => {
    also_private => [ qr/^( init | validate_object )$/x ],
  },
  'Treex::PML::Schema::Alt' => {
    also_private => [ qr/^( init | validate_object )$/x ],
  },
  'Treex::PML::Schema::Root' => {
    also_private => [ qr/^( is_atomic| init | validate_object )$/x ],
  },
  'Treex::PML::Schema::Attribute' => {
    also_private => [ qr/^( is_atomic | validate_object )$/x ],
  },
  'Treex::PML::Schema::Member' => {
    also_private => [ qr/^( is_atomic | validate_object )$/x ],
  },
  'Treex::PML::Schema::Element' => {
    also_private => [ qr/^( is_atomic | validate_object )$/x ],
  },
  'Treex::PML::Schema::Type' => {
    also_private => [ qr/^( is_atomic | validate_object )$/x ],
  },
  'Treex::PML::Schema::CDATA' => {
    also_private => [ qr/^( init )$/x ],
  },
  'Treex::PML::Schema::Choice' => {
    also_private => [ qr/^( init | post_process | serialize_.* )$/x ],
  },
  'Treex::PML::Schema::Constant' => {
    also_private => [ qr/^( init | validate_object | serialize_.* )$/x ],
  },
  'Treex::PML::Schema::Derive' => {
    also_private => [ qr/^( init )$/x ],
  },
  'Treex::PML::Schema::Import' => {
    also_private => [ qr/^( schema )$/x ],
  },
  'Treex::PML::Schema::Decl' => {
    also_private => [ qr/^( type_decl | new )$/x ],
  },
  'Treex::PML::Schema::Reader' => {
    also_private => [ qr/^( .* )$/x ],
  },
  'Treex::PML::Instance::Reader' => {
    also_private => [ qr/^( .* )$/x ],
  },
  'Treex::PML::Instance::Writer' => {
    also_private => [ qr/^( .* )$/x ],
  },
    
);

for my $module (@modules) {
  pod_coverage_ok($module,$opts{$module}||{}, "POD coverage for $module excluding deprecated functions" );
}

