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
[![Link to Dynamic Spectrogram]({https://github.com/drwilkins/rspectVid/blob/master/temp/Female barn swallow 1.png})]({https://github.com/drwilkins/rspectVid/blob/master/data/XC500855-Tui.mp4?raw=true} "Link to Dynamic Spectrogram")

