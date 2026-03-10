import os
from typing import List, Dict
from PyPDF2 import PdfReader

def ingest_pdfs(pdf_dir: str) -> List[Dict]:
    """Ingest all PDF files in a directory and return as list of dicts."""
    docs = []
    for fname in os.listdir(pdf_dir):
        if fname.lower().endswith('.pdf'):
            path = os.path.join(pdf_dir, fname)
            try:
                reader = PdfReader(path)
                text = "\n".join(page.extract_text() or '' for page in reader.pages)
                docs.append({
                    "id": fname,
                    "content": text,
                    "source": path
                })
            except Exception as e:
                print(f"Failed to read {fname}: {e}")
    return docs
