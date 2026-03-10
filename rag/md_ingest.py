import os
from typing import List, Dict

def ingest_markdown(md_path: str) -> List[Dict]:
    """Ingest a markdown file and return as a list of dicts."""
    docs = []
    if os.path.exists(md_path):
        with open(md_path, 'r', encoding='utf-8') as f:
            text = f.read()
            docs.append({
                "id": os.path.basename(md_path),
                "content": text,
                "source": md_path
            })
    return docs
