#Install/load pacman
if(!require(pacman)){install.packages("pacman");require(pacman)}
#Install/load tons of packages
p_load(ggplot2,seewave,tuneR,viridis,scales,gganimate,av,grid,tidyverse,png,warbleR,tools,devtools,ari)

#function taken from https://github.com/trinker/reports/blob/master/R/is.url.R
is.url <-function(x) { 
    grepl("www.|http:|https:", x)
}


##########
# rspect: Custom function for generating ggplot spectrogram objects in R

#Parameter descriptions:
  # *- These parameters are really important for the look of your spectrogram

  # soundFile: filenames should be relative to working directory (e.g. "song examples/1.wav"); handles .mp3 and .wav
  # dest_folder: needs to be like "figures/spectrograms/" to refer within working directory
  # if outFilename is left out, will use input (.wav) name in output filename
  # *colPal: color palette; one of "viridis","magma","plasma","inferno","cividis" from the viridis package (see: https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html) OR a 2 value vector (e.g. c("white","black)), defining the starts and ends of a custom color gradient
  # *crop: subset of recording to include; if number, interpreted as first X.X sec; if c(X1,X2), interpreted as specific time interval in sec
  # *xLim: is the time limit in seconds for all spectrograms (defaults to WAV file length, unless file duration >5s)
  # *yLim: is the frequency limits (y-axis); default is c(0,10) aka 0-10kHz
  # *ampTrans: amplitude transform; defaults to identity (actual dB values); specify a decimal number for the lambda value of scales::modulus_trans(); 2.5 is a good place to start. (This amplifies your loud values the most, while not increasing background noise much at all)
  # filterThresh: the threshold as a % to cut out of recording (try 5 to start); default= no filtering (high data loss with this)
  # bg:background color (defaults to 1st value of chosen palette)
  # *wl: window length for the spectrogram (low vals= higher temporal res; high vals= higher freq. res). Default 512 is a good tradeoff
  # ovlp: how much overlap (as %) between sliding windows to generate spec? Default 90 looks good, but takes longer
  # wn: window name (slight tweaks on algorithm that affect smoothness of output) see ?spectro
  # colbins: default 30: increasing can smooth the color contours, but take longer to generate spec

testSpec<-function(soundFile,dest_folder,outFilename,colPal,crop,xLim,yLim,plotLegend,onlyPlotSpec,ampTrans,filterThresh,min_dB,bg,wl,ovlp,wn,specWidth,specHeight,colbins,...)
{
  #Put in soundFile directory if unspecified
  if(missing(dest_folder)){dest_folder=dirname(soundFile)}
  if(!grepl("/$",dest_folder)){dest_folder=paste0(dest_folder,"/")}#if dest_folder missing terminal /, add it
  
  if(is.url(soundFile)){download.file(soundFile,basename(soundFile));soundFile=basename(soundFile)}
  
  #Convert MP3s to WAV
  if(file_ext(soundFile)=="mp3"){
      print("***Converting mp3(s) to wav***")
      try(mp32wav(path=dirname(soundFile)))
      soundFile=paste0(dirname(soundFile),"/",file_path_sans_ext(basename(soundFile)),".wav")
      }
  
  wav0<-readWave(soundFile)
  smplRt<-wav0@samp.rate
  fileDur<-max(length(wav0@left),length(wav0@right))/smplRt  
  if(missing(filterThresh)){filterThresh=0}
  if(filterThresh!=0){wav0<-afilter(wav0,f=wav0@samp.rate,threshold=filterThresh,plot=F)}
  if(!missing(crop)){ #test. If user inputs single digit crop, interpret as first X sec
    crop=eval(parse(text=crop))
    if(length(crop)==1){crop=c(0,crop)}
  }
  
  ### For long files, ask user to crop and/or segment dynamic spectrograms
  if(fileDur>5&missing(crop)){
    cat("\n\n*** File duration is >5sec *** \nProcessor intensive warning: Do you want to use the whole recording to make the dynamic spec? (y/n) ")
    cropResp=readline(prompt=">>> ")
    if(tolower(cropResp)=="y"){crop=c(0,fileDur)}
    if(tolower(cropResp)=="n"){
     cat("\n\n*** Choose how to crop your dynamic spectrogram ***\nEnter a number to use only the first X.XX sec \nEnter a range c(x1,x2) where x1 is start time & x2 is stop for a specific time segment")
      cropResp2=readline(">>> ")
    crop=eval(parse(text=cropResp2))
    if(length(crop)==1){crop=c(0,crop)}
    }
  }
  if(missing(crop)&fileDur<=5)
  {crop=c(0,fileDur)}
  
  if(missing(xLim)){
    if(fileDur<=5)
    {xLim=crop;segWavs=list(wav);segLens=xLim}else{ 
      #if cropped segment is >5s ask to segment (i.e. set xLim)
      cat("\n\n*** Segment the dynamic spectrogram? ***\nPress ENTER to make a single, zoomed-out spec for whole recording\nType a number to combine specs for every X.X sec")
      xLimResp=readline(">>> ")
    if(xLimResp==""){xLim=crop;segWavs=list(wav);segLens=xLim}
      
    }
  }else{
      segLens <- unique(c(seq(crop[1],crop[2],as.numeric(xLimResp)),crop))
      indx<- 1:(length(segLens)-1)
      segWavs<-lapply(indx,function(i) cutw(wav0,from=segLens[i],to=segLens[i+1],output="Wave"))
      xLim=c(0,as.numeric(xLimResp))
      }
  
  if(missing(outFilename)){outFilename=paste0(file_path_sans_ext(basename(soundFile)),".PNG")}
  if(missing(colPal)){colPal="inferno"}
  if(!grepl(".png|PNG",outFilename)){outFilename=paste0(outFilename,".png")}#if user didn't put suffix onto output filename, add .jpeg
  if(missing(yLim)){yLim=c(0,10)}
  if(missing(plotLegend)){plotLegend=F}
  if(missing(onlyPlotSpec)){onlyPlotSpec=T}
  if(missing(min_dB)){min_dB=-30}
  #Are we dealing with a custom or a viridis palette?
  if(length(colPal)==1){isViridis<-T}else{isViridis<-F}
  if(missing(bg)){ 
    if(isViridis){pal=eval(parse(text=paste0("viridis::",colPal)));bg=pal(1)}else{bg=colPal[1]}}#set background color as palette level 1 if missing
  if(missing(wl)){wl=512}
  if(missing(ovlp)){ovlp=90}
  if(missing(wn)){wn="blackman"}
  if(missing(specWidth)){specWidth=6}
  if(missing(specHeight)){specHeight=2}
  if(missing(colbins)){colbins=30}
  if(missing(ampTrans)){ampTrans=2.5}

#generate spec(s)
specParams<-list()
soundDur<-list()
for (i in 1:length(segWavs))
{
  sound<-segWavs[[i]]
  soundDur[[i]]<-max(length(sound@left),length(sound@right))/sound@samp.rate  
  G<-ggspectro(sound,f=sound@samp.rate,ovlp=ovlp,wl=wl,wn=wn,flim=yLim)+xlim(xLim)
  G2<-G+stat_contour(geom="polygon",aes(fill=..level..),bins=colbins,na.rm=T)+theme_bw() +theme(panel.background=element_rect(fill=bg),panel.grid.major=element_blank(),panel.grid.minor=element_blank())
  if(plotLegend==F){G3<-G2+theme(legend.position = "none")}else{G3<-G2}
  G4<-G3 #old step used to do something
  
  #Handle gradient color palette
  if(isViridis)
    {G5<-G4+scale_fill_viridis(limits=c(min_dB,0),na.value="transparent",option=colPal,trans=scales::modulus_trans(p=ampTrans))# if a Viridis Palette type specified, plot it 
  }else{
    G5<-G4+scale_fill_gradient(limits=c(min_dB,0),na.value="transparent",low=colPal[1],high=colPal[2],trans=scales::modulus_trans(p=ampTrans))
  }
  if(onlyPlotSpec){G5<-G5+theme_void()+ theme(legend.position="none",plot.background=element_rect(fill=bg))}
   
  if(length(segWavs)>1){
    if(i==1){
      cat("\nFor segmented spectrogram, only segment 1 shown\n")}
    }
#return spec parameters
    specParams[[i]]=list(soundFile=soundFile,dest_folder=dest_folder,outFilename=outFilename,crop=crop,colPal=colPal,xLim=xLim,yLim=yLim,plotLegend=plotLegend,onlyPlotSpec=onlyPlotSpec,ampTrans=ampTrans,filterThresh=filterThresh,min_dB=min_dB,bg=bg,wl=wl,ovlp=ovlp,wn=wn,specWidth=specWidth,specHeight=specHeight,colbins=colbins,fileDur=fileDur,soundDur=unlist(soundDur),spec=G5)
}
plot(specParams[[1]]$spec)
specParams<-append(specParams,list(segWavs=segWavs))
return(specParams)
}#end testSpec



#############################################################
#Function for outputting a video of spectrogram
rspectVid<-function(specParams,vidName,framerate,highlightCol,... )
{
if(missing(framerate)){framerate=30}
if(!missing(vidName)){iName0=tools::file_path_sans_ext(vidName)}else{
    iName0<-tools::file_path_sans_ext(specParams[[i]]$outFilename)
    vidName=paste0(specParams[[1]]$dest_folder,iName0,".mp4")}#base name for output, sans extension
if(missing(highlightCol)){highlightCol="gray50"}
   
  tempdir<-paste0(specParams[[1]]$dest_folder,"temp/")
  dir.create(tempdir,showWarnings=F)
  #create list of names for WAV audio segments
  outWAV<-if(length(specParams$segWavs)==1){list(paste0(tempdir,iName0,".wav"))}else{lapply(1:length(specParams$segWavs),function(x) {paste0(tempdir,iName0,"_",x,"_.wav")})}
  #export wav files if spec is to be segmented; not necessary if wav is unaltered
  if(length(specParams)>1){
    cat(paste0("Temporary files saved at: ",tempdir))
    invisible(
      lapply(1:length(specParams$segWavs), function(x){fn=outWAV[[x]]
          savewav(specParams$segWavs[[x]],filename=fn)
          cat(paste0("\n",fn))}))}
  
for(i in 1:length(specParams$segWavs)){
  #Address missing variables
  
  iName<-paste0(iName0,ifelse(length(specParams$segWavs)==1,"",paste0("_",i,"_")))

  #Save background spectrogram PNG to temp directory using tested parameters
    outPNG<-paste0(tempdir,paste0(iName,".png"))
    outTmpVid<-paste0(tempdir,paste0(iName,".mp4"))
    ggsave(filename=outPNG,plot=specParams[[i]]$spec,dpi=300,width=specParams[[i]]$specWidth,height=specParams[[i]]$specHeight,units="in")
    print(paste0("Spec saved @ ",outPNG))
 #Read PNG bitmap back in
  spec_PNG<-readPNG(outPNG)
  spec_width_px<-attributes(spec_PNG)$dim[2]
  spec_height_px<-attributes(spec_PNG)$dim[1]
    
  #Create data frame for highlighting box animation
   cursor<-seq(0,specParams[[i]]$xLim[2],specParams[[i]]$xLim[2]/10)
  played<-tibble(xmin=cursor,xmax=rep(specParams[[i]]$xLim[2],length(cursor)),ymin=rep(specParams[[i]]$yLim[1],length(cursor)),ymax=rep(specParams[[i]]$yLim[2], length(cursor)))
  
  #Make ggplot overlay of highlight box on spectrogram
  vidSegment<-ggplot(played)+annotation_custom(rasterGrob(spec_PNG,width = unit(1,"npc"), height = unit(1,"npc")),- Inf, Inf, -Inf, Inf)+geom_rect(aes(xmin=xmin,ymin=ymin,xmax=xmax,ymax=ymax),fill=highlightCol,alpha=.5)+geom_segment(aes(x=xmin,xend=xmin,y=ymin,yend=ymax),col="white")+theme_void()  +transition_reveal(xmin)

animate(vidSegment,renderer=av_renderer(outTmpVid,audio=outWAV[[i]]),duration=specParams[[i]]$xLim[2],width=spec_width_px,height=spec_height_px,fps=framerate) #Need to save audio for segments!!
}

  #if necessary, combine segments
  if(length(outWAV)>1){
    tmpPaths<-paste0("file ",paste0("'",unlist(file_path_sans_ext(outWAV)),".ts'"))
    writeLines(tmpPaths,paste0(tempdir,"wavSegments.txt"))
    #Unfortunately, can't just slap MP4 files together, so have to have an intermediate .ts file step
    ffmpegTransCode<-paste0(ffmpeg_exec(),' -y -i "',unlist(file_path_sans_ext(outWAV)),'.mp4" -c copy -f mpegts "',unlist(file_path_sans_ext(outWAV)),'.ts"')
    invisible(sapply(ffmpegTransCode,system))
    #now combine .ts files into .mp4
   system(paste0(ffmpeg_exec(),' -y -f concat -safe 0 -i "',paste0(tempdir,"wavSegments.txt"),'" -codec copy "',vidName,'"'),timeout=100 )
  }

  cat("\n\nAll done!\n")
  cat(paste0("file saved @",vidName))
  system(paste0('open "',vidName,'"'))
}#end rspectVid definition