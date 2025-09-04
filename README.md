# GRANDSLAM: Giant Recomposition AND Synthesis of LArge Models

This is a project for synthesizing large Simulink models for stress testing, scaling, or giant fuzzing. You can create new models that are
- giant sized (>50k Blocks, >10k Subsystems),
- deep (very deep Subsystem hierarchy),
- bushy (shallow, but many Subsystems per level),
- have isomorphic Subsystem tree to a given model,
- are randomly synthesized.
Each model is synthesized using a set subsystems of a corpus of models, like the SLNET-corpus, as building blocks. Suitable subsystems are puzzled together to synthesize huge models. In our case, suitable means, that the subsytems' interfaces have the same inputs and outputs. For compiling models, the types and dimensions also have to fit.

You can use these (giant) synthetic models to test the scalability of your Simulink tool, or to stress test it.



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

As MATLAB sometimes hard crashes, you may have to restart steps 2, and 3 a couple of times, until they completely go through. Progress is saved, even with crashes.

1. In `system_constants.m` state where your `SLNET` directory is located (`models_path`), where you want the useful models stored at (`tame_models_path`)  and where you want the output of the synthesizer to be stored at (`project_dir`).
2. Next, run `clean_models.m` to clean the models from your `models_path`, e.g., all Callbacks are removed, so that they 'behave' later. Models that misbehave at this cleaning process are filtered out.
3. Next, run `gather_models.m`. The `gather_models.m`-script will scan all tamed models for there suitability for typed/untyped interface checks, i.e., models that are loadable/compilable/runnable. A file `modellist.csv` will be created in `project_dir` in this step.
4. To build the database of Subsystems and their dictionaries of meta-information, use `mine.m`. In `project_dir/0` and `project_dir/1` the files `interface2subs.json`, `name2subinfo_complete.json` will be created. These are the dictionaries used in the synthesis. The `0` directory holds all models' subsystem information, while the `1` directory holds the subsystem information of the compilable and runnable models, only.
5. Finally, run the `synthesize.m` script to generate the synthetic models. In `synthesize.m` you can choose which typed/untyped equivalence (line 7) and synthesize strategies (line 8)  you want to use or leave out. Change the modes, according to the list of modes listed in line 6. The `synthesize.m` script will create models and a report at `project_dir/<0,1>/<mode>`.


The scripts with the current settings reproduce our paper's results, but will run for literal days. You probably want to change the number of total models that are scanned in line 32 of `clean_models.m` to something like 1000 or 3000. Further consider to change various constants in `Helper.m`'s `synth_profile` function: reduce time_outs, limit maximum depths, or the desired model count per strategy.


We marked the *Variant points* in the scripts with a comment stating "Varition point".
