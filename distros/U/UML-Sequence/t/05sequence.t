use strict;
use warnings;

use Test::More tests => 2;

use UML::Sequence::SimpleSeq;
BEGIN { use_ok('UML::Sequence'); }

my $outline     = UML::Sequence::SimpleSeq->grab_outline_text('t/washcar');
my $methods     = UML::Sequence::SimpleSeq->grab_methods($outline);

my $tree = UML::Sequence
    ->new($methods, $outline, \&UML::Sequence::SimpleSeq::parse_signature,
         \&UML::Sequence::SimpleSeq::grab_methods);

my @xml_out = split /\n/, $tree->build_xml_sequence('Washing the Car');

chomp(my @correct_xml = <DATA>);

is_deeply(\@xml_out, \@correct_xml, "xml output");

__DATA__
<?xml version='1.0' ?>
<sequence title='Washing the Car'>
<class_list>
  <class name='At Home' born='0' extends-to='12'>
    <activation_list>
      <activation born='0' extends-to='12' offset='0' />
    </activation_list>
  </class>
  <class name='Garage' born='1' extends-to='12'>
    <activation_list>
      <activation born='1' extends-to='1' offset='0' />
      <activation born='5' extends-to='5' offset='0' />
      <activation born='6' extends-to='6' offset='0' />
      <activation born='10' extends-to='10' offset='0' />
      <activation born='11' extends-to='11' offset='0' />
      <activation born='12' extends-to='12' offset='0' />
    </activation_list>
  </class>
  <class name='Kitchen' born='2' extends-to='4'>
    <activation_list>
      <activation born='2' extends-to='4' offset='0' />
      <activation born='3' extends-to='3' offset='1' />
      <activation born='4' extends-to='4' offset='1' />
    </activation_list>
  </class>
  <class name='Driveway' born='7' extends-to='9'>
    <activation_list>
      <activation born='7' extends-to='7' offset='0' />
      <activation born='8' extends-to='8' offset='0' />
      <activation born='9' extends-to='9' offset='0' />
    </activation_list>
  </class>
</class_list>

<arrow_list>
  <arrow from='At Home' to='Garage' type='call' label='retrieve bucket'
         from-offset='0' to-offset='0' />
  <arrow from='At Home' to='Kitchen' type='call' label='prepare bucket'
         from-offset='0' to-offset='0' />
  <arrow from='Kitchen' to='Kitchen' type='call' label='pour soap in bucket'
         from-offset='0' to-offset='1' />
  <arrow from='Kitchen' to='Kitchen' type='call' label='fill bucket'
         from-offset='0' to-offset='1' />
  <arrow from='At Home' to='Garage' type='call' label='get sponge'
         from-offset='0' to-offset='0' />
  <arrow from='At Home' to='Garage' type='call' label='open door'
         from-offset='0' to-offset='0' />
  <arrow from='At Home' to='Driveway' type='call' label='apply soapy water'
         from-offset='0' to-offset='0' />
  <arrow from='At Home' to='Driveway' type='call' label='rinse'
         from-offset='0' to-offset='0' />
  <arrow from='At Home' to='Driveway' type='call' label='empty bucket'
         from-offset='0' to-offset='0' />
  <arrow from='At Home' to='Garage' type='call' label='close door'
         from-offset='0' to-offset='0' />
  <arrow from='At Home' to='Garage' type='call' label='replace sponge'
         from-offset='0' to-offset='0' />
  <arrow from='At Home' to='Garage' type='call' label='replace bucket'
         from-offset='0' to-offset='0' />
</arrow_list>
</sequence>
