# rspectVid
Script for generating a video spectrogram from an audio file

Workflow: 
1. Tweak your spectrogram settings using the testSpec() function, storing results in variable
2. Feed variable into rspectVid to generate dynamic spectrogram
  -It does this by exporting a PNG of the testSpec() ggplot function;
  -Import PNG as a new ggplot raster layer
  -Overlay a series of translucent highlight boxes that disolve away using gganimate
      
Example usage:
```
#takes .wav or .mp3
params<-testSpec("data/Femalebarnswallow1.wav") 
rspectVid(params) 
#exports an .mp4 to the same file directory by default
```


[![Static Spectrogram](https://raw.githubusercontent.com/drwilkins/rspectVid/master/temp/Female%20barn%20swallow%201.PNG)](https://github.com/drwilkins/rspectVid/blob/master/data/FemaleBarnSwallow1.mp4)
[Link to Dynamic Spectrogram](https://github.com/drwilkins/rspectVid/blob/master/data/FemaleBarnSwallow1.mp4)



### To source the rspectVid.R script & generate a dynamic spec in a new R instance:
* Note, you will need [ffmpeg](https://www.ffmpeg.org) installed to take full advantage of this code.
* If you have a Mac, with [homebrew installed](https://brew.sh/), you can install ffmpeg easily by opening terminal and entering:
  ```brew install ffmpeg``` 
  
* Also, note that this might take up to 5 min, depending on CPU power...
```
require(devtools)
source_url("https://raw.githubusercontent.com/drwilkins/rspectVid/master/rspectVid.R")
p<-testSpec("http://www.oceanmammalinst.org/songs/hmpback3.wav",yLim=c(0,.7),crop=6,ampTrans=3) 
#sounds are all <700 Hz, thus the Ylim specification
rspectVid(p)
#Voila 🐋
```

### Now also supports .mp3 files (web or local) and multi-page dynamic spectrograms (i.e. cropping and segmenting spectrograms from larger recording files)

#### Example using Xeno-Canto to generate a 5 "page" dynamic spectrogram of a common nighthawk call (w/ different color scheme)
```
n=testSpec("https://www.xeno-canto.org/sounds/uploaded/SPMWIWZKKC/XC490771-190804_1428_CONI.mp3",crop=20,xLim=4,colPal = c("white","black"))
rspectVid(n,highlightCol = "#d1b0ff",cursorCol = "#7817ff")
```