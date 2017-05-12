# 
# This code provides an example of recombination 
# of the p-values computed by the conditionnal logistic
# regression for trio data (Cordell et al, 2002, Am J Hum Genet)
# using Li's statistics (Li et al 1991. Stat. sinica).
#
# You need to install Clayton's package DGCgenetics :
# http://www-gene.cimr.cam.ac.uk/clayton/software/


library(DGCgenetics)
# number of markers and of number imputed files
nb_mark <- 5
nb_files <- 10

# Analysis of imputed files
p_VALS<-c()

for(m in 1:nb_mark)
{
  LRT<-c()
  for(i in 1:nb_files)
  {
    # creating name of imputed files created by mi-tdt
    NAME <- sprintf("trios.ped.%02d",i) 

    DATA <- read.table(NAME, header=FALSE)
    colnames(DATA)<-c("pedigree","id","id.father","id.mother","sex","affected")

    DATA2<-DATA[,1:6] 
    for(j in 5+2*c(1:nb_mark))
    {
      DATA2<-cbind(DATA2,genotype(a1=DATA[,j], a2=DATA[,(j+1)], sep="/"))
    }   
    colnames(DATA2)<-c("pedigree","id","id.father","id.mother","sex","affected")

    # creates pseudo controls for the conditionnal logistic regression
    pscc.fmly <- pseudocc(DATA2[,(6+m)], data=DATA2)
    # performs conditionnal logistic regression
    gcontrasts(pscc.fmly[,7])<-"genotype"
    RES<-clogit(pscc.fmly$cc ~ pscc.fmly[,7] + strata(pscc.fmly$set))

    # store the LRT statistic for marker #m in file #i
    LRT<-c(LRT, summary(RES)$logtest['test'])
  }  

  # Li's recombination
  dof<-2
  VAR<-var(LRT)
  sLRT<-mean(LRT)
  r<-(1+(1/10))*((1/(10-1))*VAR)
  D=((sLRT/dof)-(((10+1)/(10-1))*r))/(1+r)
  v=(dof**(-3/10))*(10-1)*(1+(1/r))^2

  # the p-value for SNP #m.
  p_VALS<-c(p_VALS,pf(D,dof,v,lower.tail=FALSE))
}

print(p_VALS);
