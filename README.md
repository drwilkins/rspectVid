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
params<-testSpec("data/Female barn swallow 1.wav") 
rspectVid(params) 
#exports an .mp4 to the same file directory by default
```
![Static Spectrogram]("https://github.com/drwilkins/rspectVid/blob/master/temp/Female barn swallow 1.png")]
[Link to Dynamic Spectrogram]("https://github.com/drwilkins/rspectVid/blob/master/data/Female barn swallow 1.mp4?raw=true")

###To run source the rspectVid.R script & generate a dynamic spec in a new R instance:
```
require(devtools)
sourceURL("https://raw.githubusercontent.com/drwilkins/rspectVid/master/rspectVid.R")
p<-testSpec("http://www.oceanmammalinst.org/songs/hmpback3.wav")
rspectVid(p)
#Voila 🐋
```
