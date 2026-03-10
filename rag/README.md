# RAG System with LangChain, Jira API, and PDF Ingestion

This project implements a Retrieval-Augmented Generation (RAG) system using LangChain. It ingests data from Jira (via the Jira API) and from PRD documents in PDF format.

## Structure
- `main.py`: Entry point for the RAG pipeline.
- `jira_ingest.py`: Handles Jira API data ingestion.
- `pdf_ingest.py`: Handles PDF ingestion.
- `vectorstore.py`: Handles vector storage and retrieval.
- `requirements.txt`: Python dependencies.

## Setup
1. Install dependencies: `pip install -r requirements.txt`
2. Configure Jira credentials and PDF paths as needed in `main.py` or via environment variables.

## Usage
Run the pipeline:
```
python main.py
```
