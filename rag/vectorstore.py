
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from typing import List, Dict
import os

FAISS_INDEX_PATH = os.getenv("FAISS_INDEX_PATH", "faiss_index")

# Build vectorstore from docs
def build_vectorstore(docs: List[Dict], persist: bool = True):
    """Build or load a FAISS vectorstore from a list of docs, with deduplication by id."""
    embeddings = OpenAIEmbeddings()
    # Try to load existing index
    if persist and os.path.exists(FAISS_INDEX_PATH):
        vs = FAISS.load_local(FAISS_INDEX_PATH, embeddings, allow_dangerous_deserialization=True)
        existing_ids = set()
        for m in vs.docstore._dict.values():
            if hasattr(m, 'metadata') and 'id' in m.metadata:
                existing_ids.add(m.metadata['id'])
    else:
        vs = None
        existing_ids = set()

    # Deduplicate docs by id
    unique_docs = []
    seen_ids = set(existing_ids)
    for doc in docs:
        doc_id = doc.get('id')
        if doc_id and doc_id not in seen_ids:
            unique_docs.append(doc)
            seen_ids.add(doc_id)

    texts = []
    metadatas = []
    for doc in unique_docs:
        if 'content' in doc:
            texts.append(doc['content'])
            metadatas.append({k: v for k, v in doc.items() if k != 'content'})
        else:
            text = f"{doc.get('summary', '')}\n{doc.get('description', '')}"
            texts.append(text)
            metadatas.append({k: v for k, v in doc.items() if k not in ['summary', 'description']})

    if texts:
        if vs:
            vs.add_texts(texts, metadatas=metadatas)
        else:
            vs = FAISS.from_texts(texts, embeddings, metadatas=metadatas)
        if persist:
            vs.save_local(FAISS_INDEX_PATH)
    return vs

# Query vectorstore
def query_vectorstore(vs, query: str):
    """Query the vectorstore and return the most relevant document."""
    docs = vs.similarity_search(query, k=1)
    if docs:
        return docs[0].page_content
    return "No relevant document found."
