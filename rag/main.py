import os
from dotenv import load_dotenv
load_dotenv()

from jira_ingest import fetch_jira_issues
from pdf_ingest import ingest_pdfs
from md_ingest import ingest_markdown
from postgres_ingest import ingest_postgres_schema
from testrail_ingest import ingest_testrail_cases
from vectorstore import build_vectorstore, query_vectorstore

# Load Jira issues
def load_jira():
    jira_issues = fetch_jira_issues()
    return jira_issues

# Load PDF PRDs
def load_pdfs(pdf_dir):
    pdf_docs = ingest_pdfs(pdf_dir)
    return pdf_docs

if __name__ == "__main__":
    # Set your PDF directory here
    PDF_DIR = os.getenv("PRD_PDF_DIR", "./prd_pdfs")
    API_MD_PATH = os.getenv("API_MD_PATH", "../Labs/Lab10/API_Contracts.md")

    print("Fetching Jira issues...")
    jira_data = load_jira()
    print(f"Fetched {len(jira_data)} Jira issues.")

    print("Ingesting PDF PRDs...")
    pdf_data = load_pdfs(PDF_DIR)
    print(f"Ingested {len(pdf_data)} PDF documents.")

    print("Ingesting API contract markdown...")
    md_data = ingest_markdown(API_MD_PATH)
    print(f"Ingested {len(md_data)} markdown documents.")

    print("Ingesting Postgres schema...")
    try:
        pg_data = ingest_postgres_schema()
        print(f"Ingested {len(pg_data)} Postgres schema documents.")
    except Exception as e:
        print(f"Postgres schema ingestion failed: {e}")
        pg_data = []

    print("Ingesting TestRail test cases...")
    try:
        tr_data = ingest_testrail_cases()
        print(f"Ingested {len(tr_data)} TestRail test cases.")
    except Exception as e:
        print(f"TestRail ingestion failed: {e}")
        tr_data = []

    print("\nSample of ingested documents:")
    docs = jira_data + pdf_data + md_data + pg_data + tr_data
    for i, doc in enumerate(docs[:5]):
        print(f"--- Document {i+1} ---")
        for k, v in doc.items():
            print(f"{k}: {str(v)[:300]}")
        print()

    print("Building vectorstore (persistent, deduplicated)...")
    vs = build_vectorstore(docs, persist=True)
