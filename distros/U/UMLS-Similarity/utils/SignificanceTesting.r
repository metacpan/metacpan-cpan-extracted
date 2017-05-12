##########################################################################
# R program to perform statistical analysis of two files from the umls-
# similarity.pl program 
##########################################################################
#
# This program does the following : 
#  Takes in a file from sim2r.pl and calculates the
#  the pearson, spearman and kendall correlations between 
#  the gold standard and the various measures
##########################################################################
# This is how I run the program:
#     
#     R --slave --args filename <SignificanceTesting.r 
#
##########################################################################

#  get the files from the command line
n1 <- commandArgs()
n <- n1[length(n1)]
tmp<-strsplit(n,",")
file1 <- tmp[[1]][1]; 

data <- read.table(file1,header=TRUE,sep=",");

headers <- names(data);

t <- c("measure          ", "pearsons", "spearman", "kendall");

print(t, quote=F);

for (i in 3:length(headers)) {

    p <- cor(data$gold,data[i],method="pearson"); 
    s <- cor(data$gold,data[i],method="spearman");
    k <- cor(data$gold,data[i],method="kendall"); 
    a <- c(headers[i], p, s, k);
    print (a, quote=F); 
   
}
