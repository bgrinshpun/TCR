##Summary Statistics of Alloreactive TCR repetoire 
  #Statistics of JensenShannon Metric, Entropy, Clonality
# Example input file:
  #aminoAcid  vGeneName	jGeneName	total	T1stCD4	T1stCD8	T1unCD4	T1unCD8
  #CASSTNPNTGELFF	TCRBV07-09	TCRBJ02-02	420112	2557	328483	112	88960

# Example output file:
      #HC_19_10_count_aa.tsv                      CD4       CD8
                            #jsd             0.3388348 0.3976339
                            #jsd_alloRx      0.2461814 0.2239120
                            #jsd_final       0.2449246 0.2217560  
                            #e_stim          7.7013137 7.1473879
                            #e_unstim        8.1257218 7.5029507
                            #e_stim_alloRx   2.3507090 2.1805300
                            #e_unstim_alloRx 2.3084769 2.5855355


#!/Users/mm4556/Dropbox/ShenLABmichelle/code
setwd("/Volumes/BigData/TCR/Sykes/alloresponse_count_files copy")
suppressPackageStartupMessages(require(optparse))

##These are the settings on AlloAnalysis which outputs file in pwd with statistics
##AlloAnalysis <- function(file, output = "", clean = T, NT = T, fold= 5, minFreq= 1e-4)
#example data for NT file:  nucleotide total HC_10_unstim_CD4 HC_10_unstim_CD8 HC_10v12_stim_CD4 HC_10v12_stim_CD8
#example data for aa file:  aminoAcid vGeneName  jGeneName total HC_10_unstim_CD4 HC_10_unstim_CD8 HC_10v12_stim_CD4 HC_10v12_stim_CD8


alloreactive <- function(data, fold = fold, minFreq = minFreq)  {  
  
  #normalizing
  norm_data = normalize(data)

  
  #input data is normalized and corrected for CD4CD8 overlap in AlloAnalysis function
  jsd <- jensen_shannon(data[,1],data[,2])
  e_stim <- shannon.entropy(data[,1])
  e_unstim <- shannon.entropy(data[,2])
  c_stim <- cloneCal(data[,1])
  c_unstim <- cloneCal(data[,2])
  
  
  #5X threshold
  
  alloRxClones = data[data[,1] > data[,2] * fold, ] #also removed clones only in unstim
  jsd_alloRx <- jensen_shannon(alloRxClones[,1],alloRxClones[,2])
  e_stim_alloRx <- shannon.entropy(alloRxClones[,1])
  e_unstim_alloRx  <- shannon.entropy(alloRxClones[,2])
  c_stim_alloRx <- cloneCal(alloRxClones[,1])
  c_unstim_alloRx <- cloneCal(alloRxClones[,2])
  
  
  #5X threshold and 1*10^-4 threshold
  
  final_alloTCR  =  data[data[,1] > data[,2] * fold & data[,1] > minFreq, ]
  jsd_final <- jensen_shannon(final_alloTCR[,1],final_alloTCR[,2])
  e_stim_final <- shannon.entropy(final_alloTCR[,1])
  e_unstim_final <- shannon.entropy(final_alloTCR[,2])
  c_stim_final <- cloneCal(alloRxClones[,1])
  c_unstim_final <- cloneCal(alloRxClones[,2])
  
  resultall = cbind(jsd,jsd_alloRx,jsd_final,e_stim,e_unstim, e_stim_alloRx,e_unstim_alloRx, e_stim_final,e_unstim_final,c_stim, c_unstim, c_stim_alloRx,c_unstim_alloRx, c_stim_final, c_unstim_final )  
  
  
  # View(resultall)
  #return(matrix(t(resultall)))
  return(t(resultall))
}


normalize <- function(data) {
  nc = ncol(data)
  for (i in 1:nc) {
    data[,i] = data[,i] / sum(data[,i])
  }
  return(data)
}

shannon.entropy <- function(p)
{
  if (min(p) < 0 || sum(p) <= 0)
    return(NA)
  p.norm <- p[p>0]/sum(p)

  -sum(log2(p.norm)*p.norm)
}

jensen_shannon <- function(p, q){
  #input is columns of matrix with frequency of clones
  ## JSD = H(0.5 *(p +q)) - 0.5H(p) - 0.5H(q)
  # H(X) = \sum x_i * log2(x_i)
  #  p = p[p >0 & q >0]
  #  q = q[p>0 & q>0]
  p = p / sum(p)
  q = q / sum(q)
  Hj = shannon.entropy(0.5 *(p+q)) 
  Hp = shannon.entropy(p) 
  Hq = shannon.entropy(q)
  
  jsd = Hj - 0.5*(Hp+Hq)
  jsd = sqrt(jsd)
  #  cat(Hj, Hp, Hq, jsd, "\n")
  return(jsd)
}


cloneCal <- function(p) {
  x = p[p>0] / sum(p)
  l = length(x)
  entropy = shannon.entropy(p)
  maxentropy = -log2(1/l)
  return(signif(1 - entropy / maxentropy, 2)) }

cleanup <- function(cd4, cd8, ratio = 5) {
  
  ## remove contaminated clones
  
  ambi = (cd4 > 0 & cd8 > 0 & cd4 / cd8 > 1/ratio & cd4 / cd8 < ratio) 
  cd4exclude = (cd4 > 0 & cd8 > 0 & cd4 / cd8 <= 1/ratio ) 
  cd8exclude = (cd4 > 0 & cd8 > 0 & cd4 / cd8 >= ratio )
  #throws away (marks as true for exlcusion) ones that are ambi in stim, but not ambi in unstim
  #if you want to keep cd8 that is ambi in stim with cd4, but clearly not ambi in unstim and dominant, need to do comparison against all
  #remember, true means to be excluded and false means keep. false could be a zero so length of data==F is not number to keep
  # print(paste(length(ambi[ambi==T]), length(cd4exclude[cd4exclude==T]), length(cd8exclude[cd8exclude==T])))
  
  return(cbind(ambi | cd4exclude, ambi | cd8exclude))
  
}


##assumptions about the data, column for STIM and UNSTIM, set columns for CD4 and CD8

option_list = list(
  make_option(c("-f", "--file"), action="store", default=NA, type='character',
              help="input file")
)

opt = parse_args(OptionParser(option_list=option_list))

#this function gets file, organized CD4 and CD8, normalizes counts for frequency, corrects for  CD4 CD8 overlap, does alloanalysis function that outputs  values in table
AlloAnalysis <- function(file, output = "", clean = T, NT = F, fold= 5, minFreq= 1e-4)  {
  
  #get and read file
  a = read.table(file, sep="\t", header=T)
  
  ### Set Data
  if (NT==T) {
    cd4 = cbind(a[,3], a[,5])
    cd8 = cbind(a[,4], a[,6]) 
  }  
  
  if (NT==F) {
    cd4 = cbind(a[,5], a[,7])
    cd8 = cbind(a[,6], a[,8])
    #(stim, unstim)  
    
  }
  
  #normalize function
  cd4norm = normalize(cd4)
  cd8norm = normalize(cd8)
  
  cleans  = "raw"
  
  #True False table of overlapping clones. True is contimanation to be removed
  if (clean == T) {
    ##make true false table 
    truefalse_stim = cleanup(cd4norm[,1], cd8norm[,1]) 
    truefalse_unstim = cleanup(cd4norm[,2], cd8norm[,2])
    truefalse = cbind(truefalse_stim,truefalse_unstim) 
    ##make true false table into 0 and 1
    zeros_and_ones = 1-truefalse
    
    ## compare truefalse table
    m2 = cbind(cd4norm[,1], cd8norm[,1],cd4norm[,2], cd8norm[,2]) # data
    m3 = zeros_and_ones*m2  ##clean data
    colnames(m3) <- c("cd4stim","cd8stim","cd4unstim","cd8unstim")
    #m3 is clean data with zeros placed where overlapping clones were
    
    cd4 = cbind(m3[,1],m3[,3])
    cd8 = cbind(m3[,2], m3[,4])
    cd4 = normalize(cd4)
    cd8 = normalize(cd8)
    
    cleans = "clean"
    ## output is STIM and UNSTIM
    cd4r =  alloreactive(cd4, fold, minFreq)
    cd8r =  alloreactive(cd8, fold, minFreq)
    
  
  } 
  
  if (NT==F) {
    
    ##aggregate by VJ genes
    
    v <- a[,2]
    j <- a[,3] 
    cd4agg <- aggregate(x=cd4, by= list(j,v), FUN= "sum")
    cd8agg <- aggregate(x=cd8, by= list(j,v), FUN= "sum")
    cd4 <- cd4agg[,3:4]
    cd8 <- cd8agg[,3:4]
    ## output is STIM and UNSTIM
    cd4r =  alloreactive(cd4, fold, minFreq)
    cd8r =  alloreactive(cd8, fold, minFreq)
  
  }
  

  result = cbind(cd4r, cd8r)
  colnames(result) = c("CD4", "CD8")
  
  print(result)
  
  if(output == "") {
    output = paste( file, "AlloRx", clean, "txt", sep=".")
  }
  write.table(result, file=output, sep="\t", col.names = T, row.names = T, quote=F)
  
}

cat(opt$f)
AlloAnalysis(file=opt$f)
