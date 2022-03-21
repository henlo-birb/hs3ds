# hs3ds
files relating to the hs3ds project

containing:
- a fork of [Citro2d](https://github.com/devkitPro/citro2d) allowing for multicolor text drawing
- a fork of [Lovepotion](https://github.com/lovebrew/lovepotion) allowing for multicolor text drawing using the citro2d fork
- (gif_to_atlas) a python script to convert .gif files to multiple .t3x files along with lua tables to allow for animation in lovepotion on the 3ds
- (process_json) a python script to convert the information in mspa.json from [the Unofficial Homestuck Collection](https://bambosh.github.io/unofficial-homestuck-collection/) into lua tables with the relevant information for homestuck pages
- a lovepotion app to test the maplesyrup ui framework for lovepotion I'm building
- the current version of hs3ds

## to build and run:
- follow the instructions [here](https://lovebrew.org/#/building) to install devkitpro and the required libraries 
- in ```citro2d/``` run ```make clean && make install```
- in ```lovepotion/``` run ```make clean && make ctr -j8```
- copy ```lovepotion/platform/3ds/LOVEPotion.3dsx``` to the ```3ds/``` folder on your modded 3ds' sd card
- copy the ```game/``` folder from ```maplesyrup_test``` or ```hs3ds``` depending on which one you want to run to the ```3ds``` foldoper on your modded 3ds' sd card
- open the homebrew app on your 3ds and run LOVEPotion
you did it!!!!!!!!
