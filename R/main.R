#A function that calculates the sequential quantities and boundaries at each step of the analysis
#the input is a subset of the sequentialnma arguments apart from the delta argument which is inputed by fordelta function

main <- function(data, perarm=T, type, sm=sm, tau.preset = tau.preset, comb.fixed=F, comb.random=T, delta=NA){
  
  #perform network meta-analysis
  if (perarm & type=="binary"){
    Dpairs = suppressWarnings(
        pairwisenowarn(treat=t,event=r,n=n, data=data, studlab = id, sm = sm, warn=F)
        )
      checkconn = netconnection(treat1,treat2,studlab,data=Dpairs)
    if (checkconn$n.subnets==1){
      metaNetw = netmeta(TE,seTE,treat1,treat2,studlab,data=Dpairs,sm=sm,
                         comb.fixed =F,comb.random = T,tol.multiarm=T,tau.preset = tau.preset
                        , warn = F)
    }
  } 
  
  if (perarm & type=="continuous"){
    Dpairs=invisible(
      pairwise(treat=t,mean=y,sd=sd,n=n,data=data, studlab =id, sm=sm)
    )
    checkconn=netconnection(treat1,treat2,studlab,data=Dpairs)
    if (checkconn$n.subnets==1){
    metaNetw<-netmeta(TE,seTE,treat1,treat2,studlab,data=Dpairs,sm=sm,
                      comb.fixed =F,comb.random = T,tol.multiarm=T,tau.preset = tau.preset)
    }
  }
  
  if (!perarm){
    checkconn=netconnection(t1,t2,studlab=id,data=data)
    if (checkconn$n.subnets==1){
    metaNetw=netmeta(TE,seTE,t1,t2,studlab=id,data=data,sm=sm,
                     comb.fixed =F,comb.random = T,tol.multiarm=T,tau.preset = tau.preset)
    }
  }
  
  if (checkconn$n.subnets==1){
  #store pairwise and network meta-analysis results
  sideSplit=netsplit(metaNetw)
  
  if (comb.fixed){
    Direct=sideSplit$direct.fixed$TE
    DirectSE=sideSplit$direct.fixed$seTE
    DirectL=sideSplit$direct.fixed$lower
    DirectU=sideSplit$direct.fixed$upper
    TE.nma=metaNetw$TE.fixed[lower.tri(metaNetw$TE.fixed)]
    seTE.nma=metaNetw$seTE.fixed[lower.tri(metaNetw$seTE.fixed)]
    LCI.nma=metaNetw$lower.fixed[lower.tri(metaNetw$lower.fixed)]
    UCI.nma=metaNetw$upper.fixed[lower.tri(metaNetw$upper.fixed)]
  }
  
  if (comb.random){
    Direct=sideSplit$direct.random$TE
    DirectSE=sideSplit$direct.random$seTE
    DirectL=sideSplit$direct.random$lower
    DirectU=sideSplit$direct.random$upper
    TE.nma=metaNetw$TE.random[lower.tri(metaNetw$TE.random)]
    seTE.nma=metaNetw$seTE.random[lower.tri(metaNetw$seTE.random)]
    LCI.nma=metaNetw$lower.random[lower.tri(metaNetw$lower.random)]
    UCI.nma=metaNetw$upper.random[lower.tri(metaNetw$upper.random)]
  }
  
  input=cbind(c(Direct),c(DirectSE),c(DirectL),c(DirectU),c(TE.nma),c(seTE.nma),c(LCI.nma),c(UCI.nma))
  rownames(input) <- c(sideSplit$comparison)
  colnames(input) <- c("DirectTE","DirectSE","DirectL","DirectU",
                       "NetworkTE","NetworkSE","NetworkL","NetworkU")
  input=as.data.frame(input)
  
  #set anticipated effect size equal to final nma as estimated from fordelta function
  delta=as.data.frame(delta)
  delta = delta[rownames(input),]
  #calculate z scores and accumulated information
  Zpairw = input$DirectTE/input$DirectSE
  Ipairw = 1/input$DirectSE
  Zntw <- input$NetworkTE/input$NetworkSE
  Intw <- 1/input$NetworkSE
  #maximum required information, consider putting alpha and beta as arguments
  # !!!!!!!!!!!!!!!!!!! shall be easy - at the moment you have a 5% power 90% right?
  #!!!! i did minor changes
  typeIerror=0.05
  power=0.9
  ImaxPairw = ImaxNMA = abs((-qnorm(typeIerror/2, 0, 1, lower.tail = TRUE,log.p = FALSE) ###!!!!!! nomizw ta  0, 1, lower.tail = TRUE,log.p = FALSE)  den xreiazontai
                      + qnorm(power, 0, 1, lower.tail = TRUE, log.p = FALSE))/(delta))
  #fraction of accumulated information
  tallPairw = Ipairw/ImaxPairw
  tallNMA = Intw/ImaxNMA
  
  #calculation of sequential boundaries using alpha function
##!!!!!!!!! afou stin alpha exeis balei mesa kai ta alla option oxi mono BF giati dne to exeis to BF argument?
  SeqEffPairw = alpha(method = "BF", t = tallPairw)
  SeqEffNMA = alpha(method = "BF", t = tallNMA)
  AtPairw = SeqEffPairw[, 2]##!!!!!!!!! perita, des parakatw
  EbPairw = SeqEffPairw[, 3]
  AtNMA = SeqEffNMA[, 2]
  EbNMA = SeqEffNMA[, 3]
  #repeated confidence intervals
  LrciPairw = input$DirectTE - EbPairw * input$DirectSE
  #!!!! kalutera LrciPairw = input$DirectTE - eqEffPairw$E * input$DirectSE kai ta alla parakatw omoiws
  UrciPairw = input$DirectTE + EbPairw * input$DirectSE
  LrciNMA = input$NetworkTE - EbNMA * input$NetworkSE
  UrciNMA = input$NetworkTE + EbNMA * input$NetworkSE
  #store sequential nma calculations together with nma results
  output = data.frame(input,delta, Zpairw, Ipairw, Zntw, Intw, 
                      tallPairw, tallNMA, AtPairw, EbPairw, AtNMA, EbNMA, 
                      LrciPairw, UrciPairw, LrciNMA, UrciNMA)
  colnames(output) <- c("DirectTE","DirectSE","DirectL","DirectU",
                        "NetworkTE","NetworkSE","NetworkL","NetworkU",
                        "delta","DirectZscore", "DirectI", "NetworkZscore", 
                        "NetworkI", "DirectTaccum", "NetworkTaccum", "DirectAlpha", 
                        "DirectBoundary", "NetworkAlpha", "NetworkBoundary", 
                        "DirectLowerRCI", "DirectUpperRCI", "NetworkLowerRCI", 
                        "NetworkUpperRCI")
  ###!!!!!!!! gia na apofeugeis lathi stis antistoixiseis kalutera ta dyo parapanw commands na ta grapseis
  ###!!!  output = cbind.data.frame(input,delta=delta,DirectZscore=Zpairw,DirectI= Ipairw......)
  
  
  return(output)###!!!! den katalabainw giati na einai list?
  }
}


