#requires installation of imagemagick 
# on a mac, run 'brew install imagemagick' in terminal (provided you've already set up Homebrew (https://brew.sh/))  

#Install/load pacman
if(!require(pacman)){install.packages("pacman");require(pacman)}
#Install/load tons of packages
p_load(ggplot2,seewave,tuneR,viridis,scales,gganimate,av,grid,tidyverse,png)

##########
# rspect: Custom function for generating ggplot spectrogram objects in R

#Parameter descriptions:
  # *- These parameters are really important for the look of your spectrogram

  # waveFile: filenames should be relative to working directory (e.g. "song examples/1.wav")
  # dest_folder: needs to be like "figures/spectrograms/" to refer within working directory
  # if outFilename is left out, will use input (.wav) name in output filename
  # *colPal: color palette; one of "viridis","magma","plasma","inferno","cividis" from the viridis package (see: https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html) OR a 2 value vector (e.g. c("white","black)), defining the starts and ends of a custom color gradient
  # *Xlim: is the time limit in seconds (defaults to WAV file length)
  # *Ylim: is the frequency limits (y-axis); default is c(0,10) aka 0-10kHz
  # *ampTrans: amplitude transform; defaults to identity (actual dB values); specify a decimal number for the lambda value of scales::modulus_trans(); 2.5 is a good place to start. (This amplifies your loud values the most, while not increasing background noise much at all)
  # filterThresh: the threshold as a % to cut out of recording (try 5 to start); default= no filtering (high data loss with this)
  # bg:background color (defaults to 1st value of chosen palette)
  # *wl: window length for the spectrogram (low vals= higher temporal res; high vals= higher freq. res). Default 512 is a good tradeoff
  # ovlp: how much overlap (as %) between sliding windows to generate spec? Default 90 looks good, but takes longer
  # wn: window name (slight tweaks on algorithm that affect smoothness of output) see ?spectro
  # colbins: default 30: increasing can smooth the color contours, but take longer to generate spec

testSpec<-function(waveFile,dest_folder,outFilename,colPal,Xlim,Ylim,plotLegend,onlyPlotSpec,ampTrans,filterThresh,min_dB,bg,wl,ovlp,wn,specWidth,specHeight,colbins,...)
{
  if(missing(colPal)){colPal="inferno"}
  if(missing(dest_folder)){dest_folder=dirname(waveFile)}#Put in wavefile directory if unspecified
  if(!grepl("/$",dest_folder)){dest_folder=paste0(dest_folder,"/")}#if dest_folder missing terminal /, add it
  if(missing(outFilename)){outFilename=paste0(tools::file_path_sans_ext(basename(waveFile)),".PNG")}
  if(!grepl(".png|PNG",outFilename)){outFilename=paste0(outFilename,".png")}#if user didn't put suffix onto output filename, add .jpeg
  if(missing(Ylim)){Ylim=c(0,10)}
  if(missing(plotLegend)){plotLegend=T}
  if(missing(onlyPlotSpec)){onlyPlotSpec=F}
  if(missing(min_dB)){min_dB=-30}
  #Are we dealing with a custom or a viridis palette?
  if(length(colPal)==1){isViridis<-T}else{isViridis<-F}
  if(missing(bg)){ 
    if(isViridis){pal=eval(parse(text=paste0("viridis::",colPal)));bg=pal(1)}else{bg=colPal[1]}}#set background color as palette level 1 if missing
  if(missing(filterThresh)){filterThresh=0}
  wav0<-readWave(waveFile)
  if(missing(wl)){wl=512}
  if(missing(ovlp)){ovlp=90}
  if(missing(wn)){wn="blackman"}
  if(missing(specWidth)){specWidth=6}
  if(missing(specHeight)){specHeight=2}
  if(missing(colbins)){colbins=30}
  if(missing(ampTrans)){ampTrans=1}

  
  
  if(filterThresh==0){wav<-wav0}else{wav<-afilter(wav0,f=wav0@samp.rate,threshold=filterThresh,plot=F)}

  file_dur<-max(length(wav0@left),length(wav0@right))/wav0@samp.rate  

  G<-ggspectro(wav,f=wav0@samp.rate,ovlp=ovlp,wl=wl,wn=wn,flim=Ylim,...)
  G2<-G+stat_contour(geom="polygon",aes(fill=..level..),bins=colbins)+theme_bw() +theme(panel.background=element_rect(fill=bg),panel.grid.major=element_blank(),panel.grid.minor=element_blank())
  if(plotLegend==F){G3<-G2+theme(legend.position = "none")}else{G3<-G2}
  if(!missing(Xlim)){G4<-G3+xlim(Xlim)}else{G4<-G3;Xlim=c(0,file_dur)}
  
  #Handle gradient color palette
  if(isViridis)
    {G5<-G4+scale_fill_viridis(limits=c(min_dB,0),na.value="transparent",option=colPal,trans=scales::modulus_trans(p=ampTrans))# if a Viridis Palette type specified, plot it 
  }else{
    G5<-G4+scale_fill_gradient(limits=c(min_dB,0),na.value="transparent",low=colPal[1],high=colPal[2],trans=scales::modulus_trans(p=ampTrans))
  }
  if(onlyPlotSpec){G5<-G5+theme_void()+ theme(legend.position="none",plot.background=element_rect(fill=bg))}
    
#return spec parameters
  specParams=list(waveFile=waveFile,dest_folder=dest_folder,outFilename=outFilename,colPal=colPal,Xlim=Xlim,Ylim=Ylim,plotLegend=plotLegend,onlyPlotSpec=onlyPlotSpec,ampTrans=ampTrans,filterThresh=filterThresh,min_dB=min_dB,bg=bg,wl=wl,ovlp=ovlp,wn=wn,specWidth=specWidth,specHeight=specHeight,colbins=colbins,file_dur=file_dur,spec=G5)
}#end testSpec


#Function for outputting a video of spectrogram

rspectVid<-function(specParams,framerate,vidName,... )
{
  #Address missing variables
  if(missing(framerate)){framerate=25}
  if(missing(vidName)){vidName=paste0(tools::file_path_sans_ext(specParams$waveFile),".mp4")}
  
  #Save background spectrogram PNG using tested parameters
    out<-paste0(specParams$dest_folder,specParams$outFilename)
    ggsave(out,dpi=300,width=specParams$specWidth,height=specParams$specHeight,units="in")
    print(paste0("Spec saved @ ",out))
 #Read PNG bitmap back in
  spec_PNG<-readPNG(out)
  spec_width_px<-attributes(spec_PNG)$dim[2]
  spec_height_px<-attributes(spec_PNG)$dim[1]
    
  #Create data frame for highlighting box animation
   cursor<-c(seq(0,specParams$file_dur,round(specParams$file_dur/framerate,3)),specParams$file_dur)
  played<-tibble(xmin=rep(specParams$Xlim[1],length(cursor)),ymin=rep(specParams$Ylim[1], length(cursor)),xmax=cursor,ymax=rep(specParams$Ylim[2], length(cursor)) )
  
  #Make ggplot overlay of highlight box on spectrogram
  vidSegment<-ggplot(played)+theme_void()+annotation_custom(rasterGrob(spec_PNG,width = unit(1,"npc"),height= unit(1,"npc")))+xlim(specParams$Xlim)+ylim(specParams$Ylim)+geom_rect(aes(xmin=xmin,ymin=ymin,xmax=xmax,ymax=ymax),fill="white",alpha=.2)+transition_reveal(along=cursor)

animate(vidSegment,renderer=av_renderer(vidName,audio=specParams$waveFile),duration=specParams$file_dur,width=spec_width_px,height=spec_height_px) 
  
}#end rspectVid definition

params<-testSpec("data//Female Barn Swallow 1.wav",dest_folder="temp/",ampTrans = 2.5)
rspectVid(params)


