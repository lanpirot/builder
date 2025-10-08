Find the data (synthesized models, intermediate results) of this project here: [![DOI](https://zenodo.org/badge/808521433.svg)](https://10.5281/zenodo.17296885)

# GRANDSLAM: Linearly Scalable Model Synthesis

This is a project for synthesizing large Simulink models for stress testing, scaling, or giant fuzzing. In its standard settings, you can create new models that are syntactically valid and
- giant sized (>100k Blocks, >15k Subsystems), the strategy that produces these is GIANT,
- deep (50-100 levels deep), the strategy is DEPTH,
- bushy and dense (more shallow, but manymany Subsystems per level), the strategy is WIDTH,
- have isomorphic Subsystem tree to a given model (from the SLNET set), the strategy is AST_MODEL,
- are randomly synthesized, the strategy is RANDOM.
Each model is synthesized using a set of subsystems of a corpus of models, like the SLNET-corpus, as building blocks. Suitable subsystems are puzzled together to synthesize (huge) models. 

You can also create new models with GRANDSLAM that are compilable or simulatable. These models are much smaller and currently not all of the synthesis attempts will result in a compilable/simulatable model.

You can use the synthetic models to test the scalability of Simulink, or your Simulink tool, or to fuzz them.

## Models
This package comes with 4,600 synthesized models of various shapes and sizes. 600 of them are very large.
- In the directory `0` you can find syntactically valid models from our strategies. The largest model is `0/WIDTH/model70.slx` it has more than 4 million model elemnents and is 500MB large.
- In the directory `1` you can find models of which some are compilable and simulatable. The largest compilable model is `1/GIANT/model77.slx`. The largest simulatable model is `1/GIANT/model2.slx`.

You can look up various properties of the models in either `modellist_synthed.csv` or `X/STRATEGY/synth_report.csv` where `X=0` or `X=1` and `STRATEGY` is one of our strategy names.


## ⚠ Disclaimer ⚠
⚠ This is not a normal replication package. ⚠ Our approach is inherently fuzzing Simulink in various of its operations: loading, simulating, copying, saving, closing with a diverse and challenging corpus such as SLNET. 
If you follow our instructions below, most likely you will experience program errors, hard crashes of MATLAB/Simulink, or even system-critical memory leaks. So caution is advised. 
Keeping that in mind, most of our scripts are designed to pick up their work, where they hard crashed the last time. 
So usually, restarting the script; restarting MATLAB and then restarting the script; restarting your PC, then MATLAB, then the script should skip over the bug to continue the work.
We reported a number of bugs to Mathworks, so maybe you won't experience as many issues as we did in the most current MATLAB/Simulink version.



## Usage
We used the model collection [SLNET](https://zenodo.org/records/5259648) for GRANDSLAM. Have the model collection unzipped at some location `models_path` into directories (names of directories are numbers), like this: 
```
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
```

As MATLAB sometimes hard crashes, you may have to restart steps 2, and 3 a couple of times, until they completely go through. Progress is saved, even with crashes.

1. In `system_constants.m` state where your `SLNET` directory is located (`models_path` location from earlier), where you want the useful models stored at (`tame_models_path`), where you want the output of the synthesizer to be stored at (`project_dir`), and optionally where your copy of `project_dir` is in `synthed_models_path`. We used `synthed_models_path` if we restart the synthesis a couple of times, to not ruin prior runs.
2. Next, run `clean_models.m` to clean the models from your `models_path`, e.g., all Callbacks are removed, so that they 'behave' later. Models that misbehave at this cleaning process are filtered out. The cleaned models are put into `tame_models_path`.
3. Next, run `gather_models.m`. The `gather_models.m`-script will scan all cleaned models for their suitability for typed/untyped interface checks, i.e., models that are loadable/compilable/runnable. A file `modellist.csv` will be created in `project_dir` in this step.
4. To build the database of Subsystems and their dictionaries of meta-information, use `mine.m`. In `project_dir/0` (for statically correct models) and `project_dir/1` (for compilable models) the files `interface2subs.json`, `name2subinfo_complete.json` will be created. These are the dictionaries used in the synthesis. The `0` directory holds all models' subsystem information, while the `1` directory holds the subsystem information of the compilable and runnable models, only.
5. Finally, run the `synthesize.m` script to generate the synthetic models. In `synthesize.m` you can choose which typed/untyped equivalence (line 8) and synthesize strategies (line 9)  you want to use or leave out. Change the modes, according to the list of modes listed in line 7. The `synthesize.m` script will create models and a report at `project_dir/<0,1>/<mode>/synth_report.csv`.


### Optional
We used the current settings to produce the results given in our paper. Our scripts ran for days though. You probably want to change the number of total models that are scanned in line 32 of `clean_models.m` to something like 1000 or 3000 (will work good for statically correct models). Further consider to change various constants in `Helper.m`'s `synth_profile` function: reduce time_outs, limit maximum depths, or the desired model count per strategy.

We added these functions to our MATLAB path, to suppress warning and error dialogues, that otherwise will spam your screen and make work near impossible:

`cat MATLAB/warndlg.m`
```
function h = warndlg(varargin)
    disp('[Suppressed warndlg]');
    if nargout > 0
        h = []; % return empty if output is expected
    end
```



`cat errordlg.m`

```
function h = errordlg(varargin)
    disp('[Suppressed errordlg]');
    if nargout > 0
        h = []; % return empty if output is expected
    end
```