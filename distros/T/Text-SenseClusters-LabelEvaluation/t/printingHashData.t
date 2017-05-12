#http://search.cpan.org/dist/Test-Simple/lib/Test/Tutorial.pod
use Test::More tests => 1;

# Testing whether the package is present in the package.
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::PrintingHashData}


# Including the LabelEvaluation Module.
use Text::SenseClusters::LabelEvaluation::PrintingHashData;

%labelClusterHash = (
'cluster0' =>  {
                   'Descriptive' 	=> 'George Bush, Al Gore, White House, Cox News, BRITAIN London, Prime Minister, New York',
                   'Discriminating' => 'George Bush, Cox News, BRITAIN London'
               },
'cluster1' =>  {
                   'Descriptive'    => 'Al Gore, White House, more than, George W, York Times, New York, Prime Minister',
                   'Discriminating'  => 'more than, York Times, George W'
               }
);


Text::SenseClusters::LabelEvaluation::PrintingHashData::prinHashOfHash(
			\%labelClusterHash);	



