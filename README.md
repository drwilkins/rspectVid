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
rspectVid(params,delTemps=F) 
#exports an .mp4 to the same file directory by default
```
[![Static Spectrogram of a female barn swallow song](https://raw.githubusercontent.com/drwilkins/rspectVid/master/web/Femalebarnswallow1.png)](https://github.com/drwilkins/rspectVid/blob/master/web/FemaleBarnSwallow1.mp4)
[Link to female barn swallow Dynamic Spectrogram](https://github.com/drwilkins/rspectVid/blob/master/web/FemaleBarnSwallow1.mp4)



### To source the rspectVid.R script & generate a dynamic spec in a new R instance:
* Note, you will need [ffmpeg](https://www.ffmpeg.org) installed to take full advantage of this code.
* If you have a Mac, with [homebrew installed](https://brew.sh/), you can install ffmpeg easily by opening terminal and entering:
  ```brew install ffmpeg``` 
  
* Also, note that this might take up to 5 min, depending on CPU power...
* You use testSpec() to preview & tweak the spec
  * crop=12 is interpreted as only use the first 12 seconds of the file; can also specify interval w/ c(0,12)
  * xLim=3 specifies the "page window" i.e. how many seconds each "page" of the dynamic spectrogram should display, here 3 sec
  * ampTrans=3 is a nonlinear signal booster. Basically collapses the difference between loudest and quietest values (higher values= brighter specs)
  
```
require(devtools)
source_url("https://raw.githubusercontent.com/drwilkins/rspectVid/master/rspectVid.R")
p<-testSpec("http://www.oceanmammalinst.org/songs/hmpback3.wav",yLim=c(0,.7),crop=12,xLim=3,ampTrans=3) 
#sounds are all <700 Hz, thus the Ylim specification
rspectVid(p)
#Voila 🐋
```
[![Humpback whale song spectrogram](https://raw.githubusercontent.com/drwilkins/rspectVid/master/web/hmpbackSpec.png)](https://raw.githubusercontent.com/drwilkins/rspectVid/master/web/hmpback3.mp4)
[Download whale song spec here](https://github.com/drwilkins/rspectVid/blob/master/web/hmpback3.mp4?raw=true)

### Now also supports .mp3 files (web or local) and multi-page dynamic spectrograms (i.e. cropping and segmenting spectrograms from larger recording files)

#### Example using Xeno-Canto to generate a 5 "page" dynamic spectrogram of a common nighthawk call (w/ different color scheme)
```
n=testSpec("https://www.xeno-canto.org/sounds/uploaded/SPMWIWZKKC/XC490771-190804_1428_CONI.mp3",crop=20,xLim=4,colPal = c("white","black"))
rspectVid(n,highlightCol = "#d1b0ff",cursorCol = "#7817ff")
```
[![Nighthawk call multipage dynamic spectrogram](https://raw.githubusercontent.com/drwilkins/rspectVid/master/web/nighthawkSpec.png)](https://raw.githubusercontent.com/drwilkins/rspectVid/master/web/XC490771-190804_1428_CONI.mp4)
[Download nighthawk call spec here](https://github.com/drwilkins/rspectVid/blob/master/web/XC490771-190804_1428_CONI.mp4?raw=true)