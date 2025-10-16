# How to contribute

Contributions are welcome to this repo, but we do have a few guidelines for
contributors.

## Open an issue and pull request for changes

All submissions, including those from project members, are required to go through
review. We use [GitHub Pull Requests](https://help.github.com/articles/about-pull-requests/)
for this workflow, which should be linked with an issue for tracking purposes.
A GitHub action will be run against your PR to ensure code standards have been
applied.

> NOTE: The devcontainer in this repo contains the pre-commit and supporting tools by default.

[pre-commit] is used to ensure that all files have consistent formatting and to
avoid committing secrets.

1. Install [pre-commit] in a virtual python environment or globally: see
   [instructions](https://pre-commit.com/#installation)
2. Fork and clone this repo
3. Install pre-commit hook to git

   E.g.

   ```shell
   uv sync --all-extras --all-packages
   uv run pre-commit install --hook-type commit-msg --hook-type pre-commit
   ```

4. Create a new branch for changes
5. Execute `pytest` tests to validate changes

   ```shell
   uv run pytest -v
   ```

6. Commit and push changes for PR

   The hook will ensure that `pre-commit` will be run against all staged changes
   during `git commit`.

[pre-commit]: https://pre-commit.com/
