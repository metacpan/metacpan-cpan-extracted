# $Id: DBI.pm,v 1.8 2003/08/18 21:15:27 matt Exp $

package XML::Generator::DBI;
use strict;

use MIME::Base64;
use XML::SAX::Base;

use vars qw($VERSION @ISA);

$VERSION = '1.00';
@ISA = ('XML::SAX::Base');

my %defaults = (
        RootElement => "database",
        QueryElement => "select",
        RowElement => "row",
        ColumnsElement => "columns",
        ColumnElement => "column",
    );

sub new {
    my $class = shift;
    my $s = $class->SUPER::new(@_);
    my $self = bless { %defaults, %$s }, ref($s);
    
    return $self;
}

sub execute {
    my $self = shift;
    my ($query, $bind, %p) = @_;
    
    my %params = (%defaults, %$self, %p);
    
    # This might confuse people, but the methods are actually
    # called on this proxy object, which is a mirror of $self
    # with the new params inserted.
    my $proxy = bless \%params, ref($self);
    
    # turn on throwing exceptions
    local $proxy->{dbh}->{RaiseError} = 1;
    
    $proxy->pre_execute();
    $proxy->execute_one($query, $bind);
    $proxy->post_execute();
    
}

sub pre_execute {
    my $proxy = shift;

    # TODO - figure out how to call set_document_locator() here
        
    $proxy->SUPER::start_document({});
    $proxy->SUPER::start_prefix_mapping({ Prefix => 'dbi', NamespaceURI => 'http://axkit.org/NS/xml-generator-dbi' });
    $proxy->send_start($proxy->{RootElement});
}

sub post_execute {
    my $proxy = shift;
    
    $proxy->send_end($proxy->{RootElement});
    $proxy->SUPER::end_prefix_mapping({ Prefix => 'dbi', NamespaceURI => 'http://axkit.org/NS/xml-generator-dbi' });
    $proxy->SUPER::end_document({});
}

sub execute_one {
    my ($self, $query, $bind, %p) = @_;

    my %params = (%defaults, %$self, %p);
    
    # create yet another proxy object
    my $proxy = bless \%params, ref($self);
    
    my @bind;
    if (defined($bind)) {
        @bind = ref($bind) ? @{$bind} : ($bind);
    }
    
    my $sth;
    if (ref($query)) {
        # assume its a statement handle
        $sth = $query;
        $query = "Unknown - executing statement handle";
    }
    else {
        $sth = $proxy->{dbh}->prepare($query);
    }
    
    $sth->execute(@bind);
    
    #open QueryElement if defined
    if($proxy->{QueryElement}){
        $proxy->send_start($proxy->{QueryElement}, $proxy->{ShowSQL} ? (query => $query) : ());
    }
    
    my $names = $proxy->{LowerCase} ? $sth->{NAME_lc} : $sth->{NAME};
    
    #get index of group field
    my $group_by_ind;
    if(defined $proxy->{GroupBy}){
        $group_by_ind = 0;
        foreach my $name (@$names){
            last if $name eq $proxy->{GroupBy};
            $group_by_ind++;
        }
    }

    # output columns if necessary
    $proxy->add_column_info($sth, $names);
    
    my @row;
    $sth->bind_columns( 
            \( @row[ 0 .. $#{$names} ] )
        );
    
    my $group;
    
    while ($sth->fetch) {
        my @encoding;
        my $i = 0;
        foreach (@row) {
            if (defined($_) and /[\x00-\x08\x0A-\x0C\x0E-\x19]/) {
                # in foreach loops, $_ is an lvalue!
                $_ = MIME::Base64::encode_base64($_);
                $encoding[$i] = 'base64';
            }
            $i++;
        }
    
        if ($proxy->{AsAttributes}) {
            $proxy->send_attributes_row(\@row, $names, \@encoding, \$group, $group_by_ind);
        }
        else {
            $proxy->send_tags_row(\@row, $names, \@encoding, \$group, $group_by_ind);
        }
    }

    # close previous group element if any
    $proxy->send_end($proxy->{GroupElement}) if defined $proxy->{GroupElement};
    
    # close QueryElement if defined
    $proxy->send_end($proxy->{QueryElement}) if $proxy->{QueryElement};
}

sub send_tags_row {
    my $proxy = shift;
    my ($row, $names, $encoding, $group, $group_by_ind) = @_;
    
    $proxy->send_group($row, $group, $group_by_ind);
    
    $proxy->send_start($proxy->{RowElement}) if $proxy->{RowElement};
    
    my @stack;
    my @el_stack;
    
    # for each column...
    foreach my $i (0 .. $#{$names}) {
        # skip group element
        if (defined($proxy->{GroupBy}) and $i == $group_by_ind){
            next;
        }
        
        # get the element stack: address/street -> <address><street>
        if ($proxy->{ByColumnName}) {
            @el_stack = split(/\//, $names->[$i]);
            if(! defined $el_stack[0]){
                shift @el_stack;
            }
        }
        else {
            @el_stack = ($names->[$i]);
        }
        
        my $stack_len = $#stack;
        my $el_stack_len = $#el_stack;
        
        my $ind = 0;
        while ($el_stack[$ind] eq $stack[$ind] and
               $ind <= $stack_len and
               $ind <= $el_stack_len)
        {
            $ind ++;
        }
        
        if ($el_stack[$ind] eq $stack[$ind] and $el_stack_len == $stack_len) {
            # We're already at the end of the stack, so output the column
            $proxy->send_tag($names->[$i], $row->[$i],
                            $encoding->[$i] ? 
                                ('dbi:encoding' => $encoding->[$i])
                                :
                                ()
            ) if defined($row->[$i]);
        }
        else {
            # Otherwise we need to close all previous tags...
            foreach my $n ($ind .. $stack_len){
                $proxy->send_end(pop @stack);
            }
            
            # And open all the new ones...
            foreach my $n ($ind .. ($el_stack_len - 1) ){
                push @stack, $el_stack[$n];
                $proxy->send_start($el_stack[$n]);
            }
            
            # Then send the column
            $proxy->send_tag($el_stack[$el_stack_len], $row->[$i],
                            $encoding->[$i] ? 
                                ('dbi:encoding' => $encoding->[$i])
                                :
                                ()
            ) if defined($row->[$i]);
        }
    }
    
    $proxy->send_end(pop @stack) while(@stack);
    
    $proxy->send_end($proxy->{RowElement}) if $proxy->{RowElement};
}

sub send_group {
    my $proxy = shift;
    my ($row, $group, $group_by_ind) = @_;
    
    # maintain GroupBy before RowElement
    if (defined $proxy->{GroupBy}) {
        if ($$group ne $row->[$group_by_ind]) { # a new group
            my $group_element = $proxy->{GroupElement} || die "GroupElement not defined";
            
            # close previous group element if any
            $proxy->send_end($group_element) if (defined $$group);
            
            if ($proxy->{GroupAttribute}) {
                #send start and value as attribute
                $proxy->send_start($group_element, $proxy->{GroupAttribute} => $row->[$group_by_ind]);
            }
            elsif ($proxy->{GroupValueElement}) {
                #send start and value as element
                $proxy->send_start($group_element);
                $proxy->send_tag($proxy->{GroupValueElement},  $row->[$group_by_ind]);
            }
            else {
                die "You have to define either 'GroupAttribute' or 'GroupValueElement'";
            }
            $$group = $row->[$group_by_ind];
        }
    }
}

sub send_attributes_row {
    my $proxy = shift;
    my ($row, $names, $encoding, $group, $group_by_ind) = @_;

    my %attribs = map { $names->[$_] => $row->[$_] } # create hash
                  grep { defined $row->[$_] } # remove undef ones
                  grep { $names->[$_] ne $proxy->{GroupBy} } #remove group data
                  (0 .. $#{$names});
    
    # GroupElement
    $proxy->send_group($row, $group, $group_by_ind);

    my $enc_cols = join(',',
        map { $names->[$_] }
        grep { $encoding->[$_] }
        (0 .. $#{$names}));

    my $null_cols = join(',',
        map { $names->[$_] }
        grep { !defined $row->[$_] }
        (0 .. $#{$names}));
    
    $proxy->send_tag($proxy->{RowElement}, undef, %attribs,
        $null_cols ? ('dbi:null-columns' => $null_cols) : (),
        $enc_cols ? ('dbi:encoded-columns' => $enc_cols) : (),
    );
}

sub add_column_info {
    my $self = shift;
    my ($sth, $names) = @_;
    
    return unless $self->{ShowColumns};
    return unless $self->{dbh};
    
    my $types = $sth->{TYPE};
    my $precision = $sth->{PRECISION};
    my $scale = $sth->{SCALE};
    my $null = $sth->{NULLABLE};
    $self->send_start($self->{ColumnsElement});
    foreach my $i (0 .. $#{$names}) {
        my $type_info = $self->{dbh}->type_info($types->[$i]);
        if ($self->{AsAttributes}) {
            my %attribs;
            $attribs{name} = $names->[$i];
            $attribs{raw_type} = $types->[$i];
            $attribs{type} = $type_info->{TYPE_NAME} if $type_info->{TYPE_NAME};
            $attribs{size} = $type_info->{COLUMN_SIZE} if $type_info->{COLUMN_SIZE};
            $attribs{precision} = $precision->[$i] if defined($precision->[$i]);
            $attribs{scale} = $scale->[$i] if defined($scale->[$i]);
            $attribs{nullable} = (!$null->[$i] ? "NOT NULL" : ($null->[$i] == 1) ? "NULL" : "UNKNOWN") if defined($null->[$i]);
            
            $self->send_tag($self->{ColumnElement}, undef, %attribs);
        }
        else {
            $self->send_start($self->{ColumnElement});

            $self->send_tag(name => $names->[$i]);
            $self->send_tag(raw_type => $types->[$i]);
            $self->send_tag(type => $type_info->{TYPE_NAME}) if $type_info->{TYPE_NAME};
            $self->send_tag(size => $type_info->{COLUMN_SIZE}) if $type_info->{COLUMN_SIZE};
            $self->send_tag(precision => $precision->[$i]) if defined($precision->[$i]);
            $self->send_tag(scale => $scale->[$i]) if defined($scale->[$i]);
            $self->send_tag(nullable => (!$null->[$i] ? "NOT NULL" : ($null->[$i] == 1 ? "NULL" : "UNKNOWN"))) if defined($null->[$i]);

            $self->send_end($self->{ColumnElement});
        }
    }
    $self->send_end($self->{ColumnsElement});
}

# SAX utility functions

sub sax1tosax2_attrs {
    my $attrs = shift;
    my %new_attrs;
    foreach my $k (keys %$attrs) {
        if ($k =~ /^dbi:(.*)$/) {
            my $lname = $1;
            $new_attrs{"{http://axkit.org/NS/xml-generator-dbi}$lname"} = {
                Name => $k,
                LocalName => $lname,
                Prefix => 'dbi',
                NamespaceURI => 'http://axkit.org/NS/xml-generator-dbi',
                Value => $attrs->{$k},
            };
        }
        else {
            $new_attrs{"{}$k"} = {
                Name => $k,
                LocalName => $k,
                Prefix => '',
                NamespaceURI => '',
                Value => $attrs->{$k},
            };
        }
    }
    return \%new_attrs;
}

sub send_tag {
    my $self = shift;
    my ($name, $contents, %attributes) = @_;
    $self->SUPER::characters({ Data => (" " x $self->{cur_indent}) }) if $self->{Indent} && $self->{cur_indent};
    $self->SUPER::start_element({ Name => $name, Attributes => sax1tosax2_attrs(\%attributes) });
    $self->SUPER::characters({ Data => $contents });
    $self->SUPER::end_element({ Name => $name });
    $self->new_line if $self->{Indent};
}

sub send_start {
    my $self = shift;
    my ($name, %attributes) = @_;
    $self->SUPER::characters({ Data => (" " x $self->{cur_indent}) }) if $self->{Indent} && $self->{cur_indent};
    $self->SUPER::start_element({ Name => $name, Attributes => sax1tosax2_attrs(\%attributes) });
    $self->{cur_indent}++;
    $self->new_line if $self->{Indent};
}

sub send_end {
    my $self = shift;
    my ($name) = @_;
    $self->{cur_indent}--;
    $self->SUPER::characters({ Data => (" " x $self->{cur_indent}) }) if $self->{Indent} && $self->{cur_indent};
    $self->SUPER::end_element({ Name => $name });
    $self->new_line if $self->{Indent};
}

sub new_line {
    my $self = shift;
    $self->SUPER::characters({ Data => "\n" }) if $self->{cur_indent};
}

1;
__END__

=head1 NAME

XML::Generator::DBI - Generate SAX events from SQL queries

=head1 SYNOPSIS

  use XML::Generator::DBI;
  use XML::SAX::Writer;
  use DBI;
  my $dbh = DBI->connect("dbi:Pg:dbname=foo", "user", "pass");
  my $sth = $dbh->prepare("select * from mytable where mycol = ?");
  my $generator = XML::Generator::DBI->new(
                        Handler => XML::SAX::Writer->new(),
                        );
  $generator->execute($sth, $mycol_value);

=head1 DESCRIPTION

This module generates SAX events from SQL queries against a DBI connection.

The default XML structure created is as follows:

  <database>
   <select>
    <row>
     <column1>1</column1>
     <column2>fubar</column2>
    </row>
    <row>
     <column1>2</column1>
     <column2>intravert</column2>
    </row>
   </select>
  </database>

Alternatively, pass the option AsAttributes => 1 to either the
execute() method, or to the new() method, and your XML will look
like:

  <database>
    <select>
      <row column1="1" column2="fubar"/>
      <row column1="2" column2="intravert"/>
    </select>
  </database>

Note that with attributes, ordering of columns is likely to be lost,
but on the flip side, it may save you some bytes.

Nulls are handled by excluding either the attribute or the tag.

=head1 API

=head2 XML::Generator::DBI->new()

Create a new XML generator.

Parameters are passed as key/value pairs:

=over 4

=item Handler (required)

A SAX handler to recieve the events.

=item dbh (required)

A DBI handle on which to execute the queries. Must support the
prepare, execute, fetch model of execution, and also support
type_info if you wish to use the ShowColumns option (see below).

=item AsAttributes

The default is to output everything as elements. If you wish to
use attributes instead (perhaps to save some bytes), you can
specify the AsAttributes option with a true value.

=item RootElement

You can specify the root element name by passing the parameter
RootElement => "myelement". The default root element name is
"database".

=item QueryElement

You can specify the query element name by passing the parameter
QueryElement => "thequery". The default is "select".

=item RowElement

You can specify the row element name by passing the parameter
RowElement => "item". The default is "row".

=item Indent

By default this module does no indenting (which is different from
the previous version). If you want the XML beautified, pass the
Indent option with a true value.

=item ShowColumns

If you wish to add information about the columns to your output,
specify the ShowColumns option with a true value. This will then
show things like the name and data type of the column, whether the
column is NULLABLE, the precision and scale, and also the size of
the column. All of this information is from $dbh->type_info() (see
perldoc DBI), and may change as I'm not 100% happy with the output.

=item ByColumnName

It allows usage of column names (aliases) for element generation. 
Aliases can contain slashes in order to generate child elements.
It is limited by the length of aliases - depends on your DBMS

Example:

 $select = qq(
    SELECT  c.client as 'client_id',
            c.company_name as 'company_name',
            c.address_line as 'address/address_line',
            c.city as 'address/city',
            c.county as 'address/county',
            c.post_code as 'address/post_code',
            co.name as 'address/country',
            c.phone as 'phone',
            c.fax as 'fax',
            c.payment_term as 'payment_term',
            c.accounting_id as 'accounting_id'

    FROM    client c,
            country co

    WHERE   c.country = co.country
    AND     c.client = $client_id
            );

 $gen->execute( 
                     $select,
                     undef,
                     ByColumnName => 1,
                     RootElement => 'client_detail',
                     RowElement => 'client',
                     QueryElement => undef
                        );

 print $output;

 <?xml version="1.0" encoding="UTF-8"?>
 <client_detail>
   <client>
     <client_id>3</client_id>
     <company_name>SomeCompanyName</company_name>
     <address>
       <address_line>SomeAddress</address_line>
       <city>SomeCity</city>
       <county>SomeCounty</county>
       <post_code>SomePostCode</post_code>
       <country>SomeCountry</country>
     </address>
     <phone>22222</phone>
     <fax>11111</fax>
     <payment_term>14</payment_term>
     <accounting_id>351</accounting_id>
   </client>
 </client_detail>

=item GroupBy

By this parameter you can group rows based on changes in the value of
a particular column. It relys on ordering done by your SQL query.
This parameter requires two more parameters:

=over 4

=item GroupElement - the name of element holding all 'row' elements.

=item GroupAttribute

or

=item GroupValueElement

GroupAttribute - when the 'value' goes as attribute of GroupElement.
GroupAttribute is the name of this attribute.

GroupValueElement - when the 'value' goes in a separate element.
GroupValueElement is the name of the element holding 'value'.

=back

Note that in order to avoid unwanted nesting RowElement is undef.

Example:

 contractor_job time_record 
 -------------- ----------- 
              9          10 
              9          13 
              9          14 
             10           9 
             10          11 
             10          12 

 $select = qq(
    SELECT  time_record,
            contractor_job

    FROM    time_record

    ORDER BY contractor_job
            );

B<Using GroupAttribute:>

 $gen->execute(
                     $select, 
                     undef, 
                     ByColumnName => 1,
                     RootElement => 'client_detail',
                     RowElement => undef,
                     GroupBy => 'contractor_job',
                     GroupElement => 'group',
                     GroupAttribute => 'ID',
                     QueryElement => undef
                        );

 print $output;

 <?xml version="1.0" encoding="UTF-8"?>
 <client_detail>
   <group ID="9">
     <time_record>10</time_record>
     <time_record>13</time_record>
     <time_record>14</time_record>
   </group>
   <group ID="10">
     <time_record>9</time_record>
     <time_record>11</time_record>
     <time_record>12</time_record>
   </group>
 </client_detail>

B<Using GroupValueElement:>

 $gen->execute(
                     $select, 
                     undef, 
                     ByColumnName => 1,
                     RootElement => 'client_detail',
                     RowElement => undef,
                     GroupBy => 'contractor_job',
                     GroupElement => 'group',
                     GroupValueElement => 'ID',
                     QueryElement => undef
                        );

 print $output;

 <?xml version="1.0" encoding="UTF-8"?>
 <client_detail>
   <group>
     <ID>9</ID>
     <time_record>10</time_record>
     <time_record>13</time_record>
     <time_record>14</time_record>
   </group>
   <group>
     <ID>10</ID>
     <time_record>9</time_record>
     <time_record>11</time_record>
     <time_record>12</time_record>
   </group>
 </client_detail>

=back

=head2 $generator->execute($query, $bind, %params)

You execute a query and generate results with the execute method.

The first parameter is a string containing the query. The second is
a single or set of bind parameters. If you wish to make it more than
one bind parameter, it must be passed as an array reference:

    $generator->execute(
        "SELECT * FROM Users WHERE name = ?
         AND password = ?",
         [ $name, $password ],
         );

Following the bind parameters you may pass any options you wish to
use to override the above options to new(). Thus allowing you to
turn on and off certain options on a per-query basis.

=head2 $generator->execute_one($query, $bind, %params)

If you wish to execute multiple statements within one XML structure, you
can use the C<execute_one()> method, as follows:

  $generator->pre_execute();
  $generator->execute_one($query);
  $generator->execute_one($query);
  $generator->post_execute();

The pre and post calls are required.

=head1 Other Information

Binary data is encoded using Base64. If you are using AsElements,
the element containing binary data will have an attribute 
dbi:encoding="base64", where the DBI namespace is bound to the URL
C<http://axkit.org/NS/xml-generator-dbi>. We detect binary data as
anything containing characters outside of the XML UTF-8 allowed
character set.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 LICENSE

This is free software, you may use it and distribute it under the
same terms as Perl itself. Specifically this is the Artistic License,
or the GNU GPL Version 2.

=head1 SEE ALSO

PerlSAX, L<XML::Handler::YAWriter>.

=cut
