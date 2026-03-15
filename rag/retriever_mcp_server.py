from fastmcp import FastMCP
from get_relevant_docs import get_relevant_docs

mcp = FastMCP("RAG Vector Retriever")

@mcp.tool()
def retrieve_new(prompt: str, top_k: int = 5) -> list[dict]:
    """Retrieve relevant documents from the vector DB for a given prompt."""
    docs = get_relevant_docs(prompt, top_k=top_k)
    return docs

if __name__ == "__main__":
    mcp.run()
