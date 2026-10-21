# Project workflow

The owner requests that every addon update be committed and pushed to GitHub and published to the existing CurseForge project (1746564) for both Retail and Forever by default. This is standing authorization; do not ask again for routine pushes or uploads.

For each update, bump the version, update the changelog, build both archives with `python3 scripts/build.py`, and run the addon tests against both generated packages. Upload the current packages with the appropriate game versions and release notes. Verify file status and report moderation as pending until approval is observed. If an operation fails or requires the owner to sign in, report the exact blocker rather than claiming it was published.

Repository: https://github.com/VillainRU/ClickToCastOverlay
CurseForge: https://www.curseforge.com/wow/addons/click-to-cast-overlay
