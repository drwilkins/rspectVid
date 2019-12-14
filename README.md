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


![Static Spectrogram](https://raw.githubusercontent.com/drwilkins/rspectVid/master/temp/Female%20barn%20swallow%201.PNG)
[Link to Dynamic Spectrogram](https://github.com/drwilkins/rspectVid/blob/master/data/FemaleBarnSwallow1.mp4)


###To run source the rspectVid.R script & generate a dynamic spec in a new R instance:
```
#Note, this might take up to 5 min, depending on CPU power...
require(devtools)
source_url("https://raw.githubusercontent.com/drwilkins/rspectVid/master/rspectVid.R")
p<-testSpec("http://www.oceanmammalinst.org/songs/hmpback3.wav")
rspectVid(p)
#Voila 🐋
```
