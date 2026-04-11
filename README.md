# Directory for one-shot experiments

## Meta arc

### Iteration steps
1. Perform the task within your coding agent.
2. Generate an initial version of `PLAN.md` with this prompt:
   ```text
   now create PLAN.md with the reproducible, successful steps you took to get here, so we can replay them from where we started (with an empty directory and a running docker instance) to get back to this state.
   ```
3. Close your coding agent or create an new, empty session.
4. Manually remove all unwanted files besides `PLAN.md`
5. Test the intial `PLAN.md` with this prompt:
   ```text
   implement the plan in PLAN.md
   ```
6. Based on results, update `PLAN.md` with this prompt:
   ```text
   now update and correct PLAN.md with the reproducible, successful steps you took to get here, so we can replay them from where we started (with an empty directory and a running docker instance) to get back to this state.
   ```
7. Now do a critique step to review the propsed changes:
   ```text
   look at how PLAN.md has changed over time and reflect on your proposed changes. critique whether they are truly reproducible for the types of changes in past iterations, whether they align with the user's goals over your own implementation details, and avoid overfitting. Then correct them to be future-proof
   ```
8. Use a coding agent Task to test with this prompt:
   ```
   test your changes by spinning up an Task providing it only these exact instructions: "implement the plan in PLAN.md"
   ```

### Abstration steps

* When you see overfitting
  ```text
  I'm concerned that PLAN.md is overfitted to details at the expense of documenting process and want to abstract some parts of the instructions to focus more on the progressive goals instead of repeating implementation details, particularly in the latter steps. At the same time, I want to preserve at least one example of each core methodology. Moreover, I want anyone following this plan to end up at a functionally-equivalent final state at the end. Propose an initial change I could take to attempt to improve this.
  ```
