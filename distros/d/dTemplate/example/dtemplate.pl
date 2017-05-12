#!/usr/bin/perl
use lib '..';
use dTemplate;

### definition of the standard templates

my @TEMPLATE_LIST=qw(page table_row table_cell);
my $templates={};
foreach my $template (@TEMPLATE_LIST) {
  $templates->{$template} = 
    define dTemplate("templates/$template.htm");
}

### definition of the styled templates (styles = languages)

my @STYLES=qw(eng hun);
my @STYLED_TEMPLATE_LIST=qw(table_title);

my $style_select={ lang => 'hun' }; 

foreach my $template (@STYLED_TEMPLATE_LIST) {
  my @array=();
  foreach my $style (@STYLES) {
    push @array, $style => 
      define dTemplate("text/$style/$template.txt");
  }
  $templates->{$template} = 
    choose dTemplate $style_select, @array;
}

### setting up input data

my $table_to_print=[
  [ "Buwam",   3, 6, 9 ],
  [ "Greg",    8, 4, 2 ],
  [ "You're",  8, 3, 4 ],
  [ "HTML chars: <>", 3],
];

### setting up the global parse hash with parse parameters;

$dTemplate::parse{PAGENO}=7;

### settings up a hash with personal data.

my $person_hash={
  name => { first => "Greg" },
  zip  => "9971",
};

### this hash is simply added to other parse parameters

my $parse_hash={
  unknown => { data => 157 },
};

### the main page parse routine

print $templates->{page}->parse(
  TABLE_TITLE =>             # name => value pair
    $templates->{table_title}->parse(),
  TABLE => sub {             # name => value pair. value is a sub
    my $ret="";
    foreach my $row (@$table_to_print) {
      $ret .= $templates->{table_row}->parse(
        BODY => sub {
          my $ret="";
          foreach my $cell (@$row) {
            $ret .= $templates->{table_cell}->parse(
              TEXT => $cell,
            )
          }
          return $ret;
        }
      )
    }
    return $ret;
  },
  "person" => $person_hash,  # name => value pair. value is a href
  $parse_hash,               # only a hash with parse parameters
);
