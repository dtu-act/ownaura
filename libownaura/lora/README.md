# LoRA toolbox #

## What is LoRA? ##

LoRA is the abbreviation of 'Loudspeaker Room Auralisation Toolbox'. It uses simulated early reflections (ER) and energy decay curves (EDC) to determine loudspeaker signals or multi-channel impulse responses for Ambisonics or nearest-loudspeaker sound field reproduction. The ER and EDC data can come from any room acoustics simulation, however, LoRA was developed with ODEON (www.odeon.dk) and thus works best with it.

LoRA was first developed by Sylvain Favrot (Favrot, 2010). The current version is a successor of Sylvains work with main effort from the National Acoustic Laboratory (NAL, Australia), in particular Jorg Buchholz and Chris Oreinos. The setup was then further developed at DTU by Axel Ahrens.

## How to get LoRA? ##

* Download/pull the repository from bitbucket (https://bitbucket.org/hea-dtu/lora/)

## How to install LoRA? ##

* Copy the folder LoRAToolbox on your Hard drive (ex: C:\xyz\loRAtoolbox)
* Set this path in Matlab. Type 
```
#!matlab

addpath('C:\xyz\LoRAToolbox')
```
* Type
```
#!matlab

LoRA_addpath()
```
to add the needed subfolders

* The toolbox is installed and ready to use

## How to setup LoRA? ##

### Set variables and paths###
In the MATLAB file 'LoRA_startup.m' default values can be adapted to the preferred system settings (lines 77 to 89). In particular the HOA order, the sampling frequency and the array setup details (see next section). 

In the file 'pathstore.m', the paths to read and write files are stored. This can be adapted as needed.

### Add your loudspeaker arrangement ###
1. Create a m-file that returns the loudspeaker positions in spherical coordinates (excl. radius) between 0 and 2*pi.

```
#!matlab

[pos] = LoudspeakerPositions()
```

The output variable 'pos' must be a matrix having as many rows as number of loudspeakers and 2 columns (ls_num x 2), where the first column contains the azimuth and the second one the elevation.

2. Change the variable 'LoudSetName' in 'LoRA_startup.m' to the filename you chose, e.g. 'LoudspeakerPositions.m'.

3. Type the correct loudspeaker radius for the variable 'LoudR' in 'LoRA_startup.m'.


## How to generate LoRA input files with ODEON? ##

The LoRA toolbox computes multichannel room impulse responses (mRIR) from the early reflections and the energy curve exported from ODEON. Specific parameters must be set before computing a response in ODEON; a typically set of options can be found below. Make sure you are using a point source with an omnidirectional directivity pattern. The resulting amplitude of the mRIR depends on the sound power set up in ODEON in the characteristic of the point source.

For a specific job in a specific room, 2 ASCII text files need to be saved in ODEON in order to compute the mRIR. This is done by selecting the desired Job in the ‘Joblist’ section of ODEON; run it if not computed yet (Alt+R) then select ‘View single point response’ (Alt+P) to show the job response. Select the tab ‘Decay curves’ and press Ctrl+A to export the data in ASCII format. Save the text file in the appropriate1 folder and make sure that the end of the file name is “(...)EnergyCurves.Txt” (Default). Then, select the tab ‘Reflectogram’ and type Ctrl+A. Save the ASCII text file in the same folder and make sure the end of the file is “(...)EarlyReflections.Txt”, the beginning being the same as the one before.
![LoRAQuickGuide_Odeon_setting.jpg](https://bitbucket.org/repo/KL5qrB/images/3919903921-LoRAQuickGuide_Odeon_setting.jpg)

## How to get an mRIR using LoRA? ##

* First, open the file pathstore.m and define the locations of your ODEON files and the folder to save the results.
* Run the startup and the batch processing file:
```
#!matlab
batchLoRAProc();
```
* You can choose multiple rooms/source-receiver files and sound files from the pop-up windows.
* Finally, find your files in the defined folders.

## Contribution guidelines ##

* Create an issue
* Contact Marton Marschall or Axel Ahrens

## Literature ##
Favrot, Sylvain Emmanuel; Buchholz, Jörg. LoRA: A Loudspeaker-Based Room Auralization System. In: Acustica United with Acta Acustica, Vol. 96, No. 2, 2010, p. 364-375.

## Contact ##

* The LoRA toolbox was developed by Sylvain Favrot in his PhD project (thesis available here: http://orbit.dtu.dk/fedora/objects/orbit:90098/datastreams/file_6459932/content)
* It is now maintained by Marton Marschall and Axel Ahrens
* Hearing Systems group, Department of Electrical Engineering, Technical University of Denmark