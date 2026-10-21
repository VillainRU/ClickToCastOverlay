"""Build separate CurseForge-compatible Retail and Forever archives."""
from pathlib import Path
import re
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "ClickToCastOverlay"
VERSION = re.search(r"^## Version: (.+)$", (SOURCE / "ClickToCastOverlay.toc").read_text(), re.M)[1]

for flavor, interface, suffix in [("retail", "120105", ""), ("forever", "16001", "-forever")]:
    version = VERSION + suffix
    target = ROOT / "dist" / flavor / "ClickToCastOverlay"
    target.mkdir(parents=True, exist_ok=True)
    for name in ["Core.lua", "Options.lua"]:
        shutil.copy2(SOURCE / name, target / name)
    toc = (SOURCE / "ClickToCastOverlay.toc").read_text()
    toc = re.sub(r"^## Interface: .+$", "## Interface: " + interface, toc, flags=re.M)
    toc = re.sub(r"^## Version: .+$", "## Version: " + version, toc, flags=re.M)
    (target / "ClickToCastOverlay.toc").write_text(toc)
    shutil.copy2(ROOT / "LICENSE", target / "LICENSE")
    (target / "README.md").write_text("# " + flavor.title() + " package " + version + "\n\n" + (ROOT / "README.md").read_text().split("## Development")[0])
    russian = (ROOT / "docs" / "README-ruRU.md").read_text()
    if flavor == "forever":
        russian = russian.replace("WoW Retail 12.1.5 (Interface 120105)", "WoW Forever 1.60.1 (Interface 16001)")
        russian = russian.replace("_retail_/Interface/AddOns/", "_classic_beta_/Interface/AddOns/")
    (target / "README-ruRU.md").write_text(russian)
    archive = ROOT / "dist" / ("ClickToCastOverlay-" + version + ".zip")
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as bundle:
        for name in ["ClickToCastOverlay.toc", "Core.lua", "Options.lua", "LICENSE", "README.md", "README-ruRU.md"]:
            bundle.write(target / name, "ClickToCastOverlay/" + name)
    with zipfile.ZipFile(archive) as bundle:
        assert bundle.testzip() is None
        assert all(name.startswith("ClickToCastOverlay/") for name in bundle.namelist())
    print(archive.relative_to(ROOT))
