use Test2::Bundle::Extended -target => 'Trace::Mask';
use Test2::Tools::Spec;

ref_is($CLASS->masks, \%Trace::Mask::MASKS, "Got the reference");

done_testing;
