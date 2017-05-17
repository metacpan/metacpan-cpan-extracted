# fastQ_brew ver 1.0.2  
#### Damien O'Halloran, The George Washington University, 2017  
#### Filter FASTQ reads  

[![DOI](https://zenodo.org/badge/79366803.svg)](https://zenodo.org/badge/latestdoi/79366803)
[![GitHub license](https://img.shields.io/badge/license-GPL_2.0-orange.svg)](https://raw.githubusercontent.com/dohalloran/fastQ_brew/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/dohalloran/fastQ_brew.svg)](https://github.com/dohalloran/fastQ_brew/issues)

![fastQ_brew LOGO](https://cloud.githubusercontent.com/assets/8477977/22077145/f29a177e-dd80-11e6-86a6-a211e8e1e103.jpg)

## Installation
1. Download and extract the fastQ_brew.zip file  
`tar -xzvf fatsQ_brew.zip`  
2. The extracted dir will be called fastQ_brew  
  `cd fastQ_brew`   
  `perl Makefile.PL`  
  `make`  
  `make test`  
  `make install`  

## Usage 
### Run as follows:  
 ```perl   
  use fastQ_brew;
  use List::Util qw(min max sum);
  use fastQ_brew_Utilities;
  use Cwd;
  
  my $lib       = "sanger";
  my $file_path = cwd();
  my $in_file   = "sample_sanger.fastq";

  my $tmp = fastQ_brew->new();

  $tmp->load_fastQ_brew(
                    library_type  => $lib || "illumina",
                    file_path     => $file_path,
                    in_file       => $in_file,
                    summary       => "Y",
                    qual_filter   => 30,
                    length_filter => 25
  );

  $tmp->run_fastQ_brew();
```

## Filtering Options 
 ```perl   
#filter by read quality
        qual_filter   => 30
#filter by read length       
        length_filter => 25
#remove x bases from left 
        left_trim     => 5
#remove x bases from right
        right_trim    => 3
#remove specified adapter from left
        adapter_left  => "GTACGTGTGGTGGGGAT"
#remove sequences from left end that match specified 
#adapter but have x number of mismatches
        mismatches_l  => 1
#remove specified adapter from right
        adapter_right  => "GTACGTGTGGTGGGGAT"
#remove sequences from right end that match specified 
#adapter but have x number of mismatches
        mismatches_r  => 2
#remove duplicate reads
        de_duplex     => "Y"
```

## File Conversions
 ```perl   
#convert FASTQ file to FASTA format file
        fasta_convert => "Y"
#convert the DNA to RNA 
        dna_rna       => "Y"
#reverse complement the FASTQ reads 
        rev_comp      => "Y"
```

## Odds and Ends
 ```perl   
#return summary statistics on unfiltered and filtered data 
        summary       => "Y"
#remove reads that contain non designated bases e.g. N 
        remove_n      => "Y"
#remove temporary files generated during the run
        cleanup       => "Y"
```
## Contributing
All contributions are welcome.

## Support
If you have any problem or suggestion please open an issue [here](https://github.com/dohalloran/fastQ_brew/issues).

## License 
GNU GENERAL PUBLIC LICENSE





