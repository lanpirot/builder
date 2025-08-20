# Synthesizer of (giant) Simulink models

This is a project to synthesize Simulink models for stress testing, scaling, or giant fuzzing. You can create new models that are
- giant sized (>500k Blocks, >100k Subsystems)
- deep (deep Subsystem hierarchy)
- broad (shallow, but many Subsystems)
- have isomorphic Subsystem hierarchy to a given model



## Usage
Get the model collection (SLNET)[https://zenodo.org/records/5259648]. Have the model collection unzipped into directories (names of directories are numbers), like this: 
SLNET
|---SLNET_GitHub
|     |---100042416
|     |---100381142
|     |---...
|---SLNET_MATLABCentral
      |---10335
      |---10439
      |---11027
      |---...

1. In `system_constants.m` state where your `SLNET` directory is located and where you want the output of the synthesizerto be stored at.
2. Next, run `gather_models.m`. This will scan the whole database for suitable models, i.e., models that are loadable/compilable.
3. To build the database of Subsystems and their meta-information, use `mine.m`.
4. Finally, run the `synthesize.m` script to generate the various synthetic models, which you can then use to evaluate your tool with. 
