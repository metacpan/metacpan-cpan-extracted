# `fastQ_brew v.1.0.3`

[![DOI](https://zenodo.org/badge/79366803.svg)](https://zenodo.org/badge/latestdoi/79366803)
[![GitHub license](https://img.shields.io/badge/license-GPL_2.0-orange.svg)](https://raw.githubusercontent.com/dohalloran/fastQ_brew/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/dohalloran/fastQ_brew.svg)](https://github.com/dohalloran/fastQ_brew/issues)

- [x] `Filters FASTQ reads` 
- [x] `Only uses Perl core` 
- [x] `Platform independent`
- [x] `Fast and easy to use`
- [x] `Removes duplicate reads`
- [x] `Trims reads by length or quality`
- [x] `Returns summary statistics`
- [x] `Removes specific adapters`
- [x] `Implements a fast mismatch algorithm for adapter removal`
- [x] `Performs various file conversions` 

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
### Type the following to run:  
 ```perl 
  #brew_driver.pl is a driver script within the lib folder 
  
  perl brew_driver.pl -i <input_file> -path=./ -qf=30 -smry -dup -no_n -clean <command options> 
  
  #see below for command flags
```

## Command Line Arguments
### Filtering Options
 ```python   
#filter by read quality
        -qf=30
#filter by read length       
        -lf=25
#remove x bases from left 
        -trim_l=5
#remove x bases from right
        -trim_r=3
#remove specified adapter from left
        -adpt_l="GTACGTGTGGTGGGGAT"
#remove sequences from left end that match specified 
#adapter but have x number of mismatches
        -mis_l=1
#remove specified adapter from right
        -adpt_r="GTACGTGTGGTGGGGAT"
#remove sequences from right end that match specified 
#adapter but have x number of mismatches
        -mis_r=2
#remove duplicate reads 
        -dup
```

### File Conversions
 ```python   
#convert FASTQ file to FASTA format file
        -fasta
#convert the DNA to RNA 
        -rna
#reverse complement the FASTQ reads 
        -rev_comp
```

### Odds and Ends
 ```python   
#input FASTQ file (required) 
        -i=reads.fastq
#path to FASTQ file (required) 
        -path=./ # if current working dir; note: ".\" if using Windows
#library type i.e. sanger (default) or illumina 
        -lib=sanger
#return summary statistics on unfiltered and filtered data 
        -smry     
#remove reads that contain non designated bases e.g. N 
        -no_n
#remove temporary files generated during the run
        -clean  
#print flag options to STDOUT
        -help  
```
## Contributing
All contributions are welcome.

## Support
If you have any problem or suggestion please open an issue [here](https://github.com/dohalloran/fastQ_brew/issues).

## License 
GNU GENERAL PUBLIC LICENSE





