"""Regenerate mobile defaults and optionally sync the catalog/assets to a portal checkout.
Usage: python3 tool/sync_content.py [--portal /path/to/agq_admin_portal]
"""
import argparse, json, shutil
from pathlib import Path
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--portal', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
catalog = json.loads((root / 'lib/content/catalog.json').read_text())
def quote(value): return json.dumps(value, ensure_ascii=False).replace('$', r'\$')
text = '// Generated from catalog.json. Keep the portal catalog in sync.\nconst defaultAppText = <String, String>{\n'
text += ''.join(f'  {quote(e["id"])}: {quote(e["defaultValue"])},\n' for e in catalog if e['kind'] != 'image')
text += '};\n\nconst defaultAppImages = <String, String>{\n'
text += ''.join(f'  {quote(e["defaultValue"])}: {quote(e["id"])},\n' for e in catalog if e['kind'] == 'image') + '};\n'
(root / 'lib/content/content_defaults.dart').write_text(text)
if args.portal:
    for directory in ['src/content', 'functions/src/content']:
        destination = args.portal / directory
        destination.mkdir(parents=True, exist_ok=True)
        shutil.copy2(root / 'lib/content/catalog.json', destination / 'catalog.json')
    for entry in catalog:
        if entry['kind'] == 'image':
            for directory in ['public/app-content', 'functions/assets/app-content']:
                destination = args.portal / directory
                destination.mkdir(parents=True, exist_ok=True)
                shutil.copy2(root / entry['defaultValue'], destination / Path(entry['defaultValue']).name)
