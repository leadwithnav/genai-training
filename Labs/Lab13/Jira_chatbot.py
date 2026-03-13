"""
Jira Assistant RAG Agent (CLI)

This script is a CLI-based Retrieval-Augmented Generation (RAG) agent using LangChain v1.x. It answers Jira-related questions by leveraging the ingested ecommerce-Jira.md documentation as its knowledge base. The agent uses OpenAI (GPT-4) for LLM, FAISS for vector search, and a custom Jira search tool. Twilio and resume PDF ingestion have been removed.

Usage:
    1. Set your OpenAI API key in the environment variable OPENAI_API_KEY.
    2. Ensure ecommerce-Jira.md is present in the same directory as this script.
    3. Run the script and ask Jira-related questions at the prompt.
"""


import os
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.document_loaders import TextLoader
from langchain_community.vectorstores import FAISS
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.prompts import PromptTemplate
from langchain_core.tools import Tool
from langchain_classic.agents import create_tool_calling_agent, AgentExecutor
from langchain_classic.chains import RetrievalQA
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get OpenAI API key from environment
openai_api_key = os.getenv("OPENAI_API_KEY")

print(f"[DEBUG] OpenAI API Key loaded: {'Yes' if openai_api_key else 'No'}")

if not openai_api_key:
    raise ValueError("OpenAI API key not found. Please set the OPENAI_API_KEY environment variable.")

# Jira retriever tool
def jira_search_tool(query: str) -> str:
    result = qa_chain.invoke({"query": query})
    # Always return a plain string
    if isinstance(result, dict):
        answer = str(result)
    print(f"[DEBUG] Jira search result: {answer}")
    # Always return the explicit fallback phrase if not found
    if answer.strip() == "" or "I don't know" in answer:
        return "I don't know based on the Jira documentation."
    return answer

jira_tool = Tool(
    name="jira_search",
    func=jira_search_tool,
    description="Use this tool to answer Jira-related questions based on the ecommerce-Jira.md documentation. If the answer is not found, return 'I don't know based on the Jira documentation.' as a string."
)



# Ingest ecommerce-Jira.md as the knowledge base
md_path = "ecommerce-Jira.md"
loader = TextLoader(md_path)
docs = loader.load()

# Split documentation into smaller chunks
text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
split_docs = text_splitter.split_documents(docs)

# Create vector store from split documents
embeddings = OpenAIEmbeddings()
vectorstore = FAISS.from_documents(split_docs, embeddings)
retriever = vectorstore.as_retriever(search_kwargs={"k": 4})


llm = ChatOpenAI(model="gpt-4", temperature=0, api_key=openai_api_key)

# Conversational prompt template for Jira assistant
prompt_template = """
You are Jira Assistant, an expert in Jira project management and workflows. Use the ingested ecommerce-Jira.md documentation to answer user questions about Jira, its features, and best practices. If the answer is not in the documentation, say "I don't know based on the Jira documentation."
Question: {input}
{agent_scratchpad}
"""

qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=retriever,
    return_source_documents=False
)

# Create agent 
agent = create_tool_calling_agent(llm, [jira_tool], PromptTemplate.from_template(prompt_template))
executor = AgentExecutor(agent=agent, tools=[jira_tool])

print("Jira Assistant RAG Chatbot (Autonomous Agent). Type your Jira question (or 'exit' to quit):")
while True:
    question = input("You: ")
    if question.lower() == "exit":
        break
    print(f"[DEBUG] Agent received question: {question}")
    response = executor.invoke({"input": question})
    # Print output from agent
    print("Bot:", response.get("output", response))