###################################################################################################
#                   A function to perform sequential network meta-analysis
###################################################################################################
#       Arguments:
#data: a dataset in which the following arguments can be found: sortvar, studyid, t (or t1 and t2),
#n and r for binary outcomes, y, sd and n for continuous outcomes, TE and seTE for inverse variance data.
#perarm: a logical value indicating whether data are given as one treatment arm per row. 
#If TRUE the pairwise command is used to produce a dataset with one comparison per row.
#type: a character value indicating the type of the measured outcome, e.g. "binary", "continuous".
#sm: a character string indicating underlying summary measure, e.g. "OR", "RR", "RD", "MD", "SMD".
#tau.preset: an optional value for the square-root of the between-study variance τ^2. 
#If not specified heterogeneity is re-estimated at each step from the data.
#comb.fixed: A logical indicating whether a fixed effect meta-analysis should be conducted.
#comb.random: A logical indicating whether a random effects meta-analysis should be conducted.
###################################################################################################


sequentialnma = function (data, perarm=T, type, sm, tau.preset = NULL, comb.fixed=F, comb.random=T 
                        , studlab="id",sortvar="year", t="t", r="r", n="n", y="y", sd="sd", TE="TE", seTE="seTE"
                        , t1="t1", t2="t2")
{
  library(netmeta)# !!!!!!!!!kai egw etsi ta kanw alla blepw oti alloi to kanoun me  nameoflinbrary::functionname
  library(meta)
  library(plyr)
  library(caTools)
  #library(devtools) ###!!!!!!!!!!!!!!! nomizw den xreiazetai?
  
  #define arguments, correspond them to default names and sort them using formatdata function
  args =  unlist(as.list(match.call())); 
  studies=formatdata(data,args)
  
  #define unique ids and create list with sequentially added study ids
  uniqueids = unique(studies$id)
  accIds = mapply(function(i){rev(tail(rev(uniqueids),i))},1:length(uniqueids))
  
  #define anticipated treatment effect as the final NMA effect using fordelta function
  delta=fordelta(data=studies, perarm=perarm, type=type, sm=sm, tau.preset = tau.preset, comb.fixed, comb.random)
  
  #run main function which performs sequential nma on the list of sequentially added ids
  runmain = function(x){main(data=studies[studies$id %in% x,], perarm=perarm, type=type, sm=sm, 
                           tau.preset=tau.preset, comb.fixed, comb.random, delta=delta)}
  
  result=mapply(runmain,accIds,SIMPLIFY = FALSE) 

  #run again the last step of sequential nma including all studies
  #(this may be redundant but I included it to consider whether only this will be the visible outcome)
  laststep=main(data=studies, perarm=perarm, type=type, sm=sm, 
                tau.preset = tau.preset, comb.fixed, comb.random, delta=delta)
  suppressMessages({
    res=list(result=result,studies=studies,laststep=laststep);
    class(res)<-"sequentialnma"
  })
  return(res)
}
