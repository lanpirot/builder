# Synthesizer of (giant) Simulink models

This is a project to synthesize Simulink models for stress testing, scaling, or giant fuzzing. You can create new models that are
- giant sized (>500k Blocks, >100k Subsystems),
- deep (deep Subsystem hierarchy),
- broad (shallow, but many Subsystems),
- have isomorphic Subsystem hierarchy to a given model,
- are randomly built.
Each model is synthesized using a set subsystems of a corpus of models, like the SLNET-corpus, as building blocks. Suitable subsystems are puzzled together to synthesize huge models. In our case, suitable means, that the subsytems' interfaces have the same inputs and outputs. For compiling models, the types and dimensions also have to fit.

You can use the (giant) synthetic models to test the scaling of your tool, or to stress test it.



## Usage
Get the model collection (SLNET)[https://zenodo.org/records/5259648]. Have the model collection unzipped at `models_path` into directories (names of directories are numbers), like this: 
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

1. In `system_constants.m` state where your `SLNET` directory is located (`models_path`) and where you want the output of the synthesizer to be stored at (`project_dir`).
2. Next, run `gather_models.m`. As a full run of all scripts with the complete SLNET set takes literal days, we highly recommend to set the variable `max_number_of_models` (in line 3) to a lower number such as 1000 or 3000. This will also keep the amount of errors down (MATLAB is buggy and tends to crash while compiling some models.) The `gather_models.m`-script will scan the whole database for suitable models, i.e., models that are loadable/compilable/runnable. A file `modellist.csv` will be created in `project_dir`.
3. To build the database of Subsystems and their dictionaries of meta-information, use `mine.m`. In `project_dir/0` and `project_dir/1` the files `interface2subs.json`, `name2subinfo.json` will be created. These are the dictionaries used in the synthesis. The `0` directory holds all models' subsystem information, while the `1` directory holds the subsystem information of the compilable and runnable models, only.
4. Finally, run the `synthesize.m` script to generate the synthetic models. In `synthesize.m` you can choose which synthesize strategies you want to use or leave out in line 6. Change the modes, according to the list of modes listed in line 3. The `synthesize.m` script will create models and a report at `project_dir/<0,1>/<mode>`.
5. Various constants for each mode can be adapted in `Helper.m` in the `synth_profile` function. You can choose how deep models should be, the time_out for stopping synthesis, etc.
