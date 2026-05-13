# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code.

## General tips

### Subagents

- Use subagents whenever you can. They help with managing your context window.
- If you have some task that's easily delegatable (e.g. reading logs), subagents are very helpful.
- The tradeoff is how much bandwidth the task requires. For example, if it's a task where you need to read logs to search for something broad and not-well-specified that links to prior context, subagents may not be the perfect tool. It may still be possible to use subagents in these cases, for example delegating more scoped-down tasks, specifying detailed context to the subagent, or requesting high-fidelity outputs from the subagent.
- Exercise your best judgement in when and how to use subagents. This section is primarily to remind you that they're a powerful tool for managing context.

### Concurrency

- When working on a project that involves API calls to an LLM, you should feel free to use default concurrencies in the 100s at least.
- More generally, if a task involves several components that can be run in parallel, you should try to do so rather than running them in sequence. For example, if a task involves running a set of evals on a model, you should think about whether you can run them in parallel rather than one at a time. In some cases this won't be feasible (e.g. because of API concurrency, or because the machine can't handle such parallelism for heavy tasks), but I recommend reasoning through this explicitly wherever applicable.

### Monitoring

- Occasionally, I may ask you to run something that waits on external processes yourself (e.g. a script that starts a training run, or an eval suite). In these cases, I recommend setting up some mechanism that lets you autonomously check in on the process at fixed intervals.
- These check-ins should be after you've already verified that everything that runs immediately and isn't bottlenecked on something external is working as intended. For example, if a run fails with an error immediately, that's something you should fix before retiring to check-ins.
- The right interval will depend on the exact setup, but you should start with more frequent check-ins early in the process to make sure everything is going alright. A good default could be 10 minute check-ins at the start, and slowly easing off to 20-minutes and finally 30-minutes. In the rare cases something is expected to take on the order of a day, you can also increase this to 1- or 2-hour check-ins eventually.
- To help with this monitoring (and to help me read outputs and understand the results), wherever feasible you should have runs write to intermediate progress logs. What this could look like will depend on the exact process—and in some cases it will make more sense to not do this—but as a guiding heuristic it would be helpful to (among other things):
    - Identify if a particular step is taking too long
    - Identify if there are errors in the process, and if so what they are, to fix them as early as possible
    - Sanity check early results to see if they are as expected

## Guidelines for writing code

When making a new codebase from scratch (or fully refactoring an existing codebase), here are some useful heuristics:
- It's generally worth it to spend a lot of time upfront thinking about the right abstractions.
- This could involve figuring out what makes the most sense given the current project spec. Very often it also involves going back and forth with the user about what potential future features or experiments could be added. These aren't intended to always be features the user will definitely want in the future and that you should design the codebase around. Rather, you should treat them as guidelines for how the abstractions should lend toward extensibility.
- In general, keep code short, crisp, and minimal.

Here are some lower-level recommendations:
- I usually use uv, not the system Python interpreter. When trying to run Python code in a project, always try uv first. Only try the system python3 interpreter if uv does not work.
- Run ruff checks on your code after every major addition or update.
- Whenever relevant, update the README of the repository you're working in. A good README is concise, but comprehensive.
- Make commits for every major change that you make. Exercise your own judgement on what constitutes a major change, but in general try not to go overboard.

## When doing LLM research

Sometimes you'll be helping with LLM research. By LLM research, I mean anything from running evaluations of some kind on a model to doing training runs, for example SFT or RL on a model through an API or locally. In these cases I want you to default to saving as much information as you can.

For example, with an evaluation I would prefer if you saved the exact outputs, inputs, etc., from every data point that there is, in case I want to use them for debugging or visualization later, or want to do some analysis later on. With training as well, I obviously want to save the SFT data somewhere where it can be easily accessed in the future. With RL, I want to save the RL rollouts, advantages given to each input in a group, and so on and so on. Basically I want as much data as possible without going extremely overboard. If there is a large RL run, I'm totally fine with just saving all the rollouts, saving all the advantages and stuff.

Also, if there is an LLM judge: the judge prompts, judge outputs. If not, if there's a programmatic scorer or something similar, then just the whatever the equivalent of that would be. I'm sure, in context, you'd be able to figure out what the ideal setup is for this. In general I prefer saving more information. 

## Package Management Commands

Use these commands:

- Install dependencies: `uv add <package>`
- Remove dependencies: `uv remove <package>`
- Sync dependencies: `uv sync`

## Running Python Code

- Run a Python script with `uv run <script-name>.py`; this is preferred over `uv run python <script-name>.py` unless working with a repo that wasn't built with uv.
- Run Python tools like Pytest with `uv run pytest` or `uv run ruff`