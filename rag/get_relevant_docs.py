import os
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

from vectorstore import FAISS_INDEX_PATH
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS

# Resolve FAISS index path relative to this file so that calling code can live
# anywhere on disk and still find the index.
_RAG_DIR = os.path.dirname(os.path.abspath(__file__))
_FAISS_INDEX_ABS = os.path.join(_RAG_DIR, FAISS_INDEX_PATH) if not os.path.isabs(FAISS_INDEX_PATH) else FAISS_INDEX_PATH

def get_relevant_docs(prompt: str, top_k: int = 5):
    """
    Loads the persistent FAISS vectorstore and returns the top_k most relevant documents for the prompt.
    Returns a list of dicts with 'id' and 'content'.
    """
    embeddings = OpenAIEmbeddings()
    if not os.path.exists(_FAISS_INDEX_ABS):
        return []
    vs = FAISS.load_local(_FAISS_INDEX_ABS, embeddings, allow_dangerous_deserialization=True)
    docs = vs.similarity_search(prompt, k=top_k)
    results = []
    for doc in docs:
        doc_id = doc.metadata.get('id', None)
        content = doc.page_content
        results.append({"id": doc_id or "", "content": content})
    return results
